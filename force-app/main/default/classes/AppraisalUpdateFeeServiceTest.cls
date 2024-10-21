@IsTest
private class AppraisalUpdateFeeServiceTest {
    @testSetup
    static void setupTestData() {
        Date xDate = Date.valueOf('2021-03-01');
        Product_Quote_Set__c pqs = new Product_Quote_Set__c(
            Name = '2021 Mar Quote Set 123XYZ',
            External_ID__c = '4321987',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate
        );
        insert pqs;
        Product_Rate_Set__c prs = new Product_Rate_Set__c(
            Name = '2021 Mar Rate Set 5678abc',
            External_ID__c = '9876543',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate
        );
        insert prs;
        
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount','32244','Quebec', '41643210987');
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{orgAccount};
            
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op2.id);
        insert new list<ResidentialLoanApplication> {application};
            
            LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M4M4M4');
        
        Appraisal__c apr1 = TestFactory.createAppraisalFromFile(op1);
        Appraisal__c apr2 = TestFactory.createAppraisalFromProperty(prop1,op1);
        insert new List<Appraisal__c>{ apr1, apr2 };
            
            Appraisal_Order__c ao1 = TestFactory.createAppraisalOrderFromAppraisal(apr1);
        Appraisal_Order__c ao2 = TestFactory.createAppraisalOrderFromAppraisal(apr2);
        insert new List<Appraisal_Order__c>{ ao1, ao2 };
    }
    
    @IsTest
    static void testSendOrder() {
        Appraisal_Order__c ao     = [select Id, Appraisal__c from Appraisal_Order__c limit 1];
        Appraisal__c app = [select Id, Customer_split__c, HEB_Split__c, Partner_Split__c, Paid_From_Proceeds__c, Cost_Exception_Approval__c from Appraisal__c where Id = :ao.Appraisal__c];
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        String s     = AppraisalOrderController.validateUpdateFee(ao.Id, app);
        Test.stopTest();
    }
    
    @IsTest 
    static void testSplitPercentageConverted() {
        Decimal actualCost = 2000;
        Decimal mypercent = 40;
        
        System.assertEquals(AppraisalUpdateFeeService.convertPercentToDecimal(2000, 40), 800);
        System.assertEquals(AppraisalUpdateFeeService.convertPercentToDecimal(100, 25), 25);
    }
    
    
}