@IsTest
public class OpportunityTriggerTest {
    
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        List<Profile> profileList = [
            SELECT Id, Name
            FROM Profile
            WHERE
            Name IN (
                :Label.ConsumerSales_Profile_Name,
                :Label.Call_Centre_Profile_Name,
                :Label.BDM_Profile_Name,
                :Label.SystemAdmin_Profile_Name,
                :Label.HEBStandard_Profile_Name,
                :Label.Integration_Profile_Name,
                'Relationship Manager'
            )
        ];
        
        Profile adminProfile;
        Profile standardUserProfile;
        
        for (Profile p : profileList) {
            if (p.Name == Label.SystemAdmin_Profile_Name)
                adminProfile = p;
            if (p.Name == Label.HEBStandard_Profile_Name)
                standardUserProfile = p; 
        }
        
        User adminUser = new User(
            ProfileId = adminProfile.Id,
            Username = 'specialist@chip.ca',
            Email = 'specialist@chip.ca',
            FirstName = 'User',
            LastName = 'Specialist',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        User sysAdmin2 = new User(
            ProfileId = adminProfile.Id,
            Username = 'anotherAdmin@chip.ca',
            Email = 'anotherAdmin@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin2',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User standardUser = new User(
            ProfileId = standardUserProfile.Id,
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
        
        insert new List<User>{standardUser, sysAdmin2, adminUser};
            
            //TestFactory.initTestData();
            Account partnerAcc = TestFactory.createPartnerAccount(
                'West Toronto',
                'Bank',
                'M4M4C4',
                'Toronto',
                '316023456'
            );
        
         Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount',
                                                         '32244',
                                                         'Quebec',
                                                         '41643210987');
            
        
        insert new List<Account>{partnerAcc, orgAccount};
        
        Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive1');
        op1.AccountId = orgAccount.Id;
        
        Opportunity op4 = TestFactory.createConsumerOpportunity('Test Drive');
        
        insert new List<Opportunity>{op4,op1};
        
       ResidentialLoanApplication application2 = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op1.id);
        insert application2;
    }
    
    @isTest
    static void testCheckDialListMainChangesFalse() {
        
        Test.StartTest();
        
        Account oppAccount=[Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        // update acount to match the criteria
        oppAccount.Most_Recent_Inquiry_Date__pc = System.Today().addDays(-188);
        oppAccount.In_Nurture_Stream__c = false;
        oppAccount.Phone_Verification_Status__c = 'Valid';
        oppAccount.Not_Interested_Yet__c = false;
        
        update oppAccount;
        
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Opportunity.sObjectType);
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = oppAccount.Id,
                                                      StageName='Assessment Needed',
                                                      File_Queue__c = 'Initial Contact',
                                                      Channel__c = 'Consumer',
                                                      Primary_Borrower_Age__c = 60,
                                                      LeadSource = 'Client Referral',
                                                      CloseDate=System.today()
                                                     );
        insert testOpportunity;
        
        Test.StopTest();
        oppAccount=[Select Id,Dial_List_Main__c from Account WHERE Id = :oppAccount.Id];
        
