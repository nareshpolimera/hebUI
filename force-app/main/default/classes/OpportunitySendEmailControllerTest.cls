/******************************************************//**
@Test Class      OpportunitySendEmailControllerTest
@brief      Class with logic test and code coverage for OpportunitySendEmailController.

@creation   2024-08-13 Sarvesh Despande
/******************************************************/
@isTest
public class OpportunitySendEmailControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount','32244','Quebec', '41643210987');
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{orgAccount};
            
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
    }
    
    @isTest
    static void validateProperty() {
        Test.StartTest();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean result = OpportunitySendEmailController.createMarsRecord(opp.Id, MARSPlatformEventService.ACTION_UPDATE);
        System.assertNotEquals(result, null);
        System.assertEquals(result, false);
        Test.StopTest();
    }
}