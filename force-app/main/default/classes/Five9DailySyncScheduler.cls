global class Five9DailySyncScheduler implements Schedulable {
  public static final String JOB_NAME = 'Five9 Dial list batch job';

  global void execute(SchedulableContext sc) {
    Five9DailySync five9Sync = new Five9DailySync();
    DataBase.executeBatch(five9Sync, 20);
  }
}