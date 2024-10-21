trigger Task on Task(after insert, after update, before insert, before update) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    TaskHandler handler = new TaskHandler(Trigger.new);
    
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}