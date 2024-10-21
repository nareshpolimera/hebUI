/******************************************************/ /**
@Class      AccountAccountDomain
@brief      Domain class for trigger of the FinServ__AccountAccountRelation__c object.

@revision   2024-06-14 Azadeh Ahmadi
            Porting from legacy SF org.
/******************************************************/
public class AccountAccountDomain {
  private AccountAccountService service = new AccountAccountService();

  public void beforeInsert(List<FinServ__AccountAccountRelation__c> records) {
  }

  public void beforeUpdate(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
  ) {
  }

  public void beforeDelete(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
  ) {
  }

  public void afterInsert(List<FinServ__AccountAccountRelation__c> records) {
    service.updateReferralPartnerPlatformEvent(records, null);
    service.deactivatePreviousRecords(records, null);
  }

  public void afterUpdate(
    List<FinServ__AccountAccountRelation__c> records,
    Map<Id, FinServ__AccountAccountRelation__c> oldRecords
  ) {
    service.updateReferralPartnerPlatformEvent(records, oldRecords);
  }
}