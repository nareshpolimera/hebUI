public class EventDomain 
{
    private EventService service = new EventService();
    
    public void beforeInsert(List<Event> records)
    {
        service.validateNoUnactionedEvents(records);
    }

    public void beforeUpdate(List<Event> records, Map<Id, Event> oldRecords) {
        service.reassignAssociatedLead(records, oldRecords);
    }
    
    public void afterInsert(List<Event> records) {
        service.setParentLeadMeetingDateTime(records);
    }
}