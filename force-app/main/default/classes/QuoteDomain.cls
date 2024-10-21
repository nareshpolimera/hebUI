public class QuoteDomain {

    private QuoteService service = new QuoteService();
   
    public void beforeInsert(List<Quote> records) {
        service.updateFileRecordType(records);
    }
    
    public void afterInsert(List<Quote> records,  Map<Id, Quote> newRecords) {
        
    }
    
    public void beforeUpdate(List<Quote> records, Map<Id, Quote> oldRecords) {
        service.lockMARSQuote(records, oldRecords);
        service.updateFileRecordType(records);
    }  
    
    public void afterUpdate(List<Quote> records, Map<Id, Quote> oldRecords) {
        
    }
}