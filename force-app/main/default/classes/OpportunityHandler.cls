public class OpportunityHandler
{
    List<Opportunity> referrals = new List<Opportunity>();
    
    public OpportunityHandler(List<Opportunity> records)
    {
        init(records);
    }
    
    public void afterInsert(List<Opportunity> records)
    {
        new OpportunityDomain().afterInsert(records);
        if (!referrals.isEmpty())
        {
            new OpportunityDomain.ReferralDomain().afterInsert(referrals);
        }
    }
    
    public void beforeUpdate(List<Opportunity> records, Map<Id, Opportunity> oldRecords)
    {
        new OpportunityDomain().beforeUpdate(records, oldRecords);
        
        if (!referrals.isEmpty())
        {
            new OpportunityDomain.ReferralDomain().beforeUpdate(referrals, oldRecords);
        }
    }

    public void beforeInsert(List<Opportunity> records)
    {
        new OpportunityDomain().beforeInsert(records);
        
        if (!referrals.isEmpty())
        {
            new OpportunityDomain.ReferralDomain().beforeInsert(referrals);
        }
    }
    
    public void afterUpdate(List<Opportunity> records, Map<Id, Opportunity> oldRecords)
    {
System.debug('Inside After Update Handler Opp');
        new OpportunityDomain().afterUpdate(records, oldRecords);
    }
    
    private void init(List<Opportunity> records)
    {
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Opportunity.sObjectType);
        
        for (Opportunity record : records)
        {
            if (rtIDs.get(OpportunityService.OPP_RT_REFERRAL) == record.recordTypeId)
            {
                referrals.add(record);
            }
        }
    }
    
    
}