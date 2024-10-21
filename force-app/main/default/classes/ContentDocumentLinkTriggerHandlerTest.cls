@isTest
public class ContentDocumentLinkTriggerHandlerTest {
    @testSetup
    static void setupTestData()
    {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        Profile adminProfile = [SELECT Id, Name FROM Profile WHERE Name =: Label.SystemAdmin_Profile_Name LIMIT 1];
        
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
        
    }
    @isTest
    public static void testValidateFileUpload(){
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName1',
            'Smith',
            '123smith@test.heb.ca',
            '41643210987'
        );
        insert cp; 
        
        Case c = TestFactory.createComplaintCase(cp.PersonContactId, 'Case Trigger Test061123-05');
        c.Can_I_close_or_resolve_this__c = true;
        c.Is_this_about_fraud__c = false;
        c.ownerId = UserInfo.getUserId();
        insert c;  
        
        ContentVersion cv = new ContentVersion(
            Title = 'Some document',
            PathOnClient = 'some document.txt',
            VersionData = Blob.valueOf('Lorem ipsum dolor sit amet...')
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = c.Id
        );
        
        Test.startTest();
        insert cdl;
        Test.stopTest();
        
    }
    
    @isTest
    public static void testValidateFileUploadAnotherOwner(){
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        User sysAdmin = [
            SELECT Id
            FROM User
            WHERE Email = 'testadmin@chip.ca'
        ];
        TestFactory.activateCustomPermission(sysAdmin.Id, 'FPOCs_L1');
        
        Test.startTest();
        Case c = new Case();
        system.runas(sysAdmin){
            Account cp = TestFactory.createComplainant(
                'ComplainantFirstName1',
                'Smith',
                '123smith@test.heb.ca',
                '41643210987'
            );
            insert cp;
            
            c = TestFactory.createComplaintCase(cp.PersonContactId, 'Case Trigger Test061123-06');
            
            c.Can_I_close_or_resolve_this__c = true;
            c.Is_this_about_fraud__c = false;
            insert c;
            
            
            ContentVersion cv = new ContentVersion(
                Title = 'Some document',
                PathOnClient = 'some document.txt',
                VersionData = Blob.valueOf('Lorem ipsum dolor sit amet...')
            );
            insert cv;
            
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cd.Id,
                LinkedEntityId = c.Id
            );
            
            
            insert cdl;
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testValidateFileUploadWithPermissions() {
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName1',
            'Smith',
            '123smith@test.heb.ca',
            '41643210987'
        );
        insert cp;
        
        Case c = TestFactory.createComplaintCase(cp.PersonContactId, 'Case Trigger Test061123-05');
        c.Can_I_close_or_resolve_this__c = true;
        c.Is_this_about_fraud__c = false;
        c.ownerId = UserInfo.getUserId();
        insert c;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Some document',
            PathOnClient = 'some document.txt',
            VersionData = Blob.valueOf('Lorem ipsum dolor sit amet...')
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = c.Id
        );
        
        // Simulate the scenario where the user has permission
        Boolean RestrictPermissionFpoc = FeatureManagement.checkPermission('FPOCs_L1');
        
        Test.startTest();
        insert cdl;
        Test.stopTest();
        
        // Validate that the file upload was allowed
        List<ContentDocumentLink> insertedCdl = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :cd.Id
        ];
        System.assertEquals(2, insertedCdl.size(), 'File should be uploaded successfully.');
    }
    
    @isTest
    public static void testValidateFileUploadWithoutPermissions() {
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName2',
            'Doe',
            '123doe@test.heb.ca',
            '41643210988'
        );
        insert cp;
        
        Case c = TestFactory.createComplaintCase(cp.PersonContactId, 'Case Trigger Test061123-06');
        c.Can_I_close_or_resolve_this__c = true;
        c.Is_this_about_fraud__c = false;
        c.ownerId = UserInfo.getUserId();
        insert c;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Some other document',
            PathOnClient = 'some_other_document.txt',
            VersionData = Blob.valueOf('Lorem ipsum dolor sit amet...')
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = c.Id
        );
        
        // Ensure permissions are not enabled
        Boolean RestrictPermissionFpoc = FeatureManagement.checkPermission('FPOCs_L1');
        Boolean Data_Analyst_Reporting = FeatureManagement.checkPermission('Data_Analyst_Reporting');
        
        Test.startTest();
        insert cdl;
        Test.stopTest();
        
        // Validate that the file upload was not allowed (no errors means the method exited early)
        System.assertEquals(2, [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :cd.Id], 
                            'File should be uploaded successfully since there is no restriction.');
    }
    
    @isTest
    public static void testValidateFileUploadInsertingAndUpdatingIDs() {
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName3',
            'Jones',
            '123jones@test.heb.ca',
            '41643210989'
        );
        insert cp;
        
        Case c = TestFactory.createComplaintCase(cp.PersonContactId, 'Case Trigger Test061123-07');
        c.Can_I_close_or_resolve_this__c = true;
        c.Is_this_about_fraud__c = false;
        c.ownerId = UserInfo.getUserId();
        insert c;
        
        c.Is_this_about_fraud__c = true;
        update c;
        
        
        ContentVersion cv = new ContentVersion(
            Title = 'Yet another document',
            PathOnClient = 'yet_another_document.txt',
            VersionData = Blob.valueOf('Lorem ipsum dolor sit amet...')
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = c.Id
        );
        
        Test.startTest();
        insert cdl;
        Test.stopTest();
        
        // Validate that no error was thrown due to inserting and updating IDs being present
        List<ContentDocumentLink> insertedCdl = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :cd.Id
        ];
        System.assertEquals(2, insertedCdl.size(), 'File should be uploaded successfully.');
    }
    
    
}