/********************************************************
@Class      ContactHandler
@brief      Handler class for trigger of the Contact object.

@revision   2024-05-09 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class ContactHandler
{
    public static final String CONTACT_RT_BUSINESS = 'IndustriesBusiness';
    public static final String CONTACT_RT_INDIVIDUAL = 'IndustriesIndividual';
    
    List<Contact> partners = new List<Contact>();
    
    public ContactHandler(List<Contact> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<Contact> records)
    {
        new ContactDomain().beforeInsert(records);
        
        if (!partners.isEmpty())
        {
            new ContactDomain.PartnerDomain().beforeInsert(partners);
        }
    }

    public void beforeUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
    {
        new ContactDomain().beforeUpdate(records, oldRecords);

        if(!partners.isEmpty()) 
        {
            new ContactDomain.PartnerDomain().beforeUpdate(partners, oldRecords);
        }
    }

    public void afterUpdate(List<Contact> records, Map<Id, Contact> oldRecords)
    {
        new ContactDomain().afterUpdate(records, oldRecords);
        
        if (!partners.isEmpty())
        {
            new ContactDomain.PartnerDomain().afterUpdate(partners, oldRecords);
        }
    }
    
    private void init(List<Contact> records)
    {
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Contact.sObjectType);
        
        for (Contact record : records)
        {
            //Joel Ojeda - TODO:  validate Contact RecordTypes
            if(rtIDs.get(CONTACT_RT_BUSINESS) == record.recordTypeId)
            {
                partners.add(record);
            }
        }
    }
}