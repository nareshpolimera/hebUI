public class LoanApplicationPropertyDomain {

    private LoanApplicationPropertyService service = new LoanApplicationPropertyService();
    
    public void beforeInsert(List<LoanApplicationProperty> records)
    {
        //call method to auto-generate name
        service.generateAutoName(records);

        service.validatePropertyLendingArea(records,null);       
    }

    public void beforeUpdate(List<LoanApplicationProperty> records, Map<Id, LoanApplicationProperty> oldMap)
    { 
        service.validatePropertyLendingArea ( records, oldMap );
        service.updateTDSR(records, oldMap); 
    }

    public void afterInsert(List<LoanApplicationProperty> records)
    {
        service.updateQuote(records, null);
        service.fileValidation(records);     
    }
    
    public void afterUpdate(List<LoanApplicationProperty> records, Map<Id, LoanApplicationProperty> oldMap)
    {
        service.checkRequote(records, oldMap);
        service.useAvm(records, oldMap);
        service.fileValidation(records);
    }

    public void afterDelete(List<LoanApplicationProperty> records)
    {
        service.fileValidation(records);
    }
}