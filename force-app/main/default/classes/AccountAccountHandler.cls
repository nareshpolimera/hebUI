/******************************************************/ /**
@Class      AccountAccountHandler
@brief      Handler for trigger for the /******************************************************/ /**
@Class      AccountAccountHandler
@brief      Handler for trigger for the FinServ__AccountAccountRelation__c object.

@revision   2024-06-13 Azadeh Ahmadi
            Porting from legacy SF org.
/******************************************************/
public class AccountAccountHandler {
  List<FinServ__AccountAccountRelation__c> recordList = new List<FinServ__AccountAccountRelation__c>();

  public void beforeInsert(List<FinServ__AccountAccountRelation__c> records) {
    system.debug(
      'AccountAccountHandler > beforeInsert - FinServ__AccountAccountRelation__c ' +
      recordList.size()
    );
    new AccountAccountDomain().beforeInsert(records);
  }

  public void beforeDelete(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
  ) {
    system.debug(
      'AccountAccountHandler > beforeDelete - FinServ__AccountAccountRelation__c ' +
      recordList.size()
    );
    new AccountAccountDomain().beforeDelete(records, oldRecords);
  }

  public void afterInsert(List<FinServ__AccountAccountRelation__c> records) {
    system.debug(
      'AccountAccountHandler > afterInsert - FinServ__AccountAccountRelation__c ' +
      recordList.size()
    );
    new AccountAccountDomain().afterInsert(records);
  }

  public void afterUpdate(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
  ) {
    system.debug(
      'AccountAccountHandler > afterUpdate - FinServ__AccountAccountRelation__c ' +
      recordList.size()
    );
    new AccountAccountDomain().afterUpdate(records, oldRecords);
  }
}