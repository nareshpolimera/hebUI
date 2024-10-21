/********************************************************
@Class      AppraisalOrderHandler
@brief      Service class for trigger of the AppraisalOrder object.

@revision   2024-05-10 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalOrderHandler {

    public AppraisalOrderHandler(List<Appraisal_Order__c> records)
    {
        init(records);
    }

    public void beforeInsert(List<Appraisal_Order__c> records)
    {
        new AppraisalOrderDomain().beforeInsert(records);
    }

    public void afterInsert(List<Appraisal_Order__c> records, Map<Id, Appraisal_Order__c> newMap)
    {
        new AppraisalOrderDomain().afterInsert(records, newMap);
    }
    
    public void beforeUpdate(List<Appraisal_Order__c> records, Map<Id, Appraisal_Order__c> oldMap)
    {
        new AppraisalOrderDomain().beforeUpdate(records, oldMap);
    }

    private void init(List<Appraisal_Order__c> records)
    {
    }

}