public class LoanApplicationAssetService {
    
 public void setOwner(List<LoanApplicationAsset> records) {
    List<Id> loanApplicationIds = new List<Id>();
    Map<Id, LoanApplicationAsset> assetMap = new Map<Id, LoanApplicationAsset>();

    // Collect the LoanApplicationIds from LoanApplicationAsset records
    for (LoanApplicationAsset asset : records) {
        if (asset.LoanApplicationId != null) {
            loanApplicationIds.add(asset.LoanApplicationId);
            assetMap.put(asset.LoanApplicationId, asset);
        }
    }

    if (loanApplicationIds.isEmpty()) {
        return;
    }

    // Query ResidentialLoanApplication records using the LoanApplicationIds
    Map<Id, ResidentialLoanApplication> loanAppMap = new Map<Id, ResidentialLoanApplication>(
        [SELECT Id, AccountId, OpportunityId FROM ResidentialLoanApplication WHERE Id IN :loanApplicationIds]
    );

    // Collect AccountIds for accounts with no OpportunityId
    Set<Id> accountIds = new Set<Id>();
    for (ResidentialLoanApplication loanApp : loanAppMap.values()) {
        if (loanApp.OpportunityId == null && loanApp.AccountId != null) {
            accountIds.add(loanApp.AccountId);
        }
    }

    // Query Account records to get PersonContactIds
    Map<Id, Id> accountToPersonContactIdMap = new Map<Id, Id>();
    if (!accountIds.isEmpty()) {
        for (Account account : [
            SELECT Id, PersonContactId 
            FROM Account 
            WHERE Id IN :accountIds
        ]) {
            if (account.PersonContactId != null) {
                accountToPersonContactIdMap.put(account.Id, account.PersonContactId);
            }
        }
    }

    // Collect ContactIds from PersonContactIds
    Set<Id> contactIds = new Set<Id>(accountToPersonContactIdMap.values());

    // Query Contact records
    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    if (!contactIds.isEmpty()) {
        for (Contact contact : [
            SELECT Id, OwnerId 
            FROM Contact 
            WHERE Id IN :contactIds
        ]) {
            contactMap.put(contact.Id, contact);
        }
    }

    // Set the OwnerId on LoanApplicationAsset records
    for (LoanApplicationAsset asset : records) {
        ResidentialLoanApplication loanApp = loanAppMap.get(asset.LoanApplicationId);
        if (loanApp != null &&
            loanApp.OpportunityId == null &&
            loanApp.AccountId != null &&
            accountToPersonContactIdMap.containsKey(loanApp.AccountId)) {

            Id personContactId = accountToPersonContactIdMap.get(loanApp.AccountId);
            if (contactMap.containsKey(personContactId)) {
                asset.OwnerId = contactMap.get(personContactId).OwnerId;
            }
        }
    }
}

}