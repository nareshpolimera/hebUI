public with sharing class LoanApplicationFinancialService {
    //Method to auto-generate Name
    //Format: LAF-00000001
    public void generateAutoName(List<LoanApplicationFinancial> records) {        
        AutomatedNameGenerator.generateNextSequenceName(records, LoanApplicationFinancial.SobjectType);
    }
}