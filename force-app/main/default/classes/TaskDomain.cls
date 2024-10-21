public class TaskDomain {
  private TaskService service = new TaskService();

  public void afterUpdate(List<Task> records, Map<Id, Task> oldRecords) {
    service.assignAssociatedCampaign(records);
    service.setCommunicationLettersSenttoClientIndicatorValues(records, oldRecords);
  }

  public void afterInsert(List<Task> records) {
    service.assignAssociatedCampaign(records);
  }

  public void beforeInsert(List<Task> records) {
    service.updateOppStatusToContacted(records);
    //service.restrictTaskCreation(records);
    service.initialPicklistValuestoDefaultFields(records);
  }

  public void beforeUpdate(List<Task> records, Map<Id, Task> oldRecords) {
    service.assignPicklistValuestoDefaultFields(records, oldRecords);
    service.resolveCase(records, oldRecords);
  }
}