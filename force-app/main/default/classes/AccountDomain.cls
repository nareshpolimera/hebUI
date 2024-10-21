/******************************************************//**
@Class      AccountDomain
@brief      Domain class for trigger of the Account object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class AccountDomain
{
    private AccountService service = new AccountService();
    
    public void beforeInsert(List<Account> records)
    {
        service.checkCASLConsentUser(records, null);
        service.updateTitleOnAccount(records,null);
        service.setNumericPhone(records, null);
        service.setAreaCode(records, null);
        service.updateUnvalidatedNewPhoneNumberStatus(records);
        service.updateUnvalidatedNewEmailStatus(records);
        service.copyMailingAddress(records,null);     
    }
    
    public void beforeUpdate(List<Account> records, Map<Id, Account> oldRecords)
    {
        service.checkCASLConsentUser(records, oldRecords);        
        service.updateTitleOnAccount(records,oldRecords);
        service.updateUnvalidatedNewPhoneNumberStatus(records);
        service.updateUnvalidatedNewEmailStatus(records);
        service.generateListofChangedPhone(records, oldRecords);
        service.generateListofChangedEmail(records, oldRecords);
        service.generateListofChangedAddress(records, oldRecords);   
        service.setNumericPhone(records, oldRecords);     
        service.setAreaCode(records, oldRecords);    
        service.checkDialListMainChanges(records, oldRecords);
        service.copyMailingAddress(records,oldRecords);
    }
    
    public void afterInsert(List<Account> records)
    {
        service.createAccountContactRelationship(records,null);
        service.generateListofChangedPhone(records, null);
        service.generateListofChangedEmail(records, null);
        service.generateListofChangedAddress(records, null);       
        service.updateCodes(records, null);
    }
    
    public void afterUpdate(List<Account> records, Map<Id, Account> oldRecords)
    {
        service.createAccountContactRelationship(records,oldRecords);
        service.updateAccountAccountRelationships(records,oldRecords);
        service.addAccountMarsPlatformEvent(records,oldRecords);
        service.updateCodes(records, oldRecords);
    }
    
    public class ConsumerDomain
    {
        private AccountService service = new AccountService();
        
        public void beforeInsert(List<Account> records)
        {          
        }
        
        public void beforeUpdate(List<Account> records, Map<Id, Account> oldRecords, String description)
        {
            service.updateReferralOrganizationPlatformEvent(records, oldRecords, description);
        }
        
        public void afterInsert(List<Account> records)
        {
            service.assignDialList(records, null);
        }
        
        public void afterUpdate(List<Account> records, Map<Id, Account> oldRecords)
        {
            service.updateOpportunityName(records,oldrecords);
            service.assignDialList(records, oldRecords);
        }
    }
    
    public class PartnerDomain
    {
        private AccountService service = new AccountService();
        
        public void beforeInsert(List<Account> records)
        {
            //dg service.assignTerritoryViaFSA(records);
        }
        
        public void beforeUpdate(List<Account> records, Map<Id, Account> oldRecords)
        {
        }
        
        public void afterUpdate(List<Account> records, Map<Id, Account> oldRecords)
        {
            service.updateReferralOrganizationPlatformEvent(records, oldRecords, 'account');
        }
    }
}