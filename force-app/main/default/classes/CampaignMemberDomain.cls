public class CampaignMemberDomain {

    private CampaignMemberService service = new CampaignMemberService();
    
    public void beforeInsert(List<CampaignMember> records) {
        service.blockCallCentreCD(records);
    }
    
    public void afterInsert(List<CampaignMember> records)
    {
        service.rollupToLead(records);
        service.updateMRIDateOnLead(records);
    }
    
    public void afterUpdate(List<CampaignMember> records, Map<Id, CampaignMember> oldRecords)
    {
        service.rollupToLead(records);
    }

    public void beforeDelete(List<CampaignMember> records)
    {
        service.blockCallCentreCD(records);
    }
    
    public void afterDelete(List<CampaignMember> records, Map<Id, CampaignMember> oldRecords) {
        service.rollupToLead(records);
    }
}