@isTest
public class fileUploadControllerTest {
    @testSetup
    static void setupTestData() {
        
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        TestFactory.fileTestData();
    }
    
    @isTest
    static void testGetDocumentClassificationRecords() {
        Test.startTest();
        List<Document_Classification__c> result = fileUploadController.getDocumentClassificationRecords();
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve Document Classification records');
    }
    
    @isTest
    static void testGetRelatedPropertyMemberRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Account> result = fileUploadController.getRelatedPropertyMemberRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve related Property Member records');
    }
    
    @isTest
    static void testGetRelatedApplicantRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<LoanApplicant> result = fileUploadController.getRelatedApplicantRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve related Applicant records');
    }
    
    @isTest
    static void testGetRelatedDebtRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<LoanApplicationLiability> result = fileUploadController.getRelatedDebtRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve related Debt records');
    }
    
    @isTest
    static void testGetRelatedAppraisalRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Appraisal__c> result = fileUploadController.getRelatedAppraisalRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve related Appraisal records');
    }
    
    @isTest
    static void testGetRelatedPropertyRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<LoanApplicationProperty> result = fileUploadController.getRelatedPropertyRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve related Property records');
    }
    
    @isTest
    static void testGetLeadRecords() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        List<Lead> result = fileUploadController.getLeadRecords(lead.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve Lead records');
    }
    
    @isTest
    static void testGetFileRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> result = fileUploadController.getFileRecords(opp.Id);
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected to retrieve File records');
    }
    
    @isTest
    static void testUploadFile() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64 = 'SGVsbG8gd29ybGQ='; 
        String filename = 'test.txt';
        String documentType = 'Test Document Type';
        String relatedEntity = opp.Id;
        
        Test.startTest();
        fileUploadController.getFileProperties();
        String result = fileUploadController.uploadFile(base64, filename, opp.Id, documentType, relatedEntity);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected to successfully upload file and get ContentDocumentLink Id');
    }
}