@isTest
public class ObjectsPicklistFieldValuesExporterTest {
    
    @isTest
    static void exportPicklistFieldValuesTest() {
        // Create a custom picklist field on Account for testing
        SObjectField testField = Account.AccountSource;
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = globalDescribe.get('Account');
        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
        
        Test.startTest();
        ObjectsPicklistFieldValuesExporter.exportPicklistFieldValues('Account');
        Test.stopTest();
        
        List<ContentVersion> testContentVersions = [SELECT Title, PathOnClient, VersionData FROM ContentVersion WHERE Title = 'Account_PicklistValues'];
        System.assertEquals(1, testContentVersions.size(), 'One CSV file should be created.');
        System.assertEquals('Account_PicklistValues.csv', testContentVersions[0].PathOnClient, 'CSV file name should be correct.');
    }
}