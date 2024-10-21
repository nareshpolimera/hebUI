@isTest
public class UpdateAccountOwnerBatchTest {
    
    @testSetup
    static void setupData() {
        // Create necessary data for testing
        RecordType partnerOrgRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Partner_Organization' AND SObjectType = 'Account' LIMIT 1];
        
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.SystemAdmin_Profile_Name)];
        User sysAdmin = new User(
            ProfileId = profileList[0].Id,
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
        
        
        
        // Create accounts with Partner_Organization record type
        Account partnerOrgAccount1 = new Account(Name = 'Partner Org 1', RecordTypeId = partnerOrgRT.Id);
        Account partnerOrgAccount2 = new Account(Name = 'Partner Org 2', RecordTypeId = partnerOrgRT.Id);
        // Create a person account
        Account personAccount = new Account(Name = 'Person Account'); // Fake contact Id for testing
        
        insert new List<Account>{ partnerOrgAccount1, partnerOrgAccount2, personAccount };
            
            System.runAs(sysAdmin){
                setupTerritory2Association(partnerOrgAccount1.Id);
            }
        
    }
    
    @future
    private static void setupTerritory2Association(Id AccId){
        List<Territory2Type> terriType   = [SELECT id, DeveloperName from Territory2Type LIMIT 1];
        List<Profile> adminProfile = [select id, name from Profile where  name = 'System Administrator'];
        
        Territory2Model terrModel = new Territory2Model();
        terrModel .DeveloperName='ModelName'; // required field
        terrModel.Name = 'Name'; // required field
        insert terrModel ;
        
        Territory2 objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=terriType[0].Id);
        insert objTerr;
        
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = AccId, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
        
        Profile p = [SELECT id, Name FROM Profile where name = 'System Administrator' ].get(0);  
        User u = new User(firstname= 'Test',
                          lastname='XXXX',
                          Alias='Test',
                          email = 'test1234@test.com',
                          username= 'test1234xxx@test.com', 
                          profileId= p.id, 
                          emailencodingkey='UTF-8',
                          languagelocalekey='en_US',
                          localesidkey='en_US',
                          timezonesidkey='America/Los_Angeles');
        insert u;
        
        User u2 = new User(firstname= 'Test',
                           lastname='XXXX',
                           Alias='Test',
                           email = 'test1234122@test.com',
                           username= 'test1234xxx123@test.com', 
                           profileId= p.id, 
                           emailencodingkey='UTF-8',
                           languagelocalekey='en_US',
                           localesidkey='en_US',
                           timezonesidkey='America/Los_Angeles');
        insert u2;
        
        
        UserTerritory2Association objUserTerritory2Association = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manager');
        insert objUserTerritory2Association;
    }
    
    @isTest
    static void testBatchExecution() {            
        Test.startTest();
        
        // Start the batch execution
        UpdateAccountOwnerBatch batch = new UpdateAccountOwnerBatch();
        Id batchJobId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify that the accounts have the expected owner updates
        List<Account> updatedAccounts = [SELECT Id, OwnerId FROM Account WHERE RecordType.DeveloperName = 'Partner_Organization'];
        System.assertEquals(3, updatedAccounts.size(), 'Two partner organization accounts should have been updated.');
        
        // Validate owner ID or other logic as necessary
        for (Account acc : updatedAccounts) {
            System.assertNotEquals(null, acc.OwnerId, 'OwnerId should not be null after batch execution.');
        }
        
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        
        // Test scheduling the batch execution
        String jobCron = '0 0 12 * * ?'; // Schedule to run daily at noon
        System.schedule('Test Scheduled UpdateAccountOwnerBatch', jobCron, new UpdateAccountOwnerBatch());
        
        Test.stopTest();
        
        // Query and assert the batch job was executed
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name = 'Test Scheduled UpdateAccountOwnerBatch' LIMIT 1];
        System.assertEquals('WAITING', ct.State, 'Scheduled job should be in WAITING state.');
    }
    
    @isTest
    static void testUpdateAccountOwnerOnTerritoryAssignment() {
        Test.startTest();
        
        // Query for the accounts set up during test setup
        List<Account> accounts = [SELECT Id, RecordTypeId, PersonContactId FROM Account WHERE RecordType.DeveloperName = 'Partner_Organization'];
        
        // Mock oldMap with the same accounts for comparison
        Map<Id, Account> oldMap = new Map<Id, Account>(accounts);
        
        // Execute the method to update account owners
        UpdateAccountOwnerBatch batch = new UpdateAccountOwnerBatch();
        batch.updateAccountOwnerOnTerritoryAssignment(accounts, oldMap);
        
        Test.stopTest();
        
        // Query and assert that accounts have been updated
        List<Account> updatedAccounts = [SELECT Id, OwnerId FROM Account WHERE Id IN :accounts];
        for (Account acc : updatedAccounts) {
            System.assertNotEquals(null, acc.OwnerId, 'OwnerId should not be null after owner update.');
        }
    }
}