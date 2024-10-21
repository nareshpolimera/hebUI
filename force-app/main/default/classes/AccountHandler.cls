/******************************************************//**
@Class      AccountHandler
@brief      Handler for trigger for the Account object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class AccountHandler
{
    public static final String ACCOUNT_RT_CONSUMER = 'Consumer';
    public static final String ACCOUNT_RT_CLIENT = 'PersonAccount';
    public static final String ACCOUNT_RT_PARTNER = 'HEB_Bank';

    public static final String ACCOUNT_RT_FSC_ACCOUNT = 'FSC_Account';
    public static final String ACCOUNT_RT_HOUSEHOLD = 'IndustriesHousehold';
    public static final String ACCOUNT_RT_INDIVIDUAL = 'IndustriesIndividual';
    public static final String ACCOUNT_RT_MEMBER_ORG = 'Membership_Organization';
    public static final String ACCOUNT_RT_PARTNER_ORG = 'Partner_Organization';    
    
    List<Account> consumers = new List<Account>();

    List<Account> consumers2 = new List<Account>();
    
    List<Account> partners = new List<Account>();
    
    public AccountHandler(List<Account> records)
    {
        init(records);
    }
    
    public void beforeInsert(List<Account> records)
    {
        new AccountDomain().beforeInsert(records);
        
        if (!consumers.isEmpty())
        {
            new AccountDomain.ConsumerDomain().beforeInsert(consumers);
        }
        else if (!partners.isEmpty())
        {
            new AccountDomain.PartnerDomain().beforeInsert(partners);
        }
    }

    public void beforeUpdate(List<Account> records, Map<Id, Account> oldRecords) {
        new AccountDomain().beforeUpdate(records, oldRecords);
        if (!consumers.isEmpty())
        {
            new AccountDomain.ConsumerDomain().beforeUpdate(consumers, oldRecords,'pa_client');
        }
        if (!consumers2.isEmpty())
        {
            new AccountDomain.ConsumerDomain().beforeUpdate(consumers2, oldRecords,'pa_partner');
        }

    }
    
    public void afterUpdate(List<Account> records, Map<Id, Account> oldRecords)
    {
        new AccountDomain().afterUpdate(records, oldRecords);
        if (!partners.isEmpty())
        {
            new AccountDomain.PartnerDomain().afterUpdate(partners, oldRecords);
        }
        if (!consumers.isEmpty())
        {
            new AccountDomain.ConsumerDomain().afterUpdate(consumers, oldRecords);
        }
    }

    public void afterInsert(List<Account> records)
    {
        new AccountDomain().afterInsert(records);        
    }
    
    private void init(List<Account> records)
    {
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Account.sObjectType);
        
        for (Account record : records)
        {
            if (rtIDs.get(ACCOUNT_RT_CLIENT) == record.recordTypeId)
            {
                consumers.add(record);
            }
            else if (rtIDs.get(ACCOUNT_RT_PARTNER ) == record.recordTypeId)
            {
                consumers2.add(record);
            }
            else if (rtIDs.get(ACCOUNT_RT_HOUSEHOLD) == record.recordTypeId 
                    || rtIDs.get(ACCOUNT_RT_FSC_ACCOUNT) == record.recordTypeId
                    || rtIDs.get(ACCOUNT_RT_INDIVIDUAL) == record.recordTypeId
                    || rtIDs.get(ACCOUNT_RT_MEMBER_ORG) == record.recordTypeId
                    || rtIDs.get(ACCOUNT_RT_PARTNER_ORG) == record.recordTypeId)
            {
                partners.add(record);
            }
        }
    }
}