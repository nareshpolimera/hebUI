@isTest
public class QuoteRequestServiceTest {
    @testSetup
    static void setupTestData() {
        
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        // Create test data for Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create test data for Product_Rate_Set__c
        Product_Rate_Set__c prs = new Product_Rate_Set__c(
            Name = 'Test Rate Set',
            Available__c = true,
            External_ID__c = '111',
            Effective_Date__c = Date.today(),
            Current__c = true
        );
        insert prs;
        
        // Create test data for Product_Quote_Set__c
        Product_Quote_Set__c pqs = new Product_Quote_Set__c(
            Name = 'Test Quote Set',
            Available__c = true,
            External_ID__c = '191',
            Effective_Date__c = Date.today(),
            Current__c = true
        );
        insert pqs;
         // Create test data for Product
        Product2 p = new Product2( Name = 'CHIP');
        insert p;
        
        // Create test data for Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            AccountId = acc.Id,
            File_Number__c = '12345',
            //Product_Type__c = p.id,
            Product_Rate_Set__c = null,
            Product_Quote_Set__c =null
            
        );
        insert opp;
        
        // Create test data for ResidentialLoanApplication
        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'Test ResidentialLA',
            OpportunityId = opp.Id,
            Term__c = '1-Year'
        );
        insert rla;
        
        // Create test data for LoanApplicants
        Contact contact1 = new Contact(FirstName = 'John', LastName = 'Doe', Birthdate = Date.newInstance(1980, 1, 1), Age__c = 40, Gender__c = 'Male', AccountId = acc.Id);
        insert contact1;
        
        LoanApplicant loanApp1 = new LoanApplicant(
            Name = 'Test Applicant 1',
            LoanApplicationId = rla.Id,
            ContactId = contact1.Id,
            Role__c=LoanApplicantService.BORROWER_ROLE,
             Is_Primary_Borrower__c = true
        );
        insert loanApp1;
        
        Contact contact2 = new Contact(FirstName = 'Jane', LastName = 'Doe', Birthdate = Date.newInstance(1982, 2, 2), Age__c = 38, Gender__c = 'Female', AccountId = acc.Id);
        insert contact2;
        
        LoanApplicant loanApp2 = new LoanApplicant(
            Name = 'Test Applicant 2',
            LoanApplicationId = rla.Id,
            ContactId = contact2.Id,
            Role__c=LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = false
        );
        insert loanApp2;
        
        // Create test data for LoanApplicationLiability
        LoanApplicationLiability loanLiability = new LoanApplicationLiability(
            Name = 'Test Liability',
            LoanApplicationId = rla.Id,
            Secured__c = true,
            Include_Debt__c = true,
            CreditLimitAmount = 10000,
            Balance_Amount__c = 1000.00,
            Type__c = 'Mortgage',
            Amount__c = 10000.00
        );
        insert loanLiability;
        
        // Create test data for LoanApplicationProperty
        LoanApplicationProperty loanProperty = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = rla.Id,
            PropertyPostalCode = 'L5C2B8',
            PropertyCity = 'Mississauga',
            PropertyStateCode = 'ON',
            Property_Type__c = 'Single Family Dwelling'
        );
        insert loanProperty;
        
        
    }
    
    @isTest
    static void testSendRequest() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Rate_Set__c, Product_Quote_Set__c,Term__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuoteRequestServiceMockCallout());
        String response = QuoteRequestService.sendRequest(opp);
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Expected a response from the API');
    }
    
    @isTest
    static void testGenerateQuoteRequest() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Rate_Set__c, Product_Quote_Set__c,Term__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ModelQuote.Request request = QuoteRequestService.generateQuoteRequest(opp);
        System.debug(request);
        Test.stopTest();
        
        System.assertNotEquals(null, request, 'Expected to generate a quote request');
        System.assertEquals(opp.File_Number__c, request.FileNumber, 'File number should match');
        System.assertEquals(opp.Product_Type__c, request.ProductType, 'Product type should match');
    }
    
    @isTest
    static void testProcessResponse() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Quote_Set__c FROM Opportunity LIMIT 1];
        
        // Mocking a response
        String marsQuote = '{"fileNumber":"12345","locationCode":"001","propertyTypeRating":"A","isDowngraded":false,"eot":"2023-12-31","productQuotes":[{"productType":"Test Product Type","term":"30 Years","rate":3.5,"amount":200000.00,"isEligible":true,"ineligibleReason":null}],"ProductQuoteSetID":1,"ProductRateSetID":1}';
        
        Test.startTest();
        String result = QuoteRequestService.processResponse(marsQuote, opp);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Expected processResponse to return null');
        Opportunity updatedOpp = [SELECT Id, File_Number__c, Quote_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('12345', updatedOpp.File_Number__c, 'File number should be updated');
    }
    
    @isTest
    static void testGetQuotes() {
        Opportunity opp = [SELECT Id, File_Number__c, Product_Type__c, Product_Quote_Set__c,Term__c,Product_Rate_Set__c FROM Opportunity LIMIT 1];
        
        // Mocking a response
        ModelQuote.Response res = (ModelQuote.Response) JSON.deserialize('{"fileNumber":"12345","locationCode":"001","propertyTypeRating":"A","isDowngraded":false,"eot":"2023","productQuotes":[{"productType":"Test Product Type","term":"30 Years","rate":3.5,"amount":200000.00,"isEligible":true,"ineligibleReason":null}]}', ModelQuote.Response.class);
        
        Test.startTest();
        List<Quote> quotes = QuoteRequestService.getQuotes(res, opp);
        Test.stopTest();
        
        System.assertNotEquals(null, quotes, 'Expected to generate quotes from response');
        System.assertEquals(1, quotes.size(), 'Expected one quote to be generated');
        System.assertEquals('Test Product Type', quotes[0].Product_Type__c, 'Product type should match');
    }
    
    @isTest
    static void testGetOldActiveQuotes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Mocking new quotes
        List<Quote> newQuotes = new List<Quote>();
        Quote q = new Quote();
        q.Name = 'Test Quote';
        q.OpportunityId = opp.Id;
        q.Active_Quote__c = true;
        newQuotes.add(q);
        
        insert newQuotes;
        
        Test.startTest();
        List<Quote> oldQuotes = QuoteRequestService.getOldActiveQuotes(newQuotes, opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, oldQuotes, 'Expected to retrieve old active quotes');
    }
    
    @isTest
    static void testGetProperty() {
        ResidentialLoanApplication rla = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        
        Test.startTest();
        ModelQuote.Property property = QuoteRequestService.getProperty(rla);
        Test.stopTest();
        
        System.assertNotEquals(null, property, 'Expected to retrieve property from loan application');
    }
    
    @isTest
    static void testGetPropertyMembers() {
        ResidentialLoanApplication rla = [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
        
        Test.startTest();
        List<ModelQuote.Customer> customers = QuoteRequestService.getPropertyMembers(rla);
        Test.stopTest();
        
        System.assertNotEquals(null, customers, 'Expected to retrieve property members from loan application');
        System.assertEquals(0, customers.size(), 'Expected to retrieve customers');
    }
}