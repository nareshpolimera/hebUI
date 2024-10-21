public class CampaignMemberHandler
{
    public CampaignMemberHandler(List<CampaignMember> records)
    {
        init(records);
    }

    public void beforeInsert(List<CampaignMember> records)
    {
        new CampaignMemberDomain().beforeInsert(records);
    }
    
    public void afterInsert(List<CampaignMember> records)
    {
        new CampaignMemberDomain().afterInsert(records);
    }

    public void afterUpdate(List<CampaignMember> records, Map<Id, CampaignMember> oldRecords)
    {
        new CampaignMemberDomain().afterUpdate(records, oldRecords);
    }
    
    public void beforeDelete(List<CampaignMember> records)
    {
        new CampaignMemberDomain().beforeDelete(records);
    }

    public void afterDelete(List<CampaignMember> records, Map<Id, CampaignMember> oldRecords)
    {
        new CampaignMemberDomain().afterUpdate(records, oldRecords);
    }
    
    private void init(List<CampaignMember> records)
    {
    }

}