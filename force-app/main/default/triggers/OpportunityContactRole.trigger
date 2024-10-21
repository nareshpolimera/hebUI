trigger OpportunityContactRole on OpportunityContactRole (before insert, before update, after insert, after update) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }

    OpportunityContactRoleHandler handler = new OpportunityContactRoleHandler(Trigger.new);

    if (Trigger.isBefore){
        if (Trigger.isInsert){
            handler.beforeInsert(Trigger.new);
        }
        else if (Trigger.isUpdate){
            handler.beforeUpdate(Trigger.new,Trigger.oldMap);
        }
    }

    if (Trigger.isAfter){
        if (Trigger.isInsert){
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        else if (Trigger.isUpdate){
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}