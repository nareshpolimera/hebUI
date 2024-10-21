@isTest
public class IndividualServiceTest {
    
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        // Creating test Individuals
        Individual ind1 = new Individual(FirstName = 'John', LastName = 'Doe');
        Individual ind2 = new Individual(FirstName = 'Jane', LastName = 'Smith');
        
        insert new List<Individual>{ind1, ind2};
            
            // Creating test ContactPointTypeConsent records linked to the Individuals
            ContactPointTypeConsent cptc1 = new ContactPointTypeConsent(Name = 'Consent - John Doe', PartyId = ind1.Id);
        ContactPointTypeConsent cptc2 = new ContactPointTypeConsent(Name = 'Consent - Jane Smith', PartyId = ind2.Id);
        
        insert new List<ContactPointTypeConsent>{cptc1, cptc2};
            }
    
    @isTest
    static void testUpdateContactTypePointConsentName() {
        // Fetching the Individuals created in the test setup
        List<Individual> individuals = [SELECT Id, FirstName, LastName FROM Individual];
        Set<Id> setIndividualsIds = (new Map<Id,SObject>(individuals)).keySet(); 
        Map<Id, Individual> oldMap = new Map<Id, Individual>([SELECT Id, FirstName, LastName FROM Individual WHERE Id IN :individuals]);
        
        // Modifying the Individuals
        for (Individual ind : individuals) {
            if (ind.FirstName == 'John') {
                ind.FirstName = 'Johnny';
                ind.LastName = 'Dane';
            } else if (ind.FirstName == 'Jane') {
                ind.FirstName = 'Janet';
                ind.LastName = 'Smythe';
            }
        }
        
        update individuals;
        
        // Calling the method to be tested
        Test.startTest();
        new IndividualService().updateContactTypePointConsentName(individuals, oldMap);
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // Verifying the results
        List<ContactPointTypeConsent> updatedCptc = [SELECT Id, Name, PartyId FROM ContactPointTypeConsent];
        
        System.assertEquals('Consent -  Johnny Dane', updatedCptc[0].Name);
        System.assertEquals('Consent -  Janet Smythe', updatedCptc[1].Name);
    }
}