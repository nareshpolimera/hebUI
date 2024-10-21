/******************************************************/ /**
@Class      IndividualService
@brief      Class with especific-related methods to the Individual object.

@revision   2024-07-22 Suvarna Hawalppagol
Porting from legacy SF org.
@revision 202408-12 Adriano Silva
Added new method addIndividualMarsPlatformEvent
/******************************************************/
public class IndividualService {
     /*
* HEB-: Updates the Name on ContactPointTypeConsent with Individual First and Last Name on update
*/   
	public void updateContactTypePointConsentName(List<Individual>individualist, Map<id,Individual>oldmap) {    
        List<ContactPointTypeConsent> updateContactTPC = new List<ContactPointTypeConsent>(); 
        Map<id, Individual> indToctpcMap = new Map<id, Individual>();
        
        for(Individual ind : individualist){
            if(ind.LastName != oldmap.get(ind.id).LastName ||ind.FirstName != oldmap.get(ind.id).FirstName){
                indToctpcMap.put(ind.id, ind);
            }
        }
        if(!indToctpcMap.isEmpty()){
        List<ContactPointTypeConsent> ctpclist = new List<ContactPointTypeConsent>([SELECT id, name, PartyId FROM ContactPointTypeConsent WHERE PartyId =:indToctpcMap.keyset()
                                                                                 ]);
        
            for(ContactPointTypeConsent cc : ctpclist){
                cc.name = 'Consent - ' +' ' +indToctpcMap.get(cc.PartyId).FirstName + ' '+ indToctpcMap.get(cc.PartyId).LastName;
                updateContactTPC.add(cc);
            }
        }
        if(!updateContactTPC.isEmpty()){
            update updateContactTPC;
        }
    }

    public void addIndividualMarsPlatformEvent(List<Individual> records, Map<Id, Individual> oldRecords, String operation) {
		List<Individual> inds;
        if(operation == MARSPlatformEventService.ACTION_UPDATE){
            Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Individual.fieldSets.Individual_Update_MARS.getFields());
            inds = (List<Individual>) Utils.getChangedObjects(records,oldRecords,fieldsToCheck);
            if (inds.isEmpty())
                return;
        }else if(operation == MARSPlatformEventService.ACTION_INSERT){
            inds = records;
        }else{
            return;
        }
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Individual ind : inds){
            requests.add( new MARSPlatformEventService.Request(ind,MARSPlatformEventService.CONSENT_SYNC,operation,MARSPlatformEventService.CONSENT_SYNC));
        }
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
    }
}