/******************************************************//**
@trigger    Individual
@brief      Trigger for the Individual  object.

@revision   2024-07-22 Suvarna Hawalppagol
Porting from legacy SF org.
@revision 2024-08-12 Adriano Silva
			Including aftereUpdate and afterInsert
/******************************************************/
trigger Individual on Individual(before insert, before update, after insert, after update) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    IndividualHandler handler = new IndividualHandler(Trigger.new);
    
    // Before
    if(Trigger.isBefore){
        if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }else if(Trigger.isAfter){    
        if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }else if(Trigger.IsInsert) {
            handler.afterInsert(Trigger.new);
        }  
        
    }
  
}