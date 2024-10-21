global class LeadAssignmentBatch implements Database.Batchable<sObject>
{
    /*
     * Query for all leads assigned to a branch queue over the cutoff number of days ago.
     */ 
    global Database.QueryLocator start(Database.BatchableContext ctx)
    {
        return Database.getQueryLocator(
            'SELECT Id ' +
            'FROM Specialist__c '
        );
    }
    
    /*
     * Process leads to return.
     */
    global void execute(Database.BatchableContext ctx, List<Specialist__c> spls)
    {
        Set<Id> specialistIds = new Set<Id>();
        for (Specialist__c spl : spls)
        {
            specialistIds.add(spl.Id);
        }
        
        LeadAssignmentService.resetLeadAssignmentCount(specialistIDs);
    }
    
    /*
     * Finish method - close off batch activities.
     */
    global void finish(Database.BatchableContext ctx)
    {
        LeadAssignmentBatchLogService.logLastRunDate();
    }
}