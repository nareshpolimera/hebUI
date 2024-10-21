/******************************************************//**
@trigger    Quote
@brief      Trigger for the Quote object.

@revision   2020-20-08 Andrew Taylor
Created
/******************************************************/
trigger Quote on Quote (before insert, before update) {

    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    if(LoanApplicationPropertyService.runOnce(Trigger.newMap?.keySet(),Trigger.oldMap?.keySet(),Trigger.operationType)){
        return;
    }
    if(LoanApplicationPropertyService.bypassThisTrigger) {
        return;
    }
    QuoteHandler handler = new QuoteHandler(Trigger.new);
    
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
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        else if (Trigger.IsUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        else if (Trigger.IsDelete) {
            handler.afterDelete(Trigger.old, Trigger.oldMap);
        }
    }
    
}