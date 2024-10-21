@IsTest
private class AccountServiceTest
{
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        Profile standardUserProfile = [SELECT Id, Name
            FROM Profile
            WHERE
            Name =: Label.HEBStandard_Profile_Name LIMIT 1
        ];
        
        User standardUser = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'standarduser@chip.ca',
            Email = 'standarduser@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'stdUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        insert standardUser;
        
        // Partner Referral accounts
        Account partnerAcc = TestFactory.createPartnerAccount(
            'West Toronto',
            'Bank',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        Account partnerAccount1 = TestFactory.createPartnerAccount(
            'Martha',
            'Stewart',
            '123',
            '41643210987',
            '11111111111'
        );
        Account partnerAccount2 = TestFactory.createPartnerAccount(
            'Betty',
            'Crocker',
            '123',
            '41643210987',
            '11111111111'
        );
        
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
        Account clientAcc = TestFactory.createClientAccount(
            'Client FName',
            'Client LName',
            'M4M4C1',
            'Toronto',
            '316023426'
        );
        Account clientAcc2 = TestFactory.createClientAccount(
            'Client FName2',
            'Client LName2',
            'M4M4C1',
            'Toronto',
            '316023426'
        );
        Account clientAcc3 = TestFactory.createClientAccount(
            'Client FName3',
            'Client LName3',
            'M4M4C1',
            'Toronto',
            '316023426'
        );
        Account clientAcc4 = TestFactory.createClientAccount(
            'Client FName4',
            'Client LName4',
            'M4M4C1',
            'Toronto',
            '316023426'
        );
        partnerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
        // Test Class Fix 6-Aug
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{ partnerAcc, partnerAccount, partnerAccount1, partnerAccount2, orgAccount, clientAcc, clientAcc2, clientAcc3, clientAcc4 };
            
            
            FinServ__ReciprocalRole__c paymentRole = new FinServ__ReciprocalRole__c();
        paymentRole.name = 'Payment Agreement Holdee';
        paymentRole.FinServ__InverseRole__c = 'Payment Agreement Holdee';
        paymentRole.FinServ__CreateInverseRole__c = false;
        
        FinServ__ReciprocalRole__c referralRole = new FinServ__ReciprocalRole__c();
        referralRole.name = 'Referral Agreement Holdee';
        referralRole.FinServ__InverseRole__c = 'Referral Agreement Holdee';
        referralRole.FinServ__CreateInverseRole__c = false;
        
        insert new list<FinServ__ReciprocalRole__c>{paymentRole,referralRole};
            
            Reciprocal_Role_Settings__c roleSettings = Reciprocal_Role_Settings__c.getOrgDefaults();
        roleSettings.Payment_Agreement_Id__c = paymentRole.Id;
        roleSettings.Referral_Agreement_Id__c = referralRole.Id;
        upsert roleSettings;
        
        PermissionSetGroup psg= [SELECT ID FROM PermissionSetGroup WHERE DeveloperName = 'HEB_Call_Centre_PSG' LIMIT 1];
        Test.calculatePermissionSetGroup(new Id[] { psg.Id });
    }
    
    @isTest
    static void testCheckDialListMainChanges() {
        Test.startTest();
        Account oppAccount=[Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = oppAccount.Id,
                                                      StageName='Assessment Needed',
                                                      Channel__c = 'Consumer',
                                                      File_Queue__c = 'Initial Contact',
                                                      Primary_Borrower_Age__c = 60,
                                                      LeadSource='Client Referral',
                                                      CloseDate=System.today()
                                                     );
        insert testOpportunity;
        
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test', AccountId = oppAccount.Id);
        insert application;
        
        // update acount to match the criteria
        oppAccount.Most_Recent_Inquiry_Date__pc = System.Today().addDays(-188);
        oppAccount.In_Nurture_Stream__c = false;
        oppAccount.Phone_Verification_Status__c = 'Valid';
        oppAccount.Not_Interested_Yet__c = false;
        oppAccount.LastName = 'Testing Last Name';
        update oppAccount;
        oppAccount=[Select Id,Dial_List_Main__c from Account WHERE Id = :oppAccount.Id];
        
        System.AssertEquals(false, oppAccount.Dial_List_Main__c, 'Expected Dial List to be true');
        Test.stopTest();
    }
    
