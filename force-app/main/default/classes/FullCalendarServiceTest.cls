/******************************************************/ /**
@Class      FullCalendarServiceTest
@brief      Unit Test for FullCalendarService.

/******************************************************/
@IsTest
public with sharing class FullCalendarServiceTest {
    @TestSetup
    static void makeData() {
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
        
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        Profile adminProfile = [SELECT Id, Name
                                FROM Profile
                                WHERE
                                Name = :Label.SystemAdmin_Profile_Name
                               ];
        
        
        User sysAdmin = new User(
            ProfileId = adminProfile.Id,
            Username = 'testadmin@chip.ca',
            Email = 'testadmin@chip.ca',
            FirstName = 'admin',
            LastName = 'IT',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sysAdmin;
        System.runAs(sysadmin) {
            Account account = new Account(FirstName = 'Test', LastName = 'Test');
            insert account;
            Opportunity opportunity = new Opportunity(
                Name = 'Test',
                AccountId = account.Id,
                StageName = OpportunityService.DEFAULT_OPP_STAGE,
                CloseDate = System.today()
            );
            insert opportunity;
            
            // Insert a record with a Generated_Number__c value
            ResidentialLoanApplication application = new ResidentialLoanApplication(
                OpportunityId = opportunity.Id,
                Name = 'Name..');
            insert application;
            
            Specialist__c sp = TestFactory.createSpecialist(sysAdmin.Id);
            insert sp;
        }
        
    }
    
    // Test method to cover scenario where latestRecord is not null
    @isTest
    static void testCreateEvent() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        
        Test.startTest();
        
        Specialist__c sp = TestFactory.createSpecialist(UserInfo.getUserId());
        sp.Total_Lead_Assignment_Count__c = 10;
        sp.Assigned_Leads_Count__c = 10;
        insert sp;
        
        FullCalendarService.createNewEvent(DateTime.now(), UserInfo.getUserId(), Datetime.now().addDays(1), 'Subject', 
                                           'Initial Contact', UserInfo.getUserId(), opp.Id, 'Description', false);
        
        EventAssignmentService.getSortedSpecialistList();
        
        Test.stopTest();
        
        Event e = [Select Id 
                   FROM Event
                   WHERE WhatId = :opp.Id];
        System.assert(e != null, 'expected event to be created');
        
        opp = [SELECT Id, OwnerId 
               FROM Opportunity
               WHERE Id =:opp.Id ];
        System.assertEquals(UserInfo.getUserId(), opp.OwnerId, 'Expected Opp owner to have changed');
        ResidentialLoanApplication application = [SELECT
                                                  Id,
                                                  OwnerId
                                                  FROM
                                                  ResidentialLoanApplication
                                                  WHERE
                                                  OpportunityId = :opp.Id];
        System.assertEquals(UserInfo.getUserId(), application.OwnerId, 'Expected application owner to have changed');
        
    }
}