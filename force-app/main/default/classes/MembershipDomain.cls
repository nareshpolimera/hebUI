public class MembershipDomain {

    private MembershipService service = new MembershipService();
    
    public void beforeInsert(List<Membership__c> records)
    {
        service.setOwner(records);
        
    }    
    
    public void beforeUpdate(List<Membership__c> records, Map<Id, Membership__c> oldRecords)
    {
        
    }    
    
    public void afterInsert(List<Membership__c> records, Map<Id, Membership__c> newMap)
    {
        
    }

}