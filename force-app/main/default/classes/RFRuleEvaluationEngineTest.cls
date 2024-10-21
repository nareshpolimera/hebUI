@isTest
public with sharing class RFRuleEvaluationEngineTest {

    @testSetup
    static void initializeTestData() {
        // Creating accounts to be processed
        List<Account> accountList = new List<Account>();
        accountList.add(new Account(Name = 'SBT1')); 
        accountList.add(new Account(Name = 'SBT2'));
        accountList.add(new Account(Name = 'SyB')); // This should not match any condition

        insert accountList;
        
        // Creating assignment rule
        Assignment_Rule__c assignmentRule = new Assignment_Rule__c();
        assignmentRule.Object__c = 'Account';
        assignmentRule.Role__c = 'Manager';
        assignmentRule.Rule_Logic__c = '(1 OR 3) AND 3 OR (1 AND 2)';
        assignmentRule.Active__c = true;
        insert assignmentRule;

        // Creating assignment rule details
        Assignment_Rule_Detail__c ard1 = new Assignment_Rule_Detail__c();
        ard1.Assignment_Rule__c = assignmentRule.Id;
        ard1.Rule_Id__c = '1';
        ard1.Field__c = 'Name';
        ard1.Operator__c = 'contains';
        ard1.Value__c = 'SBT';
        
        Assignment_Rule_Detail__c ard2 = new Assignment_Rule_Detail__c();
        ard2.Assignment_Rule__c = assignmentRule.Id;
        ard2.Rule_Id__c = '2';
        ard2.Field__c = 'Name';
        ard2.Operator__c = 'contains';
        ard2.Value__c = 'skr';
        
        Assignment_Rule_Detail__c ard3 = new Assignment_Rule_Detail__c();
        ard3.Assignment_Rule__c = assignmentRule.Id;
        ard3.Rule_Id__c = '3';
        ard3.Field__c = 'Name';
        ard3.Operator__c = 'does not contains';
        ard3.Value__c = 'skrrr';
        
        insert new List<Assignment_Rule_Detail__c>{ard1, ard2, ard3};
    }
    
    @isTest
    static void processSObjectsTest() {
        // Querying accounts to be processed
        List<Account> listOfAcc = [SELECT Id, Name FROM Account];

        Test.startTest();
        RFRuleEvaluationEngine reEngine = new RFRuleEvaluationEngine();
        List<RFRuleMatch> filteredRecords = reEngine.evaluateRules(listOfAcc,'Manager');
        Test.stopTest();

        System.assertEquals(filteredRecords.size()>0,true);
    }
    
    @isTest
    static void processSObjectsEmptyRecordsTest() {
        // Querying accounts to be processed
        List<Account> listOfAcc = [SELECT Id, Name FROM Account WHERE Name = 'SBT4'];

        Test.startTest();
        RFRuleEvaluationEngine reEngine = new RFRuleEvaluationEngine();
        List<RFRuleMatch> filteredRecords = reEngine.evaluateRules(listOfAcc, 'Manager');
        Test.stopTest();

        System.assertEquals(filteredRecords.size()>0,false);
    }
    
    @isTest
    static void processSObjectsEmptyFilteredListTest() {
        // Querying accounts to be processed 
        List<Account> listOfAcc = [SELECT Id, Name FROM Account];
        Assignment_Rule_Detail__c ard = [SELECT Id, Value__c,Operator__c,Rule_Id__c FROM Assignment_Rule_Detail__c WHERE Rule_Id__c= '3'];
 
        ard.Operator__c = 'contains';
        update ard;

        Test.startTest();
        RFRuleEvaluationEngine reEngine = new RFRuleEvaluationEngine();
        List<RFRuleMatch> filteredRecords = reEngine.evaluateRules(listOfAcc,'Manager');
        Test.stopTest();

        System.assertEquals(filteredRecords.size()>0,true);
        System.assertEquals(filteredRecords[0].hasMatch(),false);
    }
}