/******************************************************//**
@Class      AppraisalNoteDomain
@brief      Domain class for trigger of the AppraisalNote object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalNoteDomain {

    private AppraisalNoteService service = new AppraisalNoteService();
    
    public void beforeInsert(List<Appraisal_Note__c> records)
    {
        service.validateOrder(records);
        service.designateOrigin(records);
        service.setEnteredOnDate(records);
    }
    
    public void afterInsert(List<Appraisal_Note__c> records)
    {
        service.sendNote(records);
    }

    
}