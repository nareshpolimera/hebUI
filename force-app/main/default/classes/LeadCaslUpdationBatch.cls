/*-----------------------------------------------------------------------------------
      @description       : batch is used to update CASL_Consent__c on Lead to expired
      @last modified on  : 07-09-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-09-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
public class LeadCaslUpdationBatch implements Database.Batchable<sObject>{
    String query = 'SELECT id,Name,CASL_Consent__c,HasOptedOutOfEmail  from Lead where CASL_Consent__c = \'Implied\' and CreatedDate <= N_DAYS_AGO:180';
    
    public Database.QueryLocator start(Database.BatchableContext BC){  
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Lead> scope){
        list<Lead> leadList = new list<Lead>(); 
        for(Lead lead : scope){ 
                lead.CASL_Consent__c = 'Expired';
            	lead.HasOptedOutOfEmail = true;
                leadList.add(lead); 
        }
        if(leadList!=null && !leadList.isEmpty()){
            update leadList; 
            syncConsentToMarsPlatformEvent(leadList);
        }
    } 
    public void finish(Database.BatchableContext BC){}
     public void syncConsentToMarsPlatformEvent(List<Lead> records) {   
        Map<Id, Lead> pmLead = new Map<Id, Lead>();
        for (Lead pm : records) { 
            pmLead.put(pm.Id, pm);         
 		}
         if (pmLead.isEmpty())
            return; 
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Lead pm : pmLead.values()){ 
            requests.add( new MARSPlatformEventService.Request( pm, MARSPlatformEventService.CONSENT_SYNC, MARSPlatformEventService.ACTION_UPDATE,MARSPlatformEventService.CONSENT_SYNC  ) );
        } 
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests); 
    } 
     
}