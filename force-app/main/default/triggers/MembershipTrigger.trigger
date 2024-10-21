trigger MembershipTrigger on Membership__c (after insert, before update, after update, before insert) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    MembershipHandler handler = new MembershipHandler(Trigger.new);
    
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
        if (Trigger.isInsert)
        {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }
    
}