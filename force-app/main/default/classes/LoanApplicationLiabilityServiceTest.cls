@isTest
public with sharing class LoanApplicationLiabilityServiceTest {
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
            PropertyCity = 'Mississauga',
            PropertyStateCode = 'ON',
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
            User standardUser = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'standarduser@chip.ca',
            Email = 'standarduser@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'stdUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert relUser;
        insert standardUser;

        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
    }

    @isTest
    static void test_blockDeletion(){
        User testUser = [SELECT Id FROM User WHERE UserName ='standarduser@chip.ca' LIMIT 1];
        PermissionSet psg= [SELECT ID,Name FROM PermissionSet WHERE Name= 'HEB_Mortgage_Sales' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = psg.Id
        );
        insert psa;
        System.runAs(testUser) {
            List<LoanApplicationProperty> applications = [SELECT Id FROM LoanApplicationProperty LIMIT 1];
            LoanApplicationLiability appLiability = new LoanApplicationLiability();
            appLiability.Balance_Amount__c = 100000;
            appLiability.Secured__c = true;
            appLiability.Type__c = 'Mortgage';
            appLiability.Amount__c = 1000000;
            appLiability.Source__c = 'Credit Bureau';
            LoanApplicationLiability appLiability2 = new LoanApplicationLiability();
            appLiability2.Balance_Amount__c = 10000;
            appLiability2.Secured__c = true;
            appLiability2.Type__c = 'Mortgage';
            appLiability2.Amount__c = 100000;
            appLiability2.Source__c = 'Credit Bureau';
            List<LoanApplicationLiability> appliabilityList = new List<LoanApplicationLiability>{appLiability, appLiability2};
            insert appliabilityList;
            Test.startTest();
            try{
            	delete appLiability;               
            }
            catch(DmlException e){
                for (LoanApplicationLiability li : appliabilityList) {
                    if (li.hasErrors()) {
                        System.assert(li.getErrors()[0].getMessage().contains('Cannot delete Credit Bureau debt records'),
                                      'Expected error message not found.');
                    }
                }
            }

            Test.stopTest();
        }
    }
    @isTest
    static void test_newUpdateAndDeleteLiability(){
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSet psg= [SELECT ID,Name FROM PermissionSet WHERE Name= 'HEB_Mortgage_Sales' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = psg.Id
        );
        insert psa;
        System.runAs(testUser) {
            ResidentialLoanApplication application = [SELECT ID FROM ResidentialLoanApplication LIMIT 1];
            LoanApplicationLiability appLiability = new LoanApplicationLiability();
            appLiability.LoanApplicationId = application.Id;
            appLiability.Balance_Amount__c = 100000;
            appLiability.Secured__c = true;
            appLiability.Type__c = 'Mortgage';
            appLiability.Amount__c = 1000000;
            appLiability.Source__c = 'Credit Bureau';
            appLiability.Include_Debt__c = false;
            appLiability.CreditLimitAmount = 10000000;
            LoanApplicationLiability appLiability2 = new LoanApplicationLiability();
            appLiability.LoanApplicationId = application.Id;
            appLiability2.Balance_Amount__c = 10000;
            appLiability2.Secured__c = true;
            appLiability2.Type__c = 'Mortgage';
            appLiability2.Amount__c = 100000;
            appLiability2.Source__c = 'Credit Bureau';
            List<LoanApplicationLiability> appliabilityList = new List<LoanApplicationLiability>{appLiability, appLiability2};
			insert appliabilityList;
            Test.startTest();
            try {
                delete appliabilityList;
                System.assert(false, System.Label.Applicant_Liabilities_error_on_delete);
            } catch (Exception e) {
            }
            Test.stopTest();
        }
    }
    @isTest
    static void test_updateQuote(){
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSet psg= [SELECT ID,Name FROM PermissionSet WHERE Name='System_Administrator' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = psg.Id
        );
         insert psa;
        System.runAs(testUser) {
            ResidentialLoanApplication application = [SELECT ID FROM ResidentialLoanApplication LIMIT 1];
            LoanApplicationLiability appLiability = new LoanApplicationLiability();
            appLiability.LoanApplicationId = application.Id;
            appLiability.Balance_Amount__c = 100000;
            appLiability.Secured__c = true;
            appLiability.Type__c = 'Mortgage';
            appLiability.Amount__c = 1000000;
            appLiability.Source__c = 'Credit Bureau';
            appLiability.Include_Debt__c = false;
            appLiability.CreditLimitAmount = 10000000;
            List<LoanApplicationLiability> appliabilityList = new List<LoanApplicationLiability>{appLiability};

            Test.startTest();
            	insert appliabilityList;
            	appliabilityList[0].Include_Debt__c = true;
            	update appliabilityList;
            Test.stopTest();
        }
    }
    @isTest
    static void test_AutoName() {

        List<LoanApplicationProperty> applications = [SELECT Id FROM LoanApplicationProperty LIMIT 1];
        System.assert(!applications.isEmpty());

        test.startTest();

        LoanApplicationLiability appLiability = new LoanApplicationLiability();
        appLiability.Balance_Amount__c = 100000;
        appLiability.Secured__c = true;
        appLiability.Type__c = 'Mortgage';
        appLiability.Amount__c = 1000000;
        insert appLiability;

        test.stopTest();

        List<LoanApplicationLiability> appLiabilities = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationLiability 
                                                    WHERE Id = :appLiability.Id];

        
        System.assertEquals('AL-00000001', appLiabilities[0].Name);
        System.assertEquals(1, appLiabilities[0].Generated_Number__c);
    }

    @isTest
    static void test_ManualName_nochange() {

        List<LoanApplicationProperty> applications = [SELECT Id FROM LoanApplicationProperty LIMIT 1];
        System.assert(!applications.isEmpty());

        test.startTest();

        LoanApplicationLiability appLiability = new LoanApplicationLiability();
        appLiability.Name = 'Test Name';
        appLiability.Balance_Amount__c = 100000;
        appLiability.Secured__c = true;
        appLiability.Type__c = 'Mortgage';
        appLiability.Amount__c = 1000000;
        insert appLiability;

        test.stopTest();

        List<LoanApplicationLiability> appLiabilities = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationLiability 
                                                    WHERE Id = :appLiability.Id];

        
        System.assertEquals('Test Name', appLiabilities[0].Name);
        System.assertEquals(null, appLiabilities[0].Generated_Number__c);
    }

    @isTest
    static void test_Name_noMarsUser() {

        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = '';
        upsert settings;

        List<LoanApplicationProperty> applications = [SELECT Id FROM LoanApplicationProperty LIMIT 1];
        System.assert(!applications.isEmpty());

        test.startTest();

        LoanApplicationLiability appLiability;

        appLiability = new LoanApplicationLiability();
        appLiability.Name = 'Test Name';
        appLiability.Balance_Amount__c = 100000;
        appLiability.Secured__c = true;
        appLiability.Type__c = 'Mortgage';
        appLiability.Amount__c = 1000000;
        insert appLiability;

        test.stopTest();

        List<LoanApplicationLiability> appLiabilities = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationLiability 
                                                    WHERE Id = :appLiability.Id];

        
        System.assertEquals('Test Name', appLiabilities[0].Name);
        System.assertEquals(null, appLiabilities[0].Generated_Number__c);
    }
    
    @isTest
    static void testdeleteLoanApplicationLiability() {
        List<LoanApplicationProperty> applications = [SELECT Id FROM LoanApplicationProperty LIMIT 1];
        System.assert(!applications.isEmpty());
        LoanApplicationLiability appLiability;
        appLiability = new LoanApplicationLiability();
        appLiability.Name = 'Test Name';
        appLiability.Balance_Amount__c = 100000;
        appLiability.Secured__c = true;
        appLiability.Type__c = 'Mortgage';
        appLiability.Amount__c = 1000000;
        insert appLiability;
        List<LoanApplicationLiability> appLiabilities = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationLiability 
                                                    WHERE Id = :appLiability.Id];
  		test.startTest();
        try{
             delete appLiabilities;
        }catch(DmlException e){
            System.assertEquals(e.getDmlMessage(0),System.Label.Applicant_Liabilities_error_on_delete);
        }
        test.stopTest();
    }
}