/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_OpportunityContactRoleTrigger on OpportunityContactRole
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    dlrs.RollupService.triggerHandler(OpportunityContactRole.SObjectType);
}