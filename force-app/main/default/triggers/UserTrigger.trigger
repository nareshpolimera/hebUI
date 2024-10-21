trigger UserTrigger on User (after update) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    UserHandler handler = new UserHandler(Trigger.new);
    
    /*After*/
    if (Trigger.isAfter)
    {
        if (Trigger.IsUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}