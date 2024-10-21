public class LeadAssignmentBatchConfigService
{
    public static final String DAILY   = 'Daily';
    public static final String WEEKLY  = 'Weekly';
    public static final String MONTHLY = 'Monthly';
    
    public static final Integer WEEK_SPAN    = 7;
    public static final Integer MONTHS_COUNT = 12;
    
    @testVisible
    private static Lead_Assignment_Batch_Config__mdt config;
    
    private static void loadConfig()
    {
        config = [
            SELECT Id, Frequency__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c, Frequency_Interval__c, Day_of_the_Month__c
            FROM Lead_Assignment_Batch_Config__mdt
            LIMIT 1
        ];
    }
    
    public static Boolean isCycleComplete(Date cycleStartDate)
    {
        if (config == null) loadConfig();
        
        Integer daysBetween = cycleStartDate.daysBetween(Date.today());
        
        if (config.Frequency__c == DAILY)
        {
            // E.g. if the interval is 2, then the batch will run every other day.
            return config.Frequency_Interval__c <= daysBetween;
        }
        else if (config.Frequency__c == WEEKLY)
        {
            Integer weeksBetween = daysBetween / WEEK_SPAN;
            
            return config.Frequency_Interval__c <= weeksBetween
                && isConfigEnabledDayOfWeek(dayOfWeekNumber(Date.today()));
        }
        else if (config.Frequency__c == MONTHLY)
        {
            Integer monthsBetween = Math.mod(Date.today().month() - cycleStartDate.month(), MONTHS_COUNT) + (Date.today().year() - cycleStartDate.year()) * MONTHS_COUNT;
            
            return config.Frequency_Interval__c <= monthsBetween
                && Date.today().day() == Integer.valueOf(config.Day_of_the_Month__c);
        }
        
        return false;
    }
    
    public static Boolean isConfigEnabledDayOfWeek(Integer dayOfWeekNumber)
    {
        if (config == null) loadConfig();
        
        return (dayOfWeekNumber == 0 && config.Sunday__c)
            || (dayOfWeekNumber == 1 && config.Monday__c)
            || (dayOfWeekNumber == 2 && config.Tuesday__c)
            || (dayOfWeekNumber == 3 && config.Wednesday__c)
            || (dayOfWeekNumber == 4 && config.Thursday__c)
            || (dayOfWeekNumber == 5 && config.Friday__c)
            || (dayOfWeekNumber == 6 && config.Saturday__c);
    }
    
    /**
* Return 0 for Sunday, 6 for Saturday
*/
    public static Integer dayOfWeekNumber(Date aDate)
    {
        return Math.mod(Date.newInstance(1900, 1, 7).daysBetween(aDate), WEEK_SPAN);
    }
}