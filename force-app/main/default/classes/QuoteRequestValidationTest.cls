@IsTest
public class QuoteRequestValidationTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
         // Partner Referral accounts
            Account partnerAcc = TestFactory.createPartnerAccount(
                'West Toronto',
                'Bank',
                'M4M4C4',
                'Toronto',
                '316023456'
            );
        insert partnerAcc;
        //Product_Rate_Set__c prs = new Product_Rate_Set__c();
        //prs.Name = 'Test';
        //insert prs;
        Opportunity opp = new Opportunity( 
            Name = 'fname', 
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = system.today(),
            //Product_Rate_Set__c = prs.Id,
            File_Number__c='123456',
            AccountId=partnerAcc.Id
        );
        insert opp;
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'TestApp',OpportunityId=opp.Id, AccountId = partnerAcc.Id);
        insert application;
        LoanApplicationProperty loanProperty = new LoanApplicationProperty(
            Name = 'test1',
            LoanApplicationId = application.Id,
            Property_Type__c = 'Single Family Dwelling',
            PropertyPostalCode = 'M4M4M4',
            PropertyCity = 'Mississauga',
            PropertyStateCode = 'AB',
            PropertyCountryCode = 'CA'
        );
        
        insert loanProperty;
        
    }
    
    /*
* HEB-222 Validates the Property for Quote
*/
    @IsTest
    static void validateProperty() {
        Account partnerAcc = [Select Id From Account LIMIT 1];
        ResidentialLoanApplication loanApplication = [
            SELECT Id
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        LoanApplicationProperty prop = [
            SELECT Property_Type__c, CreatedById
            FROM LoanApplicationProperty
            WHERE LoanApplicationId = :loanApplication.Id
            LIMIT 1
        ]; 
		 LoanApplicant la = new LoanApplicant (
            LoanApplicationId = loanApplication.id,
            name = 'test',
            Role__C = 'Borrower',
            Client__c = partnerAcc.Id,
            Is_Primary_Borrower__c = false
        );
        insert la;
        Test.StartTest(); 
        Map<String, Object> jsonMap;
        
        try {
            
            prop.PropertyPostalCode = 'asd';
            prop.PropertyCity = 'Montreal';
            update prop;
            QuoteRequestValidationController.ValidateProperty(prop);
            
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains(Label.Error_Invalid_PostalCode_City),
                'Property not validated'
            );
        }
        Test.StopTest();
    }
    
    /*
* HEB-222 Validates the Property for Quote
*/
    @IsTest
    static void validatePropertyOnQuoteRequest() {
        Test.StartTest();
       // Account partnerAcc = [SELECT Id FROM Account WHERE LastName = 'Bank' Limit 1];
        //TestFactory.createLoanApplicationAndRelatedObjects(partnerAcc);
        //update partnerAcc;
        ResidentialLoanApplication loanApplication = [
            SELECT Id
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        User specialistUser = [
            SELECT Id
            FROM User
            Where IsActive =true 
            LIMIT 1
        ];
        
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        opp.ownerId = specialistUser.Id;
        update opp;
        LoanApplicationProperty prop = [
            SELECT Property_Type__c
            FROM LoanApplicationProperty
            WHERE LoanApplicationId = :loanApplication.Id
            LIMIT 1
        ];
        
        prop.PropertyPostalCode = 'asd';
        update prop;
        List<LoanApplicant> pmList = new List<LoanApplicant>();
        for (LoanApplicant pm : [
            SELECT Id, OwnerId
            FROM LoanApplicant
            WHERE LoanApplicationId = :loanApplication.Id
        ]) {
            pm.OwnerId = specialistUser.Id;
            pmList.add(pm);
        }
        update pmList;
        
        Map<String, Object> jsonMap;
        System.runAs(specialistUser) {
            
            String jsonResponse = QuoteRequestValidationController.validateQuote(
                opp.Id
            );
            jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        }
        
        //System.assertEquals((Boolean) jsonMap.get('validQuote'), false);
        Test.StopTest();
    }
    
    /*
* HEB-222 Validates the Quote
*/
    @IsTest
    static void validateQuoteRequest() {
        Account partnerAcc = [SELECT Id FROM Account WHERE LastName = 'Bank' Limit 1];
        Test.startTest();
        //TestFactory.createLoanApplicationAndRelatedObjects(partnerAcc);
        ResidentialLoanApplication loanApplication = [
            SELECT Id
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            loanApplication,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            loanApplication,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            Opportunity opp = [
                SELECT Id
                FROM Opportunity
                LIMIT 1
            ];
        
        LoanApplicationProperty prop = [
            SELECT Property_Type__c
            FROM LoanApplicationProperty
            WHERE LoanApplicationId = :loanApplication.Id
            LIMIT 1
        ];
        prop.Property_Type__c = '';
        update prop;
        
        String jsonResponse = QuoteRequestValidationController.validateQuote(
            opp.Id
        );
        Test.stopTest();
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
            jsonResponse
        );
        
        //System.assertEquals((Boolean) jsonMap.get('validQuote'), false);
        System.assert(String.isNotBlank((String) jsonMap.get('errorMessage')));
    }
    
    /*
* HEB-222 Generates the Quote from Lead
*/
    @IsTest
    static void generateQuote() {
        
        Account partnerAcc = [SELECT Id FROM Account WHERE LastName = 'Bank' Limit 1];
        //TestFactory.createLoanApplicationAndRelatedObjects(partnerAcc);
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];
        opp.File_Number__c = '';
        update opp;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuoteRequestMockCallout());
        QuoteRequestValidationController.getQuote(opp.Id);
        system.assert(
            [SELECT Id FROM Quote WHERE OpportunityId = :opp.Id] != null,
            'Quote was not generated'
        );   
        test.stopTest();
    }
    
    /*
* HEB-508 Updates the File Status on Quote generation when All Quotes are Ineligible w/ reason "Validation"
*/
    @IsTest
        public static void fileStatusOnQuoteRequestIneligibleValidation() {
            Account partnerAcc = [SELECT Id FROM Account WHERE LastName = 'Bank' Limit 1];
            //TestFactory.createLoanApplicationAndRelatedObjects(partnerAcc);
            Opportunity opp = [
                SELECT Id, Quote_Status__c
                FROM Opportunity
                LIMIT 1
            ];
			ResidentialLoanApplication loanApplication = [
                SELECT Id
                FROM ResidentialLoanApplication
                LIMIT 1
            ];
    		LoanApplicant la = new LoanApplicant (
                LoanApplicationId = loanApplication.id,
                name = 'test',
                Role__C = 'Borrower',
                Client__c = partnerAcc.Id,
                Is_Primary_Borrower__c = false
        	);
        	insert la;
            system.assertEquals(
                Label.Quote_Status_Unqualified,
                opp.Quote_Status__c,
                'Quote Status not set correctly.'
            );
             test.startTest();
            Test.setMock(
                HttpCalloutMock.class,
                new QuoteRequestIneligibleMockCallout()
            );

            QuoteRequestValidationController.getQuote(Opp.Id);           
            
            system.assert(
                [SELECT Id FROM Quote WHERE OpportunityId = :opp.Id] != null,
                'Quote was not generated'
            );
            opp = [
                SELECT Id, File_Number__c, Quote_Status__c
                FROM Opportunity
                WHERE Id = :opp.Id
            ];
            system.assertEquals(
                Label.Quote_Status_Unqualified,
                opp.Quote_Status__c,
                'Quote Status not set correctly.'
            );
             test.stopTest();
        }   
}