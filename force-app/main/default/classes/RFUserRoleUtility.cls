/* **************************************************************************
* Helper: RFUserRoleUtility
* Created by Jordan Ojeda, June 20, 2024
*
* Purpose/Methods: Orchestration class to calculate and return the remaining capacity of a user role
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFUserRoleUtility 
{

    private Logger theLogger;
    private string classContext;

    public RFUserRoleUtility(Logger log){
        this.theLogger = log;
        this.classContext = 'RFUserRoleUtility';
    }

    /**
    * Receives list of User roles, populates and returns a map of roles by Capacity Definition
    * @param List<UserRole__c> User roles
    * @return Map<Id, List<UserRole__c>> Map of user roles separated by Capacity Definitions
    */
    public Map<Id, List<UserRole__c>> populateRoleByCapDefIdMap(List<UserRole__c> userRoles) 
    {
        Map<Id, List<UserRole__c>> roleByCapDefId = new Map<Id, List<UserRole__c>>();
        for(UserRole__c userRole : userRoles) 
        {
            if(!roleByCapDefId.containsKey(userRole.CapacityDefinition__c)){
                roleByCapDefId.put(userRole.CapacityDefinition__c, new List<UserRole__c>());
            } 

            roleByCapDefId.get(userRole.CapacityDefinition__c).add(userRole);
            
        }
        
        return roleByCapDefId;
    }

    /**
    * Receives list of User roles, populates and returns a map of roles by User
    * @param List<UserRole__c> User roles
    * @return Map<Id, List<UserRole__c>> Map of user roles separated by User
    */
    public Map<Id, List<UserRole__c>> populateRoleByUserIdMap(List<UserRole__c> userRoles) 
    {
        Map<Id, List<UserRole__c>> roleByUserId = new Map<Id, List<UserRole__c>>();
        
        for(UserRole__c userRole : userRoles) 
        {
            if(!roleByUserId.containsKey(userRole.User__c)){
                roleByUserId.put(userRole.User__c, new List<UserRole__c>());
            }

            roleByUserId.get(userRole.User__c).add(userRole);
            
        }
        
        return roleByUserId;
    }


    /**
    * Generates and returns a WHERE clause string for a given list of User Roles
    * @param List<UserRole__c> User roles
    * @return String WHERE clause
    */
    private String buildWhereClause(List<UserRole__c> userRoles)
    {
        String whereClause ='';
        for(UserRole__c userRole :userRoles){
            //whereClause += 'Id = \''+ userRole.Id + '\' OR ';
            whereClause +=  '\'' + userRole.User__c + '\',';
        }
        whereClause = '(' + whereClause.removeEnd(',') + ')';

        return whereClause;
    }


   
     /**
    * Calculates and returns the remaining capacity for a list of User Roles
    * @param List<UserRole__c> User roles
    * @return Double Remaining capacity
    */
    private list<RFUserRoleCapacity> calculateCapacity(List<UserRole__c> userRoles, integer capacityCurrentUserRole)
    {
        list<RFUserRoleCapacity> resultWrappers = new list<RFUserRoleCapacity>();
        
        for(UserRole__c userRole : userRoles){
            RFUserRoleCapacity resultWrapper = new RFUserRoleCapacity(userRole, capacityCurrentUserRole);
            
            resultWrappers.add(resultWrapper);
        }
        return resultWrappers;
    }

     /**
    * Collects and returns a list of remaining capacities by user
    * @param List<CapacityDefinition__c> Capacity Definitions
    * @param Map<Id, List<UserRole__c>> Map of roles by Capacity Definition
    * @param Map<Id, List<UserRole__c>> Map of roles by User
    * @return List<RFUserRoleCapacity> Remaining capacities
    */
    public List<RFUserRoleCapacity> collectRemainingCapacities(List<CapacityDefinition__c> capDefs, Map<Id, List<UserRole__c>> roleByCapDefId, Map<Id, List<UserRole__c>> roleByUserId)
    {
        List<RFUserRoleCapacity> capacityList = new List<RFUserRoleCapacity>();
        
        for(CapacityDefinition__c cap: capDefs){
            String whereClause = buildWhereClause(roleByCapDefId.get(cap.Id));
            String capacityFilter = cap.CapacityFilter__c.replace('filter', whereClause);
            String finalQueryString = 'SELECT ' + cap.GroupField__c + ',' + 'COUNT(Id) recordsCount FROM ' + cap.APIObjectName__c + ' WHERE ' + capacityFilter + ' GROUP BY ' + cap.GroupField__c;
            System.debug('[RFUserRoleUtility] - finalQueryString: '+ finalQueryString);
            List<AggregateResult> aggResultList = Database.query(finalQueryString);
            System.debug('[RFUserRoleUtility] - aggResultList: '+ aggResultList);

            //log
            theLogger.debug(' {0} | Capacity Definition: {1}', new Object[]{classContext, cap.Id});
            //log
            theLogger.debug(' {0} | Capacity Definition query: {1}', new Object[]{classContext, finalQueryString});

            for(AggregateResult ar : aggResultList){
                List<UserRole__c> userRoleList = roleByUserId.get((Id)ar.get(cap.GroupField__c));
                integer capacityCurrentUserRole = (Integer)ar.get('recordsCount');

                if(userRoleList != null && !userRoleList.isEmpty()){
                    list<RFUserRoleCapacity> resultWrappers = calculateCapacity(userRoleList, capacityCurrentUserRole);
                    capacityList.addAll(resultWrappers);
                }
            }
        }
        
        return capacityList;
    }
    

    public List<RFUserRoleCapacity> getCapacitiesPerRole(List<RFUserRoleCapacity> remainingCapacities, List<UserRole__c> userRoles)
    {
        //log
        theLogger.debug(' {0} | User Role Capacities results', new Object[]{classContext});

        Map<Id, RFUserRoleCapacity> capacityByUserRoleMap = new Map<Id, RFUserRoleCapacity>();
        for(RFUserRoleCapacity capacity: remainingCapacities)
        {
            capacityByUserRoleMap.put(capacity.userRoleId, Capacity);
            //log
            theLogger.debug(' {0} | {1}', new Object[]{classContext, capacity.print()});
        }

        for(UserRole__c userRole: userRoles)
        {
            if(!capacityByUserRoleMap.containsKey(userRole.id)){
                RFUserRoleCapacity capacity = new RFUserRoleCapacity(userRole, 0);
                capacityByUserRoleMap.put(userRole.id, capacity);  
                //log
                theLogger.debug(' {0} | {1}', new Object[]{classContext, capacity.print()}); 
            }
        }

        return capacityByUserRoleMap.values();
    }

    public List<CapacityDefinition__c> getCapacityDefinitions(Set<Id> capacityDefinitionIds)
    {
        // Fetching Capacity Definitions related to roles in current context
        List<CapacityDefinition__c> capacityDefinitions = [SELECT Id, CapacityFilter__c, GroupField__c,APIObjectName__c  FROM CapacityDefinition__c WHERE Id IN :capacityDefinitionIds];
        return capacityDefinitions;
    }

    public Set<Id> getCapacityDefinitionRefs(List<UserRole__c> userRoles)
    {
        Set<Id> capacityDefinitionRefs = new Set<Id>();

        for(UserRole__c userRole : userRoles)
        {
            capacityDefinitionRefs.add(userRole.capacityDefinition__c);
        }

        return capacityDefinitionRefs;
    }
}