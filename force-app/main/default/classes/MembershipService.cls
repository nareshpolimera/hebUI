public class MembershipService {
    public void setOwner(List<Membership__c> records) {
        List<Id> fileIds = new List<Id>();
        for (Membership__c record : records)
            if (record.Opportunity__c != null)
            fileIds.add(record.Opportunity__c);
        if (fileIds.isEmpty())
            return;
        
        Map<Id, Opportunity> fileMap = new Map<Id, Opportunity>(
            [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :fileIds]
        );
        for (Membership__c record : records) {
            if (record.Opportunity__c == null)
                record.OwnerId = fileMap.get(record.Opportunity__c).OwnerId;
        }
    }
}