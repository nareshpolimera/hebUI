/******************************************************//**
@trigger    LoanApplicant
@brief      Trigger for the LoanApplicant object.

@revision   2020-08-31 Sneha Namdeo
Created
@revision   2020-09-10 James Lee
Added after insert, update.
@revision   2020-09-14 James Lee
Added after delete.
@revision   2024-05-14 Xiomara Hernandez
Porting from legacy SF org.
/******************************************************/
trigger LoanApplicant on LoanApplicant  (before insert, before update, before delete, after insert, after update, after delete) {
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
        LoanApplicantHandler handler = new LoanApplicantHandler( Trigger.new );
        
        if ( trigger.isBefore ) {
            if ( trigger.isInsert ) {
                handler.beforeInsert( trigger.new );
            }
            if ( trigger.isUpdate ) {
                handler.beforeUpdate( trigger.new, trigger.oldMap );
            }
            if ( trigger.isDelete ) {
                handler.beforeDelete( trigger.oldMap );
            }
        }
        else
        {
            if ( trigger.isInsert ) {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            }
            if ( trigger.isUpdate ) {
                handler.afterUpdate( trigger.new, trigger.oldMap );
            }
            if ( trigger.isDelete ) {
                handler.afterDelete( trigger.old );
            }
        }
    }