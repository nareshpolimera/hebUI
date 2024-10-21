/*-----------------------------------------------------------------------------------
      @description       : The is test class for LeadConversionBatch 
      @last modified on  : 07-07-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-07-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
@isTest
public class LeadConversionBatchSchedulableTest {   
    @isTest
    static void testGenerateCommitmentLetterPlatformEvent() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EmailValidationRequestMockCallout());
        Account l1 = new Account();
        l1 = TestFactory.createPartnerAccount(
            'Test',
            'Acc',
            '50004',
            'Toronto',
            null            
        );
        l1.PersonEmail = 'test123@test123.test';
        l1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert l1;
        Lead l = new Lead (
            
            LastName = 'Test123',
            FirstName = 'Test123',
            Email = 'test123@test123.test'
        );
        insert l; 
        LeadConversionBatchSchedulable testBatch = new LeadConversionBatchSchedulable();
        String sch ='0 48 * * * ?'; 
        String jobId = System.schedule('Schedule Test', sch,testBatch);      
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(sch, ct.CronExpression);
    }     
}