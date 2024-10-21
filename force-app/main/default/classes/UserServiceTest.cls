@IsTest
private class UserServiceTest
{
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        Profile p           = [select Id, Name from Profile where Name IN ('Standard User')][0];

        Map<String, Id> accountRecordTypes     = Utils.getRecordTypeIdsBySObjectType(Account.SObjectType);
        Account a    = new Account(
            RecordTypeId = accountRecordTypes.get('PersonAccount'),
            FirstName     = 'Alpha',
            LastName     = 'Beta',
            PersonEmail = 'alpha.beta3@chip.ca.test',
            Phone         = '555 555 5555'
        );
        insert a;

        Contact c = [select Id from Contact where Email = :a.PersonEmail];
        User u = new User(
            LastName            = a.LastName,
            FirstName           = a.FirstName,
            Alias               = 'testFirs',
            Email               = a.PersonEmail,
            Username            = a.PersonEmail,
            ProfileId           = p.id,
            // ContactId           = c.Id,
            TimeZoneSidKey      = 'America/New_York',
            LanguageLocaleKey   = 'en_US',
            EmailEncodingKey    = 'UTF-8',
            LocaleSidKey        = 'en_US'
        );
        insert u;
    }

    /*
     * HEB-74: Test method for basic coverage
     */
    @IsTest
    static void testBasicCoverage() {
        User u = [select Id, AccountId, Promotion_Opt_Out__c from User where Username = 'alpha.beta3@chip.ca.test'];

        Test.startTest();
        System.runAs(u) {
			u.Promotion_Opt_Out__c = true;
            update u;
        }
        Test.stopTest();

        List<Account> a = [select Id, FinServ__MarketingOptOut__pc from Account where Id = :u.AccountId];
        //System.assert(a.Marketing_Opt_Out__c, 'Opt Out did not sync');

        Profile p           = [select Id, Name from Profile where Name IN ('Standard User')][0];
        User user = new User(
            LastName            = 'Alpha',
            FirstName           = 'Beta',
            Alias               = 'testSec',
            Email               = 'alpha.beta4@chip.ca.test',
            Username            = 'alpha.beta4@chip.ca.test',
            ProfileId           = p.id,
            TimeZoneSidKey      = 'America/New_York',
            LanguageLocaleKey   = 'en_US',
            EmailEncodingKey    = 'UTF-8',
            LocaleSidKey        = 'en_US'
        );
        insert user;

        List <User> users = [select Id, AccountId, Promotion_Opt_Out__c from User WHERE Username = 'alpha.beta3@chip.ca.test' OR Username = 'alpha.beta4@chip.ca.test'];
        update users;
    }
}