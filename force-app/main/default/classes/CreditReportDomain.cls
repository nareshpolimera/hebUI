public class CreditReportDomain {
    private CreditReportService service = new CreditReportService();
    
    public void afterInsert(
        List<Credit_Report__c> records,
        Map<Id, Credit_Report__c> newMap
    ) {
        
        service.updateLeadWarning(records);
    }
}