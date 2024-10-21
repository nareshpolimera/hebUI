public class LoanApplicationLiabilityHandler {
    public LoanApplicationLiabilityHandler(
        List<LoanApplicationLiability> records
    ) {
        init(records);
    }

    public void beforeInsert(List<LoanApplicationLiability> records) {
        new LoanApplicationLiabilityDomain().beforeInsert(records);
    }

    public void afterInsert(
        List<LoanApplicationLiability> records,
        Map<Id, LoanApplicationLiability> newMap
    ) {
        new LoanApplicationLiabilityDomain().afterInsert(records, newMap);
    }

    public void beforeUpdate(
        List<LoanApplicationLiability> records,
        Map<Id, LoanApplicationLiability> oldRecords
    ) {
        new LoanApplicationLiabilityDomain().beforeUpdate(records, oldRecords);
    }

    public void beforeDelete(Map<Id, LoanApplicationLiability> oldRecords) {
        new LoanApplicationLiabilityDomain().beforeDelete(oldRecords);
    }
    public void afterUpdate(
        List<LoanApplicationLiability> records,
        Map<Id, LoanApplicationLiability> newMap
    ) {
        new LoanApplicationLiabilityDomain().afterUpdate(records,newMap);
    }
    public void afterDelete(Map<Id, LoanApplicationLiability> oldRecords) {
        new LoanApplicationLiabilityDomain().afterDelete(oldRecords);
    }

    private void init(List<LoanApplicationLiability> records) {
    }
}