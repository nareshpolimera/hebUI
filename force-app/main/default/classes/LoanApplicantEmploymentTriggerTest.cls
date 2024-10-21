@IsTest
public class LoanApplicantEmploymentTriggerTest {
    @testSetup
    static void setupTestData(){
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
        LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M5V2J1');
        prop1.CreatedFromLeadUI__c = true;
        Insert prop1;
        
    }
    
    @IsTest
    static void testLoanApplicantEmploymentTrigger() {
        Test.StartTest();
        ResidentialLoanApplication application = [SELECT ID FROM ResidentialLoanApplication LIMIT 1];
        LoanApplicant lApplicant = new LoanApplicant(Name='test', LoanApplicationId=application.Id,role__c=LoanApplicantService.BORROWER_ROLE, Is_Primary_Borrower__c = true);
        insert lApplicant;
        LoanApplicantEmployment laeRec = new LoanApplicantEmployment();
        laeRec.LoanApplicantId = lApplicant.Id;
        laeRec.LoanApplicationId = application.Id;
        laeRec.Name = 'Test Loan Employment';
        insert laeRec;
        laeRec.Name = 'Updated Loan Employment';
        update laeRec;
        delete laeRec;
        Test.StopTest();
    }
}