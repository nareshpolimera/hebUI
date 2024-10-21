/********************************************************
@Class      AppraisalDomain
@brief      Domain class for trigger of the Appraisal object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalDomain {
    
    private AppraisalService service = new AppraisalService();
    public void beforeInsert(List<Appraisal__c> records)
    {
        service.setAppraisalToActive(records);
    }

    public void afterInsert(List<Appraisal__c> records, Map<Id, Appraisal__c> newMap)
    {
        service.updateAppProperties(records);
        service.setAppraisalToInactive(records);
    }

    public void beforeUpdate(List<Appraisal__c> records, Map<Id, Appraisal__c> oldRecords)
    {
        service.verifyAppraisedAmount(records,oldRecords);
    }

}