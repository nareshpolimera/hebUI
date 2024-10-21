public class LoanApplicantIncomeDomain {
    private LoanApplicantIncomeService service = new LoanApplicantIncomeService();

    public void afterInsert(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> newMap) {
        service.updateTDSR(records);
    }

    public void afterUpdate(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> oldMap) {
        service.updateTDSR(records);
    }

    public void afterDelete(List<LoanApplicantIncome> records, Map<Id, LoanApplicantIncome> oldMap) {
        service.updateTDSR(records);
    }
}