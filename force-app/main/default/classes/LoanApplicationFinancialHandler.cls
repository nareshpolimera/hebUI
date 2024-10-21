public with sharing class LoanApplicationFinancialHandler {
    public LoanApplicationFinancialHandler(List<LoanApplicationFinancial> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<LoanApplicationFinancial> records){
        new LoanApplicationFinancialDomain().beforeInsert(records);
    }
    
    private void init(List<LoanApplicationFinancial> records){
    }
}