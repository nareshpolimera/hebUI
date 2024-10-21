/******************************************************//**
@trigger    AppraisalNote__c
@brief      Trigger for the Appraisal Note object.

@revision   2020-08-09 James Lee
Created
2024-05-01 Joel Ojeda
Porting from legacy SF org.
/******************************************************/
trigger AppraisalNote on Appraisal_Note__c (before insert, after insert)
{
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AppraisalNoteHandler handler = new AppraisalNoteHandler(Trigger.new);
    
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }
    /*After*/
    else if (Trigger.isAfter)
    {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}