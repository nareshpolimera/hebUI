public class AccountContactRelationHandler {
    
    public void afterInsert(List<AccountContactRelation> records)
    {
        new AccountContactRelationDomain().afterInsert(records);        
    }
    
    public void afterUpdate(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldRecords)
    {
        new AccountContactRelationDomain().afterUpdate(records,oldRecords);
    }
    
}