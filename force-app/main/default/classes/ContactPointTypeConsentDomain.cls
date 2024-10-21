/******************************************************//**
@Class      ContactPointTypeConsentDomain
@brief      Domain class for trigger of the ContactPointTypeConsent object.

@revision   2024-07-22 Suvarna Hawalppagol
            Porting from legacy SF org.
@revision 2024-08-12 Adriano Silva
			Including aftereUpdate and afterInsert
/******************************************************/
public class ContactPointTypeConsentDomain {
    
    private ContactPointTypeConsentService service = new ContactPointTypeConsentService();   
    
    public void beforeInsert(List<ContactPointTypeConsent> records){
        //call method to auto-generate name
        service.generateAutoName(records);
    }
    
     public void afterUpdate(List<ContactPointTypeConsent> records, Map<Id, ContactPointTypeConsent> oldMap){ 
       	service.addConsentTypeMarsPlatformEvent(records, oldMap,MARSPlatformEventService.ACTION_UPDATE);
    }    
    
    
    public void afterInsert(List<ContactPointTypeConsent> records){
       	service.addConsentTypeMarsPlatformEvent(records, null,MARSPlatformEventService.ACTION_INSERT);
    } 
}