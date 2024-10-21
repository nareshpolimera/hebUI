public without sharing class CampaignMemberService {

    public void rollupToLead(List<CampaignMember> records) {

        List<RollUpSummaryUtility.fieldDefinition> fieldDefinitions = 
            new List<RollUpSummaryUtility.fieldDefinition> {
                new RollUpSummaryUtility.fieldDefinition('COUNT', 'Id', 'Campaign_Member_Count__c')
        };
		RollUpSummaryUtility.rollUpTrigger(fieldDefinitions, records, 'CampaignMember', 'ContactId', 'Contact', '');
    }

    /*
     * HEB-742 Prevent call centre 
     */
    public void blockCallCentreCD(List<CampaignMember> records)
    {
        if (Trigger.isDelete && FeatureManagement.checkPermission('HEB_Call_Center_Member'))
        {
            for (CampaignMember cm : records)
            {
                    cm.addError(Label.Error_Call_Centre_Campaign_Member_CD);
            }
        }
    }

    public void updateMRIDateOnLead(List<CampaignMember> records)
    {
        List<Contact> lds = new List<Contact>();
        List<Id>   lid = new List<Id>();
        for (CampaignMember cm : records)
        {
            if (cm.ContactId != null)
            {
                lid.add(cm.ContactId);
            }
        }

        if (!lid.isEmpty())
        {
            lds = [SELECT Id, Most_Recent_Inquiry_Date__c FROM Contact WHERE ID IN :lid];
            if (!lds.isEmpty())
            {
                for (Contact ld : lds) {
                    ld.Most_Recent_Inquiry_Date__c = Datetime.now();
                }

                update lds;
            }
        }
    }
    
}