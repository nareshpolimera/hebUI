trigger EventTrigger on Event (before insert, before update, after insert) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    EventHandler handler = new EventHandler(Trigger.new);
    
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
    } else {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}