trigger CreditReport on Credit_Report__c (after insert) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    CreditReportHandler handler = new CreditReportHandler(Trigger.new);
    if (Trigger.isAfter)
    {
        if (Trigger.isInsert)
        {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }
}