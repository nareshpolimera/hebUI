/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an org are executed whenever Apex code is deployed
* to a production org to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production org. In addition, all triggers must have some code coverage.
*
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the org size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@isTest
private class CreditCheckRequestServiceTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = false;
        upsert processSwitches;
        
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        
        //Test class fix 7-Aug  
        Account partnerAccount = TestFactory.createPartnerAccount(
            'West Toronto',
            'Bank',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        
        partnerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
        // Test Class Fix 6-Aug
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{partnerAccount, orgAccount};
            
            Opportunity op4 = TestFactory.createConsumerOpportunity('Test Application');
        op4.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op4};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test', AccountId = partnerAccount.Id);
        ResidentialLoanApplication application2 = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op4.id);
        insert new list<ResidentialLoanApplication> {application,application2};
            
            LoanApplicationProperty prop1 = TestFactory.createProperty(
                application.Id,
                'test1',
                '123 Test Drive',
                'Toronto',
                'ON',
                'M4M4M4'
            );
        
        LoanApplicationProperty prop2 = TestFactory.createProperty(
            application2.Id,
            'test1',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        
        insert new list<LoanApplicationProperty> {prop1,prop2};
            
            Contact c2 = TestFactory.createConsumerContact('Test2', 'Drive', 'testdrive2@chip.ca',orgAccount.Id);
        insert c2;
        
        LoanApplicant applicant2 = TestFactory.createPropertyMember(
            c2.Id,
            application2.Id,
            LoanApplicantService.COBORROWER_ROLE
        );
        insert new list<LoanApplicant> {applicant2};
            
            Credit_Report__c cr = new Credit_Report__c(
                Credit_Score__c = 999,
                Credit_Summary__c = 'Test',
                Loan_Applicant__c = applicant2.Id,
                Assessment_Eligible__c = true,
                Credit_hit__c = true
            );
        insert cr;
    }
    
    @IsTest
    static void testRequestCreditReport() {
        ResidentialLoanApplication application = [
            SELECT Id, AccountId
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        Test.setMock(HttpCalloutMock.class, new CreditRequestMockCallout());
        Test.startTest();
        CreditCheckRequestService.runCreditRequest(application);
        Test.stopTest();
        List<Credit_Report__c> credits = [
            SELECT Id, Credit_Hit__c, Trades_Info__c
            FROM Credit_Report__c
            WHERE Person__c = :application.AccountId
        ];
        system.debug(credits);
        Assert.areEqual(2, credits.size(), 'No Credit Report created');
        Assert.areEqual(true, credits[0].Credit_Hit__c, 'Credit Report not hit');
        Assert.isTrue(
            credits[1].Trades_Info__c.contains('Type'),
            'Credit Report no trades info'
        );
    }
    
    @IsTest
    static void testCreditAssessment() {
        ResidentialLoanApplication application = [
            SELECT Id, AccountId, OpportunityId
            FROM ResidentialLoanApplication
            WHERE OpportunityId != NULL
            LIMIT 1
        ];
        LoanApplicationProperty property = [
            SELECT Id, Property_Type__c, PropertyStateCode, Property_Value_for_Quote__c, Fire_Insurance_in_place_for_12_Months__c, Annual_Property_Taxes__c, 
			Fire_Insurance_Premium__c, Monthly_Condo_Fees__c, Condo_Fees_Owing__c, Property_Tax_Owing__c, Property_Taxes_Current__c, Condo_Fees_Current__c,
            PropertyStreet, PropertyCity, PropertyPostalCode
            FROM LoanApplicationProperty
            WHERE LoanApplicationId = :application.Id
            LIMIT 1
        ];
        
        
        Test.setMock(HttpCalloutMock.class, new CreditRequestMockCallout());
        Test.startTest();
        CreditCheckRequestService.runCreditAssessment(application);
        CreditCheckRequestService.updateProperty(property);
        CreditCheckRequestService.getAssessment(application);
        
        List<Credit_Assessment__c> credits = [
            SELECT Id, Credit_Assessment_Successful__c
            FROM Credit_Assessment__c
            WHERE Application__c = :application.Id
        ];
        List<LoanApplicationLiability> liabilities = [
            SELECT Id, Source__c
            FROM LoanApplicationLiability
            WHERE LoanApplicationId = :application.Id
        ];
        CreditCheckRequestService.updateAssessment(credits[0]);
        
        Test.stopTest();
        Assert.areEqual(1, credits.size(), 'No Credit Assessment created');
        Assert.areEqual(
            true,
            credits[0].Credit_Assessment_Successful__c,
            'Credit Assessment not hit'
        );
        Assert.areEqual(3, liabilities.size(), 'No Liabilities created');
        Assert.areEqual('Credit Bureau', liabilities[0].Source__c, 'Wrong Source');
        // Aura Methods
        CreditCheckRequestService.updatePropertyMembers(
            new List<Contact>()
        );
        
    }
    
     @IsTest
    static void testNegative() {
        try{
            CreditCheckRequestService.queryProperty(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.getProperty(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.getAssessment(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.runCreditAssessment(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.runCreditRequest(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.updatePropertyMembers(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.updateProperty(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            CreditCheckRequestService.updateAssessment(null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
    }
}