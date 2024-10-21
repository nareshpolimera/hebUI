@isTest
public with sharing class AccountAccountServiceTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        FinServ__ReciprocalRole__c roleInsert = TestFactory.createReciprocalRole('Referral Agreement Holdee', 'Referral Agreement Holdee');
        insert roleInsert;
    }
    
    @isTest
    static void triggerTest(){ 
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account partnerAcc = TestFactory.createPartnerAccount(
            'West Toronto',
            'Bank',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        partnerAcc.FinServ__IndividualType__c='Group';
        insert partnerAcc;
        Account partnerAcc2 = TestFactory.createPartnerAccount(
            'West Toronto2',
            'Bank',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        partnerAcc2.FinServ__IndividualType__c='Group';
        insert partnerAcc2;
        Account partnerAcc3 = TestFactory.createPartnerOrgAccount(
            'West Toronto23',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        
        partnerAcc3.Referral_Agreement_Holder_Eligible__c = true;
        insert partnerAcc3;
        
        FinServ__AccountAccountRelation__c aar = new FinServ__AccountAccountRelation__c();
        aar.FinServ__Account__c = partnerAcc3.id;
        aar.FinServ__Role__c = [select id from FinServ__ReciprocalRole__c where Name = 'Referral Agreement Holdee' LIMIT 1].id;
        aar.Referral_Holder_or_Payment_Eligible__c = partnerAcc3.id;
        
        insert aar;
        Test.stopTest();
        
    }
    
    @isTest
    static void triggerTestdeleteopoeration(){ 
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account partnerAcc3 = TestFactory.createPartnerOrgAccount(
            'West Toronto23',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        
        partnerAcc3.Referral_Agreement_Holder_Eligible__c = true;
        insert partnerAcc3;
        
        FinServ__AccountAccountRelation__c aar = new FinServ__AccountAccountRelation__c();
        aar.FinServ__Account__c = partnerAcc3.id;
        aar.FinServ__Role__c = [select id from FinServ__ReciprocalRole__c where Name = 'Referral Agreement Holdee' LIMIT 1].id;
        aar.Referral_Holder_or_Payment_Eligible__c = partnerAcc3.id;
        
        insert aar;
        delete aar;
        Test.stopTest();
        
    }
}