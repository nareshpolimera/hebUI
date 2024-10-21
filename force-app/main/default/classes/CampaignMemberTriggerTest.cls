@IsTest
public class CampaignMemberTriggerTest {
    
    @testSetup static void setupTestData() {
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
    static void testBlockCallCentreUser () {
        // Retrieve the test user
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduser@chip.ca' LIMIT 1];
        PermissionSet psg= [SELECT ID FROM PermissionSet WHERE Name = 'HEB_Call_Centre' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = psg.Id
        );
        insert psa;
        
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            Test.startTest();
            Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
            // Prepare test data
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
            Account partnerAccount1 = TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
            partnerAccount1.RecordTypeId = partnerRecordTypeId;
            Account partnerAccount2 = TestFactory.createPartnerAccount('Surrey','Bank','V3T0G4','Surrey','123412341');
            partnerAccount2.RecordTypeId = partnerRecordTypeId;
            List<Account> partnerList = new List<Account>{ partnerAccount1, partnerAccount2};
            insert partnerList;
            Campaign camp = new Campaign( Name = 'New Campaign', Phone_Label__c = 'Campaign Phone', Phone_Number__c = '41655555555',IsActive = true, CSID__c='121212' );
            insert camp;
            List<Account> partnerAccountList = [SELECT ID, PersonContactId From Account where ID =: partnerList[0].Id OR ID =: partnerList[1].Id];
            
            List<CampaignMember> cmList = new List<CampaignMember>();
            CampaignMember cm = new CampaignMember(CampaignId = camp.Id, ContactId = partnerAccountList[0].PersonContactId);
            cmList.add(cm);
            cm = new CampaignMember(CampaignId = camp.Id, ContactId = partnerAccountList[1].PersonContactId);
            cmList.add(cm);
            insert cmList;
            
            try{
                delete cm;
            }
            catch(DmlException e){
                for (CampaignMember cm1 : cmList) {
                    if (cm1.hasErrors()) {
                        System.assert(cm1.getErrors()[0].getMessage().contains(Label.Error_Call_Centre_Campaign_Member_CD),
                                      'Expected error message not found.');
                    }
                }
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testUpdateMRIDateOnLead() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        // Prepare test data
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HEB_Bank').getRecordTypeId();
        Account partnerAccount1 = TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        partnerAccount1.RecordTypeId = partnerRecordTypeId;
        Account partnerAccount2 = TestFactory.createPartnerAccount('Surrey','Bank','V3T0G4','Surrey','123412341');
        partnerAccount2.RecordTypeId = partnerRecordTypeId;
        List<Account> partnerList = new List<Account>{ partnerAccount1, partnerAccount2};
        insert partnerList;
        List<Account> partnerAccountList = [SELECT ID, PersonContactId From Account where ID =: partnerList[0].Id OR ID =: partnerList[1].Id];
        Campaign camp = new Campaign( Name = 'New Campaign', Phone_Label__c = 'Campaign Phone', Phone_Number__c = '41655555555',IsActive = true, CSID__c='121212');
        insert camp;
        List<CampaignMember> cmList = new List<CampaignMember>();
        CampaignMember cm = new CampaignMember(CampaignId = camp.Id, ContactId = partnerAccountList[0].PersonContactId);
        cmList.add(cm);
        cm = new CampaignMember(CampaignId = camp.Id, ContactId = partnerAccountList[1].PersonContactId);
        cmList.add(cm);
        insert cmList;   
        cm.VisWa_ID__c = 'Canada';
        update cm;
        delete cm;
        Test.stopTest();
    }
}