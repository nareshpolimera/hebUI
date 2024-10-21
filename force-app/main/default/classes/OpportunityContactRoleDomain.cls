public with sharing class OpportunityContactRoleDomain {

    private OpportunityContactRoleService service = new OpportunityContactRoleService();

    public void beforeInsert( List<OpportunityContactRole> records) {
        service.validateRole(records,null);
    }
    
    public void beforeUpdate( List<OpportunityContactRole> records,
                            Map<Id, OpportunityContactRole> oldMap) {
        service.validateRole(records,oldMap);
    }

    public void afterInsert( List<OpportunityContactRole> records, 
                            Map<Id, OpportunityContactRole> newMap) {
        service.processPrimaryRole(records,null);
        service.updateOpportunity(records,null);
    }

    public void afterUpdate(List<OpportunityContactRole> records, 
                            Map<Id, OpportunityContactRole> oldRecords) {
        service.processPrimaryRole(records,oldRecords);
        service.updateOpportunity(records,oldRecords);
    }

}