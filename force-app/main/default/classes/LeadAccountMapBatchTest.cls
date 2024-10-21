/*-----------------------------------------------------------------------------------
      @description       : The is test class for LeadAccountMapBatch 
      @last modified on  : 07-08-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-08-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
@isTest
public class LeadAccountMapBatchTest {   
    @isTest
    static void testBatchMap() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EmailValidationRequestMockCallout());
        Account l1 = new Account();
        l1 = TestFactory.createPartnerOrgAccount(
            'Test',
            'Acc',
            'Toronto',
            ''      
        ); 
        insert l1;
        Lead l = new Lead (
            
            LastName = 'Test123',
            FirstName = 'Test123', 
            FinServ__RelatedAccount__c = l1.id
            
        );
        insert l; 
        LeadAccountMapBatch testBatch = new LeadAccountMapBatch(); 
        String jobId = Database.executeBatch(testBatch);      
        AsyncApexJob ct = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(jobId, ct.id);
    }     
}