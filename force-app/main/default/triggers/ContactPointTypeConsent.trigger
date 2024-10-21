/******************************************************//**
@trigger    ContactPointTypeConsent
@brief      Trigger for the ContactPointTypeConsent  object.

@revision   2024-07-22 Suvarna Hawalppagol
Porting from legacy SF org.
@revision 202408-12 Adriano Silva
Including beforeUpdate and BeforeInsert
/******************************************************/
trigger ContactPointTypeConsent on ContactPointTypeConsent (before insert, before update, after insert, after update) {
    
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    ContactPointTypeConsentHandler handler = new ContactPointTypeConsentHandler(Trigger.new);
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            handler.beforeInsert(Trigger.new);
        }
    }
    
    if (Trigger.isAfter){
        if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }else if(Trigger.IsInsert) {
            handler.afterInsert(Trigger.new);
        } 
    }
}