@isTest
public class ContactPointTypeConsentServiceTest {
    
    @testSetup
    static void setupTestData() {

        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;

        // Creating test Individuals
        Individual ind1 = new Individual(FirstName = 'John', LastName = 'Doe');
        Individual ind2 = new Individual(FirstName = 'Jane', LastName = 'Smith');
        
        insert new List<Individual>{ind1, ind2};
        
        // Creating test ContactPointTypeConsent records linked to the Individuals
        ContactPointTypeConsent cptc1 = new ContactPointTypeConsent();
        cptc1.PartyId = ind1.Id;
        cptc1.Name = 'Test Contact Point 1';
        ContactPointTypeConsent cptc2 = new ContactPointTypeConsent();
        cptc2.PartyId = ind2.Id;
        cptc2.Name = 'Test Contact Point 2';

        insert new List<ContactPointTypeConsent>{cptc1, cptc2};
    }

    @isTest
    static void test_AutoName() {


        // Calling the method to be tested
        Test.startTest();

        Individual ind1 = new Individual(FirstName = 'John', LastName = 'Doe');
        insert ind1;

        ContactPointTypeConsent cptc1 = new ContactPointTypeConsent();
        cptc1.PartyId = ind1.Id;
        insert cptc1;

        Test.stopTest();

        // Verifying the results
        List<ContactPointTypeConsent> updatedCptc = [SELECT Id, Name,Generated_Number__c FROM ContactPointTypeConsent where Id = :cptc1.Id];
        
        System.assertEquals('CC-00000001', updatedCptc[0].Name);
        System.assertEquals(1, updatedCptc[0].Generated_Number__c);
    }

    @isTest
    static void test_AutoName_Bulk() {

        // Calling the method to be tested
        Test.startTest();

        Individual ind1 = new Individual(FirstName = 'John', LastName = 'Doe');
        insert ind1;

        ContactPointTypeConsent cptc1 = new ContactPointTypeConsent();
        cptc1.PartyId = ind1.Id;
        ContactPointTypeConsent cptc2 = new ContactPointTypeConsent();
        cptc2.PartyId = ind1.Id;
        ContactPointTypeConsent cptc3 = new ContactPointTypeConsent();
        cptc3.PartyId = ind1.Id;

        insert new List<ContactPointTypeConsent>{cptc1,cptc2,cptc3};

        Test.stopTest();

        // Verifying the results
        List<ContactPointTypeConsent> updatedCptc = [SELECT Id, Name,Generated_Number__c FROM ContactPointTypeConsent where Id = :cptc3.Id];
        
        System.assertEquals('CC-00000003', updatedCptc[0].Name);
        System.assertEquals(3, updatedCptc[0].Generated_Number__c);
    }

    @isTest
    static void test_ManualName_nochange() {

        // Calling the method to be tested
        Test.startTest();

        Individual ind1 = new Individual(FirstName = 'John', LastName = 'Doe');
        insert ind1;
       
        ContactPointTypeConsent cptc1 = new ContactPointTypeConsent();
        cptc1.Name = 'Test Manual Name';
        cptc1.PartyId = ind1.Id;
        insert cptc1;
		Test.getEventBus().deliver();
        Test.stopTest();

        // Verifying the results
        List<ContactPointTypeConsent> updatedCptc = [SELECT Id, Name,Generated_Number__c FROM ContactPointTypeConsent where Id = :cptc1.Id];
        
        System.assertEquals('Test Manual Name', updatedCptc[0].Name);
        System.assertEquals(null, updatedCptc[0].Generated_Number__c);
        
        //TEST MARS Records Created
        Set<Id> resultIds = (new Map<Id,SObject>(updatedCptc)).keySet();
        List<MARS_Ready_Record__c> listMarsRecords = [SELECT id,SFDC_Id__c from MARS_Ready_Record__c where SFDC_Id__c in:resultIds  ];
    }
}