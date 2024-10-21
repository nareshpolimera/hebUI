/******************************************************/ /**
@Class      ContactPointTypeConsentService
@brief      Class with especific-related methods to the ContactPointTypeConsent object.

@revision   2024-07-22 Suvarna Hawalppagol
@revision 	2024-08-12 Adriano Silva
			new method addConsentTypeMarsPlatformEvent
/******************************************************/
public without sharing class ContactPointTypeConsentService {
    
    //Method to auto-generate Name
    //Format: CC-00000001
    public void generateAutoName(List<ContactPointTypeConsent> records) {        
        AutomatedNameGenerator.generateNextSequenceName(records, ContactPointTypeConsent.SobjectType);
    }
    
    
    public void addConsentTypeMarsPlatformEvent(List<ContactPointTypeConsent> records, Map<Id, ContactPointTypeConsent> oldRecords, String operation) {
        List<ContactPointTypeConsent> consents;
        Map<Id,String> indiIds = new Map<Id,String>();
        Map<Id,Opportunity> cptIds = new Map<Id,Opportunity>();
        if(operation == MARSPlatformEventService.ACTION_UPDATE){
            Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.ContactPointTypeConsent.fieldSets.Consent_Update_MARS.getFields());
            consents = (List<ContactPointTypeConsent>) Utils.getChangedObjects(records,oldRecords,fieldsToCheck );
            if (consents.isEmpty())
                return;
        }else if(operation == MARSPlatformEventService.ACTION_INSERT){
            consents = records;
        }else{
            return;
        }
        for (ContactPointTypeConsent consent : consents){
        	indiIds.put(consent.id,consent.PartyId);
        } 
        Map<id,Opportunity> oppMap = new Map<id,Opportunity>([Select Id,File_Number__c,Account.PersonIndividualId from Opportunity where Account.PersonIndividualId IN: indiIds.values() and File_Number__c != null]);
        for(Opportunity o : oppMap.values()){
             cptIds.put(o.Account.PersonIndividualId,o);
        } 
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (ContactPointTypeConsent consent : consents){
            if(cptIds.containsKey(consent.PartyId)){
                requests.add(new MARSPlatformEventService.Request(consent,MARSPlatformEventService.CONSENT_SYNC, operation, MARSPlatformEventService.CONSENT_SYNC));
            } 	
        }
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
    }
}