/******************************************************//**
@Test Class      SharingServiceTest
@brief      Class with logic test and code coverage for SharingService.

@creation   2024-08-13 Mrunal Bhosale
/******************************************************/
@IsTest
private class SharingServiceTest {
    @testSetup
    static void setupTestData()
    {
        List<Opportunity> opptyList = new List<Opportunity>();
        for(Integer i = 0; i<100; i++) {
            Opportunity opp = TestFactory.createConsumerOpportunity('Test Opportunity');
            opptyList.add(opp);
        }
        insert opptyList;
    }
    
    @IsTest
    static void testcreateShareRecord() {
        Test.startTest();
        List<Opportunity> opptyList = [SELECT Id FROM Opportunity];
        SharingService sharingService = new SharingService(Opportunity.sObjectType);
        for(Opportunity opp: opptyList){
            sharingService.createShareRecord('READ', opp.Id, UserInfo.getUserId());
        }
        Test.stopTest();
    }
}