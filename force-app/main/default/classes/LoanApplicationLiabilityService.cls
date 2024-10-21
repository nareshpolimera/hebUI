public class LoanApplicationLiabilityService {
    public Map<Id, ResidentialLoanApplication> masterApplicationMap = new Map<Id, ResidentialLoanApplication>();
    
    public void getParentRecords(List<LoanApplicationLiability> records){
        Set<Id> parentApplicationIDSet = new Set<Id>();
        for(LoanApplicationLiability record : records){
            if(record.LoanApplicationId <> null){
                parentApplicationIDSet.add(record.LoanApplicationId);
            }
        }
        masterApplicationMap = new Map<Id, ResidentialLoanApplication>([SELECT Id, OpportunityId, Opportunity.OwnerId, Opportunity.RecordTypeId, 
                                                                        Opportunity.RecordType.Name, Opportunity.Quote_Parameters_Updated__c FROM ResidentialLoanApplication 
                                                                        WHERE ID IN: parentApplicationIDSet]);
    }
    
    public void setOwner(List<LoanApplicationLiability> records) {
        getParentRecords(records);
        for (LoanApplicationLiability record : records) {
            if (record.LoanApplicationId <> null && masterApplicationMap <> null && masterApplicationMap.containsKey(record.LoanApplicationId) 
                && masterApplicationMap.get(record.LoanApplicationId).OpportunityId <> null) {
                    record.OwnerId = masterApplicationMap.get(record.LoanApplicationId).Opportunity.OwnerId;
                }
        }
    }
    
    public void updateFileRecordType(List<LoanApplicationLiability> records) {
        if(masterApplicationMap.isEmpty() || (!masterApplicationMap.isEmpty() && records.size() != masterApplicationMap.size())){
            getParentRecords(records);
        }
        for (LoanApplicationLiability rd : records) {
            if(rd.LoanApplicationId <> null && masterApplicationMap <> null && masterApplicationMap.containsKey(rd.LoanApplicationId) 
               && masterApplicationMap.get(rd.LoanApplicationId).OpportunityId != null 
               && masterApplicationMap.get(rd.LoanApplicationId).Opportunity.RecordTypeId != null){
                   rd.File_Record_Type__c = (masterApplicationMap.get(rd.LoanApplicationId).Opportunity.RecordType.Name).contains(Label.File_RecordType_Referred)
                       ? Label.File_RecordType_Referred : Label.File_RecordType_Consumer;
               }
        }
    }
    
    public void onDeleteValidation(Map<Id, LoanApplicationLiability> oldRecordsMap) {
       // for (Id key : oldRecordsMap.keySet()) {
        //    if (!FeatureManagement.checkPermission('Debt_Control_Permission') &&
        //        oldRecordsMap.get(key).Source__c == 'Credit Bureau') {
         //           oldRecordsMap.get(key).addError('Cannot delete Credit Bureau debt records');
         //       }
       // }
    
        Id currentUserId = UserInfo.getUserId();

    // Query to check if the user is assigned a permission set group that includes 'HEB_Mortgage_Sales' permission set
    List<PermissionSetGroupComponent> psaListName = [SELECT PermissionSet.Name,PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponent where PermissionSet.Name='HEB_Mortgage_Sales'];
        if(!psaListName.isEmpty()){
            List<PermissionSetAssignment> psaList = [SELECT PermissionSetGroup.DeveloperName, PermissionSetGroup.Id, PermissionSetGroup.MasterLabel,PermissionSet.Type FROM PermissionSetAssignment WHERE AssigneeId = :currentUserId AND PermissionSet.Name =:psaListName[0].PermissionSetGroup.DeveloperName];
     // If the user is assigned a permission set group with 'HEB_Mortgage_Sales', prevent deletion
         if (!psaList.isEmpty()) {
                for (LoanApplicationLiability app : oldRecordsMap.values()) {
                    app.addError(System.Label.Applicant_Liabilities_error_on_delete);
                }
            }
        }
    }
    
    public void updateTDSR(List<LoanApplicationLiability> records) {
        if (!TDSRCalculationService.runTDSROnce && !System.isFuture() && !System.isBatch()) {
            Map<Id, String> appIds = new Map<Id, String>();
            Set<Id> opportunityIds = new Set<Id>();
            if(masterApplicationMap.isEmpty() || (!masterApplicationMap.isEmpty() && records.size() != masterApplicationMap.size())){
                getParentRecords(records);
            }
            for (LoanApplicationLiability record : records) {
                if(record.LoanApplicationId <> null && !masterApplicationMap.isEmpty() && masterApplicationMap.containsKey(record.LoanApplicationId)){
                    opportunityIds.add(masterApplicationMap.get(record.LoanApplicationId).OpportunityId);
                    appIds.put(masterApplicationMap.get(record.LoanApplicationId).OpportunityId, record.LoanApplicationId);
                }
            }
            if (opportunityIds.isEmpty()) {return;}
            
            if(!Test.isRunningTest()){
                for (String opportunityId : opportunityIds) {
                    TDSRCalculationService.runTDSROnce = true;
                    TDSRCalculationService.runTDSRCalculation(opportunityId, appIds.get(opportunityId));
                }
            }
        }
    }
    
    /** HEB-367 When lead details are updated a new quote is requested */
    public void updateQuote(List<LoanApplicationLiability> records, Map<Id, LoanApplicationLiability> oldRecords) {
        //Return if called from batch; future; for more than 1 record; if the user has specific custom permission
        if (System.isBatch() || system.isFuture() || 
            FeatureManagement.checkPermission(Utils.CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD) || 
            records.size() > 1 ) {
            return;
        }
        
        //validate if quote request must be skipped
        if(QuoteRequestManager.doSkipQuoteService()){
            return;
        }
        
        //get newly created Property
        LoanApplicationLiability updatedLiability =  null;
        
        boolean isChangedField1 = oldRecords.get(records[0].Id).Secured__c != records[0].Secured__c ;
        boolean isChangedField2 = oldRecords.get(records[0].Id).Include_Debt__c != records[0].Include_Debt__c;
        
        if ( oldRecords != null && records[0].Secured__c && records[0].Include_Debt__c && records[0].CreditLimitAmount != null && ( isChangedField1 || isChangedField2  ) ){
            updatedLiability = records[0];
        } 
        
        //get opp id
        ResidentialLoanApplication app = new ResidentialLoanApplication();
        if(updatedLiability != null && (masterApplicationMap.isEmpty() || (!masterApplicationMap.isEmpty() && !masterApplicationMap.ContainsKey(updatedLiability.LoanApplicationId)))){
            //get Opportunity Out of the liability
            app = [SELECT Id, OpportunityId, Opportunity.Quote_Parameters_Updated__c FROM ResidentialLoanApplication WHERE id = :updatedLiability.LoanApplicationId];
        } else if(updatedLiability != null && !masterApplicationMap.isEmpty() && masterApplicationMap.ContainsKey(updatedLiability.LoanApplicationId)) {
                app = new ResidentialLoanApplication(Id = updatedLiability.LoanApplicationId, OpportunityId = masterApplicationMap.get(updatedLiability.LoanApplicationId).OpportunityId);
        }
        if(app != null && app.opportunityId != null && !Test.isRunningTest()){
            QuoteRequestValidationController.getQuoteForTrigger(app.opportunityId);
        }
    }
    
    //Method to auto-generate Name
    //Format: AL-00000001
    public void generateAutoName(List<LoanApplicationLiability> records) {        
        AutomatedNameGenerator.generateNextSequenceName(records, LoanApplicationLiability.SobjectType);
    }
}