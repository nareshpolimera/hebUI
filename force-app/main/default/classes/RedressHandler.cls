public class RedressHandler {
 public RedressHandler(List<Redress__c> records)
    {
        init(records);
    }
    public void beforeUpdate(List<Redress__c> records, Map<Id, Redress__c> oldRecords)
    {
        new RedressDomain().beforeUpdate(records, oldRecords);
    }

    public void beforeInsert(List<Redress__c> records)
    {
        new RedressDomain().beforeInsert(records);
    }
    public void afterUpdate(List<Redress__c> records, Map<Id, Redress__c> oldRecords)
    {
        new RedressDomain().afterUpdate(records, oldRecords);
    }

    public void afterInsert(List<Redress__c> records)
    {
        new RedressDomain().afterInsert(records);
    }
    
   public void afterDelete(List<Redress__c> records)
    {
        new RedressDomain().afterDelete(records);
    }
    
    private void init(List<Redress__c> records)
        
    {
    }
    
    
    
}