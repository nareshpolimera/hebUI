public class LoanApplicationAssetDomain {
    private LoanApplicationAssetService service = new LoanApplicationAssetService();

    public void beforeInsert(List<LoanApplicationAsset> records) {
        service.setOwner(records);
    }

    public void afterInsert(
        List<LoanApplicationAsset> records,
        Map<Id, LoanApplicationAsset> newMap
    ) {
    }

    public void beforeUpdate(
        List<LoanApplicationAsset> records,
        Map<Id, LoanApplicationAsset> oldRecords
    ) {}
}