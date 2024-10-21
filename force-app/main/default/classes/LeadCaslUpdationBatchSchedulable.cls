/*-----------------------------------------------------------------------------------
      @description       : The is scheduler for LeadCaslUpdationBatchSchedulable 
      @last modified on  : 07-09-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-09-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
global with sharing class LeadCaslUpdationBatchSchedulable implements Schedulable{
    global void execute (SchedulableContext sc) {   
        LeadCaslUpdationBatch batchObj = new LeadCaslUpdationBatch();
        Database.executeBatch(batchObj,200);  
    } 
}