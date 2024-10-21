trigger LoanApplicationAssetTrigger on LoanApplicationAsset(before insert,before update,after insert,before delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    LoanApplicationAssetHandler handler = new LoanApplicationAssetHandler(Trigger.new);
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }
}