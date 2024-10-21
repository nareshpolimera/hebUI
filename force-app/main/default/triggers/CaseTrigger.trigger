/******************************************************//**
@trigger    Case
@brief      Trigger for the Case object.

@revision   2022-02-16 Richard W.
Created
/******************************************************/
trigger CaseTrigger on Case (before insert, after insert, before update, after update, after delete ) {
    CaseHandler handler = new CaseHandler(Trigger.new);
    System.debug('!!! Trigger');
    System.debug(Trigger.isAfter);
    System.debug(Trigger.isInsert);
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert) {
            handler.beforeInsert(trigger.new);
        }
        else if (Trigger.isUpdate) {
            handler.beforeUpdate(trigger.new, trigger.oldMap);
        }
    }
    /*After*/
    else if (Trigger.isAfter)
    {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
            CaseService.createdIdList=Trigger.newMap.keyset();
        }
        else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}