public with sharing class LoanApplicantIncomeService {
    
    public Map<Id, LoanApplicant> masterApplicantMap = new Map<Id, LoanApplicant>();
    
    public LoanApplicantIncomeService() {}

    public void getParentRecords(List<LoanApplicantIncome> records){
        Set<Id> parentApplicantIDSet = new Set<Id>();
        for(LoanApplicantIncome record : records){
                parentApplicantIDSet.add(record.LoanApplicantId);
        }
        masterApplicantMap = new Map<Id, LoanApplicant>([SELECT Id, LoanApplicationId, LoanApplication.OpportunityId FROM LoanApplicant 
                                                                        WHERE ID IN: parentApplicantIDSet]);
    }
    
    public void updateTDSR(List<LoanApplicantIncome> records) {
        if(masterApplicantMap.isEmpty() || (!masterApplicantMap.isEmpty() && records.size() != masterApplicantMap.size())){
            getParentRecords(records);
        }
        if (!TDSRCalculationService.runTDSROnce && !System.isFuture() && !System.isBatch()) {
            Set<Id> oppIds = new Set<Id>();
            Map<Id, String> appIds = new Map<Id, String>();
            for (LoanApplicantIncome record : records) {
                oppIds.add(masterApplicantMap.get(record.LoanApplicantId).LoanApplication.OpportunityId);
                appIds.put(masterApplicantMap.get(record.LoanApplicantId).LoanApplication.OpportunityId, masterApplicantMap.get(record.LoanApplicantId).LoanApplicationId);
            }
            if(!Test.isRunningTest()){
                for (String oppId : oppIds) {
                    TDSRCalculationService.runTDSROnce = true; TDSRCalculationService.runTDSRCalculation(oppId, appIds.get(oppId));
            	}
            }
        }
    }
}