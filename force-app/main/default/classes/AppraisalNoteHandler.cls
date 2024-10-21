/******************************************************//**
@Class      AppraisalNoteHandler
@brief      Handler class for trigger of the AppraisalNote object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalNoteHandler
{
    public AppraisalNoteHandler(List<Appraisal_Note__c> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<Appraisal_Note__c> records)
    {
        new AppraisalNoteDomain().beforeInsert(records);
    }
    
    public void afterInsert(List<Appraisal_Note__c> records)
    {
        new AppraisalNoteDomain().afterInsert(records);
    }
    
    private void init(List<Appraisal_Note__c> records)
    {
    }

    
}