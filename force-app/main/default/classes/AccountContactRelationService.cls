public class AccountContactRelationService {

    
    public void setCurrentOrganization(
        List<AccountContactRelation> records, 
        Map<Id, AccountContactRelation> oldRecords){
        
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> contactIds = new Set<Id>();
        List<AccountContactRelation> createdOrUpdatedRelations = new List<AccountContactRelation>();
            
        if (oldRecords != null) {
            Set<String> fieldsToCheck = new Set<String>{ 'is_Direct__c' };
                createdOrUpdatedRelations = (List<AccountContactRelation>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
        } else {
            createdOrUpdatedRelations = records;
        }    
            
            if(!createdOrUpdatedRelations.isEmpty()){
                for(AccountContactRelation relation : createdOrUpdatedRelations){
                    if(relation.is_Direct__c)
                    	ContactIds.add(relation.ContactId);
                }
                accountsToUpdate = [SELECT id, PersonContactId, CurrentOrganization__c FROM Account WHERE PersonContactId In :ContactIds];
            }
            
            if(!accountsToUpdate.isEmpty()){
                for(AccountContactRelation relation : createdOrUpdatedRelations){
                    for(Account acc : accountsToUpdate){
                      if(relation.contactId == acc.PersonContactId &&
                         acc.CurrentOrganization__c != relation.AccountId){
                          acc.CurrentOrganization__c = relation.AccountId;
                      }
                    }
                }
                try{
                    update accountsToUpdate;
                }catch(DMLException ex){
                    system.debug(ex.getMessage());
                }
            }
    }
}