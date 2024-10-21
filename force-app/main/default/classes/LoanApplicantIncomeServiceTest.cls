@IsTest
public class LoanApplicantIncomeServiceTest {
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
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.SystemAdmin_Profile_Name)];
        
           User sysAdmin = new User(
            ProfileId = profileList[0].Id,
            Username = 'testadmin@chip.ca',
            Email = 'testadmin@chip.ca',
            FirstName = 'admin',
            LastName = 'IT',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sysAdmin;
    }
    @isTest
    static void test_newUpdateAndDeleteLiability(){
        User testUser = [SELECT Id FROM User WHERE UserName = 'testadmin@chip.ca' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            ResidentialLoanApplication application = [SELECT ID FROM ResidentialLoanApplication LIMIT 1];
            LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M5V2J1');
            prop1.CreatedFromLeadUI__c = true;
            Insert prop1;
            LoanApplicant lApplicant = new LoanApplicant(Name='test', LoanApplicationId=application.Id,role__c=LoanApplicantService.BORROWER_ROLE, Is_Primary_Borrower__c = true);
        	insert lApplicant;
            LoanApplicantIncome aIncome = new LoanApplicantIncome(LoanApplicantId = lApplicant.Id, LoanApplicationId=application.Id, Name = 'Test Income', MonthlyIncomeAmount = 10000);
            
            insert aIncome;
            System.AssertNotEquals(aIncome.LoanApplicationId, null);
            aIncome.MonthlyIncomeAmount = 15000;
            update aIncome;
            delete aIncome;
            Test.stopTest();
        }
    }
    
}