@isTest
public class UpdateAccountChannelBatchTest {
    @isTest
    static void testAccountChannelUpdateBatch() {
        // Create test data
        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{acc1, acc2};

        Opportunity opp1 = new Opportunity(Name = 'Test Opp 1', AccountId = acc1.Id, Channel__c = 'Consumer', CloseDate = Date.today(), CreatedDate = Date.today(), StageName = 'Prospecting', LeadSource = 'Other');
        Opportunity opp2 = new Opportunity(Name = 'Test Opp 2', AccountId = acc2.Id, Channel__c = 'Referred', CloseDate = Date.today(), CreatedDate = Date.today(), StageName = 'Prospecting', LeadSource = 'Other');
        Opportunity opp3 = new Opportunity(Name = 'Test Opp 3', AccountId = acc1.Id, Channel__c = 'Mortgage Broker Direct', CloseDate = Date.today(), CreatedDate = Date.today().addDays(-1), StageName = 'Prospecting', LeadSource = 'Other');
        insert opp1;
        insert opp2;
        insert opp3;

        Test.startTest();
        UpdateAccountChannelBatch batch = new UpdateAccountChannelBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify results
        Account updatedAcc1 = [SELECT Channel__c FROM Account WHERE Id = :acc1.Id];
        Account updatedAcc2 = [SELECT Channel__c FROM Account WHERE Id = :acc2.Id];
        
        System.assertEquals('Mortgage Broker Direct', updatedAcc1.Channel__c, 'Account 1 should have Mortgage Broker Direct from the oldest opportunity');
        System.assertEquals('Referred', updatedAcc2.Channel__c, 'Account 2 should have Referred from the oldest opportunity');
    }

    @isTest
    static void testAccountChannelUpdateSchedule() {
        Test.startTest();
        UpdateAccountChannelBatch schedule = new UpdateAccountChannelBatch();
        String cronExp = '0 0 0 * * ?'; // Every day at midnight
        System.schedule('Test Update Account Channel Schedule', cronExp, schedule);
        Test.stopTest();

        // Verify that the job was scheduled
        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE CronExpression = :cronExp];
        System.assertEquals('0 0 0 * * ?', ct.size() > 0 ? ct[0].CronExpression : '', 'Cron expression should match');
    }
}