@isTest
public class LeadAssignmentBatchTest
{
    @testSetup
    static void setup()
    {
        List<Specialist__c> spls = new List<Specialist__c>();
        for (User u : [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator'
        ])
        {
            Specialist__c spl = new Specialist__c();
            spl.User__c = u.Id;
            spls.add(spl);
        }
        
        insert spls;
    }
    
    @isTest
    static void testBatch()
    {
        Test.startTest();
        {
            LeadAssignmentBatch splb = new LeadAssignmentBatch();
            Database.executeBatch(splb);
        }
        Test.stopTest();
        
        Lead_Assignment_Batch_Log__c labl = [
            SELECT Last_Run_Date__c
            FROM Lead_Assignment_Batch_Log__c
        ];
        System.assertEquals(Date.today(), labl.Last_Run_Date__c);
    }
}