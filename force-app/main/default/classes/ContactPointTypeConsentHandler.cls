/******************************************************//**
@Class      ContactPointTypeConsentHandler
@brief      Handler for trigger for the ContactPointTypeConsent object.

@revision   2024-07-22 Suvarna H
            Porting from legacy SF org.
@revision 2024-08-12 Adriano Silva
			Including aftereUpdate and afterInsert
/******************************************************/
public class ContactPointTypeConsentHandler {
    
    public ContactPointTypeConsentHandler(List<ContactPointTypeConsent> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<ContactPointTypeConsent> records){
        new ContactPointTypeConsentDomain().beforeInsert(records);
    }
    
    public void afterUpdate(List<ContactPointTypeConsent> records, Map<Id, ContactPointTypeConsent> oldRecords){
        new ContactPointTypeConsentDomain().afterUpdate(records, oldRecords);
    }

    public void afterInsert(List<ContactPointTypeConsent> records){
        new ContactPointTypeConsentDomain().afterInsert(records);
    }
    
    private void init(List<ContactPointTypeConsent> records){
    }
}