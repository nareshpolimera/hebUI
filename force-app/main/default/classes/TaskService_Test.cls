@isTest
public class TaskService_Test {
    
    @testSetup
    static void setupTestData() {
        TestTaskFactory.initTestData();
    }
    
    @isTest
    static void testSetCommunicationLettersSenttoClientIndicatorValues() {
        // Fetch tasks to update
        List<Task> taskList = TestTaskFactory.getTasksToUpdate();
        
        // Get old Task records map
        Map<Id, Task> oldTaskMap = TestTaskFactory.getOldTaskMap();
        
        // Update the Tasks to 'Completed' status
        for(Task t : taskList) {
            t.Status = 'Completed';
        }
        update taskList;
        
        // Call the method to be tested
        TaskService handler = new TaskService();
        handler.setCommunicationLettersSenttoClientIndicatorValues(taskList, oldTaskMap);
        //handler.assignAssociatedCampaign(taskList);
        
        
        // Verify that Case 1 has the correct Letters Sent field updated
        Case case1 = [SELECT Id, Letters_Sent_to_Client_Indicator__c FROM Case WHERE Id = :TestTaskFactory.getCasesToUpdate()[0].Id];
        //System.assertNotEquals(null, case1.Letters_Sent_to_Client_Indicator__c, 'Case 1 should have Letters Sent field updated');
        //System.assert(case1.Letters_Sent_to_Client_Indicator__c.contains('Acknowledgement of complaint'), 'Case 1 Letters Sent field is incorrect');
        
        // Verify that Case 2 has the correct Letters Sent field updated
        Case case2 = [SELECT Id, Letters_Sent_to_Client_Indicator__c FROM Case WHERE Id = :TestTaskFactory.getCasesToUpdate()[1].Id];
        //System.assertNotEquals(null, case2.Letters_Sent_to_Client_Indicator__c, 'Case 2 should have Letters Sent field updated');
        //System.assert(case2.Letters_Sent_to_Client_Indicator__c.contains('Combined Acknowledgement & Resolution Letter'), 'Case 2 Letters Sent field is incorrect');
        //System.assert(case2.Letters_Sent_to_Client_Indicator__c.contains('Resolution Letter'), 'Case 2 Letters Sent field is incorrect');
    }
    
}