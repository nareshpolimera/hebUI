@isTest
public with sharing class OpportunityContactRoleServiceTest {
    
    private static final String REFERRAL_PARTNER = 'Referral Partner';
    private static final String SUBMISSION_AGENT = 'Submission Agent';
    
    @testSetup
    public static void initializeData(){
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        Account clientAcc = TestFactory.createClientAccount(
                'Client FName',
                'Client LName',
                'M4M4C1',
                'Toronto',
                '316023426'
        );

        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestOrg',
                                                         '32244',
                                                         'Quebec',
                                                         '41643210987');
        Account orgAccount2 = TestFactory.createPartnerOrgAccount( 'TestOrg2',
                                                         '32244',
                                                         'Quebec',
                                                         '41643210987');
        
        Id partnerRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
        Account partnerAcc = new Account();
        partnerAcc.RecordTypeId = partnerRecordTypeId;      
        partnerAcc.FirstName = 'West Toronto';        
        partnerAcc.LastName = 'Bank';
        partnerAcc.BillingPostalCode = 'M4M4C4';
        partnerAcc.BillingCity = 'Toronto';
        partnerAcc.Phone = '316023456';

        Account partnerAcc2 = new Account();
        partnerAcc2.RecordTypeId = partnerRecordTypeId;      
        partnerAcc2.FirstName = 'West Toronto';        
        partnerAcc2.LastName = 'Bank2';
        partnerAcc2.BillingPostalCode = 'M4M4C4';
        partnerAcc2.BillingCity = 'Toronto';
        partnerAcc2.Phone = '316023456';

        insert new List<Account>{clientAcc,orgAccount,orgAccount2,partnerAcc,partnerAcc2};

        partnerAcc.CurrentOrganization__c = orgAccount.Id;
        update partnerAcc;

        partnerAcc2.CurrentOrganization__c = orgAccount2.Id;
        update partnerAcc2;

        Opportunity opp = TestFactory.createConsumerOpportunity('Test Application');
        opp.AccountId = clientAcc.Id;
        insert opp;
    }

    @isTest
    static void test_ReferralPartner() {
         
        List<Account> accounts = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank' limit 1];
        system.assert(!accounts.isEmpty());

        List<Opportunity> opps = [Select Id,AccountId from Opportunity limit 1];
        system.assert(!opps.isEmpty());

        Test.StartTest();

        OpportunityContactRole ocr = new opportunityContactRole();
        ocr.OpportunityId = opps[0].id;
        ocr.ContactId = accounts[0].PersonContactId;
        ocr.Role = 'Referral Partner';
        ocr.IsPrimary = true;
        insert ocr;

        Test.StopTest();

        opps = [Select Id,AccountId, 
                    Referral_Partner__c, 
                    Referral_Organization__c, 
                    BDM__c 
                    from Opportunity limit 1];
            
        system.assert(!opps.isEmpty());
        system.assertEquals(accounts[0].Id,opps[0].Referral_Partner__c);
        system.assertEquals(accounts[0].CurrentOrganization__c,opps[0].Referral_Organization__c);
        system.assertEquals(accounts[0].OwnerId,opps[0].BDM__c);
    }

    @isTest
    static void test_ReferralPartner_OnlyOnePrimary() {
         
        List<Account> accounts1 = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank' limit 1];
        system.assert(!accounts1.isEmpty());

        List<Account> accounts2 = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank2' limit 1];
        system.assert(!accounts2.isEmpty());

        List<Opportunity> opps = [Select Id,AccountId from Opportunity limit 1];
        system.assert(!opps.isEmpty());

        Test.StartTest();

        OpportunityContactRole ocr = new opportunityContactRole();
        ocr.OpportunityId = opps[0].id;
        ocr.ContactId = accounts1[0].PersonContactId;
        ocr.Role = 'Referral Partner';
        ocr.IsPrimary = true;
        insert ocr;

        OpportunityContactRole ocr2 = new opportunityContactRole();
        ocr2.OpportunityId = opps[0].id;
        ocr2.ContactId = accounts2[0].PersonContactId;
        ocr2.Role = 'Referral Partner';
        ocr2.IsPrimary = true;
        insert ocr2;

        Test.StopTest();

        opps = [Select Id,AccountId, 
                    Referral_Partner__c, 
                    Referral_Organization__c, 
                    BDM__c 
                    from Opportunity limit 1];
            
        system.assert(!opps.isEmpty());
        system.assertEquals(accounts2[0].Id,opps[0].Referral_Partner__c);
        system.assertEquals(accounts2[0].CurrentOrganization__c,opps[0].Referral_Organization__c);
        system.assertEquals(accounts2[0].OwnerId,opps[0].BDM__c);

        List<OpportunityContactRole> contactRoles = [SELECT Id 
                                                    FROM OpportunityContactRole 
                                                    WHERE IsPrimary = true 
                                                    AND OpportunityId = :opps[0].id
                                                    AND Role = 'Referral Partner'];
        system.assertEquals(1,contactRoles.size());                                 
    }

    @isTest
    static void test_SubmissionAgent() {
         
        List<Account> accounts = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank' limit 1];
        system.assert(!accounts.isEmpty());

        List<Opportunity> opps = [Select Id,AccountId from Opportunity limit 1];
        system.assert(!opps.isEmpty());

        Test.StartTest();

        OpportunityContactRole ocr = new opportunityContactRole();
        ocr.OpportunityId = opps[0].id;
        ocr.ContactId = accounts[0].PersonContactId;
        ocr.Role = 'Submission Agent';
        ocr.IsPrimary = true;
        insert ocr;

        Test.StopTest();

        opps = [Select Id,AccountId, 
                    Submission_Partner__c 
                    from Opportunity limit 1];
            
        system.assert(!opps.isEmpty());
        system.assertEquals(accounts[0].PersonContactId,opps[0].Submission_Partner__c);
    }

    @isTest
    static void test_SubmissionAgent_OnlyOne() {
         
        List<Account> accounts1 = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank' limit 1];
        system.assert(!accounts1.isEmpty());

        List<Account> accounts2 = [Select Id,LastName,
                                    PersonContactId,
                                    CurrentOrganization__c,
                                    OwnerId
                                    from Account WHERE LastName ='Bank2' limit 1];
        system.assert(!accounts2.isEmpty());

        List<Opportunity> opps = [Select Id,AccountId from Opportunity limit 1];
        system.assert(!opps.isEmpty());

        Test.StartTest();

        OpportunityContactRole ocr = new opportunityContactRole();
        ocr.OpportunityId = opps[0].id;
        ocr.ContactId = accounts1[0].PersonContactId;
        ocr.Role = 'Submission Agent';
        insert ocr;

        try{
            OpportunityContactRole ocr2 = new opportunityContactRole();
            ocr2.OpportunityId = opps[0].id;
            ocr2.ContactId = accounts2[0].PersonContactId;
            ocr2.Role = 'Submission Agent';
            insert ocr2;

            system.assert(false);
        }
        catch(Exception e){
            Assert.isTrue(e.getMessage().contains(Label.Error_Opp_Contact_Role_Submission));
        }

        Test.StopTest(); 
    }
    
    @IsTest
    static void testUpdateOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Account> accounts1 = [Select Id,LastName,PersonContactId,CurrentOrganization__c,OwnerId
                                   from Account WHERE LastName ='Bank' limit 1];

        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = accounts1[0].PersonContactId, Role = REFERRAL_PARTNER);
        insert ocr;

        Test.startTest();
        ocr.IsPrimary = true;
        update ocr;
        Test.stopTest();

        opp = [SELECT Referral_Partner__c, Referral_Organization__c, BDM__c FROM Opportunity WHERE Id = :opp.Id];
        
        System.assertEquals(accounts1[0].Id, opp.Referral_Partner__c, 'Referral Partner should be set');
        System.assertEquals(accounts1[0].CurrentOrganization__c, opp.Referral_Organization__c, 'Referral Organization should be set');
        System.assertEquals(accounts1[0].OwnerId, opp.BDM__c, 'BDM should be set');
    }
}