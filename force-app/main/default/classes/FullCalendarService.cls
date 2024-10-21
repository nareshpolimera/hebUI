public without sharing class FullCalendarService {

    @AuraEnabled(cacheable=true)
    public static List<Event> fetchAllEvents() {
        return [
            SELECT Id, Subject, WhatId, WhoId, 
                Description, EndDate, EndDateTime, OwnerId, StartDateTime,
                ActivityDate, ActivityDateTime
            FROM Event
            WHERE OwnerId IN (
                SELECT User__c
                FROM Specialist__c
            )
            AND StartDateTime >= THIS_WEEK
            ORDER BY StartDateTime
            LIMIT 2000
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Event> fetchAllEventsByUser(String userId) {
        return [
            SELECT Id, Subject, WhatId, WhoId, 
                Description, EndDate, EndDateTime, OwnerId, StartDateTime,
                ActivityDate, ActivityDateTime
            FROM Event
            WHERE OwnerId = :userId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static void createNewEvent(Datetime StartDateTime, Id OwnerId, Datetime EndDateTime, String Subject, String TypeOfMeeting, Id WhoId, Id RecordId, String Description, Boolean IsLiveTransfer)
    {
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Event.sObjectType);
        Opportunity relatedRecord = [
            SELECT Id, Name, OwnerId, StageName, Account.PersonContactId
            FROM Opportunity
            WHERE Id = :RecordId
        ];

        ResidentialLoanApplication application = [SELECT 
                                                  Id,
                                                  OwnerId
                                                  FROM ResidentialLoanApplication
                                                  WHERE OpportunityId = :RecordId
                                                  LIMIT 1];

        Event e = new Event(
            StartDateTime      = StartDateTime,
            OwnerId            = OwnerId,
            EndDateTime        = EndDateTime,
            Subject            = Subject,
            Type_of_Meeting__c = TypeOfMeeting,
            WhoId              = relatedRecord.Account.PersonContactId,
            WhatId              = RecordId,
            Description         = Description,
            Is_Live_Transfer__c = IsLiveTransfer,
            RecordTypeId        = rtIds.get('Event')
        );
        
        insert e;    

        relatedRecord.OwnerId = OwnerId;
        relatedRecord.File_Queue__c = '';
        relatedRecord.StageName = Label.Lead_Status_Assigned;
        update relatedRecord;

        
        if (application != null && application.OwnerId != OwnerId) {
            application.OwnerId = OwnerId;
            update application;   
        }

        Set<Id> userIds = new Set<Id>();
        userIds.add(relatedRecord.OwnerId);

        Map<Id, Specialist__c> spls = new Map<Id, Specialist__c>([
            SELECT Id
            FROM Specialist__c
            WHERE User__c IN :userIds
        ]);
        
        if (!spls.isEmpty() && spls.size() > 0) {
           // Increase lead assigned count.
           EventAssignmentService.incrementAssignmentCount(spls.keySet());
        }

    }
}