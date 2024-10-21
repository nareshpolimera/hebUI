/******************************************************/ /**
@Class      ResidentialLoanApplicationService
@brief      Class with especific-related methods to the Application object.

@revision   2024-07-03 Juan Contreras 
Task 6389.
/******************************************************/
public with sharing class ResidentialLoanApplicationService {

    public static Boolean bypassThisTrigger = false;
    
    public void generateName(List<ResidentialLoanApplication> records) { 
        set <id> oppId = new set<id>();
        List<ResidentialLoanApplication> rlaList = new List<ResidentialLoanApplication>();
        for( ResidentialLoanApplication r : records){
            if(r.OpportunityId != null){oppId.add(r.OpportunityId);}
        }
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select id,Account.firstname,account.lastname,File_Number__c from Opportunity where id IN : oppId]); 
        for( ResidentialLoanApplication r : records){ 
            if(r.OpportunityId != null && oppMap.containsKey(r.OpportunityId)){
                r.Name = 'LA' + (oppMap.get(r.OpportunityId) != null ? ' - ' +oppMap.get(r.OpportunityId).Account.LastName : '') + (oppMap.get(r.OpportunityId).File_Number__c != null ? ' - ' +oppMap.get(r.OpportunityId).File_Number__c : ''); 
                rlaList.add(r);
            }
            
        }
        if(!rlaList.isEmpty()){
            //update rlaList;
        }
    }
    
    /** HEB-367 When lead details are updated a new quote is requested */
    public void updateQuote(List<ResidentialLoanApplication> records, Map<Id, ResidentialLoanApplication> oldRecords) {
        if (System.isBatch() || 
            FeatureManagement.checkPermission(Utils.CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD) ||
            records.size() > 1){
            return;
        }

        //validate if quote request must be skipped
        if(QuoteRequestManager.doSkipQuoteService()){
            return;
        }
       
        //get newly created Property
        ResidentialLoanApplication updatedApplication = oldRecords != null && oldRecords.get(records[0].Id).Term__c != records[0].Term__c ? records[0] : null;
        
        if(updatedApplication != null && updatedApplication.opportunityId != null && !Test.isRunningTest()){
            QuoteRequestValidationController.getQuoteForTrigger(updatedApplication.opportunityId);
        }
        
    }

    public void updateOpportunityLoanPurpose(List<ResidentialLoanApplication> records) {
        Map<Id, String> oppApplicationMap = new Map<Id, String>();
        List<Opportunity> updateList = new List<Opportunity>();
        for (ResidentialLoanApplication appRecord : records) {
            if(appRecord.Loan_Purpose__c!=null) {
                oppApplicationMap.put(appRecord.OpportunityId, appRecord.Loan_Purpose__c);   
            }
        }
        for(Opportunity op : [Select Id, Loan_Purpose__c From Opportunity Where Id In : oppApplicationMap.keySet()]) {
            op.Loan_Purpose__c = oppApplicationMap.get(op.Id);
            updateList.add(op);
        }
        if(!updateList.isEmpty()) {
            bypassThisTrigger = true;
            update updateList;
            bypassThisTrigger = false;
        }
    }
}