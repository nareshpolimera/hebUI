public class CreditReportService {
    public void updateLeadWarning(List<Credit_Report__c> records) {
        List<Credit_Report__c> rl = new List<Credit_Report__c>();
        Set<Lead> updateLeadList = new Set<Lead>();
        List<Id> lsPM = new List<Id>();
        Map<Id, Account> pmMap = new Map<Id, Account>();
        for (Credit_Report__c cr : records) {
            if (cr.Person__c != null) {
                lsPM.add(cr.Person__c);
            }
        }
        
        for (Account p : [
            SELECT Id, Lead__pc, Lead__pr.RecordType.Name
            FROM Account
            WHERE Id IN :lsPM
        ]) {
            if(p.Lead__pc != null){
                updateLeadList.add(new lead(id = p.Lead__pc));
            }
        }
        if (updateLeadList.size() == 1) {
            update new List<Lead>(updateLeadList);
        }
    }
}