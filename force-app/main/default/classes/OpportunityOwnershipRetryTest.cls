@isTest
public class OpportunityOwnershipRetryTest {
    @testSetup
    static void setupTestData() {
        TestFactory.initTestData();
    }
    
    @isTest
    static void opportunityOwnershipRetryQueueableTest() {
        Test.StartTest();
        List<Id> opIdList = new List<Id>();
        for(Opportunity op : [Select Id From Opportunity]) {
            opIdList.add(op.Id);
        }
        OpportunityOwnershipRetry obj = new OpportunityOwnershipRetry(opIdList);
        System.enqueueJob(obj);
        Test.StopTest();
    }
    
    @isTest
    static void opportunityOwnershipServiceTest() {
        Test.StartTest();
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([SELECT Id, (SELECT Id, OwnerId FROM Appraisals__r) FROM Opportunity]);
        Opportunity testOpp = oppMap.values()[0];
        testOpp.OwnerId = [Select Id From User Where Username = 'anotherAdmin@chip.ca'][0].Id;
        update testOpp;
        OpportunityOwnershipService.processRelatedRecordsOwnership(oppMap);
        System.assertNotEquals(oppMap, null);
        System.assertNotEquals(oppMap.values()[0].OwnerId, Userinfo.getUserId());
        Test.StopTest();
    }
    
    @isTest
    static void opportunityOwnershipServiceNegativeTest() {
        Test.StartTest();
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([SELECT Id, OwnerId FROM Opportunity]);
        //OpportunityOwnershipService.executeNegativeTest = true;
        OpportunityOwnershipService.processRelatedRecordsOwnership(oppMap, true);
        System.assertNotEquals(oppMap, null);
        System.assertEquals(oppMap.values()[0].OwnerId, Userinfo.getUserId());
        Test.StopTest();
    }
    
    @isTest
    static void opportunityOwnershipServiceEmptyTest() {
        Test.StartTest();
        OpportunityOwnershipService.processRelatedRecordsOwnership(null);
        Test.StopTest();
    }
}