@IsTest
private class TaskServiceTest
{
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.SystemAdmin_Profile_Name)];
        User sysAdmin = new User(
            ProfileId = profileList[0].Id,
            Username = 'testadmin@chip.ca',
            Email = 'testadmin@chip.ca',
            FirstName = 'admin',
            LastName = 'IT',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sysAdmin;
        
        Campaign camp = new Campaign(Name = 'TestFactory',Phone_Label__c = 'TestFactory',Phone_Number__c = '41655555555',IsActive = true,CSID__c = 'TestFactory1234');
            insert camp;
        
         	Lead l1 = TestFactory.createConsumerLead('Test', 'Drive', 'testdrive@chip.ca');
            Lead l2 = TestFactory.createConsumerLead('Test','Drive2','testdrive2@chip.ca');
            Lead l3 = TestFactory.createConsumerLead('Test','Quoteable','testquotable@chip.ca');
            Lead l4 = TestFactory.createConsumerLead('Test','QuoteableLead','testquotablelead@chip.ca');
            insert new List<Lead>{ l1, l2, l3, l4 };
        
        Date xDate = Date.valueOf('2021-03-01');
        Product_Quote_Set__c pqs = new Product_Quote_Set__c(
            Name = '2021 Mar Quote Set 123XYZ',
            External_ID__c = '4321987',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate
        );
        insert pqs;
        Product_Rate_Set__c prs = new Product_Rate_Set__c(
            Name = '2021 Mar Rate Set 5678abc',
            External_ID__c = '9876543',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate
        );
        insert prs;
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount','32244','Quebec', '41643210987');
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{orgAccount};
            
            Contact c  = TestFactory.createPartnerContact('John', 'Doe', 'jd@bp1.com', orgAccount, 'IndustriesBusiness', 'M4M4C4', 'Toronto' );
        insert c;
        
         CampaignMember cm1 = new CampaignMember(CampaignId = camp.Id,LeadId = l1.Id);
            CampaignMember cm2 = new CampaignMember(CampaignId = camp.Id,LeadId = l2.Id);
        CampaignMember cm3 = new CampaignMember(CampaignId = camp.Id,ContactId = c.Id);
            insert new List<CampaignMember>{ cm1, cm2, cm3 };
           
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op2.id);
        insert new list<ResidentialLoanApplication> {application};
            }
    
    @IsTest
    static void testThatCampaignMemberCreated(){
        ResidentialLoanApplication application = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        // create some Property records to use in test methods for Opportunities
        LoanApplicationProperty propA = TestFactory.createProperty(application.Id, 'Test', '123 testThatCampaignMemberCreated Avenue', 'Waterloo', 'ON', 'N0B1K0');
        insert propA;
        
        Account a1 = TestFactory.createPartnerAccount('Test','Test','123','41643210987','11111111111');
        insert a1;
        Contact co1 = [Select Id FROM Contact WHERE AccountId = :a1.Id];
        
        Task t = new Task(WhoId = co1.Id);
        t.Category_Specialists__c = 'Inbound';
        t.Category_Consultants__c = 'Inbound';
        t.Outcome_Specialists__c = 'Complaints';
        t.Outcome_Consultants__c = 'Reason';
        t.Resolution_Mail_Status__c = 'Pending';
        t.Acknowledgement_Mail_Status__c = 'Pending';
        t.Reason_Consultants__c = 'Interest Rate';
        insert t;
        t.Service_Name__c = 'TestFactory';
        update t;
        Test.stopTest();        
        List<CampaignMember> cmList = [select Id, LeadId, Campaign.Phone_Label__c from CampaignMember where ContactId = :co1.Id];
        System.assertEquals(1,cmList.size(), 'No Campaign Memeber');
        System.assertEquals('TestFactory', cmList[0].Campaign.Phone_Label__c);
    }
    
    @IsTest static void testTaskCreationValidation(){
        User sysAdmin = [SELECT Id FROM User WHERE Email = 'testadmin@chip.ca'];
        id currentUserID = UserInfo.getUserId();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HEB_Complaints_App'];
        insert new PermissionSetAssignment(AssigneeId=currentUserID, PermissionSetId=ps.id);
        
        TestFactory.activateCustomPermission(currentUserID, 'FPOCs_L1');
        Test.startTest();
        system.runas(new User(Id = UserInfo.getUserId())){
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            Account cp = TestFactory.createPartnerAccount('ComplainantFirstName1','Smith','123','41643210987','11111111111');
            insert cp;
            
            Contact co1 = [Select Id FROM Contact WHERE AccountId = :cp.Id];
            Case c = TestFactory.createComplaintCase(co1.Id, 'Case Trigger Test061123-05');
            c.Can_I_close_or_resolve_this__c = true;
            c.Is_this_about_fraud__c = false;
            c.ownerId = UserInfo.getUserId();
            insert c;    
            Task t2 = new Task(whatid=c.id, Service_Name__c = 'TestFactory');
            insert t2;
            t2.Service_Name__c = 'TestFactory';
            t2.status = 'Completed';
            t2.Category_Specialists__c = 'Inbound';
            t2.Category_Consultants__c = 'Inbound';
            t2.Outcome_Specialists__c = 'Complaints';
            t2.Outcome_Consultants__c = 'Reason';
            t2.Resolution_Mail_Status__c = 'Pending';
            t2.Acknowledgement_Mail_Status__c = 'Pending';
            // t2.Brochure_Mail_Status__c = 'Pending';
            t2.Reason_Consultants__c = 'Interest Rate';
            update t2;
            Case c1;
            
            Task t3 = new Task(whatid=c.id, Service_Name__c = 'TestFactory');
            insert t3;
            c1 = TestFactory.createComplaintCase(co1.Id, 'Case Trigger Test061123-05');
            c1.Can_I_close_or_resolve_this__c = true;
            c1.Is_this_about_fraud__c = false;
            c1.ownerId = sysAdmin.id;
            insert c1;
            
        }
        Test.stopTest();        
    } 
    
    @isTest
    static void testThatFirstLoggedCallChangesOppStatus() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account a1 = TestFactory.createPartnerAccount('ComplainantFirstName1','Smith','123','41643210987','11111111111');
        insert a1;
        Opportunity o1 = TestFactory.createConsumerOpportunity('Test Drive');
        o1.AccountId = a1.Id;
        o1.StageName = 'New';
        insert o1;
        System.assertEquals('New', o1.StageName);
        
        Contact co1 = [Select Id FROM Contact WHERE AccountId = :a1.Id]; 
        Task t = new Task(WhoId = co1.Id,WhatId=o1.id, Outcome__c='Not Interested');
        insert t;
        Test.stopTest();
        
        List<Id> oppIds = new List<Id>();
        Opportunity o2 = [SELECT Id, StageName FROM Opportunity WHERE Id = :o1.Id];
        System.assertEquals('Contacted', o2.StageName);
    }
    
}