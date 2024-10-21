public class EventHandler {
    
    public EventHandler(List<Event> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<Event> records)
    {
        new EventDomain().beforeInsert(records);
    }

    public void beforeUpdate(List<Event> records, Map<Id, Event> oldRecords) 
    {
        new EventDomain().beforeUpdate(records, oldRecords);
    }

    public void afterInsert(List<Event> records)
    {
        new EventDomain().afterInsert(records);
    }
    
    private void init(List<Event> records)
    {
    }
}