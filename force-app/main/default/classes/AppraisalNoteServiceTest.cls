@IsTest
private class AppraisalNoteServiceTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
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
        
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.HEBStandard_Profile_Name)];
        
        User standardUser = new User(
            ProfileId = profileList[0].Id,
            Username = 'standarduser@chip.ca',
            Email = 'standarduser@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'stdUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert new List<User>{standardUser};
            
            Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount','32244','Quebec', '41643210987');
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{orgAccount};
            
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op2.id);
        insert new list<ResidentialLoanApplication> {application};
            
            LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M4M4M4');
        
        Appraisal__c apr1 = TestFactory.createAppraisalFromFile(op1);
        Appraisal__c apr2 = TestFactory.createAppraisalFromProperty(prop1,op1);
        insert new List<Appraisal__c>{ apr1, apr2 };
            
            Appraisal_Order__c ao1 = TestFactory.createAppraisalOrderFromAppraisal(apr1);
        Appraisal_Order__c ao2 = TestFactory.createAppraisalOrderFromAppraisal(apr2);
        insert new List<Appraisal_Order__c>{ ao1, ao2 };
            }
    
    @IsTest
    static void testSendOrder() {
        // Retrieve the test user
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSet psg= [SELECT ID FROM PermissionSet WHERE Name = 'System_Administrator' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = psg.Id
        );
        insert psa;
        
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new AppraisalSendNoteMockCallout ());
            Test.startTest();
            Appraisal_Order__c ao = [SELECT Id, Reference_ID__c FROM Appraisal_Order__c LIMIT 1];
            ao.Reference_ID__c = '123';
            update ao;
            
            Appraisal_Note__c an = new Appraisal_Note__c();
            an.Appraisal_Order__c = ao.Id;
            an.Content__c = 'Test';
            an.Incoming_Note__c = FALSE;
            insert an;
            
            
            
            Test.stopTest();
            an = [SELECT Id, Send_Note_Status__c, Incoming_Note__c FROM Appraisal_Note__c WHERE Id = :an.Id];
            System.assertEquals(FALSE, an.Incoming_Note__c);
        }
        
    }
}