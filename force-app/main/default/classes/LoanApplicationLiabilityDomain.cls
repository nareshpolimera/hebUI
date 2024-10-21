public class LoanApplicationLiabilityDomain {
    private LoanApplicationLiabilityService service = new LoanApplicationLiabilityService();

    public void beforeInsert(List<LoanApplicationLiability> records) {
        //call method to auto-generate name
        service.generateAutoName(records);
        service.setOwner(records);
        service.updateFileRecordType(records);
    }

    public void afterInsert( List<LoanApplicationLiability> records, Map<Id, LoanApplicationLiability> newMap) {
        service.updateTDSR(records);
    }

    public void afterUpdate(List<LoanApplicationLiability> records, Map<Id, LoanApplicationLiability> oldRecords) {
        service.updateTDSR(records);
        service.updateQuote(records, oldRecords);
    }

    public void beforeUpdate(
        List<LoanApplicationLiability> records,
        Map<Id, LoanApplicationLiability> oldRecords
    ) {
        service.updateFileRecordType(records);
    }

    public void beforeDelete(Map<Id, LoanApplicationLiability> oldRecords) {
        service.onDeleteValidation(oldRecords);
    }

    public void afterDelete(Map<Id, LoanApplicationLiability> oldRecords) {
        service.updateTDSR(oldRecords.values());
    }
}