    @isTest
    static void testCheckDialListMainChangesTrue() {
        Account oppAccount=[Select Id,LastName from Account WHERE LastName ='Bank' limit 1][0];
        Test.startTest();
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      AccountId = oppAccount.Id,
                                                      StageName='Assessment Needed',
                                                      Channel__c = 'Consumer',
                                                      File_Queue__c = 'Initial Contact',
                                                      Primary_Borrower_Age__c = 60,
                                                      LeadSource='Client Referral',
                                                      CloseDate=System.today()
                                                     );
        insert testOpportunity;
        testOpportunity.File_Queue__c = 'Initial Contact';
        update testOpportunity;
        
        oppAccount.Phone_Verification_Status__c = 'Valid';
        oppAccount.Not_Interested_Yet__c = FALSE;
        oppAccount.Dialer_Dormant__c = FALSE;
        update oppAccount;
        
        ResidentialLoanApplication application1 = new ResidentialLoanApplication(Name = 'Test2', AccountId = oppAccount.Id, OpportunityId = testOpportunity.id);
        insert application1;
        
        LoanApplicationProperty prop1 = TestFactory.createProperty(
            application1.Id,
            'test1',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        prop1.Appraised_Amount__c = 2500001;
        insert prop1;
        // update acount to match the criteria
        oppAccount.Most_Recent_Inquiry_Date__pc = System.Today().addDays(-188);
        oppAccount.In_Nurture_Stream__c = false;
        oppAccount.Phone_Verification_Status__c = 'Valid';
        oppAccount.Not_Interested_Yet__c = false;
        
        update oppAccount;
        oppAccount=[Select Id,Dial_List_Main__c from Account WHERE Id = :oppAccount.Id];
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateAddress(){
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            Account l1 = TestFactory.createPartnerAccount(
                'Test',
                'Acc',
                '50004',
                'Toronto',
                null            
            );
            insert l1;
            l1.PersonMailingStreet ='test';
            l1.PersonMailingCity='Vancouver';
            l1.PersonMailingPostalCode='32244';
            l1.PersonMailingState='BC';
            l1.Phone = '5556633';
            l1.Numeric_Phone__c='5559966';
            l1.PersonEmail = null;
            update l1;
            Test.stopTest(); 
        }
    }
    
    @IsTest
    static void testCreateAccountContactRelationship(){
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            Account l1 = TestFactory.createPartnerAccount(
                'Test',
                'Acc',
                '50004',
                'Toronto',
                null            
            );
            l1.CurrentOrganization__c = [select id from account where RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId() limit 1].Id;
            insert l1;
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testPhoneNumberValidation() {
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSetGroup psg= [SELECT ID FROM PermissionSetGroup WHERE DeveloperName = 'HEB_Call_Centre_PSG' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetGroupId = psg.Id);
        insert psa;
        
        Test.startTest();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            
            Account l1 = TestFactory.createPartnerAccount(
                'Test',
                'Acc',
                'M4M4C4',
                'Toronto',
                null
            );
            l1.Phone = '4162229999';
            //
            Account l2 = TestFactory.createPartnerAccount(
                'Test',
                'Acc2',
                'M4M4C4',
                'Toronto',
                '316023121'
            );  
            l2.Phone_Verification_Status__c = 'Valid';
            l2.Phone_Verification_Line_Type__c = 'Mobile';
            l2.SMS_Address__c = '123@test.sms.com';
            l2.Phone_Number_Validated_On__c = System.Now();
            l2.PersonMailingStreet = 'Test';
            l2.PersonMailingCity = 'Test';
            l2.PersonMailingPostalCode = 'M4M4C4';
            l2.PersonMailingState = 'QC';
            
            insert new List<Account>{ l1, l2 };
                l1 = [
                    SELECT Id, PersonEmail, phone
                    FROM Account
                    WHERE Phone = '316023121'
                ];
            l1.phone = '4161234567';
            l1.PersonEmail = 'test@test.com.inavlid';
            l1.PersonMailingStreet = 'Test1';
            l1.PersonMailingCity = 'Test1';
            l1.PersonMailingPostalCode = 'M4M4C2';
            l1.PersonMailingState = 'ON';
            update l1;
            
             l1.phone = '';
            l1.PersonEmail = '';
            update l1;
            
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testEmailValidation() {
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            Account l1 = TestFactory.createPartnerAccount(
                'Old Toronto',
                'Bank',
                'M5M5M5',
                'Toronto',
                null
            );
            l1.Phone = '4162229999';
            //
            Account l2 = TestFactory.createPartnerAccount(
                'Test',
                'Acc2',
                'M5M5M5',
                'Toronto',
                '316023121'
            );  
            l2.PersonEmail = 'test2@chip.ca.dummy';
            l2.Email_Verification_Status__c = 'Valid';
            l2.Email_Verification_Timestamp__c = System.Now();
            insert new List<Account>{ l1, l2 };
                l1 = [
                    SELECT Id, PersonEmail, phone
                    FROM Account
                    WHERE Phone = '316023121'
                ];
            l1.PersonEmail = 'testphonenumbervaliation3@chip.ca.dummy';
            update l1;
            
            Test.stopTest();
        }
    }
    
    @isTest
    public static void test_deactivateAccAccRelationship_payment() {
        
        Reciprocal_Role_Settings__c roleSettings = Reciprocal_Role_Settings__c.getOrgDefaults();
        List<Account> orgAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName='Partner_Organization' limit 1];
        List<Account> personAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName='PersonAccount' limit 1];
        List<FinServ__ReciprocalRole__c> paymentRole = [Select Id from FinServ__ReciprocalRole__c where Id = :roleSettings.Payment_Agreement_Id__c];
        
