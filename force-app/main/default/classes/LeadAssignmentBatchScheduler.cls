global class LeadAssignmentBatchScheduler implements Schedulable
{
    public static final String JOB_NAME = 'Lead Assignment Batch';
    
    global void execute(SchedulableContext sc)
    {
        
        // Do not execute if the cycle has not completed yet.
        if (isMidLeadAssignmentCycle()) return;
        
        LeadAssignmentBatch lab = new LeadAssignmentBatch();
        DataBase.executeBatch(lab);
    }
    
    private boolean isMidLeadAssignmentCycle()
    {
        Date lastRunDate = LeadAssignmentBatchLogService.getLastRunDate();
        
        return !LeadAssignmentBatchConfigService.isCycleComplete(lastRunDate);
    }
}