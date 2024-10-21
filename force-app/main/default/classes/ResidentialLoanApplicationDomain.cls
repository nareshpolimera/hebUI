public with sharing class ResidentialLoanApplicationDomain {
    private ResidentialLoanApplicationService service = new ResidentialLoanApplicationService();
    
    public void beforeInsert(List<ResidentialLoanApplication> records) {
        service.generateName(records);
    }
    
    public void afterInsert(List<ResidentialLoanApplication> records) {
    }
    
    public void beforeUpdate(
        List<ResidentialLoanApplication> records,
        Map<Id, ResidentialLoanApplication> oldRecords
    ) {
                
    }
    
    public void afterUpdate(
        List<ResidentialLoanApplication> records,
        Map<Id, ResidentialLoanApplication> oldRecords
    ) {
        service.updateQuote(records, oldRecords);
      	service.updateOpportunityLoanPurpose(records);
    }
    

    
}