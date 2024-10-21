trigger LoanApplicantIncome on LoanApplicantIncome(after insert,after update,after delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    LoanApplicantIncomeHandler handler = new LoanApplicantIncomeHandler(
        Trigger.new
    );
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            handler.afterDelete(Trigger.old, Trigger.oldMap);
        }
    }
}