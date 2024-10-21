/******************************************************//**
@trigger    AccountContactRelation
@brief      Trigger for the AccountContactRelation  object.

@revision   2024-08-12 Alaa Khouloud
/******************************************************/
trigger AccountContactRelation on AccountContactRelation (after insert,after update) {

    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AccountContactRelationHandler handler = new AccountContactRelationHandler();
    
    /*After*/
    if (Trigger.isAfter)
    {
        if (Trigger.isInsert)
        {
            handler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate)
        {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }    
}