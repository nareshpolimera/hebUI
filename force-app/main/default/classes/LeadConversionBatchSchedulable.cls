/*-----------------------------------------------------------------------------------
      @description       : The is scheduler for LeadConversionBatch 
      @last modified on  : 07-07-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-07-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
global with sharing class LeadConversionBatchSchedulable implements Schedulable{
    global void execute (SchedulableContext sc) {   
        LeadConversionBatch batchObj = new LeadConversionBatch();
        Database.executeBatch(batchObj,100);  
    } 
}