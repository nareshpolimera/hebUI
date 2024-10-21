@isTest
public class TestTaskFactory {
    
    private static Map<Id, Task> oldTaskMap;
    
    @isTest
    public static void initTestData() {
        // Insert test Cases
        List<Case> cases = new List<Case>{
            new Case(
                Subject = 'Test Case 1',
                Description = 'Description for test case 1',
                Origin = 'Email', 
                Priority = 'High',
                OwnerId = UserInfo.getUserId(),
                Complaint_Handling_Level__c = 'Level 1',
                Complaint_Category__c = 'Other',
                Category_Description__c = 'Category Description',
                Sub_Category_Description__c = 'Subcategory Description',
                Complaint_Date_Received__c = Date.today(),
                Incident_Date__c = Date.today(),
                Complainant_Type__c = 'Anonymous',
                Is_Customer_Satisfied__c = 'Yes',
                Letters_Sent_to_Client_Indicator__c = 'Combined Acknowledgement & Resolution Letter',
                Acknowledgement_Mail_Status__c = 'Sent',
                Resolution_Mail_Status__c = 'Sent',
                Confirmation_Provided__c = 'Yes'
                
            ),
                new Case(
                    Subject = 'Test Case 2',
                    Description = 'Description for test case 2',
                    Origin = 'Email',
                    Priority = 'High',
                    OwnerId = UserInfo.getUserId(),
                    Complaint_Handling_Level__c = 'Level 2',
                    Complaint_Category__c = 'Other',
                    Category_Description__c = 'Category Description',
                    Sub_Category_Description__c = 'Subcategory Description',
                    Complaint_Date_Received__c = Date.today(),
                    Incident_Date__c = Date.today(),
                    Complainant_Type__c = 'Anonymous',
                    Is_Customer_Satisfied__c = 'Yes',
                    Letters_Sent_to_Client_Indicator__c = 'Resolution Letter'
                    
                ),
                new Case(
                    Subject = 'Test Case 3',
                    Description = 'Description for test case 3',
                    Origin = 'Email',
                    Priority = 'High',
                    OwnerId = UserInfo.getUserId(),
                    Complaint_Handling_Level__c = 'Level 3',
                    Complaint_Category__c = 'Other',
                    Category_Description__c = 'Category Description',
                    Sub_Category_Description__c = 'Subcategory Description',
                    Complaint_Date_Received__c = Date.today(),
                    Incident_Date__c = Date.today(),
                    Complainant_Type__c = 'Anonymous',
                    Is_Customer_Satisfied__c = 'Yes',
                    Letters_Sent_to_Client_Indicator__c = ''
                    
                )
                };
                    insert cases;
        
        // Insert test UserRole__c records
        insertTestUserRoles();
        
        // Insert test Tasks
        List<Task> tasks = new List<Task>{
            new Task(WhatId = cases[0].Id, Status = 'Not Started', Case_Letter_Type_Sent__c = 'Acknowledge'),
                new Task(WhatId = cases[1].Id, Status = 'Not Started', Case_Letter_Type_Sent__c = 'Combined',Acknowledgement_Mail_Status__c = 'Pending'),
                new Task(WhatId = cases[2].Id, Status = 'Not Started', Case_Letter_Type_Sent__c = 'Resolve/Close',Resolution_Mail_Status__c = 'Pending')
                };
                    insert tasks;
        
        // Capture old Task records
        oldTaskMap = new Map<Id, Task>([
            SELECT Id, Status, Case_Letter_Type_Sent__c FROM Task
        ]);
    }
    
    private static void insertTestUserRoles() {
        UserRole__c userRole1 = new UserRole__c(User__c = UserInfo.getUserId(), Role__c = 'DE');
        UserRole__c userRole2 = new UserRole__c(User__c = UserInfo.getUserId(), Role__c = 'SDE');
        insert new List<UserRole__c>{ userRole1, userRole2 };
            }
    
    public static List<Case> getCasesToUpdate() {
        return [
            SELECT Id, Complaint_Handling_Level__c, OwnerId, Origin, Priority, Complaint_Category__c, 
            Category_Description__c, Sub_Category_Description__c, Complaint_Date_Received__c, 
            Incident_Date__c, Case_Owner_Business_Unit__c, Complainant_Type__c, Detail_of_Complaint__c
            FROM Case
        ];
    }
    
    public static List<Task> getTasksToUpdate() {
        return [
            SELECT Id, WhatId, Status, Case_Letter_Type_Sent__c
            FROM Task
        ];
    }
    
    public static Map<Id, Task> getOldTaskMap() {
        return oldTaskMap;
    }
    
    public static String createTestDataForDynamicDataTable(){
        
        //Create Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account a = new Account();
        a.FirstName = 'Test';
        a.LastName = 'Person Account';
        a.RecordTypeId = accRecordTypeId;
        insert a;
        
        //Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Last',
            Email = 'abc@test.com'
        );
        insert con;
        
        //Create opportunity
        Opportunity testOpp = new Opportunity(
            File_Number__c = '12345',
            Channel__c = 'Consumer',
            LeadSource = 'Web',
            StageName = 'New',
            CloseDate = Date.today(),
            AccountId = a.id,
            OwnerId = UserInfo.getUserId()
        );
        insert testOpp;
        
        //Create LoanApplication
        ResidentialLoanApplication loanApplication = new ResidentialLoanApplication(
            OpportunityId = testOpp.Id
        );
        insert loanApplication;
        
        //Create Applicant
        LoanApplicant applicant = new LoanApplicant(
            ContactId = con.Id,
            LoanApplicationId = loanApplication.Id,
            Is_Primary_Borrower__c = true
        );
        insert applicant;
        
        //Create Property
        LoanApplicationProperty prop = new LoanApplicationProperty(
            PropertyStreet = 'Test Property',
            LoanApplicationId = loanApplication.Id
        );
        insert prop;
        
        DynamicDataTableComplainantSearch.RecordWrapper wrapper= new DynamicDataTableComplainantSearch.RecordWrapper();
        wrapper.FileNumber = testOpp.File_Number__c;
        wrapper.ChannelOfComplainant = testOpp.Channel__c;
        wrapper.properityStreet = prop.PropertyStreet;
        
        return JSON.serialize(wrapper);
    }
}