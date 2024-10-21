public class LeadAssignmentBatchLogService
{
    private static Lead_Assignment_Batch_Log__c log;
    
    public static void getLog()
    {
        log = [
            SELECT Id
            , Last_Run_Date__c
            FROM Lead_Assignment_Batch_Log__c
            LIMIT 1
        ];
    }
    
    public static Date getLastRunDate()
    {
        try
        {
            // Get the cached log.
            if (log == null) { getLog(); }
        }
        catch (QueryException qe)
        {
            // Transfer log not found, generate a new one.
            generateLog();
            getLog();
        }
        
        return log.Last_Run_Date__c.date();
    } 
    
    public static void logLastRunDate()
    {
        
        try
        {
            if (log == null) { getLog(); }
        }
        catch (QueryException qe)
        {
            // Transfer log not found, generate a new one.
            generateLog();
            getLog();
        }
        
        // Update last run date for reference.
        log.Last_Run_Date__c = Date.today();
        update log;
    }
    
    public static void generateLog()
    {
        insert new Lead_Assignment_Batch_Log__c(
            Last_Run_Date__c = Date.today()
        );
    }
}