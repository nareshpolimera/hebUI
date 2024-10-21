@isTest
public class DormantOpportunityOwnerBatchTest {
    
    @TestSetup
    static void setupTestDate(){

        List<Account> testPersonAccounts = new List<Account>();

        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account partnerAcc =  new Account(
                                        RecordTypeId = personAccountRecordTypeId,        
                                        FirstName = 'TestFirst',        
                                        LastName = 'TestLast',
                                        BillingPostalCode = 'M4M4C4',
                                        BillingCity = 'Toronto',
                                        Phone = '316023456',
                                        Most_Recent_Inquiry_Date__pc = System.today().addMonths(-7)
                                    );
        
        testPersonAccounts.add(partnerAcc);

        Account partnerAcc2 =  new Account(
                                        RecordTypeId = personAccountRecordTypeId,        
                                        FirstName = 'TestFirst2',        
                                        LastName = 'TestLast2',
                                        BillingPostalCode = 'M4M4C4',
                                        BillingCity = 'Toronto',
                                        Phone = '316023456',
                                        Most_Recent_Inquiry_Date__pc = System.today().addMonths(-7)
                                    );
                                            
        testPersonAccounts.add(partnerAcc2);
        
        insert testPersonAccounts;

        User activeUser = new User(
            FirstName = 'ActiveUser',
            LastName = 'OwnerBatch',
            Username = 'activeOwnerBatch@test.com',
            Email = 'activeOwnerBatch@test.com',
            Alias = 'actv',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            IsActive = true,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert activeUser;

        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Pre-Application',
            Channel__c = 'Consumer',
            Is_Redacted__c = false,
            MARS_Stage__c = null,
            LeadSource = 'Other',
            CloseDate = System.today().addMonths(1),
            AccountId = partnerAcc2.Id
        );
        testOpportunities.add(opp1);
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Pre-Application',
            Channel__c = 'Consumer',
            Is_Redacted__c = false,
            MARS_Stage__c = null,
            LeadSource = 'Other',
            CloseDate = System.today().addMonths(1),
            AccountId = partnerAcc.Id
        );
        testOpportunities.add(opp2);

        insert testOpportunities;

        Id eventRecordType =  Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Event').getRecordTypeId();
        Event event1 = new Event(
            WhatId = opp1.Id,
            Type_Of_Meeting__c = 'Initial Contact',
            ActivityDate = System.today().addMonths(-8),
            DurationInMinutes = 25,
            ActivityDateTime = System.now().addMonths(-8),
            RecordTypeId = eventRecordType
        );
        insert event1;

        Task task1 = new Task(
            WhatId = opp2.Id,
            ActivityDate = System.today().addMonths(-9),
            CallDurationInSeconds = 20
        );
        insert task1;
    }

    @isTest
    static void oppDormantBatchTest_Success() {

        User activeUser = [SELECT Id, UserName FROM User WHERE UserName = 'activeOwnerBatch@test.com'];

        MARS_Integration_Settings__c settings = new MARS_Integration_Settings__c();
        settings.MARS_Integration_User_Id__c = activeUser.Id;
        insert settings;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for(Opportunity oppRec : [SELECT Id, OwnerId, File_Queue__c FROM Opportunity]){
            oppRec.File_Queue__c = null;
            oppsToUpdate.add(oppRec);
        }
        update oppsToUpdate;
        
        // Start the batch
        Test.startTest();
        DormantOpportunityOwnerUpdateBatch batch = new DormantOpportunityOwnerUpdateBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the outcomes
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId, File_Queue__c FROM Opportunity];

        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Initial Contact', opp.File_Queue__c, 'The opportunity owner should be updated to the Initial Contact Queue');
            System.assertEquals(activeUser.Id, opp.OwnerId, 'The opportunity owner should be updated to MARS Integration');
        }
    }


    @isTest
    static void oppDormantBatchTest_NoOwnerUpdate() {

        User activeUser = [SELECT Id, UserName FROM User WHERE UserName = 'activeOwnerBatch@test.com'];

        MARS_Integration_Settings__c settings = new MARS_Integration_Settings__c();
        settings.MARS_Integration_User_Id__c = activeUser.Id;
        insert settings;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Id eventRecordType =  Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Event').getRecordTypeId();

        List<Event> newEventsToOpp = new List<Event>();
        List<Task> newtasksForOpp = new List<Task>();

        for(Opportunity oppRec : [SELECT Id, OwnerId, File_Queue__c FROM Opportunity]){
            oppRec.File_Queue__c = null;
            oppsToUpdate.add(oppRec);

            Event oppEvent = new Event(
                WhatId = oppRec.Id,
                Type_Of_Meeting__c = 'Initial Contact',
                ActivityDate = System.today().addMonths(-1),
                DurationInMinutes = 20,
                ActivityDateTime = System.now().addMonths(-1),
                RecordTypeId = eventRecordType
            );
            newEventsToOpp.add(oppEvent);


            Task oppTask = new Task(
                WhatId = oppRec.Id,
                ActivityDate = System.today().addMonths(-2),
                CallDurationInSeconds = 15
            );
            newtasksForOpp.add(oppTask);
        }

        update oppsToUpdate;
        insert newtasksForOpp;
        insert newEventsToOpp;
        
        // Start the batch
        Test.startTest();
        DormantOpportunityOwnerUpdateBatch batch = new DormantOpportunityOwnerUpdateBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the outcomes
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId, File_Queue__c FROM Opportunity];

        for (Opportunity opp : updatedOpportunities) {
            System.assertNotEquals(activeUser.Id, opp.OwnerId, 'The opportunity owner should not be updated as there is recent activity');
        }
    }
}