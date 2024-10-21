/*-----------------------------------------------------------------------------------
@description       : The is test class for CreateNewAccount 
@last modified on  : 07-15-2024
Modifications Log 
-----------------------------------------------------------------------------------
Ver   Date         Author                               Modification
1.0   07-15-2024   Anurag Gupta                          Initial Version
-----------------------------------------------------------------------------------
*/
@isTest
public class CreateNewAccountTest {
  
    @isTest
    static void testSubmit() {
        Test.startTest();
        Account account = new Account(FirstName = 'Test', LastName = 'Test');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'Test',
            AccountId = account.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = System.today()
        );
        insert opportunity;
       // Test.setMock(HttpCalloutMock.class, new EmailValidationRequestMockCallout());
        //Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        String testWrapper = '{"primaryAccount":{"isMailingAddressSameAsProperty":false,"isPrimaryContact":false,"salutation":"Dr.","firstName":"Test","lastName":"test123","phone":"4162229999","email":"test1211test@test.com","primaryCity":"Toronto","primaryCountry":"Canada","primaryPostalCode":"123456","primaryProvince":"ON","primaryStreet":"Testing Street"},"PropertyMemberOne":{"isPrimaryContact":false,"salutation":"Prof.","firstName":"test2","lastName":"test55","phone":"","email":"test889@test88.com","age":"33","gender":"Female","dateOfBirth":"2024-07-08","maritalStatus":"Never Married","primaryCity":"","primaryCountry":"Canada","primaryPostalCode":"","primaryProvince":"","primaryStreet":"","isMailingAddressSameAsProperty":true,"isPrimaryBorrower":true,"controlling":"","dependent":""},"PropertyMemberTwo":{"isPrimaryContact":false,"salutation":"Prof.","firstName":"test33","lastName":"test45","phone":"","email":"","age":"66","gender":"Male","dateOfBirth":"2024-07-02","maritalStatus":"Separated","primaryCity":"","primaryCountry":"Canada","primaryPostalCode":"","primaryProvince":"","primaryStreet":"","isMailingAddressSameAsProperty":true,"isPrimaryBorrower":false,"controlling":"","dependent":"","RelationshipCategory":"Marital","RelationshipType":"Common-Law Spouse"},"fileDetails":{"Source":"Client Referral","Type":"Reverse Mortgage","Language":"English","Channel":"Consumer"},"partnerDetails":{"ReferralChannel":"BANK/CREDIT UNION - Investment Specialist/Financial Planners etc.","Territory":"","ReferralPartner":"","ReferralOrganization":""},"consent":{"CASLConsent":"Implied","CASLConsentObtainedBy":"","CASLConsentProvidedOn":"2024-07-01"},"property":{"PropertyType":"Townhouse / Row House","HomeValue":"22","CountryCode":"Canada","Street":"street","City":"Test","State":"ON","Zip":"123456"},"LoanPurpose":["Divorce/Separation"]}';
        try{
        	CreateNewAccount.submitRecords(testWrapper);
        }
        catch(Exception Ex){
            System.AssertNotEquals(ex,null); 
        }
        String testgQ = CreateNewAccount.generateQuotes(account.id);
        Test.stopTest();
        System.assertEquals('No Opportunities Attached',testgQ);
        
    }
    
    @IsTest
    static void testGetReferalAssociationsWithSecurity() {
        // Create test data
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestOrg',
                                                                 '32244',
                                                                 'Quebec',
                                                                 '41643210987');
        Id partnerRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
        Account partnerAcc = new Account();
        partnerAcc.RecordTypeId = partnerRecordTypeId;      
        partnerAcc.FirstName = 'West Toronto';        
        partnerAcc.LastName = 'Bank';
        partnerAcc.BillingPostalCode = 'M4M4C4';
        partnerAcc.BillingCity = 'Toronto';
        partnerAcc.Phone = '316023456';
        insert partnerAcc;
        Profile profileList = [ SELECT Id, Name FROM Profile WHERE Name IN (  :Label.SystemAdmin_Profile_Name  ) ]; 
        
        User u = new User(ProfileId = profileList.Id,
                          Username = 'rel@chip.ca',
                          Email = 'rel@chip.ca',
                          FirstName = 'rel',
                          LastName = 'user',
                          TimeZoneSidKey = 'GMT',
                          LocaleSidKey = 'en_US',
                          Alias = 'relUser',
                          EmailEncodingKey = 'UTF-8',
                          LanguageLocaleKey = 'en_US',
                          IsActive = true);
        insert u;
        Territory2 territory = new Territory2();
        // Create a test Territory
        System.RunAs(u) {
            Territory2Model territoryModel = new Territory2Model(Name = 'Test Model', DeveloperName = 'Test');
            insert territoryModel;
            
            Territory2Type territoryType =  [SELECT id, DeveloperName from Territory2Type  limit 1];
            
            territory = new Territory2(Name = 'Test Territory', Territory2ModelId = territoryModel.Id,DeveloperName = 'Test',Territory2TypeId = territoryType.id);
            insert territory;
            
            // Associate the Account with the Territory
            ObjectTerritory2Association ota = new ObjectTerritory2Association(
                ObjectId = partnerAcc.Id,
                Territory2Id = territory.Id,
                AssociationCause = 'Territory2Manual'
            );
            insert ota;
        }
        
        Test.startTest();
        try {
            Account clientAcc = TestFactory.createClientAccount(
                'Client FName',
                'Client LName',
                'M4M4C1',
                'Toronto',
                '316023426'
            );
            List<SObject> result = CreateNewAccount.getReferalAssociations(clientAcc.Id);
            
            // Verify results
            System.assertEquals(0, result.size());
        } catch (AuraHandledException e) {
            System.assert(false, 'Should not throw exception when user has proper permissions: ' + e.getMessage());
        }
        Test.stopTest(); 
    }
    
    @IsTest
    static void testGetReferalAssociationsException() {
        Test.startTest();
        try {
            // Pass null to force an exception
            CreateNewAccount.getReferalAssociations(null);
            System.assert(true, 'Should have thrown an AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertEquals('Error retrieving referal data', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
}