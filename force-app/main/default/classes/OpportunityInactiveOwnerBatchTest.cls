/*-----------------------------------------------------------------------------------
    @description       : test class for OpportunityInactiveOwnerBatch and OpportunityOwnershipBatchSchedulable apex classes
    @last modified on  : 09-20-2024
    Modifications Log 
    -----------------------------------------------------------------------------------
    Ver   Date         Author                               Modification
    1.0   09-20-2024   Mudit Arora                          Initial Version
    -----------------------------------------------------------------------------------
*/
@isTest
public class OpportunityInactiveOwnerBatchTest {

    @TestSetup
    static void setupTestDate(){

        // Create test data
        User inactiveUser = new User(
            FirstName = 'InactiveUser',
            LastName = 'OwnerBatch',
            Username = 'inactiveuserOwnerBatch@test.com',
            Email = 'inactiveuserOwnerBatch@test.com',
            Alias = 'inact',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            IsActive = true,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert inactiveUser;

        User activeUser = new User(
            FirstName = 'ActiveUser',
            LastName = 'OwnerBatch',
            Username = 'activeOwnerBatch@test.com',
            Email = 'activeOwnerBatch@test.com',
            Alias = 'actv',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            IsActive = true,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert activeUser;

        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Pre-Application',
            Channel__c = 'Consumer',
            Is_Redacted__c = false,
            MARS_Stage__c = null,
            LeadSource = 'Other',
            CloseDate = System.today().addMonths(1)
        );
        testOpportunities.add(opp1);
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Pre-Application',
            Channel__c = 'Consumer',
            Is_Redacted__c = false,
            MARS_Stage__c = null,
            LeadSource = 'Other',
            CloseDate = System.today().addMonths(1)
        );
        testOpportunities.add(opp2);

        insert testOpportunities;
    }
    
    @isTest
    static void OpportunityInactiveOwnerBatchTest_Success() {

        User activeUser = [SELECT Id, UserName FROM User WHERE UserName = 'activeOwnerBatch@test.com'];

        MARS_Integration_Settings__c settings = new MARS_Integration_Settings__c();
        settings.MARS_Integration_User_Id__c = activeUser.Id;
        insert settings;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        User inactiveUser = [SELECT Id, UserName, IsActive FROM User WHERE UserName = 'inactiveuserOwnerBatch@test.com'];

        for(Opportunity oppRec : [SELECT Id, OwnerId, File_Queue__c FROM Opportunity]){
            oppRec.File_Queue__c = null;
            oppRec.OwnerId = inactiveUser.Id;
            oppsToUpdate.add(oppRec);
        }
        update oppsToUpdate;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs (thisUser) {
            inactiveUser.IsActive = false;
            update inactiveUser;
        }
        
        // Start the batch
        Test.startTest();
        OpportunityInactiveOwnerBatch batch = new OpportunityInactiveOwnerBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the outcomes
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId, File_Queue__c FROM Opportunity];

        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Initial Contact', opp.File_Queue__c, 'The opportunity owner should be updated to the Initial Contact Queue');
            System.assertEquals(activeUser.Id, opp.OwnerId, 'The opportunity owner should be updated to MARS Integration');
        }
    }

    @isTest
    static void OpportunityInactiveOwnerBatchTest_Failure() {

        User activeUser = [SELECT Id, UserName FROM User WHERE UserName = 'activeOwnerBatch@test.com'];

        MARS_Integration_Settings__c settings = new MARS_Integration_Settings__c();
        settings.MARS_Integration_User_Id__c = activeUser.Id;
        insert settings;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        User inactiveUser = [SELECT Id, UserName, IsActive FROM User WHERE UserName = 'inactiveuserOwnerBatch@test.com'];

        HEB_Kill_Switch__c switchSetting = new HEB_Kill_Switch__c();
        switchSetting.Deactivate_Validation_Rules__c = true;
        insert switchSetting;

        for(Opportunity oppRec : [SELECT Id, OwnerId, File_Queue__c, LeadSource FROM Opportunity]){
            oppRec.File_Queue__c = null;
            oppRec.OwnerId = inactiveUser.Id;
            oppRec.LeadSource = null;
            oppsToUpdate.add(oppRec);
        }
        update oppsToUpdate;

        switchSetting.Deactivate_Validation_Rules__c = false;
        update switchSetting;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs (thisUser) {
            inactiveUser.IsActive = false;
            update inactiveUser;
        }
        
        // Start the batch
        Test.startTest();
        OpportunityInactiveOwnerBatch batch = new OpportunityInactiveOwnerBatch();
        Database.executeBatch(batch);
        Test.stopTest();
    }

    @isTest
    static void OpportunityOwnerBatchSchedulableTest() {
		
        Test.startTest();
        OpportunityOwnershipBatchSchedulable testBatch = new OpportunityOwnershipBatchSchedulable();
        String sch ='0 48 * * * ?'; 
        String jobId = System.schedule('Opp Owner Schedule Test', sch, testBatch);      
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(sch, ct.CronExpression, 'Opp ownership batch is scheduled for run');
    }
}