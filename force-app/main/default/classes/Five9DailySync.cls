global class Five9DailySync implements Database.Batchable<sObject> {
  global Database.QueryLocator start(Database.BatchableContext ctx) {
    return Database.getQueryLocator(
      'SELECT Id, Delete_from_f9list_id__c, Current_Five9_List__c ' +
      'FROM Account WHERE  Current_Five9_List__c != null AND Dial_List_Main__c = false '
    );
  }

  /*
   * Process accounts to return.
   */
  global void execute(Database.BatchableContext ctx, List<Account> accList) {
    List<Account> accupd = new List<Account>();
    for (Account acc : accList) {
      acc.Delete_from_f9list_id__c = acc.Current_Five9_List__c;
      acc.Current_Five9_List__c = null;
      accupd.add(acc);
    }

    update accupd;
  }

  /*
   * Finish method - close off batch activities.
   */
  global void finish(Database.BatchableContext ctx) {
    
  }
}