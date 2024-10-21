/******************************************************//**
@trigger    AccountAccountTrigger
@brief      Trigger for the FinServ__AccountAccountRelation__c  object.

@revision   2024-06-14 Azadeh Ahmadi
Porting from legacy SF org.
/******************************************************/
trigger AccountAccountTrigger on FinServ__AccountAccountRelation__c (before insert, before delete, after insert, after update) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    AccountAccountHandler handler = new AccountAccountHandler();   
    if (Trigger.isBefore)
    { 
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        
        if(Trigger.isDelete) {
            handler.beforeDelete(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter)
    {       
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        
    }
}