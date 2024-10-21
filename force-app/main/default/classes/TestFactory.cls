/*
* TestFactory Class
*    - used to initialize loosely coupled business records to be leveraged in the org,
*    to minimalize the amount of test data creation directly in a test method.
*    - helper methods in place to initialize common records (e.g. Leads) to ensure required fields (for database and use cases for tests) are set (and can be managed in a minimal number of places)
*/
@IsTest
public without sharing class TestFactory {
    /*
* create test data to leverage for test methods
* - call from @testSetup method in test class to initialize setup and business data to be leveraged in test methods
*/
    @IsTest
    public static void initTestData() {
        
        
        List<Profile> profileList = [
            SELECT Id, Name
            FROM Profile
            WHERE
            Name IN (
                :Label.ConsumerSales_Profile_Name,
                :Label.Call_Centre_Profile_Name,
                :Label.BDM_Profile_Name,
                :Label.SystemAdmin_Profile_Name,
                :Label.HEBStandard_Profile_Name,
                :Label.Integration_Profile_Name,
                'Relationship Manager'
            )
        ];
        Profile adminProfile;
        Profile standardUserProfile;
        Profile relManagerProfile;

        OpportunityService.inhibitQuoteCallout = true;
        
        for (Profile p : profileList) {
            if (p.Name == Label.SystemAdmin_Profile_Name)
                adminProfile = p;
            if (p.Name == Label.HEBStandard_Profile_Name)
                standardUserProfile = p;  
            if (p.Name == 'Relationship Manager')
                relManagerProfile = p;  
        }
        
        User relUser = new User(
            ProfileId = relManagerProfile.Id,
            Username = 'rel@chip.ca',
            Email = 'rel@chip.ca',
            FirstName = 'rel',
            LastName = 'user',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'relUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );

        User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca',
            Email = 'testadmin@chip.ca',
            FirstName = 'admin',
            LastName = 'IT',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User sysAdmin2 = new User(
            ProfileId = adminProfile.Id,
            Username = 'anotherAdmin@chip.ca',
            Email = 'anotherAdmin@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin2',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
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
        User marsIntUser = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'marsUser@chip.ca',
            Email = 'testint@chip.ca',
            FirstName = 'Integration',
            LastName = 'IT',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'intUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        // TODO: assign the correct profile and role once finalized.
        User specialist = new User(
            ProfileId = adminProfile.Id,
            Username = 'specialist@chip.ca',
            Email = 'specialist@chip.ca',
            FirstName = 'User',
            LastName = 'Specialist',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User specialist2 = new User(
            ProfileId = adminProfile.Id,
            Username = 'specialist2@chip.ca',
            Email = 'specialist2@chip.ca',
            FirstName = 'User2',
            LastName = 'Specialist2',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User specialist3 = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'specialist3@chip.ca',
            Email = 'specialist3@chip.ca',
            FirstName = 'User3',
            LastName = 'Specialist3',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User socuser1 = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'socuser1@chip.ca',
            Email = 'socuser1@chip.ca',
            FirstName = 'SCOUser1',
            LastName = 'SalesExpert',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'SOC321',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            External_ID__c = '8123'
            //Sales_Ops_Coordinator__c = true
        );
        User socuser2 = new User(
            ProfileId = standardUserProfile.Id,
            Username = 'socuser2@chip.ca',
            Email = 'socuser2@chip.ca',
            FirstName = 'SCOUser2',
            LastName = 'SalesExpert2',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'SOC123',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            External_ID__c = '8124'
            //Sales_Ops_Coordinator__c = true
        );
        insert new List<User>{
            specialist,
                specialist2,
                specialist3,
                socuser1,
                socuser2,
                sysAdmin,
                sysAdmin2,
                marsIntUser,
                standardUser, 
				relUser
                };
                    
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        // Now that the setup data is done, create the business data
        System.runAs(new User(Id = UserInfo.getUserId())){
            
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            
            // Partner Referral accounts
            Account partnerAcc = createPartnerAccount(
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
            
            Account orgAccount = createPartnerOrgAccount( 'TestAccount',
                                                         '32244',
                                                         'Quebec',
                                                         '41643210987');
            
            //Test class fix 7-Aug  
            Account partnerAccount = createPartnerAccount(
                'West Toronto',
                'Bank',
                'M4M4C4',
                'Toronto',
                '316023456'
            );
            Account clientAcc = createClientAccount(
                'Client FName',
                'Client LName',
                'M4M4C1',
                'Toronto',
                '316023426'
            );
            Account clientAcc2 = createClientAccount(
                'Client FName2',
                'Client LName2',
                'M4M4C1',
                'Toronto',
                '316023426'
            );
            Account clientAcc3 = createClientAccount(
                'Client FName3',
                'Client LName3',
                'M4M4C1',
                'Toronto',
                '316023426'
            );
            Account clientAcc4 = createClientAccount(
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
                
                Contact c1 = createConsumerContact('Test1', 'Drive', 'testdrive1@chip.ca',orgAccount.Id);
            Contact c2 = createConsumerContact('Test2', 'Drive', 'testdrive2@chip.ca',orgAccount.Id);
            Contact c3 = createConsumerContact('Test3', 'Drive', 'testdrive3@chip.ca',orgAccount.Id);
            insert new List<Contact>{ c1,c2,c3};
                
                
                // create some Lead records to use in test methods, associated with the Properties above
                Lead l1 = createConsumerLead('Test', 'Drive', 'testdrive@chip.ca');
            Lead l2 = createConsumerLead('Test','Drive2','testdrive2@chip.ca');
            Lead l3 = createConsumerLead('Test','Quoteable','testquotable@chip.ca');
            Lead l4 = createConsumerLead('Test','QuoteableLead','testquotablelead@chip.ca');
            insert new List<Lead>{ l1, l2, l3, l4 };
                
                // create some Opportunity records to use in test methods, associated with the Properties above
                Opportunity op1 = createConsumerOpportunity('Test Drive');
            Opportunity op2 = createConsumerOpportunity('Test Drive2');
            Opportunity op3 = createConsumerOpportunity('Test Quoteable');
            Opportunity op4 = createConsumerOpportunity('Test Application');
            op4.AccountId = orgAccount.Id;
            insert new List<Opportunity>{ op1, op2, op3 ,op4};
                
                ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test', AccountId = partnerAcc.Id);
            ResidentialLoanApplication application2 = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op4.id);
            insert new list<ResidentialLoanApplication> {application,application2};
                
                //Test class fix 7-Aug
                Account partAccDetails = [SELECT Id, PersonContactId FROM Account WHERE Id =: partnerAccount.Id];
            OpportunityContactRole ocr = new opportunityContactRole(OpportunityId = op4.id, ContactId = partAccDetails.PersonContactId, IsPrimary = true );
            insert ocr;
            
            LoanApplicationProperty prop1 = createProperty(
                application.Id,
                'test1',
                '123 Test Drive',
                'Toronto',
                'ON',
                'M4M4M4'
            );
            LoanApplicationProperty prop2 = createProperty(
                application.Id,
                'test2',
                '456 Fake Boulevard',
                'Toronto',
                'ON',
                'M4M5M5'
            );
            LoanApplicationProperty prop3 = createProperty(
                application.Id,
                'test3',
                '101 Main Road',
                'Toronto',
                'ON',
                'M4M6M6'
            );
            LoanApplicationProperty prop4 = createProperty(
                application.Id,
                'test4',
                '102 Main Road',
                'Toronto',
                'ON',
                'M4M6M6'
            );
            LoanApplicationProperty prop5 = createProperty(
                application2.Id,
                'test4',
                '102 Main Road',
                'Toronto',
                'ON',
                'M4M6M6'
            );
            
            // create some Property records to use in test methods for Opportunities
            
            insert new List<LoanApplicationProperty>{
                prop1,
                    prop2,
                    prop3,
                    prop4,
                    prop5
                    };
                        
                        LoanApplicant applicant1 = createPropertyMember(
                            c1.Id,
                            application2.Id,
                            LoanApplicantService.BORROWER_ROLE
                        );
            LoanApplicant applicant2 = createPropertyMember(
                c2.Id,
                application2.Id,
                LoanApplicantService.COBORROWER_ROLE
            );
            LoanApplicant applicant3 = createPropertyMember(
                c3.Id,
                application2.Id,
                LoanApplicantService.COBORROWER_ROLE
            );
            insert new list<LoanApplicant> {applicant1,applicant2,applicant3};
                
                Credit_Report__c cr = new Credit_Report__c(
                    Credit_Score__c = 999,
                    Credit_Summary__c = 'Test',
                    Loan_Applicant__c = applicant2.Id,
                    Assessment_Eligible__c = true,
                    Credit_hit__c = true
                );
            insert cr;
            
            // Debt__c debt1 = createDebtFromLead(l1);
            // Debt__c debt2 = createDebtFromLead(l2);
            
            // insert new List<Debt__c>{ debt1, debt2 };
            
            Quote quote1 = createEligibleQuoteFromLead(l1);
            Quote quote2 = createEligibleQuoteFromLead(l2);
            
            insert new List<Quote>{ quote1, quote2 };    
                
                // Add Campaign and Campaign Members so Leads can be converted in tests (HEB-248)
                Campaign camp = new Campaign(
                    Name = 'TestFactory',
                    Phone_Label__c = 'TestFactory',
                    Phone_Number__c = '41655555555',
                    IsActive = true,
                    CSID__c = 'TestFactory1234'
                );
            insert camp;
            
            CampaignMember cm1 = new CampaignMember(
                CampaignId = camp.Id,
                LeadId = l1.Id
            );
            CampaignMember cm2 = new CampaignMember(
                CampaignId = camp.Id,
                LeadId = l2.Id
            );
            insert new List<CampaignMember>{ cm1, cm2 };
                
                Appraisal__c apr1 = createAppraisalFromFile(op1);
            Appraisal__c apr2 = createAppraisalFromProperty(prop1,op1);
            Appraisal__c apr3 = createAppraisalFromProperty(prop5,op4);
            
            insert new List<Appraisal__c>{ apr1, apr2, apr3 };
                
                Appraisal_Order__c ao1 = createAppraisalOrderFromAppraisal(apr1);
            Appraisal_Order__c ao2 = createAppraisalOrderFromAppraisal(apr2);
            Appraisal_Order__c ao3 = createAppraisalOrderFromAppraisal(apr3);
            
            insert new List<Appraisal_Order__c>{ ao1, ao2, ao3 };
                
                Marketing_Association__c m1 = new Marketing_Association__c(
                    Name = 'CARP',
                    Consent_Script_French__c = 'french consent',
                    Consent_Script_English__c = 'english consent',
                    Is_Active__c = true
                );
            Marketing_Association__c m2 = new Marketing_Association__c(
                Name = 'Legion',
                Consent_Script_French__c = 'french consent',
                Consent_Script_English__c = 'english consent',
                Is_Active__c = true
            );
            insert new List<Marketing_Association__c>{ m1, m2 };
                
                Membership__c mem1 = new Membership__c(
                    Membership_Number__c = '123456',
                    Opportunity__c = op3.Id,
                    Marketing_Association__c = m1.Id,
                    Consent_received_on__c = system.TODAY()
                );
            insert mem1;
            
            /*Specialist__c spl = new Specialist__c(User__c = specialist.Id);
Specialist__c spl2 = new Specialist__c(User__c = specialist2.Id);
insert new List<Specialist__c>{ spl, spl2 };*/
            
            Account consumerAcc = createConsumerAccount('Test', 'Consumer');
            insert consumerAcc;
            
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
        }
        
        FinServ__ReciprocalRole__c roleInsert = createReciprocalRole('Referral Agreement Holdee', 'Referral Agreement Holdee');
        insert roleInsert;
        
        createSpecialist(UserInfo.getUserId());
    }
    
    public static Specialist__c createSpecialist(Id userId){
        return new Specialist__c(User__c = userId);
    }
    
    public static FinServ__ReciprocalRole__c createReciprocalRole (
        String roleName,
        String inverseRoleName
    ) {
        return new FinServ__ReciprocalRole__c(Name = roleName,
                                              FinServ__InverseRole__c = inverseRoleName);
    }
    
    public static LoanApplicant createPropertyMember(
        Id contactId,
        Id appId,
        String role
    ) {
        Account acc = createClientAccount('Client FName',
                'Client LName',
                'M4M4C1',
                'Toronto',
                '316023426');
        LoanApplicant loanApp = new LoanApplicant();
        loanApp.name = 'Test';
        loanApp.contactId = contactId;
        loanApp.Client__c = acc.Id;
        loanApp.LoanApplicationId = appId;
        if(role == LoanApplicantService.BORROWER_ROLE){
            loanApp.role__c = role;
            loanApp.Is_Primary_Borrower__c = true;
        }else if(role == LoanApplicantService.COBORROWER_ROLE){
            loanApp.role__c = LoanApplicantService.BORROWER_ROLE;
            loanApp.Is_Primary_Borrower__c = false;
        }else{
            loanApp.role__c = role;
        }
        return loanApp;
        
    }
    
    public static Contact createConsumerContact(
        String fName,
        String lName,
        String email,
        Id accountId 
    ) {
        Map<String, Id> cRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Contact.SObjectType
        );
        return new Contact(
            FirstName = fName,
            LastName = lName,
            Email = email,
            AccountID = accountid,
            Phone = '5555555555'
        );
    }
    
    /*
Initialize a Consumer Lead with required fields to save and meet basic validation needs
- use the Property__c record id for the File_Number__c value, since it will be unique and keeps test data setup simple
- HEB-633 - setting the MARS_Validation_Run__c flag on insert to bypass the heavy MARS validation by default
*/
    public static Lead createConsumerLead(
        String fName,
        String lName,
        String email
    ) {
        Map<String, Id> leadRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Lead.SObjectType
        );
        return new Lead(
            RecordTypeId = leadRecordTypes.get('Consumer_Prospect'),
            //Home_Value__c = 1000000,
            FirstName = fName,
            LastName = lName,
            Email = email,
            //Property__c = p.Id,
            //File_Number__c = p.Id,
            //Product_Type__c = 'CHIP',
            //Channel__c = 'Consumer',
            Phone = '5555555555'
            //CASL_Consent__c = Label.CASL_Implied,
            //CASL_Consent_Provided_On__c = System.Today().addDays(-1 * 180),
            //CASL_Content_Obtained_By__c = UserInfo.getUserId(),
            //MARS_Validation_Run__c = true
        );
    }
    
    /*
Initialize a Consumer Lead with required fields to save and meet basic validation needs
- use the Property__c record id for the File_Number__c value, since it will be unique and keeps test data setup simple
*/
    public static Lead createReferralLead(
        String fName,
        String lName,
        String email,
        Contact c
    ) {
        Map<String, Id> leadRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Lead.SObjectType
        );
        return new Lead(
            RecordTypeId = leadRecordTypes.get('Referred_Lead'),
            //Home_Value__c = 1000000,
            FirstName = fName,
            LastName = lName,
            Email = email
            //Property__c = p.Id,
            //File_Number__c = p.Id,
            //Product_Type__c = 'CHIP',
            //Partner_Referrer__c = c.Id,
            //CASL_Consent__c = Label.CASL_Implied,
            //CASL_Consent_Provided_On__c = System.Today().addDays(-1 * 180),
            //CASL_Content_Obtained_By__c = UserInfo.getUserId(),
            //MARS_Validation_Run__c = true
        );
    }
    
    /*
Initialize a Partner Contact record to be used in test methods.
*/
    public static Contact createPartnerContact(
        String fName,
        String lName,
        String email,
        Account acc,
        String partnerType,
        String postalCode,
        String city
    ) {
        Map<String, Id> contactRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Contact.SObjectType
        );
        return new Contact(
            RecordTypeId = contactRecordTypes.get(partnerType),
            AccountId = acc.Id,
            FirstName = fName,
            LastName = lname,
            Email = email,
            MailingPostalCode = postalCode,
            MailingCity = city
        );
    }
    
    /*
Initialize a Person Account to be used in test methods.
*/
    public static Account createConsumerAccount(
        String firstName,
        String lastName
    ) {
        Map<String, Id> accountRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Account.SObjectType
        );
        return new Account(
            // RecordTypeId = accountRecordTypes.get('StandardAccount'),
            FirstName = firstName,
            LastName = lastName,
            CASL_Consent__c = Label.CASL_Implied,
            CASL_Consent_Provided_On__c = System.Today().addDays(-1 * 180)
            //CASL_Content_Obtained_By__c = UserInfo.getUserId()
        );
    }  
    
    /*
Initialize an Eligible Quote record to be used in test methods;
Make it eligible so that Lead records can be converted in test methods (HEB-248)
*/
    public static Quote createEligibleQuoteFromLead(Lead l) {
        return new Quote(
            Name = 'Test',
            Quote_Amount__c = 100000,
            Is_Eligible__c = true,
            Product_Type__c = 'CHIP'
        );
    }
    
    /*
Initialize a Quote record to be used in test methods;
*/
    public static Quote createEligibleQuoteFromOpportunity(Opportunity o) {
        return new Quote(
            Name = 'Test',
            Quote_Amount__c = 100000,
            OpportunityId = o.Id,
            Is_Eligible__c = true,
            Product_Type__c = 'CHIP'
        );
    }
    
    /*
Initialize a Consumer Opportunity with required fields to save and meet basic validation needs
- use the Property__c record id for the File_Number__c value, since it will be unique and keeps test data setup simple
*/
    public static Opportunity createConsumerOpportunity(
        String fName
    ) {
        Map<String, Id> opptyRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Opportunity.SObjectType
        );
        return new Opportunity(
            RecordTypeId = opptyRecordTypes.get('Refinance'),
            Name = fname,
            //Property__c = p.Id,
            //File_Number__c = p.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = system.today()
            //Home_Value__c = 1000000
        );
    }
    
    /*
Initialize a Referred Opportunity with required fields to save and meet basic validation needs
- use the Property__c record id for the File_Number__c value, since it will be unique and keeps test data setup simple
*/
    public static Opportunity createReferredOpportunity(
        String fName
    ) {
        Map<String, Id> opptyRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Opportunity.SObjectType
        );
        return new Opportunity(
            RecordTypeId = opptyRecordTypes.get('Referred'),
            Name = fname,
            //Property__c = p.Id,
            //File_Number__c = p.Id,
            //StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = system.today()
            //Home_Value__c = 1000000
        );
    }
    
    /*
Initialize a Partner Account to be used in test methods.
*/
    public static Account createPartnerOrgAccount(
        String accName,
        String postalCode,
        String city,
        String phone
    ) {
        
        Id businessRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        return new Account(
            RecordTypeId = businessRecordTypeId,        
            Name = accName,        
            BillingPostalCode = postalCode,
            BillingCity = city,
            Phone = phone
        );
    }
    
    /*
Initialize a Partner Account to be used in test methods.
*/
    public static Account createPartnerAccount(
        String accFirstName,
        String accLastName,        
        String postalCode,
        String city,
        String phone
    ) {
        
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        return new Account(
            RecordTypeId = personAccountRecordTypeId,        
            FirstName = accFirstName,        
            LastName = accLastName,
            BillingPostalCode = postalCode,
            BillingCity = city,
            Phone = phone
        );
    }
    
    public static Account createClientAccount(
        String accFirstName,
        String accLastName,        
        String postalCode,
        String city,
        String phone
    ) {
        
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        return new Account(
            RecordTypeId = personAccountRecordTypeId,        
            FirstName = accFirstName,        
            LastName = accLastName,
            BillingPostalCode = postalCode,
            BillingCity = city,
            Phone = phone
        );
    }
    
    public static Appraisal__c createAppraisalFromFile(Opportunity oppfile) {
        return new Appraisal__c(File__c = oppfile.Id);
    }
    
    public static Appraisal_Order__c createAppraisalOrderFromAppraisal(Appraisal__c a) {
        return new Appraisal_Order__c(Appraisal__c = a.Id);
    }
    
    public static Appraisal__c createAppraisalFromProperty(LoanApplicationProperty pro, Opportunity opp) {
        return new Appraisal__c(Application_Property__c = pro.Id,Application__c=pro.LoanApplicationId,Active__c=true, File__c = opp.Id);
    }
    
    /*
Initialize a Property record to be used in test methods.
*/
    public static LoanApplicationProperty createProperty(
        String applicationId,
        String name,
        String street,
        String city,
        String province,
        String postalCode
    ) {
        return new LoanApplicationProperty(
            LoanApplicationId = applicationId, 
            Name = name,
            PropertyCity= city,
            PropertyPostalcode= postalCode,
            Property_Type__c = 'Single Family Dwelling',
            PropertyStateCode = province,
            PropertyStreet = street
        );
    }
    
    /*
Initialize a Complaint Case.
*/
    public static Case createComplaintCase(id complainant, string details) {
        Map<String, Id> leadRecordTypes = Utils.getRecordTypeIdsBySObjectType(
            Lead.SObjectType
        );
        return new Case(
            Status = 'Ongoing',
            Origin = 'Email',
            Subject = details,
            Complainant_Type__c = 'Personal (made directly by complainant)',
            // DG 6/10/24 Complainant__c = complainant,
            Complaint_Category__c = 'Interest Rate',
            Complaint_Subcategory__c = 'Interest rate change letter',
            Complaint_Date_Received__c = system.today(),
            Incident_Date__c = system.today(),
            Language__c = 'English',
            Detail_of_Complaint__c = 'Test by Tester - Complaint Case'
        );
    }
    /*
Initialize a Complainant.
*/
    public static Account createComplainant(
        String fName,
        String lName,
        String email,
        String phone
    ) {
        return new Account(
            FirstName = fName,
            LastName = lName,
            PersonEmail = email,
            Phone = phone
        );
    }
    Public static ResidentialLoanApplication createLoanApplicationAndRelatedObjects(Account partnerAcc){
        Opportunity opp1 = createConsumerOpportunity('Test AVM');
        opp1.File_Number__c='123456';
        opp1.AccountId=partnerAcc.Id;
        insert opp1;
        
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'TestApp',OpportunityId=opp1.Id, AccountId = partnerAcc.Id);
        insert application;
        LoanApplicationProperty pro1 = createProperty(
            application.Id,
            'testAVM',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        insert pro1;
        Appraisal__c apr = createAppraisalFromProperty(pro1,opp1);
        insert apr;
        LoanApplicant lApcnt=new LoanApplicant(Name='test',LoanApplicationId=application.Id,role__c=LoanApplicantService.BORROWER_ROLE, Is_Primary_Borrower__c = true);
        insert lApcnt;
        return application;
    }
    
    public static LoanApplicant createLoanApplicant(String fName,
                                                    String lName,
                                                    String email,
                                                    ResidentialLoanApplication rla,
                                                    String role)   
    {
        LoanApplicant loanApp = new LoanApplicant();
        loanApp.name = fName;
        loanApp.LoanApplicationId=rla.Id;
        if(role == LoanApplicantService.BORROWER_ROLE){
            loanApp.role__c = role;
            loanApp.Is_Primary_Borrower__c = true;
        }else if(role == LoanApplicantService.COBORROWER_ROLE){
            loanApp.role__c = LoanApplicantService.BORROWER_ROLE;
            loanApp.Is_Primary_Borrower__c = false;
        }else{
            loanApp.role__c = role;
        }
        return loanApp;
    }
    
    public static ResidentialLoanApplication createResidentialLoanApplication(String name){
        return new ResidentialLoanApplication(Name=name);
    }
    
    @isTest
    public static void testData(){
        // Create test data for Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create test data for Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            AccountId = acc.Id,
            File_Number__c = '12345',
            Product_Rate_Set__c = null,
            Product_Quote_Set__c = null
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
            Role__c =  LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = true
        );
        insert loanApp1;
        
        Contact contact2 = new Contact(FirstName = 'Jane', LastName = 'Doe', Birthdate = Date.newInstance(1982, 2, 2), Age__c = 38, Gender__c = 'Female', AccountId = acc.Id);
        insert contact2;
        
        LoanApplicant loanApp2 = new LoanApplicant(
            Name = 'Test Applicant 2',
            LoanApplicationId = rla.Id,
            ContactId = contact2.Id,
            role__c = LoanApplicantService.BORROWER_ROLE,
            Is_Primary_Borrower__c = false
        );
        insert loanApp2;
        
        // Create test data for LoanApplicationLiability
        // added Balance_Amount__c, Type__c, Amount__c required fields @pranshul
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
        
    }
    @isTest
    public static void fileTestData(){
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            AccountId = acc.Id
        );
        insert opp;
        
        Document_Classification__c docClass = new Document_Classification__c(
            Document_Type__c = 'Test Document Type',
            External_ID__c = 12345, 
            Expired__c = false
        );
        insert docClass;
        
        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'Test ResidentialLA',
            OpportunityId = opp.Id
        );
        insert rla;
        
        LoanApplicant loanApp = new LoanApplicant(
            Name = 'Test Applicant',
            LoanApplicationId = rla.Id,
            role__c = LoanApplicantService.BORROWER_ROLE
        );
        insert loanApp;
        
        //added required fileds Balance_Amount__c, Type__c, Amount__c
        LoanApplicationLiability loanLiability = new LoanApplicationLiability(
            Name = 'Test Liability',
            LoanApplicationId = rla.Id,
            Balance_Amount__c = 1000.00,
            Type__c = '	Personal Loan',
            Amount__c = 10000.00
        );
        insert loanLiability;
        
        Appraisal__c appraisal = new Appraisal__c(
            File__c = opp.Id,
            Active__c = true
        );
        insert appraisal;
        
        LoanApplicationProperty loanProperty = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = rla.Id
        );
        insert loanProperty;
        
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert lead;
        
    }
    
    public static void activateCustomPermission(Id userId, String permissionName) {
        PermissionSet ps = new PermissionSet(
            Name = 'CustomPermissionEnabled',
            Label = 'Custom Permisison Enabled'
        );
        insert ps;
        
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = [
                SELECT Id
                FROM CustomPermission
                WHERE DeveloperName = :permissionName
                LIMIT 1
            ].Id
        );
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = ps.Id
        );
        
        insert new List<SObject>{ sea, psa };
            }
}