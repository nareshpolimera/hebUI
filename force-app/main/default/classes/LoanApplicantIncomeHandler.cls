public with sharing class LoanApplicantIncomeHandler {
    
    public LoanApplicantIncomeHandler(List<LoanApplicantIncome> records) 
    {
        init(records);
    }

    public void afterInsert(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> newMap)
    {
        new LoanApplicantIncomeDomain().afterInsert(records, newMap);
    }

    public void afterUpdate(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> oldMap )
    {
        new LoanApplicantIncomeDomain().afterUpdate(records, oldMap);
    }

    public void afterDelete(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> oldMap)
    {
        new LoanApplicantIncomeDomain().afterDelete(records, oldMap);
    }

    private void init(List<LoanApplicantIncome> records) {}
    
}