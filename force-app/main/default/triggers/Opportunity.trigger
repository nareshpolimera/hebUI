/******************************************************//**
@trigger    Opportunity
@brief      Trigger for the Opportunity object.

@revision   2020-26-08 Andrew Taylor
Created
@revision   2020-05-10 James Lee
Added after insert.
/******************************************************/
trigger Opportunity on Opportunity (after insert, before update, after update, before insert) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    if(ResidentialLoanApplicationService.bypassThisTrigger) {
        return;
    }

    OpportunityHandler handler = new OpportunityHandler(Trigger.new);
    
    if (Trigger.isBefore)
    {
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }
    else if (Trigger.isAfter)
    {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}