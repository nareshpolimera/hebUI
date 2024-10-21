@isTest
public class TDSRCalculationServiceTest {
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
            Property_Type__c = 'Single Family Dwelling',
            Monthly_Condo_Fees__c=100000
        );
        insert loanProperty;
    }   
    @isTest
    static void testRunTDSRCalculation() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Rate_Set__c, Product_Quote_Set__c FROM Opportunity LIMIT 1];
        ResidentialLoanApplication rla = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TDSRCalculationMockCallout());
        TDSRCalculationService.runTDSRCalculation(opp.Id, rla.Id);
        Test.stopTest();
        
    }    
    @isTest
    static void testTDSRRequestConstructor() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Rate_Set__c, Product_Quote_Set__c FROM Opportunity LIMIT 1];
        ResidentialLoanApplication rla = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
            LoanApplicationLiability appLiability = new LoanApplicationLiability();
            appLiability.LoanApplicationId = rla.Id;
            appLiability.Balance_Amount__c = 100000;
            appLiability.Secured__c = true;
            appLiability.Type__c = 'Mortgage';
            appLiability.Amount__c = 1000000;
            appLiability.Source__c = 'Credit Bureau';
            appLiability.Include_Debt__c = true;
            appLiability.CreditLimitAmount = 10000000;
            LoanApplicationLiability appLiability2 = new LoanApplicationLiability();
            appLiability.LoanApplicationId = rla.Id;
            appLiability2.Balance_Amount__c = 10000;
            appLiability2.Secured__c = true;
            appLiability2.Type__c = 'Mortgage';
            appLiability2.Amount__c = 100000;
            appLiability2.Source__c = 'Credit Bureau';
            List<LoanApplicationLiability> appliabilityList = new List<LoanApplicationLiability>{appLiability, appLiability2};
			insert appliabilityList;
        
        Test.startTest();
        TDSRCalculationService.TDSRrequest request = new TDSRCalculationService.TDSRrequest(opp.Id, rla.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, request, 'Expected TDSRrequest to be created.');
    }
    
    @isTest
    static void testTDSRResult() {
        TDSRCalculationService.TDSRResult result = new TDSRCalculationService.TDSRResult();
        result.TDSRValue = 0.35;
        result.IsSucessful = true;
        result.Error = null;
        
        System.assertEquals(0.35, result.TDSRValue, 'The TDSR value should match.');
        System.assertEquals(true, result.IsSucessful, 'The result should be successful.');
        System.assertEquals(null, result.Error, 'There should be no error.');
    }
    
    class TDSRCalculationMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"TDSRValue": 0.35, "IsSucessful": true, "Error": null}');
            return res;
        }
    }
}