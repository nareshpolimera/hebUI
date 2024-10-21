/******************************************************//**
@trigger    LoanApplicationProperty
@brief      Trigger for the LoanApplicationProperty object.

@revision   2024-14-05 Xiomara Hernandez
Porting from legacy SF org.

/******************************************************/
trigger LoanApplicationProperty on LoanApplicationProperty (before insert, before update, after update, after insert, after delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    LoanApplicationPropertyHandler handler = new LoanApplicationPropertyHandler( Trigger.new );
    
    if ( trigger.isBefore ) {
        if ( trigger.isInsert ) {
            handler.beforeInsert( trigger.new );
        }
        if ( trigger.isUpdate ) {
            handler.beforeUpdate( trigger.new, trigger.oldMap );
        }
    }
    else {
        if ( trigger.isInsert ) {
            handler.afterInsert( trigger.new );
        }
        if ( trigger.isUpdate ) {
            handler.afterUpdate( trigger.new, trigger.OldMap );
        }
        if ( trigger.isDelete ) {
            handler.afterDelete( trigger.old );
        }
    }
}