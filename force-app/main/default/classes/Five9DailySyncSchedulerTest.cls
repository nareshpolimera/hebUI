@isTest
    public class Five9DailySyncSchedulerTest {
        @isTest
        static void testFive9DailySyncScheduler() {
            Test.startTest();
            Five9DailySyncScheduler testBatch = new Five9DailySyncScheduler();
            String sch ='0 48 * * * ?'; 
            String jobId = System.schedule('Schedule Test', sch,testBatch);      
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            Test.stopTest();
            System.assertEquals(sch, ct.CronExpression);
        }
        
        @isTest
        static void testFive9DailySync() {
            Account l1 = new Account();
            Test.startTest();
            
            l1 = TestFactory.createPartnerAccount(
                'Test Account',
                'Acc',
                '50004',
                'Toronto',
                null            
            );
            l1.PersonEmail = 'test123@test123.test';
            l1.Current_Five9_List__c = 'Test';
            l1.Dial_List_Main__c = FALSE;
            l1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            insert l1;
            Database.executeBatch(new Five9DailySync());
            Test.stopTest();
            Account acc = [SELECT Id, Delete_from_f9list_id__c, Current_Five9_List__c FROM Account WHERE Id =: l1.Id];
            System.assertEquals(NULL, acc.Current_Five9_List__c);
        }
    }