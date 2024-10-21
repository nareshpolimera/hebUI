/* **************************************************************************
* Service: RFAssignmentCountService
* Created by Joel Ojeda, July 12, 2024
*
* Purpose/Methods: Service class to support Assigment Count View LWC
*
* Unit Test: RFAssignmentCountServiceTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFAssignmentCountService {

    @AuraEnabled(cacheable=true)
    public static List<OptionValue> getRoleOptions() {
        List<OptionValue> results = new List<OptionValue>();
        results.add(new OptionValue('',''));
        Set<String> roleLst = new Set<String>();

        //get all users and roles
        for( UserRole__c urole: [SELECT Id,Name,
                        Available__c,
                        Role__c,
                        User__c,
                        User_name__c,
                        CapacityDefinition__c,
                        CapacityDefinition__r.Name
                        FROM UserRole__c]){

            if(urole.Role__c != null){
                if(!roleLst.contains(urole.Role__c)){
                    results.add(new OptionValue(urole.Role__c,urole.Role__c));
                    roleLst.add(urole.Role__c);
                }
            }
        }
        System.debug('[RFAssignmentCountService] - getRoleOptions: '+results);
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<OptionValue> getGroupOptions(String role) {
        List<OptionValue> results = new List<OptionValue>();
        results.add(new OptionValue('',''));
        Set<Id> groupList = new Set<Id>();

        for(Pooling_Member__c member : [SELECT Id,
                                        Pooling_Group__c,
                                        Pooling_Group__r.name
                                        FROM Pooling_Member__c 
                                        WHERE User_Role__r.Role__c = :role]){
            if(!groupList.contains(member.Pooling_Group__c)){
                results.add(new OptionValue(member.Pooling_Group__r.name,member.Pooling_Group__c));
                groupList.add(member.Pooling_Group__c);
            }
        }

        System.debug('[RFAssignmentCountService] - getGroupOptions: '+results);
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<OptionValue> getUserOptions(String role) {
        List<OptionValue> results = new List<OptionValue>();
        results.add(new OptionValue('',''));
        Set<String> userList = new Set<String>();

        //get all users and roles
        for( UserRole__c urole: [SELECT Id,Name,
                        Available__c,
                        Role__c,
                        User__c,
                        User_name__c,
                        CapacityDefinition__c,
                        CapacityDefinition__r.Name
                        FROM UserRole__c
                        WHERE Role__c = :role]){

            if(urole.User__c != null){
                if(!userList.contains(urole.User__c)){
                    results.add(new OptionValue(urole.User_name__c,urole.User__c));
                    userList.add(urole.User__c);
                }
            }
        }
        System.debug('[RFAssignmentCountService] - getUserOptions: '+results);
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AssignmentCount> getAssigmnetCount(String role, String userId, String groupId) {
        System.debug('[RFAssignmentCountService] - getAssigmnetCount - role '+role);
        System.debug('[RFAssignmentCountService] - getAssigmnetCount - userId '+userId);
        System.debug('[RFAssignmentCountService] - getAssigmnetCount - groupId '+groupId);

        List<AssignmentCount> results = new List<AssignmentCount>();
        
        //query user roles to calculate capacity
        List<UserRole__c> uroles = queryUserRoles(role,userId,groupId);

        //call capacity calculation engine
        RFCapacityCalculationEngine ccEngine = new RFCapacityCalculationEngine();
        List<RFUserRoleCapacity> capacityResults = ccEngine.calculateUserRoleCapacity(uroles);

        if(results != null){
            for(RFUserRoleCapacity urc : capacityResults){
                results.add(new AssignmentCount(urc));
            }
        }

        return results;
    }

    private static List<UserRole__c> queryUserRoles(String role, String userId, String groupId){
        List<UserRole__c> results = new List<UserRole__c>();
        if(!String.isEmpty(groupId)){
            //query pooling members before query user roles
            if(!String.isEmpty(userId)){
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
                                                WHERE Pooling_Group__c = :groupId
                                                AND User_Role__r.Role__c = :role
                                                AND User_Role__r.User__c = :userId]){
                    results.add(member.User_Role__r);
                }
            }
            else{
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
                                                WHERE Pooling_Group__c = :groupId
                                                AND User_Role__r.Role__c = :role]){
                    results.add(member.User_Role__r);
                }
            }
        }
        else if(!String.isEmpty(userId)){
            results = [SELECT Id,Name,
                        Available__c,
                        CapacityDefinition__c,
                        External_Occupation__c,
                        MaxCapacity__c,
                        Role__c,
                        User__c,
                        User_name__c
                        FROM UserRole__c
                        WHERE User__c = :userId AND
                        Role__c = :role];
        }
        else{
            results = [SELECT Id,Name,
                        Available__c,
                        CapacityDefinition__c,
                        External_Occupation__c,
                        MaxCapacity__c,
                        Role__c,
                        User__c,
                        User_name__c
                        FROM UserRole__c
                        WHERE Role__c = :role];
        }
    
        return results;
    }

    public class AssignmentCount {
        @AuraEnabled
        public Id userRoleId { get; set; }
        @AuraEnabled
        public Decimal occupation { get; set; }
        @AuraEnabled
        public Decimal maxCapacity { get; set; }
        @AuraEnabled
        public Decimal capacity { get; set; }
        @AuraEnabled
        public String roleName { get; set; }
        @AuraEnabled
        public Id userId { get; set; }
        @AuraEnabled
        public String userName { get; set; }
        @AuraEnabled
        public String userUrl { get; set; }
        @AuraEnabled
        public boolean available { get; set; }
 
        public AssignmentCount(RFUserRoleCapacity userRole) {
            this.userRoleId = userRole.userRoleId;
            this.occupation = userRole.occupation;
            this.maxCapacity = userRole.maxCapacity;
            this.roleName = userRole.role;
            this.userId = userRole.userId;
            this.userName = userRole.userName;
            this.userUrl = '/'+userRole.userId;
            this.available = userRole.available;
            this.capacity = userRole.getCapacity();
        }
    }

    public class OptionValue {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }

        public OptionValue(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}