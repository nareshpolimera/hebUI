public with sharing class LoanApplicationFinancialDomain {
    private LoanApplicationFinancialService service = new LoanApplicationFinancialService();   
    
    public void beforeInsert(List<LoanApplicationFinancial> records){
        //call method to auto-generate name
        service.generateAutoName(records);
    }
}