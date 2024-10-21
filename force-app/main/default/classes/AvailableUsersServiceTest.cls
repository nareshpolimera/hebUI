/******************************************************//**
    @Test Class      AvailableUsersServiceTest
    @brief      Class with logic test and code coverage for AvailableUsersService.
    
    @creation   2024-08-16 Mrunal Bhosale
    /******************************************************/
    @isTest
    public class AvailableUsersServiceTest {
        
        @testSetup
        static void setupTestData() {
            HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
            processSwitches.Deactivate_Triggers__c = FALSE;
            upsert processSwitches;
            
            List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.HEBStandard_Profile_Name)];
            
            User standardUser = new User(
                ProfileId = profileList[0].Id,
                Username = 'standarduser@chip.ca',
                Email = 'standarduser@chip.ca',
                FirstName = 'admin',
                LastName = 'Support',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                Alias = 'stdUser',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            insert standardUser;
        }
        
        
        @isTest
        static void testgetUsernameById() {
            User testUser = [SELECT Id, FirstName, LastName FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
            String name = testUser.FirstName+ ' '+testUser.LastName;
            Test.startTest();
            String userString = AvailableUsersService.getUsernameById(testUser.Id);
            system.assertEquals(name,userString);
            Test.stopTest();
        }
        
    }