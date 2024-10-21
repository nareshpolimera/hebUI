/******************************************************//**
@trigger    CampaignMember
@brief      Trigger for the CampaignMember object.

@revision   2020-20-08 Andrew Taylor
Created
/******************************************************/
trigger CampaignMember on CampaignMember (before insert, after insert, after update, before delete, after delete) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    CampaignMemberHandler handler = new CampaignMemberHandler(Trigger.new);
    
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isDelete) {
            handler.beforeDelete(Trigger.old);
        }
    }
    /*After*/
    else if (Trigger.isAfter)
    {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        else if (Trigger.IsUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        else if (Trigger.IsDelete) {
            handler.afterDelete(Trigger.old, Trigger.oldMap);
        }
    }
    
}