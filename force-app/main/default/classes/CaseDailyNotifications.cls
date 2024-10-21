public class CaseDailyNotifications {    
    
    public static final String NOTIFICATION_ID  = [Select Id from CustomNotificationType where DeveloperName = 'Custom_Notification' limit 1].Id;
    public static final String TASK_RECORD_TYPE  = [Select Id from RecordType where DeveloperName = 'Complaint_task'].Id;
    public static final String CASE_ESCALATION_ALERT = 'Case escalation alert:';
    public static final String CHECK_STATUS = 'Check Status Day';
    
    public static final String DAY_14_TITLE = 'Complaint needs to be assigned:';
    public static final String TASK_TITLE   = 'Status Reminder Day';   
    
    public static final String DAY_13_BODY = 'Complaint will be escalated by EOD tomorrow if it is not closed or resolved.';
    public static final String DAY_14_BODY = 'Complaint has been unassigned. Please action accordingly.';    
    public static final String DAY_30_BODY = 'It\'s Day 30 of the case. Review progress & check if another update needs to be provided.';
    public static final String DAY_38_BODY = 'Please consider escalating the complaint to SDE level in the next 48 hours.';
    public static final String DAY_50_BODY = 'It looks like the complaint is still open. Please check and update the complaint as needed.';
    public static final String DAY_54_BODY = 'Complaint must be resolved in the next 48 hours. Please check and update accordingly.';
    public static final String TASK_BODY   = 'Please update complainant with the latest status.';  
    
    @InvocableMethod
    public static void activateNotificationsOnCase() {
        
        Set<String> recipientIds = new Set<String>();
        String caseOwnerId;
        List<Task> taskList = new List<Task>(); 
        Integer complaintAgeOfCase;
        String caseId;
        String title;
        String body;
        try {
            
            Map<String,String> caseHandlingLevelMap = getCaseHandlingLevelMap(CaseDailyNotifications.retrieveCases());
            Boolean handlingLevelCheck = false;
            List<String> acceptedHandlingLevels = getHandlingLevelMetadata();
            Map<String,String> deQueueNameIdMap = getDEQueueIds();
            
            for(Case c: retrieveCases()) {
                
                if(caseHandlingLevelMap.get(c.Id) != null)
                    handlingLevelCheck = acceptedHandlingLevels.contains(caseHandlingLevelMap.get(c.Id));
                
                caseId = c.Id;            
                caseOwnerId = c.ownerId;                
                if(c.Complaint_Date_Received__c == null) {
                    continue;
                }
                complaintAgeOfCase = c.Complaint_Date_Received__c.daysBetween(System.today());
                recipientIds = new Set<String>();
                recipientIds.add(caseOwnerId);                
                
                if(complaintAgeOfCase == 7 || complaintAgeOfCase == 21 ) {
                    
                    if( caseOwnerId.startsWith('005') ) {
                        
                        Task task = new Task();
                        task.ActivityDate = System.today();
                        task.Description = TASK_BODY;
                        task.OwnerId = c.OwnerId;
                        task.Priority = 'Normal';
                        task.RecordTypeId = TASK_RECORD_TYPE;
                        task.Status = 'Open';
                        task.Subject = TASK_TITLE + ' ' + complaintAgeOfCase;
                        task.WhatId = caseId;
                        taskList.add(task);                    
                    }
                    
                } 
                
                if (complaintAgeOfCase <= 14) {
                    
                    if( complaintAgeOfCase == 13) {
                        
                        title = CASE_ESCALATION_ALERT +' '+c.CaseNumber;
                        body  = DAY_13_BODY;
                        sendCustomNotification(recipientIds, title, body, caseId);
                        
                    }
                    
                    if(caseOwnerId.startsWith('00G') && handlingLevelCheck) {
                        
                        Set<String> queueIds = new Set<String>();
                        String queueId;
                        
                        if(c.Case_Owner_Business_Unit__c != null)
                            queueId = deQueueNameIdMap.get('DE'+' '+c.Case_Owner_Business_Unit__c);
                        
                       
                        queueIds.add(queueId);
                        
                        title = DAY_14_TITLE +' '+ c.CaseNumber;
                        body = DAY_14_BODY;                
                        sendCustomNotification(queueIds, title, body, caseId);                        
                    }                
                    
                } else {
                    
                    if( complaintAgeOfCase == 30) {
                        
                        title = CHECK_STATUS + ' '+ complaintAgeOfCase +': ' + c.CaseNumber;
                        body  = DAY_30_BODY;
                        sendCustomNotification(recipientIds, title, body, caseId);
                        
                    } else if( complaintAgeOfCase == 38) {
                        
                        title = CASE_ESCALATION_ALERT +' '+c.CaseNumber;
                        body  = DAY_38_BODY;
                        sendCustomNotification(recipientIds, title, body, caseId);
                        
                    } else if( complaintAgeOfCase == 50) {
                        
                        title = CHECK_STATUS + ' '+ complaintAgeOfCase +': ' + c.CaseNumber;
                        body = DAY_50_BODY;
                        sendCustomNotification(recipientIds, title, body, caseId);
                        
                    } else if( complaintAgeOfCase == 54) {
                        
                        title = CHECK_STATUS + ' '+ complaintAgeOfCase +': ' + c.CaseNumber;
                        body = DAY_54_BODY;
                        sendCustomNotification(recipientIds, title, body, caseId);                    
                    }                
                }
            }
            
            insert taskList;
            
        } catch(Exception e) {
            System.debug('Error occurred'+e);
        }
    }
    
    public static  Map<String,String> getCaseHandlingLevelMap (List<Case> cases) {
        
        Map<String,String> caseHandlingLevelMap = new Map<String,String>();
        
        for( Case c: cases) {            
            if(c.Complaint_Handling_Level__c != null)
                caseHandlingLevelMap.put(c.id,c.Complaint_Handling_Level__c);            
        }
        
        return caseHandlingLevelMap;
        
    }
    
    public static List<Case> retrieveCases() {
        
        return [SELECT Id, OwnerId, Owner.Isactive, CaseNumber, Complaint_Date_Received__c, 
                Complaint_Handling_Level__c, Case_Owner_Business_Unit__c
                FROM Case where Status IN ('Ongoing','Reopened') AND Owner.Isactive = true ORDER BY CaseNumber DESC limit 50000];        
    }
    
    public static void sendCustomNotification(Set<String> recipientsIds, String title, String body, String targetId) {
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        notification.setTitle(title);
        
        notification.setBody(body);
        
        notification.setTargetId(targetId);
        
        notification.setNotificationTypeId(NOTIFICATION_ID);
        
        notification.send(recipientsIds);
        
    }
    
    public static List<String> getHandlingLevelMetadata() {
        
        List<String> acceptedHandlingLevels = new List<String>();
        
        for(Handling_Level_For_Notifications__mdt metadata: [Select Handling_Level__c From Handling_Level_For_Notifications__mdt where Active__c = true]) {
            acceptedHandlingLevels.add(metadata.Handling_Level__c);
        }
        
        return acceptedHandlingLevels;
        
    }
    
    public static Map<String,String> getDEQueueIds() {
        
        Map<String,String> deQueueMap = new Map<String,String> ();
        
        for(Group grp : [Select Id, Name From Group where Type = 'Queue' and Name like 'DE%']) {
            
            deQueueMap.put(grp.Name,String.valueOf(grp.Id));
        }
        
        return deQueueMap;
    }    
}