/*-----------------------------------------------------------------------------------
@description       : batch is used to map FinServ__RelatedAccount__c and Related_Account__c fields on Lead
@last modified on  : 07-08-2024
Modifications Log 
-----------------------------------------------------------------------------------
Ver   Date         Author                               Modification
1.0   07-08-2024   Anurag Gupta                          Initial Version
-----------------------------------------------------------------------------------
*/
public class LeadAccountMapBatch implements Database.Batchable<sObject>{ 
    String query = 'SELECT id, IsConverted ,FinServ__RelatedAccount__c,Related_Account__c,FinServ__RelatedAccount__r.RecordTypeId  from Lead where IsConverted = false and FinServ__RelatedAccount__c !=null ';
    public Database.QueryLocator start(Database.BatchableContext BC){  
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Lead> scope){
        List<Lead> leadList = new List<Lead>(); 
        String accountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        for(Lead lead : scope){
            if(accountRT == lead.FinServ__RelatedAccount__r.RecordTypeId){
                lead.Related_Account__c = lead.FinServ__RelatedAccount__c;
            } 
            lead.FinServ__RelatedAccount__c = null;
            leadList.add(lead);
        }
        if(leadList!=null && !leadList.isEmpty()){update leadList;}
    }
    public void finish(Database.BatchableContext BC){}
}