        System.AssertEquals(false, oppAccount.Dial_List_Main__c, 'Expected Dial List to be true');
    }
    
    @isTest
    static void testCheckDialListMainChangesTrue() {
        Test.StartTest();
        
        Account oppAccount=[Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        // update acount to match the criteria
        oppAccount.Most_Recent_Inquiry_Date__pc = System.Today().addDays(-188);
        oppAccount.In_Nurture_Stream__c = false;
        oppAccount.Phone_Verification_Status__c = 'Valid';
        oppAccount.Not_Interested_Yet__c = false;
        
        update oppAccount;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = oppAccount.Id,
                                                      StageName='Assessment Needed',
                                                      File_Queue__c = 'Initial Contact',
                                                      Channel__c = 'Consumer',
                                                      Primary_Borrower_Age__c = 50,
                                                      LeadSource = 'Client Referral',
                                                      CloseDate=System.today()
                                                     );
        insert testOpportunity;
        ResidentialLoanApplication application1 = new ResidentialLoanApplication(Name = 'Test2', AccountId = oppAccount.Id, OpportunityId = testOpportunity.id);
        insert application1;
        
        LoanApplicationProperty prop1 = TestFactory.createProperty(
            application1.Id,
            'test1',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        prop1.Appraised_Amount__c = 2500001;
        insert prop1;
        
        testOpportunity.Primary_Borrower_Age__c = 60;
        update testOpportunity;
        Test.StopTest();
        oppAccount=[Select Id,Dial_List_Main__c from Account WHERE Id = :oppAccount.Id];
        
        System.AssertEquals(true, oppAccount.Dial_List_Main__c, 'Expected Dial List to be true');
    }
    
    /*
* HEB-28: Check that Opportunity MARS fields are updated automatically when moves to In Application
*/
    @IsTest
    static void testThatOpportunityMARSFieldsUpdatedOnInApplicationStage() {
        
        
        list<Opportunity> oCheck = [
            SELECT Id, Ready_for_MARS__c, MARS_Stage__c, RecordtypeId
            FROM Opportunity
            WHERE Name = 'Test Drive'
        ];
        Test.startTest();
        OpportunityService service = new OpportunityService();
        service.sendToMarsPlatformEvent(oCheck);
        
        Test.stopTest();
        oCheck = [
            SELECT Id, Ready_for_MARS__c, MARS_Stage__c, RecordtypeId
            FROM Opportunity
            WHERE Name = 'Test Drive'
        ];
        System.assertEquals(
            oCheck[0].MARS_Stage__c,
            OpportunityService.APPLICATION_MARS_STAGE,
            'MARS Stage not updated as expected'
        );
        
    }
    
    /*
* HEB-284: When the Lead requests a mailed quote (snail mail), ensure a Platform Event fires
*/
    @IsTest
    static void testSendToMarsPlatformEvent() {
        
        OpportunityService.OpportunityRequest req = new OpportunityService.OpportunityRequest();
        req.opportunity = [
            SELECT Id 
            FROM Opportunity
            WHERE Name = 'Test Drive' limit 1
        ];
        Test.startTest();
        OpportunityService.sendOppotunitiesToMarsPlatformEventInvocable(new List<OpportunityService.OpportunityRequest>{req});
        Test.stopTest();
        list<Opportunity> oCheck = [
            SELECT Id, StageName 
            FROM Opportunity
            WHERE Id = :req.opportunity.Id
        ];
        System.assertEquals(
            OpportunityService.APPLICATION_OPP_STAGE,
            oCheck[0].StageName,
            'MARS Stage not updated as expected'
        );
        
    }
    
    /*
* Test Ref Org and Territory assignment based on Partner
*/
    @IsTest
    static void testBDMAccessOpportunity() {
        User bdmUser = [
            SELECT Id
            FROM User
            WHERE Email = 'specialist@chip.ca'
        ];
        
        Account partnerAcc = [SELECT Id FROM Account WHERE FirstName = 'West Toronto' LIMIT 1];
        
        Opportunity o = new Opportunity();
        o.Name = 'Joe';
        o.CloseDate = system.today();
        o.BDM__c = bdmUser.Id;
        o.AccountId = partnerAcc.Id;
        o.StageName = 'New';
        
        Test.startTest();
        insert o;
        Test.stopTest();
        
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test', OpportunityId = o.Id);
        insert application;
        
        LoanApplicationAsset asset = new LoanApplicationAsset(
            LoanApplicationId = application.Id,
            Name = 'Test'
        );
        insert asset;
        
        LoanApplicationLiability debt = new LoanApplicationLiability(
            LoanApplicationId = application.Id,
            Balance_Amount__c = 200.00, 
            Type__c = 'Credit Card', 
            Amount__c = 1500.00,
            Name = 'Test'
        );
        insert debt;
        
        Boolean accessError = false;
        
        System.runAs(bdmUser) {
            try {
                o = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :o.Id];
            } catch (Exception e) {
                system.assert(
                    e.getMessage() != null,
                    'BDM cannot access related records'
                );
                accessError = true;
            }
            
            System.assertEquals(
                accessError,
                false,
                'There was an error querying the records'
            );
        }
    }
    
    @isTest
    Public static void testUpdateOpportunityNameWithFileNumber(){
        Account testAccount=[Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        update testAccount;
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = testAccount.Id,
                                                      StageName='Assessment Needed',
                                                      CloseDate=System.today()
                                                     );
        insert testOpportunity;
        Test.startTest();
        testOpportunity.File_Number__c='123';
        update testOpportunity;
        Test.stopTest();
        
        // Verify the updated Opportunity name
        Opportunity updatedOpportunity = [SELECT Name FROM Opportunity WHERE Id = :testOpportunity.Id];
        // new file name :  'File - ' + opp.Account.LastName + ' - ' + (opp.File_Number__c != null ? opp.File_Number__c : '');
        String expectedName = 'OP - ' + testAccount.LastName + ' - ' + (testOpportunity.File_Number__c != null ? testOpportunity.File_Number__c : '');
        System.assertEquals(expectedName, updatedOpportunity.Name, 'Opportunity name should be updated correctly');
    }
    
    @isTest
    public static void test_FileQuote_Inbound(){
        
        //add permission to running user
        TestFactory.activateCustomPermission(UserInfo.getUserId(),'HEB_Call_Center_Member');
        
        Account testAccount = [Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = testAccount.Id,
                                                      StageName='New',
                                                      CloseDate=System.today()
                                                     );
        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testOpportunity;
        }
        
        Test.stopTest();
        
        testOpportunity = [SELECT Id, File_Queue__c FROM Opportunity WHERE Id =  :testOpportunity.Id];
        System.assertEquals('Inbound In-Progress',testOpportunity.File_Queue__c);
    }
    
  
    @isTest
    public static void snailMailPlatformEventtest(){
        
        //add permission to running user
        TestFactory.activateCustomPermission(UserInfo.getUserId(),'HEB_Call_Center_Member'); 
        Account testAccount = [Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        List<Opportunity> testOpportunityList = new List<Opportunity>();
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = testAccount.Id,
                                                      StageName='New',
                                                      CloseDate=System.today(),Send_Mail_Communcation__c=TRUE
                                                     );
        testOpportunityList.add(testOpportunity);
        Test.startTest();
        OpportunityService.snailMailPlatformEvent(testOpportunityList,null);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testOpportunity;
        } 
        Test.stopTest(); 
        testOpportunity = [SELECT Id, File_Queue__c FROM Opportunity WHERE Id =  :testOpportunity.Id];
        System.assertEquals('Inbound In-Progress',testOpportunity.File_Queue__c);
    }
    @isTest
    public static void retryRelatedRecordsOwershiptest(){
        
        //add permission to running user
        TestFactory.activateCustomPermission(UserInfo.getUserId(),'HEB_Call_Center_Member'); 
        Account testAccount = [Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        List<Id> testOpportunityIdList = new List<Id>();
        Set<Id> testOpportunityIdSet = new Set<Id>();
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = testAccount.Id,
                                                      StageName='New',
                                                      CloseDate=System.today(),Send_Mail_Communcation__c=TRUE,Quote_Parameters_Updated__c=true
                                                     );
        Id conRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
        
        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testOpportunity;
        }
        testOpportunityIdList.add(testOpportunity.id);
        testOpportunityIdSet.add(testOpportunity.id);
        OpportunityService.getContactPC(conRecordtypeId);
        OpportunityService.retryRelatedRecordsOwership(testOpportunityIdList);
        OpportunityService.setRequote(testOpportunityIdSet);
        Test.stopTest(); 
        testOpportunity = [SELECT Id, File_Queue__c,Quote_Parameters_Updated__c FROM Opportunity WHERE Id =  :testOpportunity.Id];
        System.assertEquals('Inbound In-Progress',testOpportunity.File_Queue__c);
        System.assertEquals(True,testOpportunity.Quote_Parameters_Updated__c);
    }
    @isTest
    public static void fileValidationPriorToCommitmentLetterTest(){
        
        //add permission to running user
        TestFactory.activateCustomPermission(UserInfo.getUserId(),'HEB_Call_Center_Member'); 
        Account testAccount = [Select Id,LastName,PersonContactId from Account WHERE LastName ='Bank' limit 1][0]; 
        List<Opportunity> testOpportunityList = new List<Opportunity>();
        Set<Id> testOpportunityIdSet = new Set<Id>();
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = testAccount.Id,
                                                      StageName='New',
                                                      CloseDate=System.today(),Send_Mail_Communcation__c=TRUE,Quote_Parameters_Updated__c=true,Commitment_Letter_Decision_Date__c=null,Commitment_Letter_Decision__c='Approve',Commitment_Letter_Validation_Message__c='test' 
                                                     );
        
        Test.startTest(); 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testOpportunity;
        }  
        testOpportunityList.add(testOpportunity);
        OpportunityService  t = new OpportunityService();
        t.fileValidationPriorToCommitmentLetter(testOpportunityList,null); 
        Test.stopTest(); 
        testOpportunity = [SELECT Id, File_Queue__c,Quote_Parameters_Updated__c FROM Opportunity WHERE Id =  :testOpportunity.Id];
        System.assertEquals('Inbound In-Progress',testOpportunity.File_Queue__c); 
    }
    @isTest
    static void opportunityOwnershipServiceTest() {
        Test.StartTest();
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([SELECT Id, (SELECT Id, OwnerId FROM Appraisals__r) FROM Opportunity]);
        Opportunity testOpp = oppMap.values()[0];
        testOpp.OwnerId = [Select Id From User Where Username = 'anotherAdmin@chip.ca'][0].Id;
        update testOpp;
        OpportunityService.processRelatedRecordsFileRecordType(oppMap);
        System.assertNotEquals(oppMap, null);
        System.assertNotEquals(oppMap.values()[0].OwnerId, Userinfo.getUserId());
        Test.StopTest();
    } 
}