trigger ContactTrigger on Contact (before insert, after update, before update)
{
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    ContactHandler handler = new ContactHandler(Trigger.new);
    
    /*Before*/
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert)
        {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate)
        {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    else
    {
        if (Trigger.isUpdate)
        {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}