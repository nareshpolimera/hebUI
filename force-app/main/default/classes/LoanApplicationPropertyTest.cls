@IsTest
private class LoanApplicationPropertyTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        Account partnerAccount =TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert partnerAccount;
        Opportunity opp1 = TestFactory.createConsumerOpportunity('Test AVM');
        opp1.File_Number__c='123456';
        opp1.AccountId=partnerAccount.Id;
        insert opp1;
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'TestApp',OpportunityId=opp1.Id, AccountId = partnerAccount.Id);
        insert application;
        LoanApplicationProperty loanProperty = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = application.Id,
            PropertyPostalCode = 'L5C2B8',
            PropertyCity = 'Alberta',
            PropertyStateCode = 'AB',
			PropertyCountryCode = 'CA',
            Property_Type__c = 'Single Family Dwelling'
        );
        insert loanProperty;
        List<Profile> profileList = [
            SELECT Id, Name
            FROM Profile
            WHERE
            Name IN (
                :Label.ConsumerSales_Profile_Name,
                :Label.Call_Centre_Profile_Name,
                :Label.BDM_Profile_Name,
                :Label.SystemAdmin_Profile_Name,
                :Label.HEBStandard_Profile_Name,
                :Label.Integration_Profile_Name,
                'Relationship Manager'
            )
        ];
        Profile adminProfile;
        Profile standardUserProfile;
        Profile relManagerProfile;
         for (Profile p : profileList) {
            if (p.Name == Label.SystemAdmin_Profile_Name)
                adminProfile = p;
            if (p.Name == Label.HEBStandard_Profile_Name)
                standardUserProfile = p;  
            if (p.Name == 'Relationship Manager')
                relManagerProfile = p;  
        }
            User relUser = new User(
            ProfileId = relManagerProfile.Id,
            Username = 'rel@chip.ca',
            Email = 'rel@chip.ca',
            FirstName = 'rel',
            LastName = 'user',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'relUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert relUser;
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
        
    }
    
    @isTest
    static void testCheckRequote() {
        LoanApplicationProperty p = 
            [select id, PropertyStreet,LoanApplication.OpportunityId from LoanApplicationProperty where LoanApplication.OpportunityId!= null limit 1];
        User relUser = [
            SELECT Id
            FROM User
            WHERE Username = 'rel@chip.ca'
        ];
        System.runAs(relUser) {
            Test.startTest();
            p.PropertyStreet = 'Test';
            p.Water_Type__c = 'Cistern';
            update p;
        }
        Opportunity opp = [SELECT Id, Quote_Parameters_Updated__c FROM Opportunity WHERE Id = :p.LoanApplication.OpportunityId];
        
        system.debug('opp.Quote_Parameters_Updated__c'+opp.Quote_Parameters_Updated__c);
        System.assertEquals(true, opp.Quote_Parameters_Updated__c);
        Test.stopTest();
    }
    
    @isTest
    static void testGetFile() {
        
        Test.startTest();
        System.assert(
            LoanApplicationPropertyService.getFileProperty([select id, PropertyStreet,LoanApplication.OpportunityId from LoanApplicationProperty limit 1].Id) != null
        );
        Test.stopTest();
        
    }
    
    @isTest
    static void test_AutoName() {
        
        List<ResidentialLoanApplication> applications = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        System.assert(!applications.isEmpty());
        
        test.startTest();
        
        LoanApplicationProperty prop1 = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = applications[0].Id,
            PropertyPostalCode = 'L5C2B8',
            PropertyCity = 'Alberta',
            PropertyStateCode = 'AB',
			PropertyCountryCode = 'CA',
            Property_Type__c = 'Single Family Dwelling'
        );
        insert prop1;
                
        test.stopTest();
        
        List<LoanApplicationProperty> properties = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationProperty 
                                                    WHERE Id = :prop1.Id];
        
        System.assertEquals('Test Property', properties[0].Name);
    }
    
    @isTest
    static void test_Name_noMarsUser() {
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = '';
        upsert settings;
        
        List<ResidentialLoanApplication> applications = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        System.assert(!applications.isEmpty());
        
        test.startTest();
        
       LoanApplicationProperty prop1 = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = applications[0].Id,
            PropertyPostalCode = 'L5C2B8',
            PropertyCity = 'Alberta',
            PropertyStateCode = 'AB',
			PropertyCountryCode = 'CA',
            Property_Type__c = 'Single Family Dwelling'
        );
        insert prop1;
        
        test.stopTest();
        
        List<LoanApplicationProperty> properties = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationProperty 
                                                    WHERE Id = :prop1.Id];
        
        System.assertEquals('Test Property', properties[0].Name);
        System.assertEquals(null, properties[0].Generated_Number__c);
    }
    
    @isTest
    static void testgetFileProperty(){
        List<LoanApplicationProperty> lap =[SELECT Id, PropertyStreet, PropertyCity, PropertyState, PropertyPostalCode FROM LoanApplicationProperty limit 1];
        
        Test.StartTest();
        LoanApplicationPropertyService.getFileProperty(lap[0].Id);
        Test.StopTest();
        
        
    }
    
    @isTest
    static void testGetFileProperty_Error() {
        Test.startTest();
        
        // Create a mock LoanApplicationProperty record
        LoanApplicationProperty property =[SELECT Id, PropertyStreet, PropertyCity,PropertyState, PropertyPostalCode FROM LoanApplicationProperty limit 1];
        
        // Pass an invalid Id to simulate an exception
        Id invalidId; // Invalid Id format
        
        // Call the method and capture the result
        LoanApplicationProperty result = LoanApplicationPropertyService.getFileProperty(invalidId);
        
        // Validate that the result is null, which indicates that an exception was caught
        System.assert(result == null, 'Expected result to be null when an invalid Id is provided');
        
        // Additionally, check for a valid record Id
        result = LoanApplicationPropertyService.getFileProperty(property.Id);
        System.assert(result != null, 'Expected result to be not null when a valid Id is provided');
        
        Test.stopTest();
    }
    
    @isTest
    static void testValidFSAValues() {
        // Create test data for FSA__c records
        List<FSA__c> fsas = new List<FSA__c>{
            new FSA__c(FSA__c = 'M4M', City__c = 'Toronto', Is_Active__c = true),
                new FSA__c(FSA__c = 'K1A', City__c = 'Ottawa', Is_Active__c = true),
                new FSA__c(FSA__c = 'V5K', City__c = 'Vancouver', Is_Active__c = false) // This should be excluded
                };
                    insert fsas;
        
        // Prepare sets to test
        Set<String> fsaSet = new Set<String>{'M4M', 'K1A', 'V5K'};
            Set<String> citySet = new Set<String>{'Toronto', 'Ottawa', 'Vancouver'};
                
                // Call the method
                Set<String> result = LoanApplicationPropertyService.validFSAValues(fsaSet, citySet);
        
        // Expected keys
        Set<String> expectedKeys = new Set<String>{
            LoanApplicationPropertyService.fsaKeyGenerator('M4M', 'Toronto'),
                LoanApplicationPropertyService.fsaKeyGenerator('K1A', 'Ottawa')
                };
                    
                    // Assert that the result matches the expected keys
                    System.assertEquals(expectedKeys, result, 'The valid FSA keys did not match the expected values.');
    }
    
    @isTest
    static void testValidatePropertyLendingArea() {
        List<LoanApplicationProperty> properties = [Select id,PropertyPostalCode,PropertyCity,CreatedFromLeadUI__c from LoanApplicationProperty where LoanApplication.OpportunityId !=null limit 3];
        Test.startTest();
        LoanApplicationPropertyService service = new LoanApplicationPropertyService();
        service.validatePropertyLendingArea(properties, null);
        Test.stopTest();      
    }
    
     @isTest
    static void testRunOnce_NoRecursion() {
        // Retrieve records
        Account acc1 =TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        Account acc2 =TestFactory.createPartnerAccount('West Torono','Bank','M4M4C4','Toronto','316023456');
        // Test for an insert operation (no recursion initially)
        Set<Id> newRecordIds = new Set<Id>{acc1.Id, acc2.Id};
        Set<Id> oldRecordIds = new Set<Id>();
        Boolean result = LoanApplicationPropertyService.runOnce(newRecordIds, oldRecordIds,TriggerOperation.AFTER_INSERT);
        
        System.assertEquals(false, result, 'Recursion should not have been detected on first run');
    }
    
        @isTest
    	static void testRunOnce_WithRecursion() {
        // Retrieve records
        Account acc1 =TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        Account acc2 =TestFactory.createPartnerAccount('West Torono','Bank','M4M4C4','Toronto','316023456');

        // Test for an insert operation (simulate recursion)
        Set<Id> newRecordIds = new Set<Id>{acc1.Id, acc2.Id};
        Set<Id> oldRecordIds = new Set<Id>();

        // First run should not detect recursion
        Boolean result = LoanApplicationPropertyService.runOnce(newRecordIds, oldRecordIds,TriggerOperation.AFTER_INSERT);
        System.assertEquals(false, result, 'Recursion should not have been detected on first run');

        // Second run with the same operation and records should detect recursion
        result = LoanApplicationPropertyService.runOnce(newRecordIds, oldRecordIds,TriggerOperation.AFTER_INSERT);
        System.assertEquals(true, result, 'Recursion should have been detected on second run');
    }
    
}