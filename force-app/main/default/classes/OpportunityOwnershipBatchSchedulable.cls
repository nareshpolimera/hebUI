/*-----------------------------------------------------------------------------------
    @description       : The is scheduler for Opportnity Inactive Owner update batch and Dormant Opportutniy owner update batch
    @last modified on  : 09-20-2024
    Modifications Log 
    -----------------------------------------------------------------------------------
    Ver   Date         Author                               Modification
    1.0   09-20-2024   Mudit Arora                          Initial Version
    -----------------------------------------------------------------------------------
*/
global with sharing class OpportunityOwnershipBatchSchedulable implements Schedulable{
    global void execute (SchedulableContext sc) {   
        OpportunityInactiveOwnerBatch batchObj = new OpportunityInactiveOwnerBatch();
        Database.executeBatch(batchObj,200);
    } 
}