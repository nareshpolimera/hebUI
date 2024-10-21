public class LoanApplicationPropertyHandler {
    public LoanApplicationPropertyHandler(list<LoanApplicationProperty> records) {
        init(records);
    }
    
    public void afterInsert(List<LoanApplicationProperty> records){
        new LoanApplicationPropertyDomain().afterInsert(records);
    }
    
    public void beforeInsert(List<LoanApplicationProperty> records)
        {
            new LoanApplicationPropertyDomain().beforeInsert(records);
        }
    
        public void beforeUpdate(List<LoanApplicationProperty> records, Map<Id, LoanApplicationProperty> oldMap)
        {
            new LoanApplicationPropertyDomain().beforeUpdate(records, oldMap);
        }
        
        public void afterUpdate(List<LoanApplicationProperty> records, Map<Id, LoanApplicationProperty> oldMap)
        {
            new LoanApplicationPropertyDomain().afterUpdate(records, oldMap);
        }

        public void afterDelete(List<LoanApplicationProperty> records)
        {
            new LoanApplicationPropertyDomain().afterDelete(records);
        }
            
        private void init(List<LoanApplicationProperty> records)
        {

        }
        
    
}