public class AccountContactRelationDomain {
    
    private AccountContactRelationService service = new AccountContactRelationService();
    
    public void afterInsert(List<AccountContactRelation> records)
    {
       service.setCurrentOrganization(records, null);
    }
        
    public void afterUpdate(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldRecords)
    {
    }
}