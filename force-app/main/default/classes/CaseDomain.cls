public class CaseDomain {
    private CaseService service = new CaseService();
    private Logger theLogger;
    private CaseRoutingService caseRoutingService = new CaseRoutingService();
    
    public void beforeInsert(List<Case> records) {
        // service.updateNewFirstEscalatedDate(records);
        service.setEmailOrTaskSubject(records);
        service.populateEmail2Case(records);
        service.setHandlingLevelBasedOnUserRole(records);
        
        caseRoutingService.routeToDEOrSDEUsers(records);
        service.setCaseStatus(records);
        service.updateNewFirstEscalatedDate(records);
        
        // IsEscalated
        // Customer Satisified
        
        // content API
        //
        // Complainant_Review_Body__c
        
    }
    
    public void beforeUpdate(List<Case> records, Map<Id, Case> oldRecords) {
        //service.assignCaseToQueue(records, oldRecords);
        // service.RestrictEditing(records, oldRecords);
        // service.validate(records, oldRecords);
        // service.updateHasbeenDeclinedForCase(records, oldRecords);
        service.validateEditPermissions(records, oldRecords);
        service.validateComplaintResolvedClosedRecords(records, oldRecords);
        service.updateFirstEscalatedDate(records, oldRecords);        
        caseRoutingService.routeToUsers(records,oldRecords);
       // LoggerDMLService.saveLog(caseRoutingService.getLog());
    }
    
    public void beforeUpdateWithMap( Map<Id, Case>  Newrecords, Map<Id, Case> oldRecords) {
        Service.validateOnUpdate(Newrecords, oldRecords);
        Service.ownerBasevalidateOnUpdate(Newrecords, oldRecords); 
        Service.UpdateOwnerName(Newrecords, oldRecords);
        
    }
    
    public void afterInsert(List<Case> records) {
        service.addIdToSendForEmails(records);
        service.createCaseStatusHistoryInsert(records);
        CaseService.sendNewCaseToMarsPlatformEvent(records);
    }
    
    public void afterUpdate(List<Case> records, Map<Id, Case> oldRecords) {
        service.createCaseStatusHistoryUpdate(records, oldRecords);
        CaseService.sendUpdatedCaseToMarsPlatformEvent(records, oldRecords);
    }
    
}