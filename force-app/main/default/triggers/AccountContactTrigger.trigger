/******************************************************//**
@trigger    AccountContactTrigger
@brief      Trigger for the AccountContactRelation  object.

@revision   2024-04-20 Diego Guerrero
Porting from legacy SF org.
/******************************************************/
trigger AccountContactTrigger on AccountContactRelation (after insert, after update) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AccountContactHandler handler = new AccountContactHandler();
    
    if (Trigger.isAfter)
    {       
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        
    }
}