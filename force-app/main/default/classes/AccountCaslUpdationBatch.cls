/*-----------------------------------------------------------------------------------
@description       : batch is used to update CASL_Consent__c on Account to expired
@last modified on  : 07-09-2024
Modifications Log 
-----------------------------------------------------------------------------------
Ver   Date         Author                               Modification
1.0   07-09-2024   Anurag Gupta                          Initial Version
-----------------------------------------------------------------------------------
*/
public class AccountCaslUpdationBatch implements Database.Batchable<sObject>{
    String query = 'SELECT id,CASL_Consent__c,PersonHasOptedOutOfEmail  from Account where CASL_Consent__c = \'Implied\' and CreatedDate <= N_DAYS_AGO:180';
    
    public Database.QueryLocator start(Database.BatchableContext BC){  
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Account> scope){
        list<Account> accountList = new list<Account>(); 
        for(Account a : scope){ 
            a.CASL_Consent__c = 'Expired';
            a.PersonHasOptedOutOfEmail = true;
            accountList.add(a); 
        }
        if(accountList!=null && !accountList.isEmpty()){
            update accountList;
            syncConsentToMarsPlatformEvent(accountList);
        }
    } 
    public void finish(Database.BatchableContext BC){}
    public void syncConsentToMarsPlatformEvent(List<Account> records) {   
        Map<Id, Account> pmAccts = new Map<Id, Account>();
        for (Account pm : records) { 
            pmAccts.put(pm.Id, pm);         
 		}
         if (pmAccts.isEmpty())
            return; 
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Account pm : pmAccts.values()){ 
            requests.add( new MARSPlatformEventService.Request( pm, MARSPlatformEventService.CONSENT_SYNC, MARSPlatformEventService.ACTION_UPDATE,MARSPlatformEventService.CONSENT_SYNC  ) );
        } 
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests); 
    } 
}