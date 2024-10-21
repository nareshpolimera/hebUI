/******************************************************//**
@Class      AccountContactDomain
@brief      Domain class for trigger of the AccountContactRelation object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class AccountContactDomain {
    
    private AccountContactService service = new AccountContactService();

    public void afterInsert(List<AccountContactRelation> records)
    {
        service.updateReferralPartnerPlatformEvent(records, null);
    }

    public void afterUpdate(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldRecords)
    {
        service.updateReferralPartnerPlatformEvent(records, oldRecords);
    }    
}