trigger ResidentialLoanApplicationTrigger on ResidentialLoanApplication(before insert, after insert, before update, after update,before delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    ResidentialLoanApplicationHandler handler = new ResidentialLoanApplicationHandler(Trigger.new);
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }else{
        if(Trigger.isInsert){
            handler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            handler.afterUpdate( trigger.new, trigger.OldMap );
        }
    }
    
}