trigger LoanApplicationLiability on LoanApplicationLiability(before insert,before update,after insert,before delete,after update,after delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    LoanApplicationLiabilityHandler handler = new LoanApplicationLiabilityHandler(Trigger.new);
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            handler.beforeDelete(Trigger.oldMap);
        }
    } else {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            handler.afterDelete(Trigger.oldMap);
        }
    }
}