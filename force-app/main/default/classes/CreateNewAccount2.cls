public with sharing class CreateNewAccount2 {
    @AuraEnabled
    public static string submitRecords(String wrapperString) {
        try {
            system.debug('SBT 0.0:');
            CreateAccountWrapper wrapperDetails = (CreateAccountWrapper) JSON.deserialize(wrapperString, CreateAccountWrapper.class);
            Account personAcc = new Account();
            system.debug('SBT 0: ' + wrapperDetails);
            if (wrapperDetails != null) {

                // Individual //
                Individual individualRecord = new Individual();
                individualRecord.Salutation = wrapperDetails.primaryAccount.salutation;
                individualRecord.FirstName = wrapperDetails.primaryAccount.firstName;
                individualRecord.LastName = wrapperDetails.primaryAccount.lastName;
                individualRecord.BirthDate = null;
                individualRecord.IndividualsAge = '16 or Older';
                if(wrapperDetails.consent.CASLConsentObtainedBy != '' && wrapperDetails.consent.CASLConsentObtainedBy != null) {
                    individualRecord.OwnerId = wrapperDetails.consent.CASLConsentObtainedBy;
                }
                
                
                system.debug('SBT 1: Before insert individualRecord');
                insert individualRecord;
                system.debug('SBT 2: After insert individualRecord');

                // ContactPointTypeConsent //
                ContactPointTypeConsent contactPointTypeConsentRecord = new ContactPointTypeConsent();
                contactPointTypeConsentRecord.Name = null;
                contactPointTypeConsentRecord.PartyId = individualRecord.Id;
                contactPointTypeConsentRecord.ContactPointType = 'Email';
                contactPointTypeConsentRecord.PrivacyConsentStatus = 'OptIn';
                contactPointTypeConsentRecord.CaptureDate = System.today();
                contactPointTypeConsentRecord.EffectiveFrom = null;
                contactPointTypeConsentRecord.CaptureContactPointType = 'Phone';

                system.debug('SBT 3: Before insert contactPointTypeConsentRecord');
                insert contactPointTypeConsentRecord;
                system.debug('SBT 4: After insert contactPointTypeConsentRecord');

                // Person Account //
                personAcc.Salutation = wrapperDetails.primaryAccount.salutation;
                personAcc.Firstname = wrapperDetails.primaryAccount.firstName;
                personAcc.LastName = wrapperDetails.primaryAccount.lastName;
                personAcc.Phone = wrapperDetails.primaryAccount.phone;
                personAcc.PersonEmail = wrapperDetails.primaryAccount.email;
                personAcc.Language__pc = wrapperDetails.fileDetails.Language;
                personAcc.PersonMailingStreet = wrapperDetails.primaryAccount.isMailingAddressSameAsProperty ? wrapperDetails.property.Street : wrapperDetails.primaryAccount.primaryStreet;
                personAcc.PersonMailingCity = wrapperDetails.primaryAccount.isMailingAddressSameAsProperty ? wrapperDetails.property.City : wrapperDetails.primaryAccount.primaryCity;
                personAcc.PersonMailingState = wrapperDetails.primaryAccount.isMailingAddressSameAsProperty ? wrapperDetails.property.State : wrapperDetails.primaryAccount.primaryProvince;
                personAcc.PersonMailingPostalCode = wrapperDetails.primaryAccount.isMailingAddressSameAsProperty ? wrapperDetails.property.Zip : wrapperDetails.primaryAccount.primaryPostalCode;
                Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                personAcc.recordTypeId = personAccountRecordTypeId;
                personAcc.PersonIndividualId = individualRecord.Id;

                if (personAcc.LastName != null && personAcc.LastName != '') {
                    system.debug('SBT 5: Before insert personAcc');
                    insert personAcc;
                    system.debug('SBT 6: After insert personAcc');
                }

                Contact personContact;
                if (personAcc.LastName != null && personAcc.LastName != '') {
                    personContact = [SELECT Id, AccountId FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];
                }

                if (personAcc != null) {

                    // Opportunity/File // 
                    Opportunity oppRecord = new Opportunity();
                    oppRecord.LeadSource = wrapperDetails.fileDetails.Source;
                    oppRecord.File_Type__c = wrapperDetails.fileDetails.Type;
                    oppRecord.Channel__c = wrapperDetails.fileDetails.Channel;
                    oppRecord.Language__c = wrapperDetails.fileDetails.Language;
                    oppRecord.Name = wrapperDetails.primaryAccount.firstName + ' ' + wrapperDetails.primaryAccount.lastName;
                    oppRecord.stageName = 'New';
                    oppRecord.MARS_Validation_Run__c = true;
                    oppRecord.CloseDate = System.today() + 60;
                    oppRecord.AccountId = personAcc.Id;

                    system.debug('SBT 7: Before insert oppRecord');
                    insert oppRecord;
                    system.debug('SBT 8: After insert oppRecord');

                    if (oppRecord != null) {

                        // ResidentialLoanApplication //
                        ResidentialLoanApplication resLoanRecord = new ResidentialLoanApplication();
                        resLoanRecord.OpportunityId = oppRecord.Id;
                        resLoanRecord.Name = null;
                        String lpString = '';
                       /* if (wrapperDetails.LoanPurpose != null && wrapperDetails.LoanPurpose.length() > 0) {
                            for (Object o : wrapperDetails.LoanPurpose.split(';')) {
                                lpString += (String) o + ';';
                            }
                        } */
                        resLoanRecord.Loan_purpose__c = lpString;
                        resLoanRecord.Status = 'New';

                        system.debug('SBT 9: Before insert resLoanRecord');
                        insert resLoanRecord;
                        system.debug('SBT 10: After insert resLoanRecord');

                        if (resLoanRecord != null) {

                            // LoanApplicationProperty //
                            LoanApplicationProperty appProperty = new LoanApplicationProperty();
                            appProperty.LoanApplicationId = resLoanRecord.Id;
                            appProperty.Name = null;
                            appProperty.Loan_purpose__c = lpString;
                            appProperty.Property_Type__c = wrapperDetails.property.PropertyType;
                            appProperty.Customer_Estimated_Amount__c = wrapperDetails.property.HomeValue != null ? Decimal.valueOf(wrapperDetails.property.HomeValue) : null;
                            appProperty.PropertyCity = wrapperDetails.property.City;
                            appProperty.PropertyCountry = wrapperDetails.property.CountryCode;
                            appProperty.PropertyPostalCode = wrapperDetails.property.Zip;
                            appProperty.PropertyState = wrapperDetails.property.State;
                            appProperty.PropertyStreet = wrapperDetails.property.Street;
                            appProperty.CreatedFromLeadUI__c = true;

                            system.debug('SBT 11: Before insert appProperty');
                            insert appProperty;
                            system.debug('SBT 12: After insert appProperty');

                            // LoanApplicationAsset //
                            LoanApplicationAsset appAsset = new LoanApplicationAsset();
                            appAsset.LoanApplicationId = resLoanRecord.Id;
                            appAsset.Name = null;

                            system.debug('SBT 13: Before insert appAsset');
                            insert appAsset;
                            system.debug('SBT 14: After insert appAsset');

                            if (appAsset != null) {

                                // LoanApplicationLiability //
                                LoanApplicationLiability appLiability = new LoanApplicationLiability();
                                appLiability.LoanApplicationId = resLoanRecord.Id;
                                appLiability.Name = null;
                                appLiability.Opportunity__c = oppRecord.Id;
                                //appLiability.Application_Property__c = appProperty.Id;
                                appLiability.LoanApplicationAssetId = appAsset.Id; 
                                appLiability.Amount__c = 0;
                                appLiability.Balance_Amount__c = 0;
                                appLiability.Type__c = 'Other';

                                system.debug('SBT 15: Before insert appLiability');
                                insert appLiability;
                                system.debug('SBT 16: After insert appLiability');
                            }

                            // LoanApplicants //
                            List<LoanApplicant> applicantList = new List<LoanApplicant>();
                            List<Account> accountList = new List<Account>();
                            for (CreateAccountWrapper.PropertyMember applicantWrapperRecord : new List<CreateAccountWrapper.PropertyMember> { wrapperDetails.PropertyMemberOne, wrapperDetails.PropertyMemberTwo }) {
                                LoanApplicant applicantObject = new LoanApplicant();

                                applicantObject.BorrowerType = applicantWrapperRecord.isPrimaryBorrower ? 'Borrower' : 'CoBorrower';

                                if (applicantObject.BorrowerType == 'Borrower') {
                                    if (!applicantWrapperRecord.isPrimaryContact) {
                                        Account applicantPersonAccount = createPersonAccountForApplicant(applicantWrapperRecord);
                                        if (applicantPersonAccount != null && applicantPersonAccount.LastName != null && applicantPersonAccount.LastName != '') {
                                            Contact personContact2 = [SELECT Id, AccountId FROM Contact WHERE AccountId = :applicantPersonAccount.Id LIMIT 1];
                                            applicantObject.ContactId = personContact2.Id;
                                        }
                                    } else {
                                        applicantObject.ContactId = personContact != null ? personContact.Id : null;
                                        personAcc.Date_of_Birth__pc = Date.valueOf(applicantWrapperRecord.dateOfBirth);
                                        personAcc.PersonBirthdate = Date.valueOf(applicantWrapperRecord.dateOfBirth);
                                        personAcc.Gender__pc = applicantWrapperRecord.gender;
                                        personAcc.Marital_Status__pc = applicantWrapperRecord.maritalStatus;
                                        accountList.add(personAcc);
                                    }
                                    applicantObject.Is_Primary_Borrower__c = true;
                                } else {
                                    Account applicantPersonAccount = createPersonAccountForApplicant(applicantWrapperRecord);
                                    if (applicantPersonAccount != null && applicantPersonAccount.LastName != null && applicantPersonAccount.LastName != '') {
                                        Contact personContact2 = [SELECT Id, AccountId FROM Contact WHERE AccountId = :applicantPersonAccount.Id LIMIT 1];
                                        applicantObject.ContactId = personContact2.Id;
                                    }
                                }

                                if (applicantWrapperRecord.controlling == 'Delegate' && applicantWrapperRecord.dependent == 'POA' && applicantObject.BorrowerType == 'CoBorrower') {
                                    applicantObject.Role__c = 'Power of Attorney';
                                } else {
                                    applicantObject.Role__c = 'Borrower';
                                }
                                applicantObject.LoanApplicationId = resLoanRecord.Id;
                                applicantObject.GenderType = applicantWrapperRecord.gender;
                                applicantObject.MaritalStatus = applicantWrapperRecord.maritalStatus;
                                applicantObject.Name = null;

                                if (applicantWrapperRecord.lastName != null && applicantWrapperRecord.lastName != '') {
                                    applicantList.add(applicantObject);
                                }
                            }
                            if (applicantList.size() > 0 && applicantList != null) {
                                system.debug('SBT 17: Before insert applicantList');
                                insert applicantList;
                                system.debug('SBT 18: After insert applicantList');
                            }
                            if (accountList.size() > 0 && accountList != null) {
                                system.debug('SBT 19: Before upsert accountList');
                                upsert accountList;
                                system.debug('SBT 20: After upsert accountList');
                            }

                            List<LoanApplicantIncome> applicantIncomeList = new List<LoanApplicantIncome>();
                            List<LoanApplicantEmployment> applicantEmploymentList = new List<LoanApplicantEmployment>();
                            List<LoanApplicantAddress> applicantAddressList = new List<LoanApplicantAddress>();

                            if (applicantList.size() > 0 && applicantList != null) {
                                for (LoanApplicant applicantObject : applicantList) {
                                    // LoanApplicantIncome //
                                    LoanApplicantIncome applicantIncomeRecord = new LoanApplicantIncome();
                                    applicantIncomeRecord.LoanApplicantId = applicantObject.Id;
                                    applicantIncomeRecord.LoanApplicationId = resLoanRecord.Id;
                                    applicantIncomeRecord.Name = null;
                                    applicantIncomeList.add(applicantIncomeRecord);

                                    // LoanApplicantEmployment //
                                    LoanApplicantEmployment applicantEmploymentRecord = new LoanApplicantEmployment();
                                    applicantEmploymentRecord.LoanApplicantId = applicantObject.Id;
                                    applicantEmploymentRecord.LoanApplicationId = resLoanRecord.Id;
                                    applicantEmploymentRecord.Name = null;
                                    applicantEmploymentList.add(applicantEmploymentRecord);

                                    // LoanApplicantAddress //
                                    LoanApplicantAddress applicantAddressRecord = new LoanApplicantAddress();
                                    applicantAddressRecord.LoanApplicantId = applicantObject.Id;
                                    applicantAddressRecord.LoanApplicationId = resLoanRecord.Id;
                                    applicantAddressRecord.Name = null;
                                    applicantAddressList.add(applicantAddressRecord);
                                }

                                if (applicantIncomeList.size() > 0) {
                                    system.debug('SBT 21: Before insert applicantIncomeList');
                                    insert applicantIncomeList;
                                    system.debug('SBT 22: After insert applicantIncomeList');
                                }
                                if (applicantEmploymentList.size() > 0) {
                                    system.debug('SBT 23: Before insert applicantEmploymentList');
                                    insert applicantEmploymentList;
                                    system.debug('SBT 24: After insert applicantEmploymentList');
                                }
                                if (applicantAddressList.size() > 0) {
                                    system.debug('SBT 25: Before insert applicantAddressList');
                                    insert applicantAddressList;
                                    system.debug('SBT 26: After insert applicantAddressList');
                                }
                            }
                        }
                    }
                }
            }
            return personAcc.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Account createPersonAccountForApplicant(CreateAccountWrapper.PropertyMember appWrapperRecord) {
        Account personAcc = new Account();
        personAcc.Salutation = appWrapperRecord.salutation;
        personAcc.Firstname = appWrapperRecord.firstName;
        personAcc.LastName = appWrapperRecord.lastName;
        personAcc.PersonHomePhone = appWrapperRecord.phone;
        personAcc.PersonEmail = appWrapperRecord.email;
        personAcc.PersonMailingStreet = appWrapperRecord.primaryStreet;
        personAcc.PersonMailingCity = appWrapperRecord.primaryCity;
        personAcc.PersonMailingState = appWrapperRecord.primaryProvince;
        personAcc.PersonMailingPostalCode = appWrapperRecord.primaryPostalCode;
        personAcc.PersonMailingCountry = appWrapperRecord.primaryCountry;
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        personAcc.recordTypeId = personAccountRecordTypeId;
        personAcc.PersonBirthdate = Date.valueOf(appWrapperRecord.dateOfBirth);
        personAcc.Date_of_Birth__pc = Date.valueOf(appWrapperRecord.dateOfBirth);
        personAcc.Age__pc = Integer.valueOf(appWrapperRecord.age);
        personAcc.Gender__pc = appWrapperRecord.gender;
        personAcc.Marital_Status__pc = appWrapperRecord.maritalStatus;

        if (personAcc.LastName != null && personAcc.LastName != '') {
            system.debug('SBT 27: Before insert personAcc in createPersonAccountForApplicant');
            insert personAcc;
            system.debug('SBT 28: After insert personAcc in createPersonAccountForApplicant');
        }
        return personAcc;
    }
}