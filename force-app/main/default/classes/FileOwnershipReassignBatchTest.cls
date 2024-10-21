@isTest
private class FileOwnershipReassignBatchTest {
    
    @TestSetup
    static void makeData(){
        Profile adminProfile = [SELECT Id, Name FROM Profile WHERE Name = :Label.SystemAdmin_Profile_Name];
        
        PermissionSetGroup marsIntegrationPermissionSetGroup = [Select Id FROM PermissionSetGroup WHERE DeveloperName = 'MARS_Integration'];
        Test.calculatePermissionSetGroup(new Id[] { marsIntegrationPermissionSetGroup.Id });
        
        
        
        // Create test Integration User with Mars Integration permission set
        User integrationUser = new User(
            FirstName = 'MarsIntegrationBatch',
            LastName = 'User',
            ProfileId = adminProfile.Id,
            Email = 'integrationuser@example.com',
            UserName = 'integrationuser@example.com',
            Alias = 'intuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert integrationUser;
       
       
    }
    
    // Test method to cover the batch job execution
    @isTest
    static void testFileOwnershipReassignBatch() {
        User integrationUser = [SELECT Id FROM User where FirstName = 'MarsIntegrationBatch'];
        PermissionSet marsIntegrationPermissionSet = [Select Id FROM PermissionSet WHERE Name = 'MARS_Integration'];
         
        // Assign Mars Integration permission set to the Integration User
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = integrationUser.Id,
                                                                  PermissionSetId = marsIntegrationPermissionSet.Id
                                                                 );
        insert psa;
        
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Opportunity testOpportunity = new Opportunity();
        System.runAs(integrationUser) { 
        Account partnerAcc = TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert partnerAcc;
        
        // Create test Opportunity with File_Queue__c = 'Inbound In-Progress' and owned by Integration User
        testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = partnerAcc.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            File_Queue__c = 'Inbound In-Progress',
            CloseDate = system.today(),
            OwnerId = integrationUser.Id
        );
        insert testOpportunity;
        }
        Test.startTest();
        // Execute the batch job
        FileOwnershipReassignBatch batch = new FileOwnershipReassignBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        // Verify the results
        Opportunity updatedOpportunity = [SELECT Id, File_Queue__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Initial Contact', updatedOpportunity.File_Queue__c, 'File_Queue__c should be updated to Initial Contact');
    }    
}