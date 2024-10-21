global class FileOwnershipReassignBatch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query Opportunity records where File_Queue__c = 'Inbound In-Progress' and Owner's profile has 'Mars Integration' permission set
        return Database.getQueryLocator([
            SELECT Id, File_Queue__c, OwnerId
            FROM Opportunity
            WHERE File_Queue__c = 'Inbound In-Progress'
            AND OwnerId IN (SELECT 
                            AssigneeId 
                            FROM PermissionSetAssignment 
                            WHERE PermissionSet.Name = 'MARS_Integration')
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        // List to hold Opportunities that need to be updated
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        // Iterate through each Opportunity in the batch
        for (Opportunity opp : scope) {
            // Update File_Queue__c to 'Initial Contact'
            opp.File_Queue__c = 'Initial Contact';
            opportunitiesToUpdate.add(opp);
        }
        
        // Update the Opportunities with the new File_Queue__c value
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optionally, add finish logic here if needed
    }
    
    global void execute(SchedulableContext sc) {
        // Schedule entry point
        FileOwnershipReassignBatch batch = new FileOwnershipReassignBatch();
        Database.executeBatch(batch);
    }
}