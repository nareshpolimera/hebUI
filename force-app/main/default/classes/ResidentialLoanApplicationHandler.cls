public with sharing class ResidentialLoanApplicationHandler {
    List<ResidentialLoanApplication> referrals = new List<ResidentialLoanApplication>();
    
    public ResidentialLoanApplicationHandler(List<ResidentialLoanApplication> records) {
        init(records);
    }
    
    public void afterInsert(List<ResidentialLoanApplication> records) {
        new ResidentialLoanApplicationDomain().afterInsert(records);
    }
    
    public void beforeInsert(List<ResidentialLoanApplication> records) {
        new ResidentialLoanApplicationDomain().beforeInsert(records);
    }
    
    public void beforeUpdate( List<ResidentialLoanApplication> records, Map<Id, ResidentialLoanApplication> oldRecords) {
        new ResidentialLoanApplicationDomain().beforeUpdate(records, oldRecords);
    }
    
    public void afterUpdate(List<ResidentialLoanApplication> records, Map<Id, ResidentialLoanApplication> oldMap) {
        new ResidentialLoanApplicationDomain().afterUpdate(records, oldMap);
    }
    
    private void init(List<ResidentialLoanApplication> records) {
    }
    

}