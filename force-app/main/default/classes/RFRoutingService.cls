/* **************************************************************************
* Trigger: RFRoutingService
* Created by Joel Ojeda, June 26, 2024
*
* Purpose/Methods: Orchestration class to find winning user(s) for a given list of records
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFRoutingService {
    
    private Logger theLogger;
    private string classContext;

    public RFRoutingService(){
        this.theLogger = new Logger('Routing Framework');
        this.classContext = 'RFRoutingService';
    }

    public RFRoutingService(Logger log){
        this.theLogger = log;
        this.classContext = 'RFRoutingService';
    }

    /**
    * Receives list of records to find winning user(s) based on role and capacity
    * @param List<sObject> List of records to find winning user(s)
    * @param String Role name to find winning user(s)
    * @return List<RFRoutingUser> List of winning users
    */
    public List<RFRoutingUser> getWinningUser(List<sObject> records, String role){
        List<RFRoutingUser> result;
		
        if(records == null || records.isEmpty()){
            return null;
        }

        //call rule evaluation engine to get list of matching rules
        RFRuleEvaluationEngine ruleEngine = new RFRuleEvaluationEngine(theLogger);
        List<RFRuleMatch> matchingRules = ruleEngine.evaluateRules(records,role);

        System.debug('[RFRoutingService] matchingRules: '+ matchingRules);
        if(!checkRuleResults(matchingRules)){
            //log
            theLogger.info(' {0} | No matching rules found.', new Object[]{classContext});
            return null;
        }

        //query pooling members with user roles
        UserRoleInfo userRoleData = getUserRoles(matchingRules,role);
        System.debug('[RFRoutingService] userRoleData: '+ userRoleData.hasData());

        if(userRoleData.hasData()){
            //call capacity calculation engine
            RFCapacityCalculationEngine ccengine = new RFCapacityCalculationEngine(theLogger);
            List<RFUserRoleCapacity> capacityResults = ccengine.calculateUserRoleCapacity(userRoleData.getAllRoles());
            System.debug('[RFRoutingService] capacityResults: '+ capacityResults);

            //group user role candidates per record
            List<RFUserRoleCandidates> candidates = groupUserRoles(matchingRules,userRoleData.rolesByGroupMap);
            System.debug('[RFRoutingService] candidates: '+ candidates);

            //call user selection engine to find the winning users
            RFUserSelectionEngine routingEngine = new RFUserSelectionEngine(theLogger);
            result = routingEngine.selectWinningUser(candidates,capacityResults);
            system.debug('result :'+ result);
        }
        else{
            //log
            theLogger.info(' {0} | END | User Roles not found for matching rules.', new Object[]{classContext});
        }

        if(result != null && result.isEmpty()){
            return null;
        }else{
            return result;
        }
    }

    private boolean checkRuleResults(List<RFRuleMatch> matchingRules){
        if(matchingRules == null || matchingRules.isEmpty()){
            return false;
        }

        boolean result = false;
        for(RFRuleMatch rm : matchingRules){
            result = result || rm.hasMatch();
        }

        return result;
    }

    private List<RFUserRoleCandidates> groupUserRoles(List<RFRuleMatch> matchingRules, Map<Id,List<UserRole__c>> rolesMap){
        List<RFUserRoleCandidates> candidates = new List<RFUserRoleCandidates>();
        for(RFRuleMatch rm : matchingRules){
            if(rm.hasMatch()){
                RFUserRoleCandidates uCandidates = new RFUserRoleCandidates(rm.record);
                for(Id groupId : rm.getGroupIds()){
                    List<UserRole__c> uRoles = rolesMap.get(groupId);
                    uCandidates.addCandicates(uRoles);
                }
                candidates.add(uCandidates);
            }
        }
        return candidates;
    }

    private UserRoleInfo getUserRoles(List<RFRuleMatch> matchingRules, String role){
        UserRoleInfo result = new UserRoleInfo();
        Set<Id> poolingGroupIds = new Set<Id>();

        theLogger.info(' START | Finding User Roles for matching rules.');

        for(RFRuleMatch rm : matchingRules){
            poolingGroupIds.addAll(rm.getGroupIds());
        }

        //query pooling members with user roles
        Map<Id,List<UserRole__c>> rolesMap = new Map<Id,List<UserRole__c>>();
        for(Pooling_Member__c member : [SELECT Id, User_Role__c,
                                            User_Role__r.Available__c,
                                            User_Role__r.CapacityDefinition__c,
                                            User_Role__r.MaxCapacity__c,
                                            User_Role__r.Role__c,
                                            User_Role__r.User__c,
                                            User_Role__r.External_Occupation__c,
                                            User_Role__r.User_name__c,
                                            Pooling_Group__c
                                            FROM Pooling_Member__c 
                                            WHERE Pooling_Group__c IN :poolingGroupIds
                                            AND User_Role__r.Role__c = :role
                                            AND User_Role__r.Available__c = true
                                            AND User_Role__r.User__r.IsActive = true]){
            result.addPoolingMember(member);
        }

        return result;
    }

    /**
    * Received a record to find possible candidates based on role and capacity
    * @param sObject Record to find candidates
    * @param String Role name
    * @return List<RFRoutingUser> List of candidate users
    */
    public List<RFUserRoleCapacity> getCandicateUsers(sObject record, String role){
        List<RFUserRoleCapacity> result = new List<RFUserRoleCapacity>();

        if(record == null){
            return null;
        }
        
        //call rule evaluation engine to get list of matching rules
        List<sObject> records = new List<sObject>{record};
        RFRuleEvaluationEngine ruleEngine = new RFRuleEvaluationEngine(theLogger);
        List<RFRuleMatch> matchingRules = ruleEngine.evaluateRules(records,role);
		System.debug('RFRuleMatch - matchingRules'+matchingRules);
        
        if(!checkRuleResults(matchingRules)){
            //log
            theLogger.info(' {0} | No matching rules found.', new Object[]{classContext});
            return null;
        }

        //query pooling members with user roles
        UserRoleInfo userRoleData = getUserRoles(matchingRules,role);

        if(userRoleData.hasData()){
            //call capacity calculation engine
            RFCapacityCalculationEngine ccengine = new RFCapacityCalculationEngine(theLogger);
            List<RFUserRoleCapacity> capacityResults = ccengine.calculateUserRoleCapacity(userRoleData.getAllRoles());

            //group user role candidates per record
            List<RFUserRoleCandidates> candidates = groupUserRoles(matchingRules,userRoleData.rolesByGroupMap);

            if(candidates == null || candidates.isEmpty()){
                //log
                theLogger.info(' {0} | Candidates not found for matching rules.', new Object[]{classContext});
                return null;
            }

            //get capacity info for each candidate to return
            for(UserRole__c uRole : candidates[0].userRoles){
                for(RFUserRoleCapacity capacity : capacityResults){
                    if (uRole.User__c == capacity.userId && uRole.Role__c == capacity.role) {
                        result.add(capacity);
                    }
                }
            }
        }   
        else{
            //log
            theLogger.info(' {0} | END | User Roles not found for matching rules.', new Object[]{classContext});
        }

        if(result != null && result.isEmpty()){
            return null;
        }else{
            return result;
        }
    }

    public class UserRoleInfo{
        public Map<Id,List<UserRole__c>> rolesByGroupMap;
        public Map<String,UserRole__c> allRoles;

        public UserRoleInfo(){
            this.rolesByGroupMap = new Map<Id,List<UserRole__c>>();
            this.allRoles = new Map<String,UserRole__c>();
        }

        public void addPoolingMember(Pooling_Member__c member){       
            //add user role to map by group
            if(rolesByGroupMap.get(member.Pooling_Group__c) == null){
                rolesByGroupMap.put(member.Pooling_Group__c,new List<UserRole__c>());
            }
            rolesByGroupMap.get(member.Pooling_Group__c).add(member.User_Role__r);

            //generate key to list of roles
            String key = member.User_Role__r.User__c + '_' + member.User_Role__r.Role__c;
            allRoles.put(key,member.User_Role__r);
        }

        public List<UserRole__c> getAllRoles(){
            return allRoles.values();
        }

        public boolean hasData(){
            return !allRoles.isEmpty();
        }
    }
}