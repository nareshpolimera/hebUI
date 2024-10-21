public class TaskHandler {
  public TaskHandler(List<Task> records) {
    init(records);
  }

  public void afterUpdate(List<Task> records, Map<Id, Task> oldRecords) {
    new TaskDomain().afterUpdate(records, oldRecords);
  }

  public void afterInsert(List<Task> records) {
    new TaskDomain().afterInsert(records);
  }

  public void beforeInsert(List<Task> records) {
    new TaskDomain().beforeInsert(records);
  }

  public void beforeUpdate(List<Task> records, Map<Id, Task> oldRecords) {
    new TaskDomain().beforeUpdate(records, oldRecords);
  }

  private void init(List<Task> records) {
  }
}