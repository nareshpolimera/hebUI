/*-----------------------------------------------------------------------------------
      @description       : batch is used to map and convert lead using person account
      @last modified on  : 07-07-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-07-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
public class LeadConversionBatch implements Database.Batchable<sObject>{
    String query = 'SELECT id,Name,FirstName,LastName,Email,IsConverted,PartnerAccountId,FinServ__RelatedAccount__c  from Lead where IsConverted = false and FinServ__RelatedAccount__c = null and email != null';
    
    public Database.QueryLocator start(Database.BatchableContext BC){  
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Lead> scope){
        list<Lead> LeadsToConvert = new list<Lead>(); 
        Map<String,String> leadEmailMap = new Map<String,String>(); 
        Map<String,String> accountEmailMap = new Map<String,String>();
        for(Lead lead : scope){
            leadEmailMap.put((lead.Email).toUpperCase(),String.valueOf(lead.id));
        }
        ID accountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        for(Account acct : [Select id, PersonEmail from Account where PersonEmail IN : leadEmailMap.keyset() and RecordTypeId =: accountRT and PersonEmail != NULL]){
            accountEmailMap.put((acct.PersonEmail).toUpperCase(),String.valueOf(acct.id));
        }
        for(Lead lead : scope){
            if(accountEmailMap.containsKey((lead.Email).toUpperCase())){ 
                lead.FinServ__RelatedAccount__c = accountEmailMap.get((lead.Email).toUpperCase());
                LeadsToConvert.add(lead);
            }
        }
        if(LeadsToConvert!=null && !LeadsToConvert.isEmpty()){
            update LeadsToConvert;
            convertLeads(LeadsToConvert);
        }
    }
    
    
    
    public void finish(Database.BatchableContext BC){}
    
    public static void convertLeads (List<Lead> leadsToConvert){ 
        LeadStatus cLeadStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1]; 
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>(); 
        for(Lead l : leadsToConvert){
            if(l.FinServ__RelatedAccount__c != null){  
                Database.LeadConvert lc = new Database.LeadConvert(); 
                lc.setLeadId(l.Id); 
                lc.setConvertedStatus(cLeadStatus.MasterLabel); 
                lc.setDoNotCreateOpportunity(true);   
                lc.setAccountId(l.FinServ__RelatedAccount__c); 
                leadConverts.add(lc);
            } 
        }
        List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts,true);
    }
}