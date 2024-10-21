@isTest
public class LeadAssignmentServiceTest {
    
    @testSetup
    static void setupTestData() {
        Specialist__c spRecord = new Specialist__c();
        spRecord.Unavailable_For_Meetings__c = false;
        spRecord.Assigned_Leads_Count__c = 1;
        spRecord.Total_Lead_Assignment_Count__c = 1;
        insert spRecord;
    }
    
    @isTest
    static void getSortedSpecialistListTest() {
        Test.StartTest();
        List<Specialist__c> resultList = LeadAssignmentService.getSortedSpecialistList();
        System.assertNotEquals(resultList, null);
        System.assertEquals(resultList.size(), 1);
        Test.StopTest();
    }
    
    @isTest
    static void resetLeadAssignmentCountTest() {
        Test.StartTest();
        Set<Id> specialistIdSet = new Map<Id, Specialist__c>([Select Id From Specialist__c LIMIT 1]).keySet();
        LeadAssignmentService.resetLeadAssignmentCount(specialistIdSet);
        List<Specialist__c> spls = [SELECT Id, Assigned_Leads_Count__c, Total_Lead_Assignment_Count__c  FROM Specialist__c];
        System.assertNotEquals(spls, null);
        System.assertEquals(spls[0].Assigned_Leads_Count__c, 0);
        Test.StopTest();
    }
    
    @isTest
    static void incrementAssignmentCountTest() {
        Test.StartTest();
        Set<Id> specialistIdSet = new Map<Id, Specialist__c>([Select Id From Specialist__c LIMIT 1]).keySet();
        LeadAssignmentService.incrementAssignmentCount(specialistIdSet);
        List<Specialist__c> spls = [SELECT Id, Assigned_Leads_Count__c, Total_Lead_Assignment_Count__c  FROM Specialist__c];
        System.assertNotEquals(spls, null);
        System.assertEquals(spls[0].Assigned_Leads_Count__c, 2);
        System.assertEquals(spls[0].Total_Lead_Assignment_Count__c, 2);
        Test.StopTest();
    }
    
    @isTest
    static void decrementAssignmentCountTest() {
        Test.StartTest();
        Set<Id> specialistIdSet = new Map<Id, Specialist__c>([Select Id From Specialist__c LIMIT 1]).keySet();
        LeadAssignmentService.decrementAssignmentCount(specialistIdSet);
        List<Specialist__c> spls = [SELECT Id, Assigned_Leads_Count__c, Total_Lead_Assignment_Count__c  FROM Specialist__c];
        System.assertNotEquals(spls, null);
        System.assertEquals(spls[0].Assigned_Leads_Count__c, 0);
        System.assertEquals(spls[0].Total_Lead_Assignment_Count__c, 0);
        Test.StopTest();
    }
    
}