        System.assert(!personAccount.isEmpty());
        System.assert(!orgAccount.isEmpty());
        System.assert(!paymentRole.isEmpty());
        
        orgAccount[0].Payment_Organization_Eligible__c = true;
        orgAccount[0].Referral_Agreement_Holder_Eligible__c = true;
        update orgAccount;
        
        test.startTest();
        //create acc-acc relation
        FinServ__AccountAccountRelation__c aar = new FinServ__AccountAccountRelation__c();
        aar.FinServ__Account__c = personAccount[0].id;
        aar.FinServ__Role__c = paymentRole[0].id;
        aar.Referral_Holder_or_Payment_Eligible__c = orgAccount[0].id;
        insert aar;
        
        orgAccount[0].Payment_Organization_Eligible__c = false;
        update orgAccount;
        
        test.stopTest();
        
        List<FinServ__AccountAccountRelation__c> aarList = [SELECT Id,FinServ__Active__c FROM FinServ__AccountAccountRelation__c WHERE Id = :aar.Id];
        System.assert(!aarList.isEmpty());
    }
    
    @isTest
    public static void test_deactivateAccAccRelationship_referral() {
        
        Reciprocal_Role_Settings__c roleSettings = Reciprocal_Role_Settings__c.getOrgDefaults();
        List<Account> orgAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName='Partner_Organization' limit 1];
        List<Account> personAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName='PersonAccount' limit 1];
        List<FinServ__ReciprocalRole__c> referralRole = [Select Id from FinServ__ReciprocalRole__c where Id = :roleSettings.Referral_Agreement_Id__c];
        
        System.assert(!personAccount.isEmpty());
        System.assert(!orgAccount.isEmpty());
        System.assert(!referralRole.isEmpty());
        
        orgAccount[0].Payment_Organization_Eligible__c = true;
        orgAccount[0].Referral_Agreement_Holder_Eligible__c = true;
        update orgAccount;
        
        test.startTest();
        //create acc-acc relation
        FinServ__AccountAccountRelation__c aar = new FinServ__AccountAccountRelation__c();
        aar.FinServ__Account__c = personAccount[0].id;
        aar.FinServ__Role__c = referralRole[0].id;
        aar.Referral_Holder_or_Payment_Eligible__c = orgAccount[0].id;
        insert aar;
        
        orgAccount[0].Referral_Agreement_Holder_Eligible__c = false;
        update orgAccount;
        
        test.stopTest();
        
        List<FinServ__AccountAccountRelation__c> aarList = [SELECT Id,FinServ__Active__c FROM FinServ__AccountAccountRelation__c WHERE Id = :aar.Id];
        System.assert(!aarList.isEmpty());
    }
    
    @IsTest
    public static void testGenerateListofChangedPhone() {
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSetGroup psg= [SELECT ID FROM PermissionSetGroup WHERE DeveloperName = 'HEB_Call_Centre_PSG' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetGroupId = psg.Id);
        insert psa;
        
        System.runAs(testUser) { 
            Account existingAccount = TestFactory.createPartnerAccount(
                'Old Toronto',
                'Bank',
                'M5M5M5',
                'Toronto',
                '4161112222'
            );
            insert existingAccount;
            
            // Simulate old records
            Map<Id, Account> oldRecords = new Map<Id, Account>{
                existingAccount.Id => new Account(
                    Id = existingAccount.Id,
                    Phone = '4161112222'
                )
                    };
                        
                        // Simulate updated records
                        existingAccount.Phone = '4169998888';
            
            List<Account> updatedRecords = new List<Account>{ existingAccount };
                
                // Verify the updated fields on the Account
                Account result = [
                    SELECT Phone_Verification_Status__c, Phone_Verification_Line_Type__c, Phone_Number_Validated_On__c, SMS_Address__c 
                    FROM Account 
                    WHERE Id = :existingAccount.Id
                    LIMIT 1
                ];
            
            // Test for blank phone number
            existingAccount.Phone = '';
            oldRecords.put(existingAccount.Id, existingAccount);
            
            // Set up the mock for the callout in validatePhoneNumber
            Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
            
            new AccountService().generateListofChangedPhone(updatedRecords, oldRecords);
            Test.stopTest();            
            
            
            result = [
                SELECT Phone_Verification_Status__c, Phone_Verification_Line_Type__c, Phone_Number_Validated_On__c, SMS_Address__c
                FROM Account 
                WHERE Id = :existingAccount.Id
                LIMIT 1
            ];
            
            
        }
    }
    
    @IsTest
    public static void testValidateEmail() {
        // Setup test data
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = TRUE;
        upsert processSwitches;
        
        Account testAccount = TestFactory.createPartnerAccount(
            'Test',
            'Acc',
            '50004',
            'Toronto',
            null            
        );
        insert testAccount;
        
        // List of Account Ids to validate
        List<Id> accountIds = new List<Id>{ testAccount.Id };
            
            // Set up the mock for EmailValidationService
            Test.setMock(HttpCalloutMock.class, new EmailValidationRequestMockCallout());
        
        // Call the method under test
        Test.startTest();
        AccountService.validateEmail(accountIds);
        Test.stopTest();
        
        // Verify that the Account's email verification fields were updated
        Account result = [
            SELECT Email_Verification_Status__c, Email_Verification_Timestamp__c
            FROM Account
            WHERE Id = :testAccount.Id
            LIMIT 1
        ];
        
        // Assertions based on the mock response
        System.assertEquals(result.Email_Verification_Status__c, 'Valid', 'Email_Verification_Status__c should be Valid.');
        System.assertNotEquals(result.Email_Verification_Timestamp__c, null, 'Email_Verification_Timestamp__c should be updated.');
    }
    
    @IsTest
    public static void testAccountAddressParse() {
        // Setup test data
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = TRUE;
        upsert processSwitches;
        
        // Create test Account with necessary fields for address parsing
        Account testAccount = TestFactory.createPartnerAccount(
            'Test',
            'Acc',
            '50004',
            'Toronto',
            null            
        );
        insert testAccount;
        
        // List of Account Ids to be parsed
        List<Id> accountIds = new List<Id>{ testAccount.Id };
            
            // Set up the mock for ParseAddressService
            Test.setMock(HttpCalloutMock.class, new ParseAddressMockCallout());
        
        // Call the method under test
        Test.startTest();
        AccountService.accountAddressParse(accountIds);
        Test.stopTest();
        
        // Verify that the Account's address fields were updated
        Account result = [
            SELECT UnitFragment__c,
            AddressNumberFragment__c,StreetFragment__c, StreetTypeFragment__c,StreetDirectionFragment__c, CityFragment__c,PostalCodeFragment__c,ProvinceFragment__c,
            Is_Address_Parsed__c
            FROM Account
            WHERE Id = :testAccount.Id
            LIMIT 1
        ];
    }
    
    @IsTest
    public static void getPersonAccountRecordTypeTest() {
        Test.StartTest();
        String recordTypeID = AccountService.getPersonAccountRecordTypeId();
        System.assertNotEquals(recordTypeID, null);
        Test.StopTest();
    }
    
    @IsTest
    public static void assignDialListNewTest() {
        Test.StartTest();
        Account acc = [Select Id, LastName From Account Where LastName = 'Bank' LIMIT 1];
        acc.LastName = 'Updated Bank';
        update acc;
        Test.StopTest();
    }
    
    @IsTest
    public static void test_copyMailingAddress_insert(){
        
        Account partnerAcc = TestFactory.createPartnerAccount(
            'Test West Toronto',
            'Bank',
            null,
            null,
            '316023456'
        );
        
        partnerAcc.PersonMailingCity = 'Toronto';
        partnerAcc.PersonMailingCountry = 'Canada';
        partnerAcc.PersonMailingPostalCode = 'M4M4C4';
        partnerAcc.PersonMailingState = 'ON';
        partnerAcc.PersonMailingStreet = 'Street1';
        
        Test.startTest();
        
        insert partnerAcc;
        
        Test.stopTest();
        
        List<Account> accs = [SELECT Id, 
                              PersonMailingCity,
                              PersonMailingCountry,
                              PersonMailingPostalCode,
                              PersonMailingState,
                              PersonMailingStreet,
                              BillingCity,
                              BillingCountry,
                              BillingPostalCode,
                              BillingState,
                              BillingStreet
                              FROM Account WHERE Id = :partnerAcc.Id];
        
        System.assert(!accs.isEmpty());
        System.assertEquals(accs[0].PersonMailingCity , accs[0].BillingCity );
        System.assertEquals(accs[0].PersonMailingCountry , accs[0].BillingCountry );
        System.assertEquals(accs[0].PersonMailingPostalCode , accs[0].BillingPostalCode );
        System.assertEquals(accs[0].PersonMailingState , accs[0].BillingState );
        System.assertEquals(accs[0].PersonMailingStreet , accs[0].BillingStreet );
    }
    
    @IsTest
    public static void test_copyMailingAddress_update_valid(){
        
        Account partnerAcc = TestFactory.createPartnerAccount(
            'Test West Toronto',
            'Bank',
            null,
            null,
            '316023456'
        );
        
        insert partnerAcc;
        
        Test.startTest();
        
        partnerAcc.PersonMailingCity = 'Toronto';
        partnerAcc.PersonMailingCountry = 'Canada';
        partnerAcc.PersonMailingPostalCode = 'M4M4C4';
        partnerAcc.PersonMailingState = 'ON';
        partnerAcc.PersonMailingStreet = 'Street1';
        
        update partnerAcc;
        
        Test.stopTest();
        
        List<Account> accs = [SELECT Id, 
                              PersonMailingCity,
                              PersonMailingCountry,
                              PersonMailingPostalCode,
                              PersonMailingState,
                              PersonMailingStreet,
                              BillingCity,
                              BillingCountry,
                              BillingPostalCode,
                              BillingState,
                              BillingStreet
                              FROM Account WHERE Id = :partnerAcc.Id];
        
        System.assert(!accs.isEmpty());
        System.assertEquals(accs[0].PersonMailingCity , accs[0].BillingCity );
        System.assertEquals(accs[0].PersonMailingCountry , accs[0].BillingCountry );
        System.assertEquals(accs[0].PersonMailingPostalCode , accs[0].BillingPostalCode );
        System.assertEquals(accs[0].PersonMailingState , accs[0].BillingState );
        System.assertEquals(accs[0].PersonMailingStreet , accs[0].BillingStreet );
    }
    
    @IsTest
    public static void test_copyMailingAddress_update_notvalid(){
        
        Account partnerAcc = TestFactory.createPartnerAccount(
            'Test West Toronto',
            'Bank',
            null,
            null,
            '316023456'
        );
        
        partnerAcc.PersonMailingCity = 'Toronto';
        partnerAcc.PersonMailingCountry = 'Canada';
        partnerAcc.PersonMailingPostalCode = 'M4M4C4';
        partnerAcc.PersonMailingState = 'ON';
        partnerAcc.PersonMailingStreet = 'Street1';
        insert partnerAcc;
        
        Test.startTest();
        
        partnerAcc.PersonMailingCity = 'Toronto';
        partnerAcc.PersonMailingCountry = 'Canada';
        partnerAcc.PersonMailingPostalCode = 'M4M4C4';
        partnerAcc.PersonMailingState = 'ON';
        partnerAcc.PersonMailingStreet = 'Street1 Changed';
        
        update partnerAcc;
        
        Test.stopTest();
        
        List<Account> accs = [SELECT Id, 
                              PersonMailingCity,
                              PersonMailingCountry,
                              PersonMailingPostalCode,
                              PersonMailingState,
                              PersonMailingStreet,
                              BillingCity,
                              BillingCountry,
                              BillingPostalCode,
                              BillingState,
                              BillingStreet
                              FROM Account WHERE Id = :partnerAcc.Id];
        
        System.assert(!accs.isEmpty());
        System.assertNotEquals(accs[0].PersonMailingStreet , accs[0].BillingStreet );
    }
}