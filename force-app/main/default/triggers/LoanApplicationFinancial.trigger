trigger LoanApplicationFinancial on LoanApplicationFinancial (before insert) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    LoanApplicationFinancialHandler handler = new LoanApplicationFinancialHandler(Trigger.new);
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert)
        {
            handler.beforeInsert(Trigger.new);
        }
    }
}