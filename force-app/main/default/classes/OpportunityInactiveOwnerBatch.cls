/*-----------------------------------------------------------------------------------
    @description       : batch is used to update the opportunity owner when owner is Inactive and assign opp to Intial Contact Queue
    @last modified on  : 
    Modifications Log 
    -----------------------------------------------------------------------------------
    Ver   Date         Author                               Modification
    1.0   09-19-2024   Mudit Arora                          Initial Version
    -----------------------------------------------------------------------------------
*/
public class OpportunityInactiveOwnerBatch implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext BC){  

        String query = 'SELECT Id, Name, Channel__c, Is_Redacted__c, IsClosed, File_Queue__c, MARS_Stage__c, OwnerId, StageName, Owner.IsActive, File_Ownership_Update_Batch_Error__c, File_Ownership_Update_Error_Code__c ' +
                   'FROM Opportunity ' +
                   'WHERE Channel__c = \'Consumer\' ' +
                   'AND Is_Redacted__c = false ' +
                   'AND IsClosed = false ' +
                   'AND File_Queue__c NOT IN (\'Initial Contact\') ' +
                   'AND Owner.IsActive = false ' +
                   'AND MARS_Stage__c = null';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        
        OpportunityOwnershipBatchHandler.setOpportunityQueueToInitialContactQueue(scope, OpportunityBatchProcessEnums.Process.INACTIVE_OWNER);
    }
    
    public void finish(Database.BatchableContext BC){
        DormantOpportunityOwnerUpdateBatch batchObj = new DormantOpportunityOwnerUpdateBatch();
        Database.executeBatch(batchObj, 200);
    }
    
}