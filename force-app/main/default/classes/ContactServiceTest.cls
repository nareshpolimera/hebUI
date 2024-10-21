@IsTest
private class ContactServiceTest
{
    
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
    }
    
    @IsTest
    static void testContact() {
        ContactService conService = new ContactService();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account a = TestFactory.createPartnerOrgAccount('Big Partner 1 Bank', 'M4M4C4', 'Toronto','5555555');
        insert a;
        
        Contact c  = TestFactory.createPartnerContact('John', 'Doe', 'jd@bp1.com', a, 'IndustriesBusiness', 'M4M4C4', 'Toronto' );
        insert c;
        
        c.Phone = '(316)456789';
        c.Email = 'jd.test@heb.ca';
        update c;
        
        Contact cCheck = [select Id,Phone_Verification_Timestamp__c,Phone,Name,FirstName,LastName from Contact where Id = :c.Id];
        
        List<Contact> contactList = new List<Contact>();
        contactList.add(cCheck);
        Map<Id,Contact> oldMap = new Map<Id,Contact>();
        oldMap.put(c.id, c);
        new ContactDomain.PartnerDomain().beforeInsert(contactList);
        new ContactDomain.PartnerDomain().beforeUpdate(contactList, oldMap);
        new ContactDomain.PartnerDomain().afterUpdate(contactList, oldMap);
    }
    @IsTest
    static void testsetAreaCode() {
        ContactService conService = new ContactService();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account a = TestFactory.createPartnerOrgAccount('Big Partner 1 Bank', 'M4M4C4', 'Toronto','5555555');
        insert a;
        
        Contact c  = TestFactory.createPartnerContact('John', 'Doe', 'jd@bp1.com', a, 'IndustriesBusiness', 'M4M4C4', 'Toronto' );
        insert c;
        
        c.Phone = '(316)45678932434242';
        c.Email = 'jd.test@heb.ca';
        update c;
        
        Contact cCheck = [select Id,Phone_Verification_Timestamp__c,Phone,Name,FirstName,LastName from Contact where Id = :c.Id];
        
        List<Contact> contactList = new List<Contact>();
        contactList.add(cCheck);
        Map<Id,Contact> oldMap = new Map<Id,Contact>();
        oldMap.put(c.id, c);
        new ContactDomain.PartnerDomain().beforeInsert(contactList);
        new ContactDomain.PartnerDomain().beforeUpdate(contactList, oldMap);
        new ContactDomain.PartnerDomain().afterUpdate(contactList, oldMap);
    }
    @isTest
    static void testGenerateListofChangedPhone() {
         Profile adminProfile = [SELECT Id, Name
                                FROM Profile
                                WHERE
                                Name ='Relationship Manager'
                               ];
        
          User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca.invalid',
            Email = 'testadmin@chip.ca.invalid',
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
            ContactService conService = new ContactService();
            Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
            Account testAccount = TestFactory.createPartnerOrgAccount('Big Partner 1 Bank', 'M4M4C4', 'Toronto','5555555');
            insert testAccount;
            System.runAs(sysAdmin) {
            Contact testContact1  = TestFactory.createPartnerContact('John', 'Doe', 'jd@bp1.com', testAccount, 'IndustriesBusiness', 'M4M4C4', 'Toronto' );
            
            Contact testContact2  = TestFactory.createPartnerContact('John', 'Doe', 'jd@bp1.com', testAccount, 'IndustriesBusiness', 'M4M4C4', 'Toronto' );
            
            insert new List<Contact>{ testContact1, testContact2 };
                
                // Create old map with initial values
                Map<Id, Contact> oldMap = new Map<Id, Contact>{
                    testContact1.Id => testContact1.clone(),
                        testContact2.Id => testContact2.clone()
                        };
                            
                            // Case 1: Update phone number for testContact1
                            testContact1.Phone = '(123)4567890';
            update testContact1;
            
            // Case 2: Update other fields for testContact2 (no phone change)
            testContact2.Email = 'js.updated@bp1.com';
            update testContact2;
            
            // Call the method for testContact1 and testContact2 via the instance
            Test.startTest();
            conService.generateListofChangedPhone(new List<Contact>{ testContact1 }, oldMap);
            conService.generateListofChangedPhone(new List<Contact>{ testContact2 }, oldMap);
            Test.stopTest();
            
            testContact1 = [SELECT Id, Phone_Verification_Status__c, Phone_Verification_Line_Type__c, SMS_Address__c FROM Contact WHERE Id = :testContact1.Id];
            System.assertEquals(null, testContact1.Phone_Verification_Status__c);
        }
        
    }
    @isTest
    static void testGenerateListofChangedPhoneNegative() {
        ContactService conService = new ContactService();
        Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
                 Profile adminProfile = [SELECT Id, Name
                                FROM Profile
                                WHERE
                                Name ='Relationship Manager'
                               ];
        
          User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca.invalid',
            Email = 'testadmin@chip.ca.invalid',
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
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
          System.runAs(sysAdmin) {
        // Create test contacts
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'jd@bp1.com',
            AccountId = testAccount.Id,
            Phone = null,
            Phone_Verification_Status__c = 'Pending',
            Phone_Verification_Line_Type__c = 'Unknown',
            Phone_Verification_Timestamp__c = null,
            SMS_Address__c = null
        );
        Contact testContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'js@bp1.com',
            AccountId = testAccount.Id,
            Phone = null,
            Phone_Verification_Status__c = 'Pending',
            Phone_Verification_Line_Type__c = 'Unknown',
            Phone_Verification_Timestamp__c = null,
            SMS_Address__c = null
        );
        insert new List<Contact>{ testContact1, testContact2 };
            
            // Create old map with initial values
            Map<Id, Contact> oldMap = new Map<Id, Contact>{
                testContact1.Id => testContact1.clone(),
                    testContact2.Id => testContact2.clone()
                    };
                        
                        // Case 1: Update phone number for testContact1
                        testContact1.Phone = null;
        update testContact1;
        
        // Case 2: Update other fields for testContact2 (no phone change)
        testContact2.Email = 'js.updated@bp1.com';
        update testContact2;
        
        // Call the method for testContact1 and testContact2 via the instance
        Test.startTest();
        conService.generateListofChangedPhone(new List<Contact>{ testContact1 }, oldMap);
        conService.generateListofChangedPhone(new List<Contact>{ testContact2 }, oldMap);
        Test.stopTest();
        
        testContact1 = [SELECT Id, Phone_Verification_Status__c, Phone_Verification_Line_Type__c, SMS_Address__c FROM Contact WHERE Id = :testContact1.Id];
        System.assertEquals('Pending', testContact1.Phone_Verification_Status__c);
          }
    }
    
    @isTest
    static void testUpdateUnvalidatedNewPhoneNumberStatus() {
        Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
               Profile adminProfile = [SELECT Id, Name
                                FROM Profile
                                WHERE
                                Name ='Relationship Manager'
                               ];
        
          User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca.invalid',
            Email = 'testadmin@chip.ca.invalid',
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
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        System.runAs(sysAdmin) {
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'jd@bp1.com',
            AccountId = testAccount.Id,
            Phone = '(316)456780',
            Phone_Verification_Status__c = null, 
            Phone_Verification_Line_Type__c = 'Unknown',
            Phone_Verification_Timestamp__c = null,
            SMS_Address__c = null
        );
        insert testContact1;
        
        ContactService conService = new ContactService();
        
        Test.startTest();
        conService.updateUnvalidatedNewPhoneNumberStatus(new List<Contact>{ testContact1 });
        Test.stopTest();
        
        testContact1 = [SELECT Id, Phone_Verification_Status__c FROM Contact WHERE Id = :testContact1.Id];
        System.assertEquals(null, testContact1.Phone_Verification_Status__c);
    }
    }
    @isTest
    static void testCheckCASLConsentUser_NoBypass() {
        Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
                     Profile adminProfile = [SELECT Id, Name
                                FROM Profile
                                WHERE
                                Name ='Relationship Manager'
                               ];
        
          User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca.invalid',
            Email = 'testadmin@chip.ca.invalid',
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
         System.runAs(sysAdmin) {
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'test@example.com',
            CASL_Consent_Obtained_By__c = UserInfo.getUserId() // Active CASL user
        );
        insert testContact;
        
        ContactService contactService = new ContactService();
        
        Test.startTest();
        contactService.checkCASLConsentUser(new List<Contact>{ testContact }, null);
        Test.stopTest();
         }
    }
    @isTest
    static void testSyncConsentToMarsPlatformEvent() {
        ContactService conService = new ContactService();
        Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'jd@bp1.com',
            AccountId = testAccount.Id,
            Phone = '(316)456780',
            Phone_Verification_Status__c = 'Pending',
            Phone_Verification_Line_Type__c = 'Unknown',
            Phone_Verification_Timestamp__c = null,
            SMS_Address__c = null
        );
        Contact testContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'js@bp1.com',
            AccountId = testAccount.Id,
            Phone = null,
            Phone_Verification_Status__c = 'Pending',
            Phone_Verification_Line_Type__c = 'Unknown',
            Phone_Verification_Timestamp__c = null,
            SMS_Address__c = null
        );
        insert new List<Contact>{ testContact1, testContact2 };
            
            Map<Id, Contact> oldMap = new Map<Id, Contact>{
                testContact1.Id => testContact1.clone(),
                    testContact2.Id => testContact2.clone()
                    };
                        
                        testContact1.FirstName = 'Test Updated';
        update testContact1;
        
        testContact2.FirstName = 'Test Updated';
        update testContact2;
        
        Test.startTest();
        conService.syncConsentToMarsPlatformEvent(new List<Contact>{ testContact1 }, oldMap);
        conService.syncConsentToMarsPlatformEvent(new List<Contact>{ testContact2 }, oldMap);
        Test.stopTest();      
    } 
    
}