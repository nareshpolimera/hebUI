/******************************************************//**
@Class      AccountContactHandler
@brief      Handler for trigger for the AccountContactRelation object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class AccountContactHandler {

    List<AccountContactRelation> recordList = new List<AccountContactRelation>();

    public void afterInsert(List<AccountContactRelation> records)
    {       
        new AccountContactDomain().afterInsert(records);        
    }

    public void afterUpdate(List<AccountContactRelation> records, Map<Id, AccountContactRelation> oldRecords)
    {       
        new AccountContactDomain().afterUpdate(records, oldRecords);        
    }   
}