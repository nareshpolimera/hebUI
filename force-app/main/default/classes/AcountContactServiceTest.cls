@isTest
public with sharing class AcountContactServiceTest {
    
    @testSetup
    static void setupTestData()
    {        
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;   
    }
    
     @IsTest
    static void deactivatetriggerTest(){ 
        Test.startTest();
    	HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = TRUE;
        upsert processSwitches;   
        
        AccountContactRelation acr = new AccountContactRelation();
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount1',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        
        Account orgAccount1 = TestFactory.createPartnerOrgAccount( 'TestAccount2',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        
        insert new List<Account> {orgAccount, orgAccount1};
        
        Contact c1 = TestFactory.createConsumerContact('Test1', 'Drive', 'testdrive1@chip.ca',orgAccount.Id);
        insert c1;
        
        acr.AccountId = orgAccount1.id;
        acr.ContactId = c1.id;
        insert acr;
        Test.stopTest();
    }
    
    @IsTest
    static void triggerTest(){      
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        AccountContactRelation acr = new AccountContactRelation();
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount1',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        
        Account orgAccount1 = TestFactory.createPartnerOrgAccount( 'TestAccount2',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        
        insert new List<Account> {orgAccount, orgAccount1};
        
        Contact c1 = TestFactory.createConsumerContact('Test1', 'Drive', 'testdrive1@chip.ca',orgAccount.Id);
        insert c1;
        
        acr.AccountId = orgAccount1.id;
        acr.ContactId = c1.id;
        insert acr;
        
        acr.IsActive = FALSE;
        update acr;
        Test.stopTest();
        
    }
}