public with sharing class CreateNewAccount {

    @AuraEnabled
    public static string submitRecords(String wrapperString) {
        try {

            //start skip trigger from calling Quote update from MARS
            QuoteRequestManager.startSkipQuoteService();

            CreateAccountWrapper wrapperDetails = Utils.parseCreateAccountWrapper(wrapperString);
            Account personAcc = new Account();
            if (wrapperDetails != null) {                

                // Person Account //
                Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                personAcc = wrapperDetails.primaryAccount.toAccount(wrapperDetails.property,wrapperDetails.fileDetails.Language);
                personAcc.recordTypeId = personAccountRecordTypeId;

                if(wrapperDetails.consent != null){
                    if( wrapperDetails.consent.CASLConsent != '' &&  wrapperDetails.consent.CASLConsent != null) {
                       personAcc.CASL_Consent__c =  wrapperDetails.consent.CASLConsent;
                    } 
                    if (wrapperDetails.consent.CASLConsentObtainedBy != '' &&  wrapperDetails.consent.CASLConsentObtainedBy != null) {
                        personAcc.CASL_Consent_Obtained_By__c = wrapperDetails.consent.CASLConsentObtainedBy;
                    }
                    if (String.valueOf(wrapperDetails.consent.CASLConsentProvidedOn) != '' &&  wrapperDetails.consent.CASLConsentProvidedOn != null) {
                       personAcc.CASL_Consent_Provided_On__c = Date.valueOf(wrapperDetails.consent.CASLConsentProvidedOn);
                    }
                }

                if (personAcc.LastName != null && personAcc.LastName != '') {
                    insert personAcc;
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
                    //adding referral partner information into File
                    List<Contact> referralContact = new List<Contact>();
                    if(wrapperDetails.partnerDetails != null){
                        oppRecord.Referral_Channel__c = wrapperDetails.partnerDetails.ReferralChannel;
                        if(!String.isEmpty(wrapperDetails.partnerDetails.Territory)){
                            oppRecord.Territory2Id = wrapperDetails.partnerDetails.Territory;
                        }
                        if(!String.isEmpty(wrapperDetails.partnerDetails.ReferralOrganization)){
                            oppRecord.Referral_Organization__c = wrapperDetails.partnerDetails.ReferralOrganization;
                        }
                        if(!String.isEmpty(wrapperDetails.partnerDetails.ReferralPartner)){
                            oppRecord.Referral_Partner__c = wrapperDetails.partnerDetails.ReferralPartner;
                            referralContact = [SELECT Id, AccountId,account.OwnerId
                                                        FROM Contact 
                                                        WHERE AccountId = :wrapperDetails.partnerDetails.ReferralPartner 
                                                        LIMIT 1];
                            if(!referralContact.isEmpty()){
                                Boolean isReferalPartnerUserId = referralContact[0].Account.OwnerId != null && String.valueOf(referralContact[0].Account.OwnerId).startsWith('005');
                                oppRecord.BDM__c = isReferalPartnerUserId ? referralContact[0].account.OwnerId: null; 
                            }        
                        }
                        if(!String.isEmpty(wrapperDetails.partnerDetails.SubmissionAgent)){
                            oppRecord.Submission_Partner__c = wrapperDetails.partnerDetails.SubmissionAgent;
                        }else if(!referralContact.isempty()){
                            oppRecord.Submission_Partner__c = referralContact[0].Id;
                        }
                    }
                    insert oppRecord;

                    if (oppRecord != null) {
                        //Create OppContactRole for Referral Partner
                        List<OpportunityContactRole> oppRoles = new List<OpportunityContactRole>();
                        if(wrapperDetails.partnerDetails != null && 
                            !String.isEmpty(wrapperDetails.partnerDetails.ReferralPartner)){
                            //find Contact of Person Account
                            if(!referralContact.isEmpty()){
                                OpportunityContactRole fileRole = new OpportunityContactRole();
                                fileRole.ContactId = referralContact[0].Id;
                                fileRole.OpportunityId = oppRecord.Id;
                                fileRole.Role = 'Referral Partner';
                                fileRole.IsPrimary = true;
                                oppRoles.add(fileRole);
                            }
                        }

                        if(wrapperDetails.partnerDetails != null && 
                            !String.isEmpty(oppRecord.Submission_Partner__c)){
                            OpportunityContactRole submissionRole = new OpportunityContactRole();
                            submissionRole.ContactId = oppRecord.Submission_Partner__c;
                            submissionRole.OpportunityId = oppRecord.Id;
                            submissionRole.Role = 'Submission Agent';
                            oppRoles.add(submissionRole);
                        }

                        if(!oppRoles.isEmpty()){
                            insert oppRoles;
                        }

                        // ResidentialLoanApplication //
                        ResidentialLoanApplication resLoanRecord = new ResidentialLoanApplication();
                        resLoanRecord.OpportunityId = oppRecord.Id;
                        resLoanRecord.Name = wrapperDetails.primaryAccount.firstName + ' ' + wrapperDetails.primaryAccount.lastName; 
                        String lpString = '';
                        if (wrapperDetails.LoanPurpose != null && wrapperDetails.LoanPurpose.size() > 0) {
                            for (String loanPurpose : wrapperDetails.LoanPurpose) {
                                lpString += loanPurpose + ';';
                            }
                            resLoanRecord.Loan_purpose__c = lpString;
                        }
                        resLoanRecord.Loan_purpose__c = lpString;
                        resLoanRecord.Status = 'New';
                        insert resLoanRecord;

                        if (resLoanRecord != null) {

                            // LoanApplicationProperty //
                            LoanApplicationProperty appProperty = new LoanApplicationProperty();
                            appProperty.LoanApplicationId = resLoanRecord.Id;
                            appProperty.Name = null;
                            appProperty.Loan_purpose__c = lpString;
                            appProperty.Property_Type__c = wrapperDetails.property.PropertyType;
                            if(wrapperDetails.property.HomeValue != null && String.valueOf(wrapperDetails.property.HomeValue) != ''){
                                appProperty.Customer_Estimated_Amount__c = Decimal.valueOf(wrapperDetails.property.HomeValue);
                            }
                            appProperty.PropertyCity = wrapperDetails.property.City;
                            appProperty.PropertyCountry = wrapperDetails.property.CountryCode;
                            appProperty.PropertyPostalCode = wrapperDetails.property.Zip;
                            appProperty.PropertyState = wrapperDetails.property.State;
                            appProperty.PropertyStreet = wrapperDetails.property.Street;
                            appProperty.CreatedFromLeadUI__c = true;
                            insert appProperty;


                            // LoanApplicants //
                            List<LoanApplicant> applicantList = new List<LoanApplicant>();
                            
                            //LoanApplicant relationships
                            LoanApplicant primaryApplicant;
                            LoanApplicant secondApplicant;
                            String relationshipType;
                            String relationshipCategory;

                            List<Account> accountList = new List<Account>();
                            for (CreateAccountWrapper.PropertyMember applicantWrapperRecord : new List<CreateAccountWrapper.PropertyMember> { wrapperDetails.PropertyMemberOne, wrapperDetails.PropertyMemberTwo }) {
                                if(applicantWrapperRecord.LastName != '' && String.valueOf(applicantWrapperRecord.LastName) != ''){
                                LoanApplicant applicantObject = new LoanApplicant();
                                applicantObject.role__c = LoanApplicantService.BORROWER_ROLE;
                                if (applicantWrapperRecord.isPrimaryBorrower) {                                    
                                    if (!applicantWrapperRecord.isPrimaryContact) {
                                        Account applicantPersonAccount = createPersonAccountForApplicant(applicantWrapperRecord, wrapperDetails);
                                        if (applicantPersonAccount != null && applicantPersonAccount.LastName != null && applicantPersonAccount.LastName != '') {
                                            Contact personContact2 = [SELECT Id, AccountId FROM Contact WHERE AccountId = :applicantPersonAccount.Id LIMIT 1];
                                            applicantObject.ContactId = personContact2.Id;
                                            applicantObject.Client__c = applicantPersonAccount.Id;
                                        }
                                    } else {
                                        applicantObject.ContactId = personContact != null ? personContact.Id : null;
                                        applicantObject.Client__c = personAcc.Id;
                                        if (String.valueOf(applicantWrapperRecord.dateOfBirth) != '' && applicantWrapperRecord.dateOfBirth != null) {
                                            personAcc.Date_of_Birth__pc = Date.valueOf(applicantWrapperRecord.dateOfBirth);
                                            personAcc.PersonBirthdate = Date.valueOf(applicantWrapperRecord.dateOfBirth);
                                        }
                                        personAcc.Gender__pc = applicantWrapperRecord.gender;
                                        personAcc.Marital_Status__pc = applicantWrapperRecord.maritalStatus;
                                        accountList.add(personAcc);
                                    }
                                    applicantObject.Is_Primary_Borrower__c = true;     
                                    primaryApplicant = applicantObject;                                                      
                                } else {
                                    Account applicantPersonAccount = createPersonAccountForApplicant(applicantWrapperRecord, wrapperDetails);
                                    if (applicantPersonAccount != null && applicantPersonAccount.LastName != null && applicantPersonAccount.LastName != '') {
                                        Contact personContact2 = [SELECT Id, AccountId FROM Contact WHERE AccountId = :applicantPersonAccount.Id LIMIT 1];
                                        applicantObject.ContactId = personContact2.Id;
                                        applicantObject.Client__c = applicantPersonAccount.Id;
                                    }
                                    secondApplicant = applicantObject;
                                    relationshipType = applicantWrapperRecord.RelationshipType;
                                    relationshipCategory = applicantWrapperRecord.RelationshipCategory;
                                }

                                if (applicantWrapperRecord.controlling == 'Delegate' && applicantWrapperRecord.dependent == 'POA' && (applicantObject.Role__c.contains(LoanApplicantService.BORROWER_ROLE) && !applicantObject.Is_Primary_Borrower__c)) {
                                    List<String> listRoleValues = new List<String>{LoanApplicantService.BORROWER_ROLE,LoanApplicantService.POA_ROLE};
                                    applicantObject.Role__c = String.join(listRoleValues, ';');
                                } else {
                                    applicantObject.Role__c = LoanApplicantService.BORROWER_ROLE;
                                }
                                applicantObject.LoanApplicationId = resLoanRecord.Id;
                                applicantObject.GenderType = applicantWrapperRecord.gender;
                                applicantObject.MaritalStatus = applicantWrapperRecord.maritalStatus;
                                applicantObject.Name = applicantWrapperRecord.firstName + ' ' + applicantWrapperRecord.lastName; 

                                if (applicantWrapperRecord.lastName != null && applicantWrapperRecord.lastName != '') {
                                    applicantList.add(applicantObject);
                                }
                            }
                        }
                        
                            // Create the Primary Contact Applicant
                            if(!wrapperDetails.PropertyMemberOne.isPrimaryContact) {
                                LoanApplicant primaryApplicantObject = new LoanApplicant();
                                primaryApplicantObject.role__c = LoanApplicantService.INFLUENCER_ROLE;
                                primaryApplicantObject.ContactId = personContact != null ? personContact.Id : null;
                                primaryApplicantObject.Client__c = personAcc.Id;
                                primaryApplicantObject.Is_Primary_Borrower__c = false;
                                primaryApplicantObject.LoanApplicationId = resLoanRecord.Id;
                                primaryApplicantObject.Name = wrapperDetails.primaryAccount.firstName + ' ' + wrapperDetails.primaryAccount.lastName; 
                                applicantList.add(primaryApplicantObject);
                            }

                            if (applicantList.size() > 0 && applicantList != null) {
                                insert applicantList;
                            }
                            if (accountList.size() > 0 && accountList != null) {
                                upsert accountList;
                            }

                            //create property member relationship
                            createMemberRelationship(relationshipCategory,relationshipType,primaryApplicant,secondApplicant);

						
                            List<LoanApplicantAddress> applicantAddressList = new List<LoanApplicantAddress>();

                            if (applicantList.size() > 0 && applicantList != null) {
                                for (LoanApplicant applicantObject : applicantList) {
                          

                                    // LoanApplicantAddress //
                                    LoanApplicantAddress applicantAddressRecord = new LoanApplicantAddress();
                                    applicantAddressRecord.LoanApplicantId = applicantObject.Id;
                                    applicantAddressRecord.LoanApplicationId = resLoanRecord.Id;
                                    applicantAddressRecord.Name = wrapperDetails.primaryAccount.firstName + ' ' + wrapperDetails.primaryAccount.lastName;
                                    applicantAddressList.add(applicantAddressRecord);
                                }

                                if (applicantAddressList.size() > 0) {
                                    insert applicantAddressList;
                                }
                            }
                        }
                    }
                }
            }

            //stop skip of trigger from calling Quote update from MARS
            QuoteRequestManager.stopSkipQuoteService();

            return personAcc.Id;
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage()); }

        
    }

    @AuraEnabled
    public static string generateQuotes(String accountId){
        Opportunity oppRecord = [SELECT id FROM Opportunity WHERE AccountId = :accountId LIMIT 1];
        
        if(oppRecord!=null && !Test.isRunningTest()){ return QuoteRequestValidationController.getQuote(oppRecord.Id); }
        return 'No Opportunities Attached';
    }

    public static Account createPersonAccountForApplicant(CreateAccountWrapper.PropertyMember appWrapperRecord,CreateAccountWrapper wrapperDetails) {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account personAcc = appWrapperRecord.toAccount(wrapperDetails.property);
        personAcc.recordTypeId = personAccountRecordTypeId;
        if (personAcc.LastName != null && personAcc.LastName != '') {
            insert personAcc;
        }
        return personAcc;
    }

    private static void createMemberRelationship(String category, String type, 
                                                    LoanApplicant primaryBorrower, 
                                                    LoanApplicant secondBorrower){

        //check if we have relationship type and category
        if(String.isEmpty(category) && String.isEmpty(type)){
            return;
        }

        //create relationship if there are 2 borrowers
        if(primaryBorrower != null && secondBorrower !=null){
            list<Property_Member_Relationship__c> relationsToCreate = new List<Property_Member_Relationship__c>();

            Property_Member_Relationship__c pmr = new Property_Member_Relationship__c();
            pmr.Property_Member__c = secondBorrower.Id;
            pmr.Relates_to__c = primaryBorrower.Id;
            pmr.Relationship_Category__c = category;
            pmr.Relationship_Type__c = type;
            relationsToCreate.add(pmr);

            //create reciprocal relation
            String reciprocalType = getReciprocalType(type);
            if(String.IsNotBlank(reciprocalType)){
                Property_Member_Relationship__c reciprocalPmr = new Property_Member_Relationship__c();
                reciprocalPmr.Property_Member__c = primaryBorrower.Id;
                reciprocalPmr.Relates_to__c = secondBorrower.Id;
                reciprocalPmr.Relationship_Category__c = category;
                reciprocalPmr.Relationship_Type__c = reciprocalType;
                relationsToCreate.add(reciprocalPmr);
            }

            insert relationsToCreate;
        }
    }

    private static String getReciprocalType(String relationType){
        List<Property_Member_Relationship_Settings__mdt> settings = [SELECT MasterLabel,Reciprocal_Type__c
                                                                     FROM Property_Member_Relationship_Settings__mdt 
                                                                     WHERE MasterLabel = :relationType];
        if(settings != null && !settings.isEmpty()){
            return settings[0].Reciprocal_Type__c;
        }
        return null;
    }

    @AuraEnabled
    public static List<SObject> getReferalAssociations(String accountId){
        try{
            List<SObject> prefilledLookupsData = new List<SObject>();
            List<ObjectTerritory2Association> associations = [SELECT Territory2Id
                                                                FROM ObjectTerritory2Association 
                                                                WHERE ObjectId = :accountId
                                                                ORDER BY LastModifiedDate DESC 
                                                                LIMIT 1];
            List<Account> organizations = [SELECT CurrentOrganization__c , personContactId
                                            FROM Account 
                                            WHERE Id = :accountId
                                            LIMIT 1];
            if(!associations.isEmpty()){  prefilledLookupsData.addAll(associations);  }
            if(!organizations.isEmpty()){  prefilledLookupsData.addAll(organizations);  }
            return prefilledLookupsData;
        }catch(Exception ex){ throw new AuraHandledException('Error retrieving referal data');  }
    }
}