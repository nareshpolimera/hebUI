public without sharing class EventService {
    public static final String INITIAL_CONTACT_MEETING = 'Initial Contact';
    public static final String INITIAL_CONTACT_FOLLOWUP = 'Initial Contact Follow-up';

    /*
     * HEB-402:
     * - Ensure there are no unactioned Initial Contact / Initial Contact Follow-up meetings if trying to create a new one
     * - Ensure there isn't a previously dispositioned Initial Contact if creating a new one
     * - Ensure there isn't a previously dispositioned Initial Contact Follow-up if creating a new one
     */
    public void validateNoUnactionedEvents(List<Event> records) {
        List<Event> meetingEvents = new List<Event>();
        List<Id> leadIds = new List<Id>();
        Boolean book_icm = FeatureManagement.checkPermission(
            Utils.CUSTOM_PERMISSION_BOOK_INITIAL_CONTACT_MEETING
        ); // Allow Book Additional Initial Contact Meeting
        Boolean no_icm = FeatureManagement.checkPermission(
            Utils.CUSTOM_PERMISSION_RESTRICT_INITIAL_CONTACT_MEETING
        ); // Restrict_Initial_Contact_Meeting

        for (Event e : records) {
            // skip if WhoId is null
            if (e.WhoId == null)
                continue;

            // check this is related to a Lead
            String leadId = e.WhoId;
            if (leadId.startsWith('003')) {
                // check this is a Initial Contact or Initial Contact Follow-up
                if (
                    e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING ||
                    e.Type_of_Meeting__c == INITIAL_CONTACT_FOLLOWUP
                ) {
                    if (no_icm && e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING) {
                        e.addError(Label.Error_InitialMeeting_Restricted);
                    } else {
                        meetingEvents.add(e);
                        leadIds.add(leadId);
                    }
                }
            }
        }


        // return if no relevant Events are captured
        if (meetingEvents.isEmpty())
            return;

        // get maps of the existing Meetings

        Map<Id, Event> unactionedMeetings = new Map<Id, Event>();
        Map<Id, Event> dispositionedInitialMeetings = new Map<Id, Event>();
        Map<Id, Event> dispositionedInitialFollowUps = new Map<Id, Event>();
        for (Event e : [
            SELECT Id, WhoId, Type, Type_of_Meeting__c, Not_Actioned__c, Dispositioned__c
            FROM Event
            WHERE
                WhoId IN :leadIds
                AND (Type_of_Meeting__c = :INITIAL_CONTACT_MEETING
                OR Type_of_Meeting__c = :INITIAL_CONTACT_FOLLOWUP)
                AND (Not_Actioned__c = TRUE
                OR Dispositioned__c = TRUE)
        ]) {
            if (e.Not_Actioned__c) {
                unactionedMeetings.put(e.WhoId, e);
            } else if (
                e.Dispositioned__c && e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING
            ) {
                dispositionedInitialMeetings.put(e.WhoId, e);
            } else if (
                e.Dispositioned__c && e.Type_of_Meeting__c == INITIAL_CONTACT_FOLLOWUP
            ) {
                dispositionedInitialFollowUps.put(e.WhoId, e);
            }
        }


        for (Event e : meetingEvents) {
   

            if (unactionedMeetings.get(e.WhoId) <> null) {
                e.addError(Label.Error_InitialMeeting_Unactioned);
            }
            // Allow user with Book_icm permission to book ICM if previouse meeting was dispoistioned
            if (
                e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING &&
                (dispositionedInitialMeetings.get(e.WhoId) <> null ||
                dispositionedInitialFollowUps.get(e.WhoId) <> null) &&
                book_icm
            ) {
                continue;
            }
            if (
                e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING &&
                dispositionedInitialMeetings.get(e.WhoId) <> null
            ) {
                e.addError(Label.Error_InitialMeeting_PrevDispositioned);
            }
            if (
                e.Type_of_Meeting__c == INITIAL_CONTACT_FOLLOWUP &&
                dispositionedInitialFollowUps.get(e.WhoId) <> null
            ) {
                e.addError(Label.Error_InitialFollowUp_PrevDispositioned);
            }
        }
    }

    /* HEB-560 allow lead reassignment automation on meeting owner change */
    public void reassignAssociatedLead(
        List<Event> records,
        Map<Id, Event> oldMap
    ) {
        List<Event> eventsToCheck = new List<Event>();
        List<Id> associatedContactIds = new List<Id>();
        Map<Id, Event> contactToEventMap = new Map<Id, Event>();

        for (Event e : records) {
            String contactId = e.WhoId;
            Event oldE = oldMap.get(e.Id);
            if (
                //Check if we are in icm or icf, if not do not use
                ((e.Type_of_Meeting__c == INITIAL_CONTACT_FOLLOWUP) ||
                (e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING)) &&
                //Check if we have a lead assigned, if not do not use
                (contactId <> null && contactId.startsWith('003')) &&
                //Check if we are changing assignment, if not do not use
                (e.OwnerId != oldE.OwnerId)
            ) {
                //If all the above are true select associated lead
                eventsToCheck.add(e);
                associatedContactIds.add(contactId);
                contactToEventMap.put(contactId, e);
            }
        }

        //Reassign the associated lead
        List<Contact> contactList = [
            SELECT Id
            FROM Contact
            WHERE Id IN :associatedContactIds
        ];
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact l : contactList) {
            Event e = contactToEventMap.get(l.Id);
            l.OwnerId = e.OwnerId;
            contactsToUpdate.add(l);
        }

        update contactsToUpdate;
    }

    public void setParentLeadMeetingDateTime(List<Event> records) {
        List<Account> accountUpdates = new List<Account>();
        Set<Id> contactIds = new Set<Id>();
        for (Event e : records) {
            contactIds.add(e.whoId);
        }
        Map<Id, Contact> contactsMap = new Map<Id, Contact>(
            [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]
        );
        for (Event e : records) {
            String contactId = e.WhoId;
            if (
                //Check if we are in icm or icf, if not do not use
                ((e.Type_of_Meeting__c == INITIAL_CONTACT_FOLLOWUP) ||
                (e.Type_of_Meeting__c == INITIAL_CONTACT_MEETING)) &&
                //Check if we have a lead assigned, if not do not use
                (contactId != null && contactId.startsWith('003'))
            ) {
                accountUpdates.add(
                    new Account(
                        Id = contactsMap.get(e.WhoId).AccountId,
                        Initial_Meeting_Time__c = e.StartDateTime
                    )
                );
            }
        }

        if (!accountUpdates.isEmpty()) {
            try {
                update accountUpdates;
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
    }
}