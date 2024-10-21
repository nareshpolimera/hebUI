/******************************************************//**
@Class      AccountContactService
@brief      Class with especific-related methods to the AccountContactRelation object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public without sharing class AccountContactService {
    public static Boolean updateReferralPartner = false;
    public void updateReferralPartnerPlatformEvent(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldRecords)
    {        
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.AccountContactRelation.fieldSets.Referral_Partner_Update_MARS.getFields());
        List<AccountContactRelation> accs = new List<AccountContactRelation>();
        String actionText ='';
        if(oldRecords == null){
            accs = records;
            actionText = MARSPlatformEventService.ACTION_INSERT;
        }
        else{
            accs = (List<AccountContactRelation>) Utils.getChangedObjects(records, oldRecords, fieldsToCheck);
            actionText = MARSPlatformEventService.ACTION_UPDATE;
        }
        if (accs.isEmpty()) return;
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (AccountContactRelation acc : accs)
            requests.add(new MARSPlatformEventService.Request(acc, MARSPlatformEventService.UPDATED_CONTACT, actionText, MARSPlatformEventService.UPDATED_CONTACT));

        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        AccountContactService.updateReferralPartner = !(errorOccurred);
    }
   
}