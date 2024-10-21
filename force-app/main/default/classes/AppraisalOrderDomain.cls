/********************************************************
@Class      AppraisalOrderDomain
@brief      Domain class for trigger of the AppraisalOrder object.

@revision   2024-05-10 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalOrderDomain {

    private AppraisalOrderService service = new AppraisalOrderService();
    
    public void beforeInsert(List<Appraisal_Order__c> records)
    {
        //Joel Ojeda - reference to Legacy Lead Record Type not needed
        service.updateFileRecordType(records);
    }    

    public void afterInsert(List<Appraisal_Order__c> records, Map<Id, Appraisal_Order__c> newMap)
    {
       
    }

    public void beforeUpdate(List<Appraisal_Order__c> records, Map<Id, Appraisal_Order__c> oldRecords)
    {
        //Joel Ojeda - reference to Legacy Lead Record Type not needed
        service.updateFileRecordType(records);
    }

}