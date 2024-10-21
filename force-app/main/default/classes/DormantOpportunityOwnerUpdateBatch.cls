public class DormantOpportunityOwnerUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

    public static Date SIX_MONTHS_PRIOR = System.today().addMonths(-6);
    public static Date THREE_MONTHS_PRIOR = System.today().addMonths(-3);
    public static Date TODAY = System.today();
    
    public Database.QueryLocator start(Database.BatchableContext BC) {

        DateTime minInquiryDate = System.now().addMonths(-3);

        String query = 'SELECT Id, Name, Channel__c, Is_Redacted__c, IsClosed, File_Queue__c, MARS_Stage__c, OwnerId, StageName, Owner.IsActive, AccountId, Account.Most_Recent_Inquiry_Date__pc, File_Ownership_Update_Batch_Error__c, File_Ownership_Update_Error_Code__c ' +
                   'FROM Opportunity ' +
                   'WHERE Channel__c = \'Consumer\' ' +
                   'AND Is_Redacted__c = false ' +
                   'AND IsClosed = false ' +
                   'AND File_Queue__c NOT IN (\'Initial Contact\') ' +
                   'AND MARS_Stage__c = null ' +
                   'AND AccountId != null ' +
                   'AND Account.Most_Recent_Inquiry_Date__pc < :minInquiryDate';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope){

        Set<Id> opportunityIds = new Set<Id>();
        List<Opportunity> opportunitiesToAssign = new List<Opportunity>();

        for (Opportunity opp : scope) {
            opportunityIds.add(opp.Id);
        }

        // Query related events and tasks
        Map<Id, List<Event>> eventsMap_PastAndFuture = new Map<Id, List<Event>>();
        Map<Id, List<Task>> tasksMap_pastAndFuture = new Map<Id, List<Task>>();

        List<Event> events = [SELECT Id, WhatId, Type_Of_Meeting__c, ActivityDate 
                              FROM Event 
                              WHERE WhatId IN :opportunityIds 
                              AND Type_Of_Meeting__c != null 
                              AND ActivityDate > :SIX_MONTHS_PRIOR];

        for (Event eventRec : events) {

            if (!eventsMap_PastAndFuture.containsKey(eventRec.WhatId)) {
                eventsMap_PastAndFuture.put(eventRec.WhatId, new List<Event>());
            }

            if(eventRec.ActivityDate > SIX_MONTHS_PRIOR && ( eventRec.Type_Of_Meeting__c == 'Initial Contact' || eventRec.Type_Of_Meeting__c == 'Initial Contact Follow-up' ) ){
                eventsMap_PastAndFuture.get(eventRec.WhatId).add(eventRec);
            }
            if(eventRec.ActivityDate > THREE_MONTHS_PRIOR && eventRec.Type_Of_Meeting__c == 'Follow-up'){
                eventsMap_PastAndFuture.get(eventRec.WhatId).add(eventRec);
            }
            if(eventRec.ActivityDate > TODAY){
                eventsMap_PastAndFuture.get(eventRec.WhatId).add(eventRec);
            }
        }

        List<Task> tasks = [SELECT Id, WhatId, ActivityDate  
                            FROM Task 
                            WHERE WhatId IN :opportunityIds 
                            AND ActivityDate > :THREE_MONTHS_PRIOR];

        for (Task taskRec : tasks) {
            if (!tasksMap_pastAndFuture.containsKey(taskRec.WhatId)) {
                tasksMap_pastAndFuture.put(taskRec.WhatId, new List<Task>());
            }
            tasksMap_pastAndFuture.get(taskRec.WhatId).add(taskRec);
        }

        
        for (Opportunity oppRec : scope) {
            List<Event> relatedEvents = eventsMap_PastAndFuture.get(oppRec.Id);
            List<Task> relatedTasks = tasksMap_pastAndFuture.get(oppRec.Id);
            
            Boolean hasRecentOrFutureMeeting = (relatedEvents != null && !relatedEvents.isEmpty());
            Boolean hasRecentOrFutureTasks = (relatedTasks != null && !relatedTasks.isEmpty());

            // Determine if the opportunity needs to be assigned to Initial contact queue
            if (!hasRecentOrFutureMeeting && !hasRecentOrFutureTasks) {
                opportunitiesToAssign.add(oppRec);
            }
        }

        if(opportunitiesToAssign != null && !opportunitiesToAssign.isEmpty()){
            OpportunityOwnershipBatchHandler.setOpportunityQueueToInitialContactQueue(opportunitiesToAssign, OpportunityBatchProcessEnums.Process.DORMANT);
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}