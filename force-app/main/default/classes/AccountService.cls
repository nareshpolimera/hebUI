/******************************************************/ /**
@Class      AccountService
@brief      Class with especific-related methods to the Account object.

@revision   2024-04-20 Diego Guerrero
Porting from legacy SF org.
/******************************************************/
public without sharing class AccountService {
    
    public static final String ROLE_PAYMENT_AGREEMENT = 'Payment Agreement Holdee';
    public static final String ROLE_REFERRAL_AGREEMENT = 'Referral Agreement Holdee';
    public static final String TYPE_BANK = 'Bank';
    public static final String TYPE_BROKERAGE = 'Broker';
    public static final String TYPE_WEALTH_PARTNER = 'Wealth Partner';
    public static final String OPPORTUNITY_STAGE = 'Assessment Needed';
    public static final Map<String, Dial_List_Settings__mdt> DIAL_LIST_METADATA = Dial_List_Settings__mdt.getAll();
    public static Boolean runOnce = true;
    
    /*
* HEB-402: set the Numeric Phone field based on the Phone
*/
    public void setNumericPhone(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        for (Account l : records) {
            if (
                oldRecords == null ||
                oldRecords.get(l.Id).Phone <> l.Phone ||
                (l.Phone <> null &&
                 l.Numeric_Phone__c == null)
            ) {
                if (l.Phone == null)
                    l.Numeric_Phone__c = null;
                else {
                    String numericPhone = l.Phone;
                    numericPhone = numericPhone.replace('(', '');
                    numericPhone = numericPhone.replace(')', '');
                    numericPhone = numericPhone.replace(' ', '');
                    numericPhone = numericPhone.replace('-', '');
                    l.Numeric_Phone__c = numericPhone;
                }
            }
        }
    }
    
    /*
* HEB-402: set the Numeric Phone field based on the Phone
*/
    public void setAreaCode(List<Account> records, Map<Id, Account> oldRecords) {
        for (Account l : records) {
            if (
                oldRecords == null ||
                oldRecords.get(l.Id).Numeric_Phone__c <> l.Numeric_Phone__c
            ) {
                if (l.Numeric_Phone__c == null)
                    l.Numeric_Phone__c = null;
                else {
                    if (l.Numeric_Phone__c.length() <= 10) {
                        l.Area_Code__c = l.Numeric_Phone__c.left(3);
                    } else {
                        l.Area_Code__c = l.Numeric_Phone__c.substring(1, 4);
                    }
                }
            }
        }
    }
    
    /*
* Validate Phone Number when Number is new or the number is changed
*/
    public void generateListofChangedPhone(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        if (Utils.isIntegrationUser())
            return;
        List<Id> lid = new List<Id>();
        
        if (oldRecords != null) {
            Set<String> fieldsToCheck = new Set<String>{ 'Phone' };
                
                List<Account> ls = (List<Account>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
            
            for (Account ld : ls) {
                if (String.isBlank(ld.Phone)) {
                    ld.Phone_Verification_Status__c = 'Invalid'; // Treat Blank phone number is an Invalid Number to simplify downstream process
                    ld.Phone_Verification_Line_Type__c = null;
                    ld.Phone_Number_Validated_On__c = null;
                    ld.SMS_Address__c = null;
                } else {
                    ld.Phone_Verification_Status__c = 'Pending';
                    ld.Phone_Verification_Line_Type__c = 'Unknown';
                    ld.Phone_Number_Validated_On__c = null;
                    ld.SMS_Address__c = null;
                }
                lid.add(ld.id);
            }
        } else {
            //Account inserting and New phone number hasn't been validated
            for (Account ld : records) {
                if (!String.isBlank(ld.Phone)) {
                    lid.add(ld.id);
                }
            }
        }
        
        if (!lid.isEmpty()) {
            validatePhoneNumber(lid);
        }
    }
    
    /*
* Validate Email when is new or the Email is changed
*/
    public void generateListofChangedEmail(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        if (Utils.isIntegrationUser())
            return;
        List<Id> lid = new List<Id>();
        
        if (oldRecords != null) {
            Set<String> fieldsToCheck = new Set<String>{ 'PersonEmail' };
                
                List<Account> ls = (List<Account>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
            
            for (Account ld : ls) {
                if (String.isBlank(ld.PersonEmail)) {
                    ld.Email_Verification_Status__c = 'Invalid'; // Treat Blank Email is an Invalid email to simplify downstream process
                    ld.Email_Verification_Timestamp__c = null;
                } else {
                    ld.Email_Verification_Status__c = 'Pending';
                    ld.Email_Verification_Timestamp__c = null;
                    lid.add(ld.id);
                }
            }
        } else {
            //Account inserting and New email hasn't been validated
            for (Account ld : records) {
                if (!String.isBlank(ld.PersonEmail)) {
                    lid.add(ld.id);
                }
            }
        }
        
        if (!lid.isEmpty()) {
            validateEmail(lid);
        }
    }
    
    /*
* Validate Address when is new or the Address is changed
*/
    public void generateListofChangedAddress(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        if (Utils.isIntegrationUser())
            return;
        List<Id> lid = new List<Id>();
        if (oldRecords != null) {
            Set<String> fieldsToCheck = new Set<String>{
                'PersonMailingStreet',
                    'PersonMailingCity',
                    'PersonMailingPostalCode',
                    'PersonMailingState',
                    'BillingStreet',
                    'BillingCity',
                    'BillingPostalCode',
                    'BillingState'
                    };
                        
                        List<Account> ls = (List<Account>) Utils.getChangedObjects(
                            records,
                            oldRecords,
                            fieldsToCheck
                        );
            system.debug(ls);
            boolean allFieldsPopulated = false;
            for (Account ld : ls) {
                if (
                    (ld.IsPersonAccount &&
                     !String.isBlank(ld.PersonMailingStreet) &&
                     !String.isBlank(ld.PersonMailingCity) &&
                     !String.isBlank(ld.PersonMailingPostalCode) &&
                     !String.isBlank(ld.PersonMailingState)) ||
                    (!ld.IsPersonAccount &&
                     !String.isBlank(ld.BillingStreet) &&
                     !String.isBlank(ld.BillingCity) &&
                     !String.isBlank(ld.BillingPostalCode) &&
                     !String.isBlank(ld.BillingState))
                ) {
                    lid.add(ld.id);
                }
            }
        } else {
            //Account inserting and New Address hasn't been validated
            for (Account ld : records) {
                if (
                    (ld.IsPersonAccount &&
                     !String.isBlank(ld.PersonMailingStreet) &&
                     !String.isBlank(ld.PersonMailingCity) &&
                     !String.isBlank(ld.PersonMailingPostalCode) &&
                     !String.isBlank(ld.PersonMailingState)) ||
                    ((ld.IsPersonAccount == null || !ld.IsPersonAccount) &&
                     !String.isBlank(ld.BillingStreet) &&
                     !String.isBlank(ld.BillingCity) &&
                     !String.isBlank(ld.BillingPostalCode) &&
                     !String.isBlank(ld.BillingState))
                ) {
                    lid.add(ld.id);
                }
            }
        }
        
        if (!lid.isEmpty()) {
            accountAddressParse(lid);
        }
    }
    
    public void updateUnvalidatedNewPhoneNumberStatus(List<Account> records) {
        if (Utils.isIntegrationUser())
            return;
        
        // inserting and New phone number hasn't been validated
        for (Account ld : records) {
            if (ld.Phone_Number_Validated_On__c == null) {
                ld.Phone_Verification_Status__c = 'Pending';
            }
        }
    }
    
    public void updateUnvalidatedNewEmailStatus(List<Account> records) {
        if (Utils.isIntegrationUser())
            return;
        
        // inserting and New email hasn't been validated
        for (Account ld : records) {
            if (ld.Email_Verification_Timestamp__c == null) {
                ld.Email_Verification_Status__c = 'Pending';
            }
        }
    }
    
    /*
* Call Phone Validation Services      service.updateUnvalidatedNewPhoneNumberStatus(records);
*/
    @future(callout=true)
    public static void validatePhoneNumber(List<Id> lid) {
        List<ModelPhoneValidation.Phone> pl = new List<ModelPhoneValidation.Phone>();
        
        List<ModelPhoneValidation.PhoneInfo> lpi = new List<ModelPhoneValidation.PhoneInfo>();
        List<Account> listLd = [
            SELECT
            Id,
            Phone,
            Phone_Verification_Line_Type__c,
            Phone_Verification_Status__c,
            Phone_Number_Validated_On__c,
            SMS_Address__c,
            IsPersonAccount
            FROM Account
            WHERE Id IN :lid
        ];
        
        for (Account l : listLd) {
            ModelPhoneValidation.Phone p = new ModelPhoneValidation.Phone();
            p.Id = String.valueOf(l.Id);
            p.PhoneNumber = l.Phone;
            pl.add(p);
        }
        
        Map<Id, Account> ldm = new Map<Id, Account>(listLd);
        
        String res = PhoneValidationService.sendRequest(pl);
        if(String.isNotBlank(res)){
            lpi = PhoneValidationService.processResponse(res);
            if (!lpi.isEmpty()) {
                for (ModelPhoneValidation.PhoneInfo pi : lpi) {
                    Id ldId = Id.valueOf(pi.Id);
                    Account l = ldm.get(ldid);
                    l.Phone_Verification_Line_Type__c = pi.lineType;
                    l.Phone_Number_Validated_On__c = pi.validatedOn;
                    l.Phone_Verification_Status__c = pi.status;
                    l.SMS_Address__c = pi.SMSAddress;
                    ldm.put(l.Id, l);
                }
                List<Account> acclist = ldm.values();
                update acclist;
            }
        }
    }
    
    @future(callout=true)
    public static void validateEmail(List<Id> lid) {
        List<ModelEmailValidation.Email> pl = new List<ModelEmailValidation.Email>();
        
        List<ModelEmailValidation.EmailInfo> lpi = new List<ModelEmailValidation.EmailInfo>();
        List<Account> listLd = [
            SELECT
            Id,
            PersonEmail,
            Email_Verification_Status__c,
            Email_Verification_Timestamp__c,
            IsPersonAccount
            FROM Account
            WHERE Id IN :lid
        ];
        
        for (Account l : listLd) {
            ModelEmailValidation.Email p = new ModelEmailValidation.Email();
            p.EmailAddress = l.PersonEmail;
            p.Id = String.valueOf(l.Id);
            pl.add(p);
        }
        
        Map<Id, Account> ldm = new Map<Id, Account>(listLd);
        
        String res = EmailValidationService.sendRequest(pl);
        if(String.isNotBlank(res)){
            lpi = EmailValidationService.processResponse(res); 
            if (!lpi.isEmpty()) {
                for (ModelEmailValidation.EmailInfo pi : lpi) {
                    Id ldId = Id.valueOf(pi.Id);
                    Account l = ldm.get(ldid);
                    
                    l.Email_Verification_Timestamp__c = pi.validatedOn;
                    l.Email_Verification_Status__c = pi.status;
                    
                    ldm.put(l.Id, l);
                }
                List<Account> acclist = ldm.values();
                update accList;
            }
        }
    }
    
    /*
* Call Address Parse Services
*/
    @future(callout=true)
    public static void accountAddressParse(List<Id> lid) {
        List<Account> listLd = [
            SELECT
            Id,
            PersonMailingStreet,
            PersonMailingCity,
            PersonMailingPostalCode,
            PersonMailingState,
            BillingStreet,
            BillingCity,
            BillingPostalCode,
            BillingState,
            AddressNumberFragment__c,
            StreetFragment__c,
            StreetTypeFragment__c,
            StreetDirectionFragment__c,
            UnitFragment__c,
            UnitTypeFragment__c,
            CityFragment__c,
            PostalCodeFragment__c,
            ProvinceFragment__c,
            Is_Address_Parsed__c,
            IsPersonAccount
            FROM Account
            WHERE Id IN :lid
        ];
        if(!listLd.isEmpty()){
            List<ModelParseAddress.Address> pl = new List<ModelParseAddress.Address>();
            
            List<ModelParseAddress.Response> lpi = new List<ModelParseAddress.Response>();
            
            for (Account accRecord : listLd) {
                ModelParseAddress.Address p = new ModelParseAddress.Address();
                p.Id = String.valueOf(accRecord.Id);
                if (accRecord.IsPersonAccount) {
                    p.Address = accRecord.PersonMailingStreet;
                    p.City = accRecord.PersonMailingCity;
                    p.Province = accRecord.PersonMailingState;
                    p.PostalCode = accRecord.PersonMailingPostalCode;
                } else {
                    p.Address = accRecord.BillingStreet;
                    p.City = accRecord.BillingCity;
                    p.Province = accRecord.BillingState;
                    p.PostalCode = accRecord.BillingPostalCode;
                }
                pl.add(p);
            }
            
            String res = ParseAddressService.sendRequest(pl);
            if(String.isNotBlank(res)){
                Map<Id, Account> ldm = new Map<Id, Account>(listLd);
                lpi = ParseAddressService.processResponse(res);
                
                if (!lpi.isEmpty()) {
                    for (ModelParseAddress.Response parsedAddress : lpi) {
                        if (parsedAddress.Id != null) {
                            Id ldId = Id.valueOf(parsedAddress.Id);
                            Account acc = ldm.get(ldid);
                            if (parsedAddress.isSuccessful == 'true') {
                                acc.UnitFragment__c = parsedAddress.Address.UnitNumber;
                                acc.AddressNumberFragment__c = parsedAddress.Address.StreetNumber;
                                acc.StreetFragment__c = parsedAddress.Address.StreetName;
                                acc.StreetTypeFragment__c = parsedAddress.Address.StreetType;
                                acc.StreetDirectionFragment__c = parsedAddress.Address.StreetDirection;
                                acc.CityFragment__c = parsedAddress.Address.City;
                                acc.PostalCodeFragment__c = parsedAddress.Address.PostalCode;
                                acc.ProvinceFragment__c = parsedAddress.Address.Province;
                                acc.Is_Address_Parsed__c = true;
                                ldm.put(acc.Id, acc);
                            } else {
                                acc.Is_Address_Parsed__c = false;
                            }
                        }
                    }
                }
                List<Account> acclist = ldm.values();
                update acclist;
            }
        }
    }
    
    
    public static Boolean syncFromPropertyMember = false;
    
    
    /*
* HEB-520: Notify to update MARS.
*/
    public static Boolean updateReferralOrganization = false;
    public void updateReferralOrganizationPlatformEvent(
        List<Account> records,
        Map<Id, Account> oldRecords,
        String description
    ) {     
        
        Set<String> fieldsToCheck = Utils.getFieldSetFields(
            Schema.SObjectType.Account.fieldSets.Referral_Organization_Update_MARS.getFields()
        );
        List<Account> accs = (List<Account>) Utils.getChangedObjects(
            records,
            oldRecords,
            fieldsToCheck
        );
        
        if (accs.isEmpty())
            return;
        
        String Mars_description = (description == 'account'
                                   ? MARSPlatformEventService.UPDATED_ACCOUNT
                                   : (description == 'pa_client'
                                      ? MARSPlatformEventService.UPDATED_PERSON_ACCOUNT_CLIENT
                                      : MARSPlatformEventService.UPDATED_PERSON_ACCOUNT_PARTNER));
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Account acc : accs)
            requests.add(
                new MARSPlatformEventService.Request(
                    acc,
                    Mars_description,
                    MARSPlatformEventService.ACTION_UPDATE,
                    MARSPlatformEventService.UPDATED_ACCOUNT
                )
            );
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        AccountService.updateReferralOrganization = !(errorOccurred);
    }
    
    /*
* HEB-596: Only currently active user can be set to CASL consent
*/
    public void checkCASLConsentUser(List<Account> records, Map<Id, Account> oldRecords)
    {
        if (Utils.allowBypassForUser()) return;        
        for (Account a : records)
        {   
            if (a.CASL_Consent_Obtained_By__pc!= null
                && a.CASL_Consent_Obtained_By__pc <> UserInfo.getUserId()
                && a.PersonEmail <> null
                && a.PersonEmail <> ''
               )
            {
                if (oldRecords == null
                    // If this is an update check if the user is trying to change the consent field.
                    || (a.CASL_Consent_Obtained_By__pc <> oldRecords.get(a.Id).CASL_Consent_Obtained_By__pc))
                {
                    a.addError(Label.Error_Only_Active_CASL_User_Can_Conset);
                }
            }
        }
    }
    
    
    /*
* HEB-: When Person Account Last name updates ,It updated all related opportunities' Name
*/
    public void updateOpportunityName(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        Set<String> fieldsToCheck = new Set<String>{ 'LastName' };
            
            List<Account> accountIds = (List<Account>) Utils.getChangedObjects(
                records,
                oldRecords,
                fieldsToCheck
            );
        List<Account> personAccounts = new List<Account>();
        for (Account acc : accountIds) {
            if (acc.IsPersonAccount) {
                personAccounts.add(acc);
            }
        }
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        // Update the last name of the Opportunities with the new last name
        for (Opportunity opp : [
            SELECT Id, Name, AccountId, File_Number__c
            FROM Opportunity
            WHERE AccountId IN :personAccounts
        ]) {
            account acc = (Account) Trigger.newMap.get(opp.AccountId);
            opp.Name =  'OP - ' + acc.LastName + (opp.File_Number__c != null ? ' - ' + opp.File_Number__c : '');
            opportunitiesToUpdate.add(opp);
        }
        // Perform the bulk update of Opportunities
        if (!opportunitiesToUpdate.isEmpty()) {
            try{ 
                update opportunitiesToUpdate;
            }catch(exception ex){system.debug(ex.getMessage());}
            
            List<ResidentialLoanApplication> rlaToUpdate = new List<ResidentialLoanApplication>();
            // Update the last name of the ResidentialLoanApplication with the new last name
            for (ResidentialLoanApplication r : [
                SELECT Id, Name, AccountId,Opportunity.File_Number__c 
                FROM ResidentialLoanApplication
                WHERE AccountId IN :personAccounts
            ]) {
                account acc = (Account) Trigger.newMap.get(r.AccountId);
                r.Name =  'LA - ' + acc.LastName + (r.Opportunity.File_Number__c != null ? ' - ' + r.Opportunity.File_Number__c : '');
                rlaToUpdate.add(r);
            }
            // Perform the bulk update of ResidentialLoanApplication
            if (!rlaToUpdate.isEmpty()) {
                try{ 
                    update rlaToUpdate;
                }catch(exception ex){system.debug(ex.getMessage());}
                
            }
            List<LoanApplicant> laToUpdate = new List<LoanApplicant>();
            // Update the last name of the LoanApplicant with the new last name
            for (LoanApplicant r : [
                SELECT Id, Name, Client__c,LoanApplication.Opportunity.File_Number__c,LoanApplication.Opportunity.AccountId 
                FROM LoanApplicant
                WHERE LoanApplication.Opportunity.AccountId IN :personAccounts
            ]) {
                account acc = (Account) Trigger.newMap.get(r.LoanApplication.Opportunity.AccountId);
                r.Name =  'PM - ' + acc.FirstName +' '+ acc.LastName + (r.LoanApplication.Opportunity.File_Number__c != null ? ' - ' + r.LoanApplication.Opportunity.File_Number__c : '');
                laToUpdate.add(r);
            }
            // Perform the bulk update of LoanApplicant
            if (!laToUpdate.isEmpty()) {
                try{ 
                    update laToUpdate;
                }catch(exception ex){system.debug(ex.getMessage());}
                
            }
        }
    } 
    public void createAccountContactRelationship(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        List<Account> createdOrUpdatedAccounts = new List<Account>();
        Set<Id> createdOrUpdatedContactIds = new Set<Id>();
        Map<Id, List<AccountContactRelation>> contactRelationMap = new Map<Id, List<AccountContactRelation>>();
        List<AccountContactRelation> newRelations = new List<AccountContactRelation>();
        List<AccountContactRelation> existingRelations = new List<AccountContactRelation>();
        
        if (oldRecords != null) {
            // Collect the changed AccountIds from the Current_Organization__c field
            Set<String> fieldsToCheck = new Set<String>{ 'CurrentOrganization__c' };
                createdOrUpdatedAccounts = (List<Account>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
        } else {
            createdOrUpdatedAccounts = records;
        }
        for (Account account : createdOrUpdatedAccounts) {
            if (account.CurrentOrganization__c != null) {
                system.debug('account.PersonContactId ='+account.PersonContactId);
                createdOrUpdatedContactIds.add(account.PersonContactId);
            }
        }
        if (!createdOrUpdatedContactIds.isEmpty()) {
            // Query the existing Account-Contact Relation records for the changed AccountIds
            List<AccountContactRelation> existingRelationsForAllAccounts = [
                SELECT Id, ContactId, Is_Direct__c
                FROM AccountContactRelation
                WHERE ContactId IN :createdOrUpdatedContactIds
            ];
            for (AccountContactRelation relation : existingRelationsForAllAccounts) {
                if (!contactRelationMap.containsKey(relation.ContactId)) {
                    contactRelationMap.put(
                        relation.ContactId,
                        new List<AccountContactRelation>()
                    );
                }
                contactRelationMap.get(relation.ContactId).add(relation);
            }
            for (Account updatedAccount : createdOrUpdatedAccounts) {
                List<AccountContactRelation> existingRelationsForContact = contactRelationMap.get(
                    updatedAccount.PersonContactId
                );
                
                if (existingRelationsForContact != null) {
                    for (
                        AccountContactRelation existingRelation : existingRelationsForContact
                    ) {
                        existingRelation.Is_Direct__c = false;
                        existingRelations.add(existingRelation);
                    }
                }
                AccountContactRelation newRelation = new AccountContactRelation(
                    AccountId = updatedAccount.CurrentOrganization__c,
                    ContactId = updatedAccount.PersonContactId,
                    Is_Direct__c = true
                );
                
                newRelations.add(newRelation);
            }
        }
        
        if (!existingRelations.isEmpty()) {
            update existingRelations;
        }
        if (!newRelations.isEmpty()) {
            insert newRelations;
        }
    }
    
    public void updateTitleOnAccount(
        List<Account> records,
        Map<Id, Account> oldRecords
    ) {
        List<Account> createdOrUpdatedAccounts = new List<Account>();
        if (oldRecords != null) {
            // Collect the changed AccountIds from the Current_Organization__c field
            Set<String> fieldsToCheck = new Set<String>{ 'CurrentOrganization__c' };
                createdOrUpdatedAccounts = (List<Account>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
        } else {
            createdOrUpdatedAccounts = records;
        }
        for (Account updatedAccount : createdOrUpdatedAccounts) {
            updatedAccount.PersonTitle = '';
        }
    }
    
    /**
* checkDialListMainChanges : checks if critieria for Dial List Main are met and sets corresponding value
*/
    public void checkDialListMainChanges(List<Account> newAccounts, Map<Id, Account> oldRecords) {
        if (!Trigger.isUpdate) {
            return;
        }
        
        // check if Dial List Main fields have been changed            
        Set<String> fieldsToCheck = new Set<String>{'Most_Recent_Inquiry_Date__pc', 'In_Nurture_Stream__c', 
            'Phone_Verification_Status__c', 'Not_Interested_Yet__c',
            'Dialer_Dormant__c', 'Dialer_DNC__c' };
                List<Account> changedAccounts = (List<Account>) Utils.getChangedObjects(
                    newAccounts,
                    oldRecords,
                    fieldsToCheck
                );
        Map<Id, List<Opportunity>> accountToOppsMap = new Map<Id, List<Opportunity>>();
        if (changedAccounts.isEmpty()) {
            return;
        }
        List<Opportunity> accountOpps = [SELECT 
                                         Id,
                                         Channel__c,
                                         File_Queue__c,
                                         AccountId,
                                         Quote_Status__c,
                                         Primary_Borrower_Age__c,
                                         (SELECT 
                                          Id,
                                          (SELECT
                                           Id,
                                           Property_Value_for_Quote__c
                                           FROM LoanApplicationProperties
                                           ORDER BY CreatedDate Desc
                                           LIMIT 1)
                                          FROM Lending_Applications)
                                         FROM Opportunity
                                         WHERE AccountId in :changedAccounts];
        if (accountOpps.isEmpty()) {
            return;
        }
        for (Opportunity opp : accountOpps) {
            if (!accountToOppsMap.containsKey(opp.AccountId)) {
                accountToOppsMap.put(opp.AccountId, new List<Opportunity> {opp});
            } else {
                accountToOppsMap.get(opp.AccountId).add(opp);
            }
        }
        for (Account oppAccount : changedAccounts) {
            Boolean dialListMain = false;
            if(accountToOppsMap.containsKey(oppAccount.Id)){
                for (Opportunity opp : accountToOppsMap.get(oppAccount.Id)) {
                    if (opp.Lending_Applications?.size() == 0 || opp.Lending_Applications[0].LoanApplicationProperties?.size() == 0) {
                        continue; // property value criteria not met
                    }
                    Decimal propertyValue = opp.Lending_Applications[0].LoanApplicationProperties[0].Property_Value_for_Quote__c;   
                    
                    if(Five9ServiceUtils.checkDialListMain(oppAccount,opp,propertyValue)){
                        dialListMain = true;
                        break; // if at least one Opportunity matches the criteria, the Account should be added to the list
                        // if none of the opportunities match the critiera, the account needs to be removed from the list
                    }
                }
                oppAccount.Dial_List_Main__c = dialListMain;
            }
        }
    }
    
    
    public void assignDialList(List<Account> newAccounts, Map<Id, Account> oldRecords) {
        Boolean meetsListCriteria = false;
        List<Account> recordsToUpdate = new List<Account>();
        List<Account> accountsUpdatedCriteria = new List<Account>();
        List<Account> accountsWithUpdateCriteria = new List<Account>();
        Map<String, String> fieldToDialistMap = new Map<String, String>();
        Map<Id, Boolean> previousAccountMetCriteriaMap = new Map<Id, Boolean>();
        Set<String> fieldsToCheck = new Set<String>{
            'Language__pc',
                'Most_Recent_Inquiry_Date__pc'
                };  
                    if(!DIAL_LIST_METADATA.isEmpty()){
                        for (String name : DIAL_LIST_METADATA.keySet()) {
                            Dial_List_Settings__mdt thisSetting = DIAL_LIST_METADATA.get(name);
                            if(thisSetting != null){
                                if(!String.isBlank(thisSetting.Filter_FIeld__c)){
                                    fieldsToCheck.add(thisSetting.Filter_FIeld__c);
                                }
                                fieldToDialistMap.put(
                                    thisSetting.Language__c +
                                    ';' +
                                    thisSetting.Filter_FIeld__c,
                                    thisSetting.List_ID__c
                                );   
                            }
                        }
                    }
        
        if (oldRecords == null) {
            accountsWithUpdateCriteria = newAccounts;//check if list have required fields filled
        } else {
            accountsWithUpdateCriteria = (List<Account>) Utils.getChangedObjects(
                newAccounts,
                oldRecords,
                fieldsToCheck
            );
        }
        // remove Language after language changes are filtered
        fieldsToCheck.remove('Language__pc');
        fieldsToCheck.remove('Most_Recent_Inquiry_Date__pc');
        
        if (oldRecords != null) {
            if(accountsWithUpdateCriteria.size() > 0){
                for (Account thisAccount : accountsWithUpdateCriteria) {
                    
                    Account previousAccount = oldRecords.get(thisAccount.Id);
                    
                    if(!fieldsToCheck?.isEmpty()){
                        for (String field : fieldsToCheck) {
                            Account accountToUpdate = new Account();
                            accountToUpdate.Id = thisAccount.Id;
                            // run when language is changed, Most recent inquiry date is updated OR when ??
                            Boolean isRemovedFromList = (previousAccount.get(field) == true &&
                                                         thisAccount.get(field) == false);
                            Boolean isAddedToList = (previousAccount.get(field) == false &&
                                                     thisAccount.get(field) == true);
                            Boolean isCurrentlyInList = thisAccount.get(field) == true;
                            Boolean isMostRecentInquiryDateChanged = (previousAccount.Most_Recent_Inquiry_Date__pc !=
                                                                      thisAccount.Most_Recent_Inquiry_Date__pc);
                            Boolean isLanguageChanged = (previousAccount.Language__pc !=
                                                         thisAccount.Language__pc);
                            
                            // remove from list if account no longer meets criteria OR if their languange is changed
                            // if their language is changed, check if they are currently in a list, if so removed the old list
                            if (isRemovedFromList || isLanguageChanged) {
                                String keyValue = previousAccount.Language__pc +';' + field;
                                if(!fieldToDialistMap?.isEmpty() && fieldToDialistMap.containsKey(keyValue)){
                                    accountToUpdate.Delete_from_f9list_id__c = fieldToDialistMap.get(keyValue);
                                }
                                accountToUpdate.Current_Five9_List__c = null;
                            }
                            
                            // Add to list if account is updated to meet criteria OR if their languange is changed
                            // if their language is changed, check if they are currently in a list, if so add to new list
                            // if most recent inquiry date is updated, add again to sync value
                            if (
                                isAddedToList ||
                                (isCurrentlyInList &&
                                 (isLanguageChanged || isMostRecentInquiryDateChanged))
                            ) {
                                String keyValue = thisAccount.Language__pc +';' + field;
                                if(!fieldToDialistMap?.isEmpty() && fieldToDialistMap.containsKey(keyValue)){
                                    accountToUpdate.Add_to_f9list_id__c = fieldToDialistMap.get(keyValue);
                                }
                                accountToUpdate.Current_Five9_List__c = accountToUpdate.Add_to_f9list_id__c;
                            }
                            recordsToUpdate.add(accountToUpdate);
                        }
                    }
                }
            }
        } else {
            if(newAccounts?.size()>0){
                for (Account thisAccount : newAccounts) {
                    Account accountToUpdate = new Account();
                    accountToUpdate.Id = thisAccount.Id;
                    if(fieldsToCheck?.size()>0){
                        for (String field : fieldsToCheck) {
                            if (thisAccount.get(field) == true) {
                                String keyValue = thisAccount.Language__pc +';' + field;
                                if(!fieldToDialistMap?.isEmpty() && fieldToDialistMap.containsKey(keyValue)){
                                    accountToUpdate.Add_to_f9list_id__c = fieldToDialistMap.get(keyValue );
                                }
                                accountToUpdate.Current_Five9_List__c = accountToUpdate.Add_to_f9list_id__c;
                            }
                            recordsToUpdate.add(accountToUpdate); //add DML check
                        }
                    }
                }
            }
        }
        try {
            if(recordsToUpdate?.size()>0){
                update recordsToUpdate;
            }
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getPersonAccountRecordTypeId() {
        try {
            // Query for the Person Account record type ID
            RecordType personAccountRecordType = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount'
                LIMIT 1
            ];
            return personAccountRecordType.Id;
        } catch (Exception e) {
            // Handle the exception
            throw new AuraHandledException('Error retrieving Person Account record type ID: ' + e.getMessage());
        }
    }
    
    private boolean isValidToUpdateAccAccRelation(Account acc, Account oldAcc){
        
        if(acc == null || oldAcc == null){
            return false;
        }
        
        if(acc.Payment_Organization_Eligible__c == false &&
           acc.Payment_Organization_Eligible__c != oldAcc.Payment_Organization_Eligible__c){
               return true;
           }
        
        if(acc.Referral_Agreement_Holder_Eligible__c == false &&
           acc.Referral_Agreement_Holder_Eligible__c != oldAcc.Referral_Agreement_Holder_Eligible__c){
               return true;
           }
        
        return false;
    }
    
    //Method to deactivate relationship based on Payment Agreement and Referral Agreement checkboxes
    public void updateAccountAccountRelationships(List<Account> accounts, Map<Id,Account> oldMap){
        Set<Id> paymentOrgIds = new Set<Id>();
        Set<Id> referralAgreementIds = new Set<Id>();
        
        //filter out liedst of accounts
        for(Account acc : accounts){
            Account oldAcc;
            if(oldMap != null && !oldMap.isEmpty()){
                oldAcc = oldMap.get(acc.Id);
            }
            if(isValidToUpdateAccAccRelation(acc,oldAcc)){
                if(acc.Payment_Organization_Eligible__c == false){
                    paymentOrgIds.add(acc.Id);
                }
                if(acc.Referral_Agreement_Holder_Eligible__c == false){
                    referralAgreementIds.add(acc.Id);
                }
            }
        }
        
        if(!paymentOrgIds.isEmpty() || !referralAgreementIds.isEmpty()){
            //query all related Acc-Acc relationships
            List<FinServ__AccountAccountRelation__c> toDeactivate = new List<FinServ__AccountAccountRelation__c>();
            for(FinServ__AccountAccountRelation__c aaRelation : [SELECT Id, FinServ__Active__c,
                                                                 Referral_Holder_or_Payment_Eligible__r.Payment_Organization_Eligible__c,
                                                                 Referral_Holder_or_Payment_Eligible__r.Referral_Agreement_Holder_Eligible__c
                                                                 FROM FinServ__AccountAccountRelation__c 
                                                                 WHERE FinServ__Active__c = true
                                                                 AND ((Referral_Holder_or_Payment_Eligible__c IN :referralAgreementIds
                                                                       AND FinServ__Role__r.Name = :ROLE_REFERRAL_AGREEMENT)
                                                                      OR (Referral_Holder_or_Payment_Eligible__c IN :paymentOrgIds
                                                                          AND FinServ__Role__r.Name = :ROLE_PAYMENT_AGREEMENT))]){
                                                                              //deactivate
                                                                              aaRelation.FinServ__Active__c = false;
                                                                              toDeactivate.add(aaRelation);
                                                                          }
            
            if(!toDeactivate.isEmpty()){
                update toDeactivate;
            }
        }
    }
    
    //method to update ownerid based on the territory user id
    public void updateAccountOwnerOnTerritoryAssignment(List<Account> accounts, Map<Id,Account> oldMap){
        // List to hold accounts to update
        List<Account> accountsToUpdate = new List<Account>();
        
        // Set to collect Account IDs for querying territory assignments
        Set<Id> accountIds = new Set<Id>();
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        // Collect the account IDs of the Partner Organizations or person contact being inserted
        for (Account acc : accounts) {
            if ((acc.RecordTypeId ==personAccountRecordTypeId) || (acc.PersonContactId!=null)) {
                accountIds.add(acc.Id);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }
        
        // Query to get the associated user from AccountUserTerritory2View
        List<AccountUserTerritory2View> userTerritories = [SELECT AccountId, UserId FROM AccountUserTerritory2View WHERE AccountId IN :accountIds];
        
        //check if more than 2 users are present in territory
        if (userTerritories.size()>1) {
            return;
        }
        if (!userTerritories.isEmpty()) {
            Id newOwnerId = userTerritories[0].UserId;
            for (Account acc : accounts) {
                Account updatedAccount = new Account(Id = acc.Id); // Only set the Id here
                updatedAccount.OwnerId = newOwnerId; // Set the new OwnerId
                
                // Add to the list of accounts to update
                accountsToUpdate.add(updatedAccount);
            }
            
            // Perform the update if there are accounts to update
            if (!accountsToUpdate.isEmpty()) 
            {
                try {
                    update accountsToUpdate; // Update the new instances of accounts
                } catch (DmlException e) {
                    // Handle the exception as necessary
                    System.debug('Error updating accounts: ' + e.getMessage());
                }
            }
        }
    }
    
    /*
*   Notify Consent to update MARS.
*/
    public void addAccountMarsPlatformEvent(List<Account> records, Map<Id, Account> oldRecords) { 
        if(System.isBatch())
            return;
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Account.fieldSets.MARS_Consent_Update.getFields());
        List<Account> acctList = Utils.getChangedObjects(records,oldRecords,fieldsToCheck);
        if (acctList.isEmpty())
            return; 
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Account A : acctList){
            requests.add( new MARSPlatformEventService.Request(A,MARSPlatformEventService.CONSENT_SYNC,MARSPlatformEventService.ACTION_UPDATE,MARSPlatformEventService.CONSENT_SYNC));
        }  
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
    }
    
    private boolean isValidToCopyAddress(Account acc, Account oldAcc){
        if(acc == null){
            return false;
        }
        
        if(oldAcc == null && 
           !isEmptyAddress('PersonMailing',acc)){
               return true;
           }
        
        if(oldAcc != null && 
           !isEmptyAddress('PersonMailing',acc) &&
           !compareAddress('PersonMailing',acc,oldAcc) &&
           isEmptyAddress('billing',acc)){
               return true;
           }
        
        return false;
    }
    
    private boolean isEmptyAddress(String addressPrefix, Account acc){
        if(acc.get(addressPrefix+'City') != null ||
           acc.get(addressPrefix+'PostalCode') != null ||
           acc.get(addressPrefix+'State') != null ||
           acc.get(addressPrefix+'Street') != null){
               return false;
           }
        return true;
    }
    
    private boolean compareAddress(String addressPrefix, Account acc, Account toCompareAcc){
        if(acc.get(addressPrefix+'City') != toCompareAcc.get(addressPrefix+'City') ||
           acc.get(addressPrefix+'Country') != toCompareAcc.get(addressPrefix+'Country') ||
           acc.get(addressPrefix+'PostalCode') != toCompareAcc.get(addressPrefix+'PostalCode') ||
           acc.get(addressPrefix+'State') != toCompareAcc.get(addressPrefix+'State') ||
           acc.get(addressPrefix+'Street') != toCompareAcc.get(addressPrefix+'Street')){
               return false;
           }
        return true;
    }
    
    public void copyMailingAddress(List<Account> records, Map<Id, Account> oldRecords){
        List<Account> validAccounts = new List<Account>();
        for(Account acc : records){
            Account oldacc;
            if(oldRecords != null){
                oldacc = oldRecords.get(acc.Id);
            }
            if(isValidToCopyAddress(acc,oldacc)){
                validAccounts.add(acc);
            }
        }
        if(!validAccounts.isEmpty()){
            for(Account acc : validAccounts){
                acc.BillingCity = acc.PersonMailingCity;
                acc.BillingCountry = acc.PersonMailingCountry;
                acc.BillingPostalCode = acc.PersonMailingPostalCode;
                acc.BillingState = acc.PersonMailingState;
                acc.BillingStreet = acc.PersonMailingStreet;
            }
        }
    }
    
    /*Method to update Dealer Code and Rep Code on Partner Records from Related Partner Organization*/
    public void updateCodes(List<Account> accounts, Map<Id,Account> oldMap){
        if (AccountService.runOnce) {
            Map<Id, Account> accountIdMap = new Map<Id, Account>();
            List<Account> updateList = new List<Account>();
            Set<Account> updateSet = new Set<Account>();
            for(Account accRec : accounts) {
                if(accRec.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId()) {
                    accountIdMap.put(accRec.Id, accRec);
                }
            }
            if(!accountIdMap.isEmpty()){
                for(AccountContactRelation acr: [Select Id, AccountId, Contact.AccountId  From AccountContactRelation Where AccountId In : accountIdMap.keySet()]){
                    Account acc = new Account(Id = acr.Contact.AccountId);
                    acc.Dealer_Code__c = accountIdMap.get(acr.AccountId).Dealer_Code__c;
                    acc.Rep_Code__c = accountIdMap.get(acr.AccountId).Rep_Code__c;
                    updateSet.add(acc);
                }
                //to avoid duplicate ids
                updateList.addAll(updateSet);
                update updateList;
                AccountService.runOnce = false;
            }
        }
    }
}