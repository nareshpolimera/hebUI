/********************************************************
@Class      AppraisalHandler
@brief      Handler class for trigger of the Appraisal object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalHandler {

    public AppraisalHandler(List<Appraisal__c> records)
    {
        init(records);
    }

    public void beforeInsert(List<Appraisal__c> records)
    {
        new AppraisalDomain().beforeInsert(records);
    }

    public void afterInsert(List<Appraisal__c> records, Map<Id, Appraisal__c> newMap)
    {
        new AppraisalDomain().afterInsert(records, newMap);
    }

    public void beforeUpdate(List<Appraisal__c> records, Map<Id, Appraisal__c> oldMap)
    {
        new AppraisalDomain().beforeUpdate(records, oldMap);
    }

    private void init(List<Appraisal__c> records)
    {
    }

}