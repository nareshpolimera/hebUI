@IsTest
public class MembershipDetailsControllerTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;

        Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        insert new List<Opportunity>{op1};
            
        Marketing_Association__c m1 = new Marketing_Association__c(
            Name = 'CARP',
            Consent_Script_French__c = 'french consent',
            Consent_Script_English__c = 'english consent',
            Is_Active__c = true
        );
        Marketing_Association__c m2 = new Marketing_Association__c(
            Name = 'Legion',
            Consent_Script_French__c = 'french consent',
            Consent_Script_English__c = 'english consent',
            Is_Active__c = true
        );
        insert new List<Marketing_Association__c>{ m1, m2 };
    }
    
    /*
    * HEB-340 Validates the Membership
    */
    @IsTest
    static void testAssociations() {
        List<Marketing_Association__c> association = MembershipController.setAllAssociations();
        system.assertEquals(association.size() > 0,true,'No Marketing association exist.');
        system.assertEquals(MembershipController.setAssociationDetails(association[0].Id).get('frenchConsent')!= null,true,'Error returning consent');
        system.assertEquals(MembershipController.setAssociationDetails(association[0].Id).get('englishConsent')!= null,true,'Error returning consent');
    }
    
    /*
    * HEB-340 Validates the Membership
    */
    
    @IsTest
    static void validateMembershipRequest() {
        List<Marketing_Association__c> association = MembershipController.setAllAssociations();
        Opportunity opptyRec = [SELECT Id FROM Opportunity WHERE Name = 'Test Drive' LIMIT 1];
        system.assertEquals(MembershipController.validMembership(opptyRec.Id, association[0].Id),'','Does not allow valid membership to be added');
        
        Membership__c oldM = new Membership__c(
            Opportunity__c = OpptyRec.Id,
            Marketing_Association__c = association[0].Id,
            Membership_Number__c = '123456',
            Consent_Received_On__c = system.today(),
            Consent_Received__c = true
        );
        insert oldM;
        system.assertEquals(oldM.Id != null, true, 'Unable to add Membership');
        system.assertEquals(MembershipController.validMembership(opptyRec.Id, association[0].Id),Label.MEMBERSHIP_EXISTS,'Duplicate Membership added');
    }
}