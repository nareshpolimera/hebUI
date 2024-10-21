@isTest
private class AutomatedNameGeneratorTest {

    // Test method to cover the generation of names
    @isTest
    static void testGenerateNextSequenceName() {
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;

        // Create test data
        List<SObject> records = new List<SObject>();
        SobjectType pType = ResidentialLoanApplication.SObjectType;

        // Insert a record to be queried
        ResidentialLoanApplication testRecord = new ResidentialLoanApplication(
        );
        //insert testRecord;
        records.add(testRecord);

        // Call the method under test
        AutomatedNameGenerator.generateNextSequenceName(records, pType);

        // Verify that the Name and Generated_Number__c fields are populated correctly
        System.assertEquals(1, records.size());
        System.assertNotEquals(null, records[0].get('Name'));
        System.assertNotEquals(null, records[0].get('Generated_Number__c'));
        System.assertEquals('LA-00000001', records[0].get('Name'));
    }

    // Test method to cover scenario where records list is empty
    @isTest
    static void testGenerateNextSequenceNameEmptyRecords() {
        List<SObject> records = new List<SObject>();
        AutomatedNameGenerator.generateNextSequenceName(records, ResidentialLoanApplication.SObjectType);

        // Verify that no changes were made to records
        System.assertEquals(0, records.size());
    }

    // Test method to cover scenario where pType is null
    @isTest
    static void testGenerateNextSequenceNameNullType() {
        List<SObject> records = new List<SObject>();
        AutomatedNameGenerator.generateNextSequenceName(records, null);

        // Verify that no changes were made to records
        System.assertEquals(0, records.size());
    }

    // Test method to cover buildQuery method
    @isTest
    static void testBuildQuery() {
        String query = AutomatedNameGenerator.buildQuery(LoanApplicationLiability.SObjectType);

        // Verify that the generated query is correct
        System.assertEquals('SELECT Generated_Number__c FROM LoanApplicationLiability WHERE Generated_Number__c != null OR Generated_Number__c = 0 ORDER BY Generated_Number__c Desc LIMIT 1', query);
    }
}