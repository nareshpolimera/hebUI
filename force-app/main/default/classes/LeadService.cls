/******************************************************/ /**
@Class      LeadService
@brief      Class with especific-related methods to the Lead object.

@revision   2024-04-20 Diego Guerrero
Porting from legacy SF org.
2024-06-05 Juan Contreras
Porting from LeadTrigger on legacy SF org.
/******************************************************/
public without sharing class LeadService {
    /*
*   Notify Consent to update MARS.
*/
    public void addLeadMarsPlatformEvent(List<Lead> records, Map<Id, Lead> oldRecords) { 
        if(System.isBatch())
            return;
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Lead.fieldSets.Lead_MARS_Consent_Update.getFields());
        List<Lead> leadList = Utils.getChangedObjects(records,oldRecords,fieldsToCheck); 
        if (leadList.isEmpty())
            return; 
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Lead A : leadList){
            requests.add( new MARSPlatformEventService.Request(A,MARSPlatformEventService.CONSENT_SYNC,MARSPlatformEventService.ACTION_UPDATE,MARSPlatformEventService.CONSENT_SYNC));
        }  
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
    }
}