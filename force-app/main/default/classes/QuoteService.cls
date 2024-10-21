public without sharing class QuoteService {
    
    public void lockMARSQuote(List<Quote> records, Map<Id, Quote> oldRecords) {
        Map<String, Id> oppRTIds = Utils.getRecordTypeIdsBySObjectType(Opportunity.sObjectType);
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.Quote.fieldSets.MARS_Locked_Fields.getFields());
        
        Set<Id> oppIDs = new Set<Id>();
        for (Quote q : records)
        {
            if (q.OpportunityId != null && oldRecords.get(q.Id).OpportunityId != null)
            {
                oppIDs.add(q.OpportunityId);
            }
        }
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([
            SELECT Id
            FROM Opportunity
            WHERE Id IN :oppIDs
        ]);
        
        for (Quote q : (List<Quote>) Utils.getChangedObjects(records, oldRecords, fieldsToCheck))
        {
            if (opps.containsKey(q.OpportunityId) && !FeatureManagement.checkPermission(Utils.CUSTOM_PERMISSION_CIRCUMVENT_LAUNCH_TO_MARS))
            {
                q.addError(Label.File_Sent_to_MARS);
            }
        }
    }

    public void updateFileRecordType(List<Quote> records) {
        List<Quote> rList = new List<Quote>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        List<Id> ls = new List<Id>();
        for(Quote record : records) {
            if (record.OpportunityId != null)  {
                //System.debug('!!! Related Lead record Type Id = '+record.lead__r.RecordTypeId);
                ls.add(record.OpportunityId);
            }
        }
        for ( Opportunity ld : [SELECT Id, RecordTypeId, RecordType.Name FROM Opportunity WHERE Id IN: ls ] )
        {
            if ( ld.RecordType.Name != null) 
            {
                opportunityMap.put( ld.id, ld );
            }
        }
                
        for(Quote record : records) {
            if (record.OpportunityId != null)  {
                System.debug('!!! Related Opp ID = '+record.OpportunityId);

                record.File_Record_Type__c = (opportunityMap.get(record.OpportunityId).RecordType.Name).contains( Label.File_RecordType_Referred )
                ? Label.File_RecordType_Referred
                : Label.File_RecordType_Consumer ;
                
                System.debug('!!! Record.File-Record-Type__c = '+ record.File_Record_Type__c);
            }
           
            rList.add(record);
        }
    }

}