/*-----------------------------------------------------------------------------------
      @description       : The is scheduler for AccountCaslUpdationBatch 
      @last modified on  : 07-09-2024
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   07-09-2024   Anurag Gupta                          Initial Version
      -----------------------------------------------------------------------------------
    */
global with sharing class AccountCaslUpdationBatchSchedulable implements Schedulable{
    global void execute (SchedulableContext sc) {   
        AccountCaslUpdationBatch batchObj = new AccountCaslUpdationBatch();
        Database.executeBatch(batchObj,200);  
    } 
}