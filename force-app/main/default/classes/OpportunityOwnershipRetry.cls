public class OpportunityOwnershipRetry implements Queueable {
    private Map<Id, Opportunity> oppMap; 
    public OpportunityOwnershipRetry(List<Id> oppIds) {
        this.oppMap = new Map<Id, Opportunity>([select Id, OwnerId from Opportunity where Id IN : oppIds]);
    }
    
    public void execute(QueueableContext context) {
        OpportunityOwnershipService.processRelatedRecordsOwnership(this.oppMap);
    }
}