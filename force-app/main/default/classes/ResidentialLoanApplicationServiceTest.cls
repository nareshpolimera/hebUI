/******************************************************/ /**
@Class      ResidentialLoanApplicationServiceTest
@brief      Unit Test for ApplicationTrigger.

@revision   2024-07-03 Juan Contreras 
            Task 6389.
/******************************************************/
@IsTest
public with sharing class ResidentialLoanApplicationServiceTest {
    @TestSetup
    static void makeData() {
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;

        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;

        Account account = new Account(FirstName = 'Test', LastName = 'Test');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'Test',
            AccountId = account.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = System.today()
        );
        insert opportunity;
    }

    // Test method to cover scenario where latestRecord is not null
    @isTest
    static void testGenerateNextSequenceNameWithLatestRecord() {
        Test.startTest();
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Insert a record with a Generated_Number__c value
        ResidentialLoanApplication application = new ResidentialLoanApplication(
                                                    OpportunityId = opportunity.Id);
        insert application;
        application = [SELECT Name, Generated_Number__c FROM ResidentialLoanApplication LIMIT 1];

        // Verify that the prefix increments correctly
        System.assertEquals('LA - Test', application.get('Name')); 
        
        // insert as a normal user to force the value of Generated Number => /!\ if this fails, make sure test running user is not a MARS integration user
        ResidentialLoanApplication application5 = new ResidentialLoanApplication( 
            OpportunityId = opportunity.Id,
            Generated_Number__c = 5,
            Name = 'LA-00000005',
            Loan_Purpose__c = 'Emergency'
        );
        insert application5;
        
        // create new application as integration user
        ResidentialLoanApplication  application6 = new ResidentialLoanApplication(
            OpportunityId = opportunity.Id,
            Loan_Purpose__c = 'Emergency'
        );
        ResidentialLoanApplication application7 = new ResidentialLoanApplication(
            OpportunityId = opportunity.Id
        );
        
        insert new List<ResidentialLoanApplication> {application6, application7};
        update new List<ResidentialLoanApplication> {application6};    
        application6 = [SELECT Name, Generated_Number__c FROM ResidentialLoanApplication Where Id =:application6.Id];
        application7 = [SELECT Name, Generated_Number__c FROM ResidentialLoanApplication Where Id =:application7.Id];
		
        // Verify that the prefix increments correctly
        System.assertEquals('LA - Test', application6.get('Name')); 
        System.assertEquals('LA - Test', application7.get('Name')); 
        Test.stopTest();
    }
}