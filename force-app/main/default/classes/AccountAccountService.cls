/******************************************************/ /**
@Class      AccountAccountService
@brief      Class with especific-related methods to the FinServ__AccountAccountRelation__c object.

@revision   2024-06-13 Azadeh Ahmadi
            Porting from legacy SF org.
/******************************************************/
public without sharing class AccountAccountService {
    public static Boolean updateReferralPartner = false;
    public void updateReferralPartnerPlatformEvent(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
    ) {
    Set<String> fieldsToCheck = Utils.getFieldSetFields(
        Schema.SObjectType.FinServ__AccountAccountRelation__c.fieldSets.Referral_Partner_Update_MARS.getFields()
    );
    List<FinServ__AccountAccountRelation__c> accs = new List<FinServ__AccountAccountRelation__c>();
    String actionText = '';
    if (oldRecords == null) {
        accs = records;
        actionText = MARSPlatformEventService.ACTION_INSERT;
    } else {
        accs = (List<FinServ__AccountAccountRelation__c>) Utils.getChangedObjects(
        records,
        oldRecords,
        fieldsToCheck
        );
        actionText = MARSPlatformEventService.ACTION_UPDATE;
    }
    if (accs.isEmpty())
        return;
    List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
    for (FinServ__AccountAccountRelation__c acc : accs)
        requests.add(
        new MARSPlatformEventService.Request(
            acc,
            MARSPlatformEventService.UPDATED_ACCOUNT,
            actionText,
            MARSPlatformEventService.UPDATED_ACCOUNT
        )
        );

    Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
    AccountAccountService.updateReferralPartner = !(errorOccurred);
    }

    public void deactivatePreviousRecords(List<FinServ__AccountAccountRelation__c> records, Map<Id, FinServ__AccountAccountRelation__c> oldRecords) {
        Set<Id> accountList = new Set<Id>();
        Set<Id> activeList = new Set<Id>();
        Set<Id> roleList = new Set<Id>();
        Set<String> keysToCheck = new Set<String>();
        List<FinServ__AccountAccountRelation__c> recordsToDiactivate = new List<FinServ__AccountAccountRelation__c>();
        
        for (FinServ__AccountAccountRelation__c currentRecord : records) {  
            if(currentRecord.FinServ__Active__c){
                accountList.add(currentRecord.FinServ__Account__c);
                activeList.add(currentRecord.Id);
                roleList.add(currentRecord.FinServ__Role__c);
                keysToCheck.add(currentRecord.FinServ__Account__c + '_' +currentRecord.FinServ__Role__c);
            }
        }

        for(FinServ__AccountAccountRelation__c AccAccRecord : [SELECT Id, FinServ__Active__c, 
                                                                FinServ__Account__c, 
                                                                FinServ__Role__c 
                                                            FROM FinServ__AccountAccountRelation__c 
                                                            WHERE FinServ__Active__c = true
                                                            AND FinServ__Account__c != null
                                                            AND FinServ__Account__c IN :accountList
                                                            AND Id Not in :activeList
                                                            AND FinServ__Role__c IN :roleList]){
            String key = AccAccRecord.FinServ__Account__c + '_' +AccAccRecord.FinServ__Role__c;
            if(keysToCheck.contains(key)){
                AccAccRecord.FinServ__Active__c = false;
                recordsToDiactivate.add(AccAccRecord);
            }
        }

        if(!recordsToDiactivate.isEmpty()){
            update recordsToDiactivate;
        }
    }
}