@IsTest
private class EventServiceTest {
    @testSetup
    static void setupTestData(){
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        //TestFactory.initTestData();

        Account partnerAcc = TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert partnerAcc;
        Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        insert op1;
        Lead l1 = TestFactory.createConsumerLead('Test', 'Drive', 'testdrive@chip.ca');
        insert l1;
    }
    
    @IsTest
    static void testThatSecondInitialContactCannotBeCreated() {
        Account account = [SELECT Id, PersonContactId FROM Account WHERE FirstName = 'West Toronto' LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId FROM Opportunity WHERE Name = 'Test Drive'];
        opp.AccountId = account.Id;
        update opp;
        // grab one of the Lead records created in the TestFactory
        Lead l = [SELECT Id FROM Lead WHERE Email = 'testdrive@chip.ca'];
        
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Event.sObjectType);
        
        Test.StartTest();
        Event meeting = new Event(WhoId = account.PersonContactId, Type_of_Meeting__c = EventService.INITIAL_CONTACT_MEETING, StartDateTime = datetime.now(), DurationInMinutes = 60, RecordTypeId = rtIds.get('AdvisorEvent'));
        insert meeting;
        
        Account lCheck = [select Id, Initial_Meeting_Time__c from Account where Id = :account.Id];
        System.assertEquals(lCheck.Initial_Meeting_Time__c, meeting.StartDateTime);
        
        Event meetingCheck = [select Id, Not_Actioned__c, Dispositioned__c from Event where Id = :meeting.Id];
        System.assertEquals(meetingCheck.Not_Actioned__c, true);
        System.assertEquals(meetingCheck.Dispositioned__c, false);
        
        Boolean secondMeetingFailed = false;
        String errorStr = null;
        Event meeting2 = new Event(WhoId = account.PersonContactId, Type_of_Meeting__c = EventService.INITIAL_CONTACT_MEETING, StartDateTime = datetime.now(), DurationInMinutes = 60, RecordTypeId = rtIds.get('AdvisorEvent'));
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
            errorStr = e.getMessage();                
        }
        
        System.assert(secondMeetingFailed, 'The second meeting was inserted!');
        System.assert(errorStr.contains(Label.Error_InitialMeeting_Unactioned));
        
        // update the Event so the Dispositioned__c field will be true
        meeting.Call_Result__c = 'Meeting Held';
        meeting.Meeting_Outcome__c = 'Take Application';
        update meeting;
        
        Event meetingCheck2 = [select Id, Not_Actioned__c, Dispositioned__c from Event where Id = :meeting.Id];
        System.assertEquals(meetingCheck2.Dispositioned__c, true);
        
        secondMeetingFailed = false;
        String errorStr2 = null;
        
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
            errorStr = e.getMessage();                
        }
        
        System.assert(secondMeetingFailed, 'The second meeting was inserted!');
        System.assert(errorStr.contains(Label.Error_InitialMeeting_PrevDispositioned));
        
        // now update the Event so it will clear the way for a new Initial Contact
        meeting.Call_Result__c = 'No Show';
        meeting.Meeting_Outcome__c = '3 Attempts Made';
        update meeting;
        
        secondMeetingFailed = false;
        System.debug('about to try to insert meeting2!!!');
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
        }
        
        System.assertEquals(secondMeetingFailed, false);        
        Test.StopTest();
    }
    
    
    @IsTest
    static void testThatSecondInitialContactFollowupCannotBeCreated() {
        Account account = [SELECT Id, PersonContactId FROM Account WHERE FirstName = 'West Toronto' LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId, Account.PersonContactId FROM Opportunity WHERE Name = 'Test Drive'];
        opp.AccountId = account.Id;
        update opp;
        // grab one of the Lead records created in the TestFactory
        Lead l = [SELECT Id FROM Lead WHERE Email = 'testdrive@chip.ca'];
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(Event.sObjectType);
        
        Test.StartTest();
        Event meeting = new Event(WhoId = account.PersonContactId, Type_of_Meeting__c = EventService.INITIAL_CONTACT_FOLLOWUP, StartDateTime = datetime.now(), DurationInMinutes = 60, RecordTypeId = rtIds.get('AdvisorEvent'));
        
        insert meeting;
        
        Event meetingCheck = [select Id, Not_Actioned__c, Dispositioned__c from Event where Id = :meeting.Id];
        System.assertEquals(meetingCheck.Not_Actioned__c, true);
        System.assertEquals(meetingCheck.Dispositioned__c, false);
        
        Boolean secondMeetingFailed = false;
        String errorStr = null;
        Event meeting2 = new Event(WhoId = account.PersonContactId, Type_of_Meeting__c = EventService.INITIAL_CONTACT_FOLLOWUP, StartDateTime = datetime.now(), DurationInMinutes = 60, RecordTypeId = rtIds.get('AdvisorEvent'));
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
            errorStr = e.getMessage();                
        }
        
        System.assert(secondMeetingFailed, 'The second meeting was inserted!');
        System.assert(errorStr.contains(Label.Error_InitialMeeting_Unactioned));
        
        // update the Event so the Dispositioned__c field will be true
        meeting.Call_Result__c = 'Meeting Held';
        meeting.Meeting_Outcome__c = 'Take Application';
        update meeting;
        
        Event meetingCheck2 = [select Id, Not_Actioned__c, Dispositioned__c from Event where Id = :meeting.Id];
        System.assertEquals(meetingCheck2.Dispositioned__c, true);
        
        secondMeetingFailed = false;
        String errorStr2 = null;
        
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
            errorStr = e.getMessage();                
        }
        
        System.assert(secondMeetingFailed, 'The second meeting was inserted!');
        System.assert(errorStr.contains(Label.Error_InitialFollowUp_PrevDispositioned));
        
        // now update the Event so it will clear the way for a new Initial Contact
        meeting.Call_Result__c = 'No Show';
        meeting.Meeting_Outcome__c = '3 Attempts Made';
        update meeting;
        
        secondMeetingFailed = false;
        
        try {
            insert meeting2;
        } catch(DmlException e) {
            secondMeetingFailed = true;
        }    
        System.assertEquals(secondMeetingFailed, false);        
        Test.StopTest();
    }
    
}