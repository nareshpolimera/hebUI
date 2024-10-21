/********************************************************
@Class      ContactService
@brief      Service class for trigger of the Contact object.

@revision   2024-05-09 Joel Ojeda
Porting from legacy SF org.
/******************************************************/
public without sharing class ContactService {
    /** HEB-519: Notify to update MARS.*/
    public static Boolean updateReferralPartner = false;
    public void updateReferralPartnerPlatformEvent(List<Contact> records,Map<Id, Contact> oldRecords) {
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Contact.fieldSets.Referral_Partner_Update_MARS.getFields());
        List<Contact> cons = (List<Contact>) Utils.getChangedObjects(records,oldRecords,fieldsToCheck);       
        
        if (cons.isEmpty())
            return;
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Contact con : cons)
            requests.add(new MARSPlatformEventService.Request(con,
                                                              MARSPlatformEventService.UPDATED_CONTACT,
                                                              MARSPlatformEventService.ACTION_UPDATE,
                                                              MARSPlatformEventService.UPDATED_CONTACT));        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        ContactService.updateReferralPartner = !(errorOccurred);
    }
    
    /** HEB-xxx: New Contact - Set Verify_Email__c to true if Email field has value.*/
    public void intialVerifyEmail(List<Contact> records) {
        List<Contact> conToAdd = new List<Contact>();
        for (Contact partner : records) {
            if (partner.email != null) {
                partner.verify_email__c = true;
            }
            contoAdd.add(partner);
        }
    }    
    /** HEB-xxx: Update Contact - Set Verify_Email__c to true if Email is Changed.*/
    public void updateVerifyEmail(List<Contact> records,Map<Id, Contact> oldRecords){
        List<Contact> conToUpdate = new List<Contact>();
        for (Contact c : records) {
            Contact oc = oldRecords.get(c.Id);
            if (c.Email != null && c.Email != oc.Email) {
                c.Email_Verification_Status__c = null;
                c.Email_Verification_Result__c = null;
                c.Verify_Email__c = true;
            }
            conToUpdate.add(c);
        }
    }   

    
    /** HEB-402: set the Numeric Phone field based on the Phone*/
    public void setNumericPhone(List<Contact> records,Map<Id, Contact> oldRecords){
        for (Contact l : records) {
            if (l.Phone != null && (oldRecords == null || oldRecords.get(l.Id).Phone <> l.Phone)) {
                String numericPhone = l.Phone;
                numericPhone = numericPhone.replace('(', '');
                numericPhone = numericPhone.replace(')', '');
                numericPhone = numericPhone.replace(' ', '');
                numericPhone = numericPhone.replace('-', '');
                l.Phone = numericPhone;
            }
        }
    }    
    /** HEB-402: set the Numeric Phone field based on the Phone*/
    public void setAreaCode(List<Contact> records,Map<Id, Contact> oldRecords){
        for (Contact l : records) {
            if (l.Phone != null && (oldRecords == null || oldRecords.get(l.Id).Phone <> l.Phone)) {
                if (l.Phone.length() <= 10) {
                    l.Area_Code__c = l.Phone.left(3);
                } else {
                    l.Area_Code__c = l.Phone.substring(1, 4);
                }
            }
        }
    }   
    /** Validate Phone Number when Number is new or the number is changed*/
    public void generateListofChangedPhone(List<Contact> records,Map<Id, Contact> oldRecords){
        if (Utils.isIntegrationUser())
            return;
        List<Id> lid = new List<Id>();
        if (oldRecords != null) {
            Set<String> fieldsToCheck = new Set<String>{ 'Phone' };               
                List<Contact> ls = (List<Contact>) Utils.getChangedObjects(records,oldRecords,fieldsToCheck);            
            for (Contact contact : ls) {
                if (contact.Phone == null || String.isBlank(contact.Phone)) {
                    contact.Phone_Verification_Status__c = 'Invalid'; // Treat Blank phone number is an Invalid Number to simplify downstream process
                    contact.Phone_Verification_Line_Type__c = null;
                    contact.Phone_Verification_Timestamp__c = null;
                    contact.SMS_Address__c = null;
                } else {                    
                    contact.Phone_Verification_Status__c = 'Pending';
                    contact.Phone_Verification_Line_Type__c = 'Unknown';
                    contact.Phone_Verification_Timestamp__c = null;
                    contact.SMS_Address__c = null;
                    lid.add(contact.id);                    
                }
            }
        } else {
            //Contacts inserting and New phone number hasn't been validated
            for (Contact contact : records) {
                if (contact.Phone != null && String.isNotBlank(contact.Phone) && contact.Phone_Verification_Timestamp__c == null) {
                    lid.add(contact.id);
                }
            }
        }       
        if (!lid.isEmpty()) {
            validatePhoneNumber(lid);
        }
    }    
    /** Call Phone Validation Services*/
    @future(callout=true)
    public static void validatePhoneNumber(List<Id> lid) {
        List<ModelPhoneValidation.Phone> pl = new List<ModelPhoneValidation.Phone>();
        List<ModelPhoneValidation.PhoneInfo> lpi = new List<ModelPhoneValidation.PhoneInfo>();
        List<Contact> listLd = [SELECT Id,Phone,Phone_Verification_Line_Type__c,Phone_Verification_Status__c,Phone_Verification_Timestamp__c,SMS_Address__c FROM Contact WHERE Id IN :lid];
        
        for (Contact l : listLd) {            
            ModelPhoneValidation.Phone p = new ModelPhoneValidation.Phone();
            p.Id = String.valueOf(l.Id);
            p.PhoneNumber = l.Phone;
            pl.add(p);            
        }
        
        Map<Id, Contact> ldm = new Map<Id, Contact>(listLd);        
        if (!Test.isRunningTest()) {
            String res = PhoneValidationService.sendRequest(pl);            
            lpi = PhoneValidationService.processResponse(res);
        }
        
        if (!lpi.isEmpty()) {
            for (ModelPhoneValidation.PhoneInfo pi : lpi) {
                Id ldId = Id.valueOf(pi.Id);
                Contact l = ldm.get(ldid);
                l.Phone_Verification_Line_Type__c = pi.lineType;
                l.Phone_Verification_Timestamp__c = pi.validatedOn;
                l.Phone_Verification_Status__c = pi.status;
                l.SMS_Address__c = pi.SMSAddress;
                ldm.put(l.Id, l);
            }
            List<Contact> contlist = ldm.values();
            update contlist;
        }
    }
    
    public void updateUnvalidatedNewPhoneNumberStatus(List<Contact> records) {
        if (Utils.isIntegrationUser())
            return;
        ModelPhoneValidation.Phone p = new ModelPhoneValidation.Phone();
        //Contacts inserting and New phone number hasn't been validated
        for (Contact contact : records) {
            if (contact.Phone_Verification_Timestamp__c == null) {
                contact.Phone_Verification_Status__c = 'Pending';
            }
        }
    }
    /** HEB-596: Only currently active user can be set to CASL consent*/
    public void checkCASLConsentUser(List<Contact> records,Map<Id, Contact> oldRecords){
        if (Utils.allowBypassForUser())
            return;        
        for (Contact pc : records) {
            if (pc.CASL_Consent_Obtained_By__c <> UserInfo.getUserId() &&pc.Email <> null &&pc.Email <> ''){
                // If this is an update check if the user is trying to change the consent field.
                if (oldRecords == null ||(pc.CASL_Consent_Obtained_By__c <>oldRecords.get(pc.Id).CASL_Consent_Obtained_By__c)){
                    pc.addError(Label.Error_Only_Active_CASL_User_Can_Conset);
                }
            }
        }
    }    
    public void syncConsentToMarsPlatformEvent(List<Contact> records,Map<Id, Contact> oldRecords){
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Contact.fieldSets.Contact_Consent.getFields());
        List<Contact> pms = (List<Contact>) Utils.getChangedObjects(records,oldRecords, fieldsToCheck);
        Map<Id, Contact> pmAccts = new Map<Id, Contact>();        
        for (Contact pm : pms) {
            if (pm.AccountId <> null) {
                pmAccts.put(pm.AccountId, pm);
            }
        }      
        if (pmAccts.isEmpty())
            return;        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Contact pm : pmAccts.values())
            requests.add(new MARSPlatformEventService.Request(pm,'Sync Contact Consent',
                                                              MARSPlatformEventService.ACTION_UPDATE,
                                                              MARSPlatformEventService.SYNC_PROPERTY_MEMBER_CONSENT
                                                             )
                        );
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(
            requests
        );
        PropertyMemberService.syncFromPersonAccount = !(errorOccurred);
    }
}