public class QuoteHandler {

    public QuoteHandler(List<Quote> records)
    {
        init(records);
    }

    public void beforeInsert(List<Quote> records) {
        new QuoteDomain().beforeInsert(records);
    }

    public void beforeUpdate(List<Quote> records, Map<Id, Quote> oldRecords) {
        new QuoteDomain().beforeUpdate(records, oldRecords);
    }
    
    public void afterInsert(List<Quote> records, Map<Id, Quote> newMap)
    {
        new QuoteDomain().afterInsert(records, newMap);
    }

    public void afterUpdate(List<Quote> records, Map<Id, Quote> oldRecords)
    {
        new QuoteDomain().afterUpdate(records, oldRecords);
    }

    public void afterDelete(List<Quote> records, Map<Id, Quote> oldRecords)
    {
        new QuoteDomain().afterUpdate(records, oldRecords);
    }
    
    
    private void init(List<Quote> records)
    {
    }

    
}