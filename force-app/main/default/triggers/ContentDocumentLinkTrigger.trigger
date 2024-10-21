trigger ContentDocumentLinkTrigger on ContentDocumentLink(before insert) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    ContentDocumentLinkTriggerHandler handler = new ContentDocumentLinkTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }
    
}