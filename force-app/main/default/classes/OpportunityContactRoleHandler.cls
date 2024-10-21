public with sharing class OpportunityContactRoleHandler {

    public OpportunityContactRoleHandler(List<OpportunityContactRole> records) {
        init(records);
    }

    public void beforeInsert(List<OpportunityContactRole> records) {
        new OpportunityContactRoleDomain().beforeInsert(records);
    }
    
    public void beforeUpdate(
        List<OpportunityContactRole> records,
        Map<Id, OpportunityContactRole> oldMap) {
        new OpportunityContactRoleDomain().beforeUpdate(records,oldMap);
    }

    public void afterInsert(
        List<OpportunityContactRole> records,
        Map<Id, OpportunityContactRole> newMap
    ) {
        new OpportunityContactRoleDomain().afterInsert(records, newMap);
    }

    public void afterUpdate(
        List<OpportunityContactRole> records,
        Map<Id, OpportunityContactRole> oldMap
    ) {
        new OpportunityContactRoleDomain().afterUpdate(records,oldMap);
    }


    private void init(List<OpportunityContactRole> records) {
    }
}