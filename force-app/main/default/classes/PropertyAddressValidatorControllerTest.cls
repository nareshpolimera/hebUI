/******************************************************//**
@Test Class      PropertyAddressValidatorControllerTest
@brief      Class with logic test and code coverage for PropertyAddressValidatorController.

@creation   2024-08-16 Mrunal Bhosale
/******************************************************/
@isTest
public class PropertyAddressValidatorControllerTest {
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        // Create test data for FSA__c records
        List<FSA__c> fsas = new List<FSA__c>{
            new FSA__c(FSA__c = 'M4M', City__c = 'Toronto', Is_Active__c = true),
                new FSA__c(FSA__c = 'M2M', City__c = 'Ottawa', Is_Active__c = true),
                new FSA__c(FSA__c = 'M3M', City__c = 'Vancouver', Is_Active__c = false) // This should be excluded
                };
                    insert fsas;
    }
    @isTest
    static void testfetchFSAs() {
        Test.startTest();
        List<FSA__c> fetchFSAs = PropertyAddressValidatorController.fetchFSAs('M');
        system.assertEquals(2, fetchFSAs.size());
        
        List<FSA__c> fetchFSA2 = PropertyAddressValidatorController.fetchFSAs('M4M');
        system.assertEquals(1, fetchFSA2.size());
        
        Test.stopTest();
    }
    @isTest
    static void testfetchFSAByParams() {
        Test.startTest();
        List<FSA__c> fetchFSAs = PropertyAddressValidatorController.fetchFSAByParams('Toronto','', 'M');
        system.assertEquals(1, fetchFSAs.size());
                
        Test.stopTest();
    }
}