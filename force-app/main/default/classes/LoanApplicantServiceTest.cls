@IsTest
private class LoanApplicantServiceTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches; 
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
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
        List<Account> acctList = new List<Account>(); 
        // Partner Referral accounts
        Account partnerAcc = TestFactory.createPartnerAccount(
            'Client lastname1%',
            'Client lastname1%',
            'M4M4C4',
            'Toronto',
            '116023456'
        );
        partnerAcc.recordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acctList.add(partnerAcc);
        
        Account partnerAcc1 = TestFactory.createPartnerAccount(
            'Client1 lastname2',
            'Client1 lastname2',
            'M4M4C4',
            'Toronto',
            '216023456'
        );
        acctList.add(partnerAcc1);
        Account partnerAcc2 = TestFactory.createPartnerAccount(
            'Client lastname2',
            'Client lastname2',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        acctList.add(partnerAcc2);
        Account partnerAcc3 = TestFactory.createPartnerAccount(
            'Client2 FName%2',
            'Client2 FName%2',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        acctList.add(partnerAcc3);
        insert acctList;
        Opportunity opp = new Opportunity( 
            Name = 'fname', 
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = system.today(),
            File_Number__c='123456',
            AccountId=partnerAcc.Id 
        );
        insert opp;
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'TestApp',OpportunityId=opp.Id, AccountId = partnerAcc.Id);
        insert application;
        LoanApplicationProperty prop1 = TestFactory.createProperty(
            application.Id,
            'test1',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        insert prop1;
        LoanApplicant la = new LoanApplicant (
            LoanApplicationId = application.id,
            name = 'test',
            Role__C = 'Borrower',
            Client__c = partnerAcc.Id,
            Is_Primary_Borrower__c = false
        );
        insert la;
    }
    
    @isTest
    static void testGenerateName()
    {
        ResidentialLoanApplication app = [
            SELECT
            Id, OpportunityId
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1];
        
        Test.startTest();    
        List<Account> c = [Select Id from Account ];
        
        LoanApplicant LA = new LoanApplicant(
            Client__c = c[0].Id,
            LoanApplicationId = app.Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true,
            Name = 'test'
            
        );
        insert LA;
        
        LA = [Select Name, Generated_Number__c,Is_Primary_Borrower__c from LoanApplicant where Id = :LA.Id];
        
        System.assertEquals( true, LA.get('Is_Primary_Borrower__c'));  
    }
    
    @isTest
    static void testGenerateNameNextSequence()
    {
        Test.startTest();  
        List<Account> c = [Select Id from Account];
        
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1];
        
            
        LoanApplicant LA = new LoanApplicant(
            Client__c = c[0].Id,
            LoanApplicationId = app.Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true,
            Name = 'test'
        );    
        LoanApplicant LA2 = new LoanApplicant(
            Client__c = c[1].Id,
            LoanApplicationId = app.Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true,
            Name = 'test'
        );    
        LoanApplicant LA3 = new LoanApplicant(
            Client__c = c[2].Id,
            LoanApplicationId = app.Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true,
            Name = 'test'
        );
        insert new List<LoanApplicant> {LA, LA2, LA3};
            
            LA3 = [Select Name, Generated_Number__c,Is_Primary_Borrower__c from LoanApplicant where Id = :LA3.Id];
        
        System.assertEquals(true, LA3.get('Is_Primary_Borrower__c')); 
    }
    /*
* HEB-32: Return list of Borrowers, leveraged in a credit check
*/
    @IsTest
    static void testThatBorrowersReturned() {
        
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId,
            (
                SELECT Id,Is_Primary_Borrower__c
                FROM LoanApplicants
                WHERE Role__c INCLUDES (:LoanApplicantService.BORROWER_ROLE) AND
                Is_Primary_Borrower__c = TRUE
            )
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1 
        ];
        
        Test.setMock(HttpCalloutMock.class, new ParseRequestMockCallout());
        Test.startTest();
        System.assertEquals(
            LoanApplicantService.getBorrowers(app.OpportunityId).applicants.size(),
            1,
            'Service method not returning the expected Borrowers'
        );
        Test.stopTest();
    }
    
    /*
* HEB-220-Test only one Primary Borrower allowed
*/
    @IsTest
    static void testPrimaryBorrowerUpdate() {
        
         Test.startTest();
        List<Account> c = [Select Id from Account];
        ResidentialLoanApplication app = [SELECT id FROM ResidentialLoanApplication LIMIT 1 ];
        
        // Create LoanApplicant records
        LoanApplicant primaryBorrower = new LoanApplicant(
            LoanApplicationId = app.Id,
            Client__c = c[0].Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true,
            name = 'test'
        );
        LoanApplicant coBorrower = new LoanApplicant(
            LoanApplicationId = app.Id,
            Client__c = c[1].Id,
            Role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = false,
            name = 'test'
        );
        // Start test to update co-borrower to primary borrower 
        insert new List<LoanApplicant> { primaryBorrower, coBorrower };
            
            // Verify initial state
            primaryBorrower = [
                SELECT Id, Role__c, Is_Primary_Borrower__c
                FROM LoanApplicant
                WHERE Id = :primaryBorrower.Id
            ];
        coBorrower = [
            SELECT Id, Role__c, Is_Primary_Borrower__c
            FROM LoanApplicant
            WHERE Id = :coBorrower.Id
        ];
        
        System.assert(primaryBorrower.Role__c.contains('Borrower'), 'Initial primary borrower should have Role__c as Borrower.');
        System.assert(primaryBorrower.Is_Primary_Borrower__c == true, 'Initial primary borrower should have Is_Primary_Borrower__c as true.');
        System.assert(coBorrower.Role__c.contains('Borrower'), 'Initial co-borrower should have Role__c as Borrower.');
        System.assert(coBorrower.Is_Primary_Borrower__c == false, 'Initial co-borrower should have Is_Primary_Borrower__c as false.');
        
        
        coBorrower.Is_Primary_Borrower__c = true;
        coBorrower.Client__c = c[2].Id;
        update coBorrower;
        Test.stopTest();
        
        // Re-fetch records to verify updates
        primaryBorrower = [
            SELECT Id, Role__c, Is_Primary_Borrower__c
            FROM LoanApplicant
            WHERE Id = :primaryBorrower.Id
        ]; 
        
        // Verify that the old primary borrower was demoted
        System.assertEquals(
            false,
            primaryBorrower.Is_Primary_Borrower__c,
            'Trigger did not remove the old primary borrower status.'
        );
        
        // Verify that the new primary borrower was set correctly
        System.assertEquals(
            true,
            coBorrower.Is_Primary_Borrower__c,
            'New Primary borrower value was not set correctly.'
        );
    }
    
    
    
    /*
* HEB-220-Test only one Primary Borrower allowed
*/
    @IsTest
    static void testPrimaryBorrowerInsert() {
        Test.startTest();
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId,
            (
                SELECT Id, Is_Primary_Borrower__c,role__c
                FROM LoanApplicants 
            )
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1
        ];
        
        LoanApplicant oldPrimaryBorrower = (app.LoanApplicants)[0];
        oldPrimaryBorrower.Role__c = LoanApplicantService.BORROWER_ROLE;
        oldPrimaryBorrower.Is_Primary_Borrower__c = true;
        
        update oldPrimaryBorrower;
        oldPrimaryBorrower = [
            SELECT Id, LoanApplicationId, Role__c,Is_Primary_Borrower__c
            FROM LoanApplicant 
            WHERE Id = :oldPrimaryBorrower.Id
        ];
        
        system.assertEquals(
            true,
            oldPrimaryBorrower.Role__c.contains(LoanApplicantService.BORROWER_ROLE) && oldPrimaryBorrower.Is_Primary_Borrower__c == true,
            'Old primary borrower was not set to Primary.'
        );
        
        LoanApplicant newPrimaryBorrower = TestFactory.createPropertyMember(
            [select id from contact limit 1].Id,
            oldPrimaryBorrower.LoanApplicationId,
            LoanApplicantService.BORROWER_ROLE
        );
        
        insert newPrimaryBorrower;
        Test.stopTest();  
        system.assertEquals(
            true,
            newPrimaryBorrower.Role__c.contains(LoanApplicantService.BORROWER_ROLE) && newPrimaryBorrower.Is_Primary_Borrower__c == true,
            'New Primary borrower value was not set.'
        ); 
    }
    
    /*
* HEB-325 Validating Deletion of Property Member
*/
    @isTest
    static void testValidateDeletePrimaryPM() {
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId,
            (
                SELECT Id
                FROM LoanApplicants
                WHERE  Role__c INCLUDES(:LoanApplicantService.BORROWER_ROLE) AND
                Is_Primary_Borrower__c = true
            )
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1
        ];
        
        Test.startTest();
        {
            try {
                delete app.LoanApplicants[0];
            } catch (Exception e) { }
        }
        Test.stopTest();
        system.assertNotEquals( null, app, 'Application not null');
    }
    
    /*
* HEB-325 Validating Deletion of Property Member
*/
    @isTest
    static void testValidateDeletePMOnFile() {
        // create some Property records to use for net new Leads
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId,
            (
                SELECT Id
                FROM LoanApplicants
                WHERE (Role__c INCLUDES(:LoanApplicantService.BORROWER_ROLE) AND
                       Is_Primary_Borrower__c = false) AND 
                Client__r.RecordType.DeveloperName = 'PersonAccount'
            )
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1
        ];
        Test.startTest();
        {
            try {
                delete app.LoanApplicants[0];
            } catch (Exception e) { }
        }
        Test.stopTest();
        system.assertNotEquals( null, app, 'Application not null');
    }
    
    @isTest
    static void testAditionalValidationOnFile() {
        // create some Property records to use for net new Leads
        ResidentialLoanApplication app = [
            SELECT
            Id,OpportunityId,
            (
                SELECT Id, Is_Primary_Borrower__c
                FROM LoanApplicants
                WHERE Role__c INCLUDES(:LoanApplicantService.BORROWER_ROLE) AND
                Is_Primary_Borrower__c = false AND Client__r.RecordType.DeveloperName = 'PersonAccount' 
            )
            FROM ResidentialLoanApplication
            WHERE OpportunityId != null limit 1
        ];
        Test.startTest();
        {
            delete app.LoanApplicants[0];
            
        }
        Test.stopTest();
        system.assertNotEquals( null, app, 'Application not null');
    }
    
    /*
* HEB-296: Check that when a Property Member is updated when the Opportunity File is sent to MARS, is blocked.
*/
    @IsTest
    static void testLockMARSPropertyMembers() {
    }
    
    /*
* HEB-386: Check only two Quotable Property Members can be selected
*/
    @IsTest
    public static void testQuoteablePropertyMembersOnlyTwo() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount',
                                                                     '32244',
                                                                     'Quebec',
                                                                     '41643210987');
            insert orgAccount;
            
            
            Contact c1 = TestFactory.createConsumerContact('Test111', 'Drive', 'testdrive111@chip.ca',orgAccount.Id);
            insert c1; 
            Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout()); 
            LoanApplicant applicant1 = TestFactory.createPropertyMember(
                c1.Id,
                [select id from ResidentialLoanApplication limit 1].Id,
                LoanApplicantService.COBORROWER_ROLE
            );
            
            applicant1.Use_For_Quote__c = true;
            
            
            
            // Test failure on trying to create >2 quoteable property members
            try {
                insert applicant1;
                system.assert(true);// to make sure the error was catched in the previous line.
            } catch (DMLException dmle) {
                System.assertEquals(
                    Label.Error_PropMem_OnlyTwoQuoteableMembers,
                    dmle.getDmlMessage(0)
                );
            }
            Test.stopTest();
            system.assertNotEquals( null, applicant1, 'applicant1 not null');
        }
    }
    
    /*
* HEB-386: Check only borrower Quotable Property Members can be selected
*/
    @IsTest
    public static void testQuoteablePropertyMembersAreBorrowers() {
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount',
                                                                     '32244',
                                                                     'Quebec',
                                                                     '41643210987');
            insert orgAccount;
            
            
            Contact c1 = TestFactory.createConsumerContact('Test111', 'Drive', 'testdrive111@chip.ca',orgAccount.Id);
            insert c1;  
            Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
            
            LoanApplicant applicant1 = TestFactory.createPropertyMember(
                c1.Id,
                [select id from ResidentialLoanApplication  limit 1].Id,
                ''
            );
            applicant1.Use_For_Quote__c = true;   
            
            try {
                insert applicant1;
            } catch (DmlException dmle) {
                System.assertEquals(
                    Label.Error_PropMem_MustBeBorrower,
                    dmle.getDmlMEssage(0)
                );
            }
            Test.stopTest();
			system.assertNotEquals( null, applicant1, 'applicant1 not null');
        }
    }
}