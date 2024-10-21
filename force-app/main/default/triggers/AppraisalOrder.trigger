/********************************************************
@Class      AppraisalOrder
@brief      Trigger of the AppraisalOrder object.

@revision   2024-05-10 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
trigger AppraisalOrder on Appraisal_Order__c (after insert, before update, before insert) {
    
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }

    AppraisalOrderHandler handler = new AppraisalOrderHandler(Trigger.new);
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    /*After*/
    else if (Trigger.isAfter)
    {
        if (Trigger.isInsert)
        {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }

}