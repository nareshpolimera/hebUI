@isTest
private class LoanApplicationFinancialServiceTest {

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

        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
    }

    @isTest
    static void test_AutoName() {

        List<ResidentialLoanApplication> applications = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        System.assert(!applications.isEmpty());

        test.startTest();

        LoanApplicationFinancial appFinancial = new LoanApplicationFinancial();
        appFinancial.LoanApplicationId = applications[0].Id;
        insert appFinancial;

        test.stopTest();

        List<LoanApplicationFinancial> appFinancials = [SELECT Id, Name, Generated_Number__c 
                                                    FROM LoanApplicationFinancial 
                                                    WHERE Id = :appFinancial.Id];

        
        System.assertEquals('LAF-00000001', appFinancials[0].Name);
        System.assertEquals(1, appFinancials[0].Generated_Number__c);
    }
}