public class CreditReportHandler {
    
    public CreditReportHandler(List<Credit_Report__c> records)
    {
        init(records);
    }
    public void afterInsert(List<Credit_Report__c> records, Map<Id, Credit_Report__c> newMap)
    {
        new CreditReportDomain().afterInsert(records, newMap);
    }
    
    private void init(List<Credit_Report__c> records)
    {
    }
    
}