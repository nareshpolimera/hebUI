global with sharing class CaseAutoEscalateBatch implements Database.Batchable<sObject>, Schedulable {
    String query = 'SELECT ID, Complaint_Date_Received__c, Complaint_Handling_Level__c, Complaint_Escalation_Rationale__c, Escalation_to_SDE_Rationale__c,First_Escalated_Date__c  FROM CASE WHERE IsClosed !=true and (Complaint_Handling_Level__c  =\'Level 1\' OR Complaint_Handling_Level__c  = \'Level 2\') ';
    
    global Database.QueryLocator start(Database.BatchableContext batchContext){  
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext batchContext,List<Case> results){
        if(results.isEmpty()){
            return;
        }
        List<Case> casesToUpdate = new List<case>();
        for(Case eachCaseRecord : results) {
            Boolean isCaseToUpdate = false;
            Integer numberDaysDue = eachCaseRecord.Complaint_Date_Received__c?.daysBetween(System.Today());
            System.debug('Case Id :: '+ eachCaseRecord.Id + ' :: numberDaysDue ::' + numberDaysDue + ' ::Complaint_Date_Received__c:: ' + eachCaseRecord.Complaint_Date_Received__c);
            
            if(numberDaysDue >= 14 && numberDaysDue <= 50 && eachCaseRecord.Complaint_Handling_Level__c != 'Level 2' ) {  
                isCaseToUpdate =true;
                eachCaseRecord.Complaint_Handling_Level__c = 'Level 2';
                eachCaseRecord.Complaint_Escalation_Rationale__c = 'This case has been automatically escalated to Level 2 because the received date falls between 15 and 50 Days'; 
                eachCaseRecord.First_Escalated_Date__c = (eachCaseRecord.First_Escalated_Date__c == null)? Date.today() : eachCaseRecord.First_Escalated_Date__c;            
            }
            if(numberDaysDue > 50 && eachCaseRecord.Complaint_Handling_Level__c != 'Level 3') {
                isCaseToUpdate =true;
                eachCaseRecord.Complaint_Handling_Level__c = 'Level 3';
                eachCaseRecord.Escalation_to_SDE_Rationale__c  = 'This case has been automatically escalated to Level 3 because the received date is greater than 50 Days';
                eachCaseRecord.First_Escalated_Date__c = (eachCaseRecord.First_Escalated_Date__c == null)? Date.today() : eachCaseRecord.First_Escalated_Date__c; 
            }
            if(isCaseToUpdate) {
                casesToUpdate.add(eachCaseRecord);
            }
        }
        
        if(casesToUpdate != null && casesToUpdate.size() > 0) {
            Database.SaveResult[] srList = Database.Update(casesToUpdate, false);
            for(Integer index = 0, size = srList.size(); index < size; index++) {
                if(!( srList[index].isSuccess())) {
                    for(Database.Error err : srList[index].getErrors()) {
                        System.debug('The following error has occurred in CaseAutoEscalateBatch ');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext batchContext) {
    }
    
    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new CaseAutoEscalateBatch(), 200); 
    }
}