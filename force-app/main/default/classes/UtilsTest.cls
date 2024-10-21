@IsTest
public class UtilsTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        //TestFactory.initTestData();
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
        
    }
    
    @IsTest
    static void testGetRecordTypeIdByDeveloperName() {
        // Retrieve the record type Id using the method
        //Account acc =[SELECT Id,RecordType.Name, RecordTypeId,RecordType.DeveloperName from Account where RecordType.DeveloperName ='Partner_Organization' limit 1];
        Id recordTypeId = Utils.getRecordTypeIdByDeveloperName(Account.SObjectType, 'Partner_Organization');
        
        // Query the RecordType directly for comparison
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Partner_Organization' LIMIT 1];
        
        // Assert that the returned Id matches the expected Id
        System.assertEquals(rt.Id, recordTypeId, 'The RecordType Id should match the expected Id');
    }
    
    @IsTest
    static void testInvertMapping() {
        // Create a sample mapping
        Map<String, Id> originalMapping = new Map<String, Id>{
            'Key1' => '001000000000001',
            'Key2' => '001000000000002',
            'Key3' => '001000000000003'
        };
        
        // Call the method to invert the mapping
        Map<Id, String> invertedMapping = Utils.invertMapping(originalMapping);
        
        // Assert that the size of the inverted mapping matches the original
        System.assertEquals(originalMapping.size(), invertedMapping.size(), 'The inverted mapping should have the same number of entries.');
        
        // Assert that each Id in the original mapping maps back to the correct key
        for (String key : originalMapping.keySet()) {
            Id originalId = originalMapping.get(key);
            String invertedKey = invertedMapping.get(originalId);
            System.assertEquals(key, invertedKey, 'The inverted mapping should correctly map Id to the original key.');
        }
    }

    @IsTest
    static void testIsAffirmativePicklist() {
        // Define the affirmative value
        String affirmativeValue = 'Yes';
        String negativeValue = 'No';
        
        // Test with an affirmative value
        Boolean result = Utils.isAffirmativePicklist(affirmativeValue);
        System.assert(result, 'The method should return true for the affirmative value.');

        // Test with a negative value
        result = Utils.isAffirmativePicklist(negativeValue);
        System.assertEquals(false, result, 'The method should return false for a non-affirmative value.');

        // Test with a null value
        result = Utils.isAffirmativePicklist(null);
        System.assertEquals(false, result, 'The method should return false for a null value.');
    }

    @IsTest
    static void testMapYesNoToBoolean() {
        // Define the affirmative value
        String affirmativeValue = 'Yes';
        String negativeValue = 'No';

        // Test with an affirmative value
        Boolean result = Utils.mapYesNoToBoolean(affirmativeValue);
        System.assertEquals(true, result, 'The method should return true for the affirmative value.');

        // Test with a negative value
        result = Utils.mapYesNoToBoolean(negativeValue);
        System.assertEquals(false, result, 'The method should return false for a non-affirmative value.');

        // Test with a null value
        result = Utils.mapYesNoToBoolean(null);
        System.assertEquals(null, result, 'The method should return null for a null input.');
    }
    
    @IsTest
    static void testRetrieveActiveApplicationForProperty() {
        // Get the ResidentialLoanApplication record created in the test setup
        ResidentialLoanApplication loanApp = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        
        // Call the method
        ResidentialLoanApplication result = Utils.retrieveActiveApplicationForProperty(loanApp.Id);
        
        // Assert that the method returns the correct record
        System.assertNotEquals(null, result, 'The method should return a ResidentialLoanApplication record');
        System.assertEquals(loanApp.Id, result.Id, 'The method should return the correct ResidentialLoanApplication record');
    }
    
    @IsTest
    static void testRetrieveOpportunityForProperty() {
        // Get the Opportunity created in the test setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Call the method
        Opportunity result = Utils.retrieveOpportunityForProperty(opp.Id);
        
        // Assert that the method returns the correct record
        System.assertNotEquals(null, result, 'The method should return an Opportunity record');
        System.assertEquals(opp.Id, result.Id, 'The method should return the correct Opportunity record');
    }

    @IsTest
    static void testGetSelectedQuoteFromRelatedRecords() {
        // Get the Opportunity created in the test setup
        Opportunity oppor = [SELECT Id, SyncedQuoteId FROM Opportunity LIMIT 1];
        // Create related Quote record
        Quote quote = new Quote(
            OpportunityId = oppor.Id,
            Quote_Amount__c = 100000,
            Name='test'
        );
        insert quote;
        Opportunity opp = [SELECT Id, SyncedQuoteId, (SELECT Id FROM Quotes where Name='test') FROM Opportunity LIMIT 1];
        
        // Call the method
        Quote selectedQuote = Utils.getSelectedQuoteFromRelatedRecords(opp);
    }

    @IsTest
    static void testGetAgeFromBirthdate() {
        // Set a birthdate 30 years ago
        Date birthdate = Date.today().addYears(-30);
        
        // Call the method
        Integer age = Utils.getAgeFromBirthdate(birthdate);
        
        // Assert that the method returns the correct age
        System.assertEquals(30, age, 'The method should return the correct age');
    }
    
    
}