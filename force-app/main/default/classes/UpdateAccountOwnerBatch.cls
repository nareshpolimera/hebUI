public class UpdateAccountOwnerBatch implements Database.Batchable<sObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query to fetch all accounts that may need owner updates
        return Database.getQueryLocator([
            SELECT Id, RecordTypeId, PersonContactId,OwnerId 
            FROM Account 
            WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId() 
            OR PersonContactId != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Fetch old data to be passed as the oldMap parameter
        Map<Id, Account> oldMap = new Map<Id, Account>([SELECT Id, RecordTypeId, PersonContactId FROM Account WHERE Id IN :scope]);
        
        // Call your existing method to update the account owner based on territory assignment
       updateAccountOwnerOnTerritoryAssignment(scope, oldMap);
      	// system.debug('scopedata'+scope);
        //AccountService service = new AccountService();
       // service.updateAccountOwnerOnTerritoryAssignment(scope,null);
    }

    public void finish(Database.BatchableContext bc) {
       
        System.debug('Batch process completed.');
    }

    public void updateAccountOwnerOnTerritoryAssignment(List<Account> accounts, Map<Id, Account> oldMap) {
        // List to hold accounts to update
        List<Account> accountsToUpdate = new List<Account>();

        // Set to collect Account IDs for querying territory assignments
        Set<Id> accountIds = new Set<Id>();
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();

        // Collect the account IDs of the Partner Organizations or person contact being inserted
        for (Account acc : accounts) {
            if ((acc.RecordTypeId == personAccountRecordTypeId) || (acc.PersonContactId != null)) {
                accountIds.add(acc.Id);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }

        // Query to get the associated user from AccountUserTerritory2View
        List<AccountUserTerritory2View> userTerritories = [SELECT AccountId, UserId FROM AccountUserTerritory2View WHERE AccountId IN :accountIds];
        map<Id,AccountUserTerritory2View> userTerritoriesMap = new map<Id,AccountUserTerritory2View>();
        for(AccountUserTerritory2View au : userTerritories){
            if(!userTerritoriesMap.containsKey(au.AccountId)){
            userTerritoriesMap.put(au.AccountId,au);
            }
            else{
                userTerritoriesMap.remove(au.AccountId);
            }
        }
 
        if (!userTerritoriesMap.isEmpty()) {
            //Id newOwnerId = userTerritories[0].UserId;
            for (Account acc : accounts) {
                Account updatedAccount = new Account(Id = acc.Id); // Only set the Id here
                if(userTerritoriesMap.containsKey(acc.Id) && userTerritoriesMap.get(acc.Id).UserId != null){
                    updatedAccount.OwnerId = userTerritoriesMap.get(acc.Id).UserId;
                }
                //updatedAccount.OwnerId = newOwnerId; // Set the new OwnerId

                // Add to the list of accounts to update
                accountsToUpdate.add(updatedAccount);
            }

            // Perform the update if there are accounts to update
            if (!accountsToUpdate.isEmpty()) {
                try {
                    update accountsToUpdate; // Update the new instances of accounts
                } catch (DmlException e) {
                    // Handle the exception as necessary
                    System.debug('Error updating accounts: ' + e.getMessage());
                }
            }
        }
    }
    
    public void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new UpdateAccountOwnerBatch(), 200); 
    }
}