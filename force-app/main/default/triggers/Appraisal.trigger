/********************************************************
@Class      Appraisal
@brief      Trigger class for trigger of the Appraisal object.

@revision   2024-05-01 Joel Ojeda
Porting from legacy SF org.
/******************************************************/
trigger Appraisal on Appraisal__c (after insert, before update, before insert) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AppraisalHandler handler = new AppraisalHandler(Trigger.new);
    if (Trigger.isBefore) 
    {
        if (Trigger.isInsert)
        {
            handler.beforeInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            handler.beforeUpdate(trigger.new, trigger.oldMap);
        }
        
    } else {
        
        if (Trigger.isAfter)
        {
            if (Trigger.isInsert)
            {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            }
        }
    }
    
}