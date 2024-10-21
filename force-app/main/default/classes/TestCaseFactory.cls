public class TestCaseFactory {
    
    /* 
* Create 5 Users
* Create Pooling Groups
* Designated Employee
* Senior Complaints Handler
* Senior Designated Employee
* Customer Care Complaint Handler
* Create Assignment Rules
*
* Create Assignment Details
* Create Pooling Members
* Create User Roles
*/
    public static void initTestData() {
        
        Profile systemAdminProfile = [SELECT Id, Name
                                      FROM Profile
                                      WHERE Name =: Label.SystemAdmin_Profile_Name]; 
        List<User> usersList = new List<User>();
        List<Pooling_Group__c> poolingGroupsList = new List<Pooling_Group__c>();
        List<UserRole__c> userRolesList = new List<UserRole__c>();
        List<Pooling_Member__c> poolingMembersList = new List<Pooling_Member__c>();
        List<Assignment_Rule__c> assignementRulesList = new List<Assignment_Rule__c>(); 
        List<Assignment_Rule_Detail__c> assignmentRuleDetailsList = new List<Assignment_Rule_Detail__c>();
        
        usersList.add(createUser(systemAdminProfile.Id,
                             'dEmployeeUser@chip.ca',
                             'dEmployeeUser@chip.ca',
                             'designatedEmployee',
                             'User','deUser'));
        
        
        usersList.add(createUser(systemAdminProfile.Id,
                             'SCHUser@chip.ca',
                             'SCHUser@chip.ca',
                             'seniorComplaints',
                             'HandlerUser','schUser'));
        
        usersList.add(createUser(systemAdminProfile.Id,
                             'SDEUser@chip.ca',
                             'SDEUser@chip.ca',
                             'seniorDesignated',
                             'EmployeeUser','sdeUser'));
        
        usersList.add(createUser(systemAdminProfile.Id,
                             'CCCHUser@chip.ca',
                             'CCCHUser@chip.ca',
                             'customerCareComplaint',
                             'HandlerUser','cchUser' ));
        
        insert usersList;
        
        poolingGroupsList.Add(createPoolingGroup('Designated Employee',TRUE,'This group helps case to redirect to DE employees when user Escalates the case.','Capacity'));
        poolingGroupsList.Add(createPoolingGroup('Senior Complaints Handler',TRUE,'Group for Senior Complaints Handler','Capacity'));
        poolingGroupsList.Add(createPoolingGroup('Senior Designated Employee',TRUE,'Group for Senior Designated Employee','Capacity'));
        poolingGroupsList.Add(createPoolingGroup('Customer Care Complaint Handler',TRUE,'Group for Customer Care Complaint Handler','Capacity'));
        
        insert poolingGroupsList;
        
        userRolesList.Add(createUserRole('DEUser',10,[SELECT ID FROM USER Where Email='dEmployeeUser@chip.ca' LIMIT 1].Id,'DE'));
        userRolesList.Add(createUserRole('SCHUser',10,[SELECT ID FROM USER Where Email='SCHUser@chip.ca' LIMIT 1].Id,'SCH'));
        userRolesList.Add(createUserRole('SDEUser',10,[SELECT ID FROM USER Where Email='SDEUser@chip.ca' LIMIT 1].Id,'SDE'));
        userRolesList.Add(createUserRole('CCCHUser',10,[SELECT ID FROM USER Where Email='CCCHUser@chip.ca' LIMIT 1].Id,'CCCH'));
        
        insert userRolesList;
        
        poolingMembersList.Add(createPoolingMember(poolingGroupsList[0].Id,userRolesList[0].Id));
        poolingMembersList.Add(createPoolingMember(poolingGroupsList[1].Id,userRolesList[1].Id));
        poolingMembersList.Add(createPoolingMember(poolingGroupsList[2].Id,userRolesList[2].Id));
        poolingMembersList.Add(createPoolingMember(poolingGroupsList[3].Id,userRolesList[3].Id));
        
        insert poolingMembersList;
        
        assignementRulesList.Add(createAssignmentRule(poolingGroupsList[0].Id,'DE'));
        assignementRulesList.Add(createAssignmentRule(poolingGroupsList[1].Id,'SCH'));
        assignementRulesList.Add(createAssignmentRule(poolingGroupsList[2].Id,'SDE'));
        assignementRulesList.Add(createAssignmentRule(poolingGroupsList[3].Id,'CCCH'));
		
        insert assignementRulesList;
        
        assignmentRuleDetailsList.Add(createAssignmentRuleDetail('Handling Level must be 1',assignementRulesList[0].Id,'1','Complaint_Handling_Level__c','Level 1','equals'));
        assignmentRuleDetailsList.Add(createAssignmentRuleDetail('Handling Level One',assignementRulesList[1].Id,'1','Complaint_Handling_Level__c','Level 2','equals'));
        assignmentRuleDetailsList.Add(createAssignmentRuleDetail('Handling Level',assignementRulesList[2].Id,'1','Complaint_Handling_Level__c','Level 3','equals'));
        assignmentRuleDetailsList.Add(createAssignmentRuleDetail('Handling Level',assignementRulesList[3].Id,'1','Complaint_Handling_Level__c','Level 1','equals'));

        insert assignmentRuleDetailsList;
        
        Account personAccount = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john.doe@example.com',
            Phone = '123-456-7890',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()
        );
        
        insert personAccount;
        
    }
    
    private static User createUser(string profileId,string username,
                                   string email,string firstName,string lastName,string alias)
    {
        User newUser = new User(ProfileId = profileId,
                                Username = username,
                                Email = email,
                                FirstName = firstName,
                                LastName = lastName,
                                TimeZoneSidKey = 'GMT',
                                LocaleSidKey = 'en_US',
                                Alias = alias,
                                EmailEncodingKey = 'UTF-8',
                                LanguageLocaleKey = 'en_US',
                                IsActive = true,
                                Business_Unit__c='Consumer Sales'

                               );
        return newUser;
    }
    
    Private static Pooling_Group__c createPoolingGroup(string name,boolean isActive,
                                                       string descr,string selectionType)
    {
        Pooling_Group__c newPoolingGroup = new Pooling_Group__c(
            Name = name,
            Active__c = isActive,
            Description__c = descr,
            User_Selection_Type__c = selectionType);
        
        return newPoolingGroup;
        
    }
    
    Private static UserRole__c createUserRole(string name,integer maxCapacity,
                                              Id userId,string roleName)
    {
        UserRole__c newUserRole = new UserRole__c(
            Name = name,
            MaxCapacity__c  = maxCapacity,
            User__c  = userId,
            Role__c = roleName,
			Available__c = TRUE
        );
        
        return newUserRole;
        
    }
    
    Private static Pooling_Member__c createPoolingMember(Id poolingGroupId,Id userRoleId)
    {
        Pooling_Member__c newPoolingMember = new Pooling_Member__c(
            Pooling_Group__c = poolingGroupId,
            User_Role__c = userRoleId
        );
        
        return newPoolingMember;
        
    }
    
    Private static Assignment_Rule__c createAssignmentRule(Id poolingGroupId,string roleName)
    {
        Assignment_Rule__c newAssignmentRule = new Assignment_Rule__c(
            Pooling_Group__c = poolingGroupId,
            Role__c = roleName,
            Object__c = 'Case',
            Rule_Logic__c = '1',
            Active__c = TRUE
        );
        
        return newAssignmentRule;
        
    }
    
     Private static Assignment_Rule_Detail__c createAssignmentRuleDetail(string name,id assignmentRuleId,
                                                    string ruleId,string fieldName,
                                                   string value,string operator)
    {
        Assignment_Rule_Detail__c newAssignementRuleDetails = new Assignment_Rule_Detail__c(
            Name = name,
            Assignment_Rule__c = assignmentRuleId,
            Rule_Id__c = ruleId,
            Field__c = fieldName,
            Value__c = value,
            Operator__c = operator
        );
        
        return newAssignementRuleDetails;
    }
    
}