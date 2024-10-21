/******************************************************//**
@trigger    Account
@brief      Trigger for the Account  object.

@revision   2024-04-20 Diego Guerrero
Porting from legacy SF org.
/******************************************************/
trigger AccountTrigger on Account (before insert, before update, after insert, after update)
{
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AccountHandler handler = new AccountHandler(Trigger.new);
    
    /*Before*/
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert)
        {
            handler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    else
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