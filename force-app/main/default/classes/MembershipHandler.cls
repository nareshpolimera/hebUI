public class MembershipHandler {

    public MembershipHandler(List<Membership__c> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<Membership__c> records)
    {
        new MembershipDomain().beforeInsert(records);
    }

    public void beforeUpdate(List<Membership__c> records, Map<Id, Membership__c> oldMap)
    {
        new MembershipDomain().beforeUpdate(records, oldMap);
    }

    public void afterInsert(List<Membership__c> records, Map<Id, Membership__c> newMap)
    {
        new MembershipDomain().afterInsert(records, newMap);
    }
    
    private void init(List<Membership__c> records)
    {
    }

}