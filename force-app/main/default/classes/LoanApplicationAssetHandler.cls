public class LoanApplicationAssetHandler {
    public LoanApplicationAssetHandler(List<LoanApplicationAsset> records) {
        init(records);
    }

    public void beforeInsert(List<LoanApplicationAsset> records) {
        new LoanApplicationAssetDomain().beforeInsert(records);
    }

    public void afterInsert(
        List<LoanApplicationAsset> records,
        Map<Id, LoanApplicationAsset> newMap
    ) {
        new LoanApplicationAssetDomain().afterInsert(records, newMap);
    }

    public void beforeUpdate(
        List<LoanApplicationAsset> records,
        Map<Id, LoanApplicationAsset> oldRecords
    ) {
        new LoanApplicationAssetDomain().beforeUpdate(records, oldRecords);
    }

    private void init(List<LoanApplicationAsset> records) {
    }
}