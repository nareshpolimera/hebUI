/********************************************************
@Class      ContactDomain
@brief      Domain class for trigger of the Contact object.

@revision   2024-05-09 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class ContactDomain
{
    private ContactService service = new ContactService();
    
    public void beforeInsert(List<Contact> records)
    {
        service.intialVerifyEmail(records); 
    }
    
    public void beforeUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
    {        
        service.updateVerifyEmail(records,oldRecords);
    }
    
    public void afterUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
    {
    }
    
    public class PartnerDomain
    {
        private ContactService service = new ContactService();
        
        public void beforeInsert(List<Contact> records)
        {
            service.setNumericPhone(records, null);
            service.setAreaCode(records, null);
            service.generateListofChangedPhone(records, null);
        }
        
        public void beforeUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
        {
            service.setNumericPhone(records, oldRecords);
            service.setAreaCode(records, oldRecords);
        }        
        
        public void afterUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
        {
            
            service.updateReferralPartnerPlatformEvent(records, oldRecords);
        }
    }
}