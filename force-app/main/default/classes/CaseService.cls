public without sharing class CaseService {
    public static final String HANDLING_LEVEL1 = 'Level 1'; //'Level 1 FPOC';
    public static final String HANDLING_LEVEL2 = 'Level 2'; // Designated Employee';
    public static final String HANDLING_LEVEL3 = 'Level 3'; // Senior Designated Employee';
    public static Boolean sendCaseToMarsEventPublished = false;
    public static final Date DT14 = Date.Today().addDays(-13);
    public static final Date DT50 = Date.Today().addDays(-49);
    public static list<id> level1EscalatedIds = new List<id>();
    public static list<id> level3EscalatedIds = new List<id>();
    public static set<Id> createdIdList = new Set<id>();
    public static final String COMPLIANTS_SPECIALIST = 'Customer Care Complaint Handlers';
    public static final String DESINATED_EMPLOYEES = 'Designated Employees';
    public static final String SENIOR_DESIGNATED_EMPLOYEES = 'Senior Designated Employees';
    public static list<id> insertingIDs = new List<id>();
    public static list<id> updatingIDs = new List<id>();
    
    public static void sendUpdatedCaseToMarsPlatformEvent(
        List<Case> records,
        Map<Id, Case> oldRecords
    ) {
        List<Case> ncs = new List<Case>();
        for (Case c0 : records) {
            if (
                String.isBlank(c0.Opportunity_File__c) == false ||
                String.isBlank(c0.MARS_File__c) == false ||
                (String.isBlank(c0.Opportunity_File__c) == true &&
                 String.isBlank(oldRecords.get(c0.Id).Opportunity_File__c) == false) ||
                (String.isBlank(c0.MARS_File__c) == true &&
                 String.isBlank(oldRecords.get(c0.Id).MARS_File__c) == false)
            ) {
                ncs.add(c0);
                system.debug(
                    '!!! - case ID = ' +
                    c0.id +
                    ' File Number = ' +
                    c0.File_Number__c
                );
            }
        }
        if (ncs.isEmpty())
            return;
        
        Set<String> fieldsToCheck = Utils.getFieldSetFields(
            Schema.SObjectType.Case.fieldSets.Complaint.getFields()
        );
        List<Case> cs = (List<Case>) Utils.getChangedObjects(
            ncs,
            oldRecords,
            fieldsToCheck
        );
        
        
        if (cs.isEmpty())
            return;
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Case c : cs)
            requests.add(
                new MARSPlatformEventService.Request(
                    c,
                    MARSPlatformEventService.IMPORT_COMPLAINT,
                    MARSPlatformEventService.ACTION_UPDATE,
                    MARSPlatformEventService.IMPORT_COMPLAINT
                )
            );
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        CaseService.sendCaseToMarsEventPublished = !(errorOccurred);
    }
    
    
    public static void sendNewCaseToMarsPlatformEvent(List<Case> records) {
        List<Case> csl = new List<Case>();
        
        for (Case c1 : records) {
            if (
                String.isBlank(c1.Opportunity_File__c) == false ||
                String.isBlank(c1.MARS_File__c) == false
            ) {
                csl.add(c1);
            }
        }
        if (csl.isEmpty())
            return;
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Case c : csl)
            requests.add(
                new MARSPlatformEventService.Request(
                    c,
                    MARSPlatformEventService.IMPORT_COMPLAINT,
                    MARSPlatformEventService.ACTION_INSERT,
                    MARSPlatformEventService.IMPORT_COMPLAINT
                )
            );
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        CaseService.sendCaseToMarsEventPublished = !(errorOccurred);
    }
    
    // as per the new change in requirement this may not be required
    public void validateOnUpdate(
        Map<Id, Case> records,
        Map<Id, Case> oldRecords
    ) {
        //updatingIDs = oldRecords.keyset();
        string level1 = 'level 1';
        string level2 = 'level 2';
        string level3 = 'level 3';
        List<Queue_Details__mdt> mcs = Queue_Details__mdt.getAll().values();
        map<string, string> queueLevelMap = new Map<string, string>();
        for (Queue_Details__mdt mdt : mcs) {
            queueLevelMap.put(mdt.MasterLabel, mdt.Level_Information__c);
        }
        
        list<id> oldOwnerIDUser = new List<id>();
        list<id> oldOwnerIDQueue = new List<id>();
        list<id> newOwnerIDUser = new List<id>();
        list<id> newOwnerIDQueue = new List<id>();
        list<id> validCaseIDs = new List<id>();
        
        for (Id csId : oldRecords.keyset()) {
            updatingIDs.add(csId);
            if (records.get(csId).ownerid != oldRecords.get(csId).ownerid) {
                validCaseIDs.add(csId);
                string newOwnerId = records.get(csId).OwnerId;
                string oldOwnerId = oldRecords.get(csId).OwnerId;
                if (newOwnerId.startsWithIgnoreCase('005')) {
                    newOwnerIDUser.add(records.get(csId).OwnerId);
                } else if (newOwnerId.startsWithIgnoreCase('00G')) {
                    newOwnerIDQueue.add(records.get(csId).OwnerId);
                }
                
                if (oldOwnerId.startsWithIgnoreCase('005')) {
                    oldOwnerIDUser.add(oldRecords.get(csId).OwnerId);
                } else if (oldOwnerId.startsWithIgnoreCase('00G')) {
                    oldOwnerIDQueue.add(oldRecords.get(csId).OwnerId);
                }
            }
        }
        Map<id, Group> allQueueMap = new Map<id, Group>(
            [
                SELECT Id, NAME
                FROM Group
                WHERE
                Type = 'Queue'
                AND (id IN :oldOwnerIDQueue
                     OR Id IN :newOwnerIDQueue)
            ]
        );
        map<id, user> userMap = new Map<id, user>(
            [
                SELECT id, ManagerId, Handling_Level__c, Name, Email
                FROM user
                WHERE id IN :newOwnerIDUser OR id IN :oldOwnerIDUser
            ]
        );
        //Escalated	IsEscalated	Checkbox		False
        //Escalation Rationale	Complaint_Escalation_Rationale__c	Long Text Area(1000)
        list<id> sameLevelTransferCaseIds = new List<id>();
        list<id> Escalatin14DaysCaseIds = new List<id>();
        list<id> escalationLevel2CaseIds = new List<id>();
        list<id> escalationLevel3CaseIds = new List<id>();
        list<id> Escalatin50DaysCaseIds = new List<id>();
        list<id> cantResolvedCaseList = new List<id>();
        for (Id csId : validCaseIDs) {
            if (records.get(csId).Resolution_Sought__c == null) {
                records.get(csId).Resolution_Sought__c = 'resolution added';
            }
            
            boolean isEscalated = false;
            boolean isEscalatedLevel3 = false;
            if (records.get(csId).Complaint_Escalation_Rationale__c != null) {
                isEscalated = true;
            }
            if (records.get(csId).Escalation_to_SDE_Rationale__c != null) {
                isEscalatedLevel3 = true;
            }
            string newOwnerId = records.get(csId).OwnerId;
            string oldOwnerId = oldRecords.get(csId).OwnerId;
            
            
            string newHandlingLevel = '';
            string oldHandlingLevel = '';
            if (newOwnerId.startsWithIgnoreCase('005')) {
                newHandlingLevel = userMap.get(newOwnerId).Handling_Level__c;
            } else if (newOwnerId.startsWithIgnoreCase('00G')) {
                newHandlingLevel = queueLevelMap.get(allQueueMap.get(newOwnerId).NAME);
            }
            if (oldOwnerId.startsWithIgnoreCase('005')) {
                oldHandlingLevel = userMap.get(oldOwnerId).Handling_Level__c;
            } else if (oldOwnerId.startsWithIgnoreCase('00G')) {
                oldHandlingLevel = queueLevelMap.get(allQueueMap.get(oldOwnerId).NAME);
            }
            
            if (
                newOwnerId.startsWithIgnoreCase('005') &&
                oldOwnerId.startsWithIgnoreCase('005')
            ) {
                if (
                    userMap.get(newOwnerId).Handling_Level__c !=
                    userMap.get(oldOwnerId).Handling_Level__c
                ) {
                    if (
                        isEscalated &&
                        (((userMap.get(newOwnerId).Handling_Level__c == level2) &&
                          (userMap.get(oldOwnerId).Handling_Level__c == level1)))
                    ) {
                        escalationLevel2CaseIds.add(csId);
                        continue;
                    } else if (
                        isEscalatedLevel3 &&
                        ((userMap.get(newOwnerId).Handling_Level__c == level3) &&
                         (userMap.get(oldOwnerId).Handling_Level__c == level2))
                    ) {
                        escalationLevel3CaseIds.add(csId);
                        continue;
                    } else if (isEscalated || isEscalatedLevel3) {
                        if (
                            !isEscalatedLevel3 &&
                            ((userMap.get(newOwnerId).Handling_Level__c == level3) &&
                             (userMap.get(oldOwnerId).Handling_Level__c == level2))
                        ) {
                            records.get(csId)
                                .addError(
                                    'Escalation to SDE Rationale field is required. Please return to the case and add an escalation rationale.'
                                );
                            continue;
                        }
                        system.debug('isEscalated001' + isEscalated);
                        records.get(csId)
                            .addError('You are only allowed to escalate to the next level.');
                        continue;
                    } else if (
                        (userMap.get(newOwnerId).Handling_Level__c == level1) &&
                        (userMap.get(oldOwnerId).Handling_Level__c == null)
                    ) {
                        continue;
                    }
                    records.get(csId)
                        .addError(
                            'Escalation Rationale is required. Please return to the case and add Escalation rationale.'
                        );
                    continue;
                } else if (
                    (isEscalated || isEscalatedLevel3) &&
                    (newHandlingLevel == oldHandlingLevel)
                ) {
                    if (isEscalatedLevel3) {
                        if (newHandlingLevel != level3) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                        }
                    } else if (isEscalated) {
                        if (newHandlingLevel != level2) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                        }
                    }
                    sameLevelTransferCaseIds.add(csId);
                    continue;
                } else {
                    sameLevelTransferCaseIds.add(csId);
                }
            } else if (
                newOwnerId.startsWithIgnoreCase('00G') &&
                oldOwnerId.startsWithIgnoreCase('00G')
            ) {
                
            } else if (
                newOwnerId.startsWithIgnoreCase('00G') &&
                oldOwnerId.startsWithIgnoreCase('005')
            ) {
                if (
                    queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) !=
                    userMap.get(oldOwnerId).Handling_Level__c
                ) {
                    if (
                        (((queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) == level2) &&
                          ((userMap.get(oldOwnerId).Handling_Level__c == level1) ||
                           (userMap.get(oldOwnerId).Handling_Level__c == null))))
                    ) {
                        if (isEscalated) {
                            level1EscalatedIds.add(csId);
                        } else {
                            system.debug('12312a');
                            records.get(csId)
                                .addError(
                                    'Escalation to DE Rationale field is required. Please return to the case and add an escalation rationale.'
                                );
                        }
                        continue;
                    } else if (
                        isEscalatedLevel3 &&
                        (((queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) == level3) &&
                          (userMap.get(oldOwnerId).Handling_Level__c == level2)) ||
                         // (records.get(csId).Auto_Escalated__c && -- Updated By Santhosh for field deletion
                         ((queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) == level3) &&
                          (userMap.get(oldOwnerId).Handling_Level__c != level3)))
                    ) {
                        level3EscalatedIds.add(csId);
                        continue;
                    } else if (
                        (userMap.get(oldOwnerId).Handling_Level__c == level3 &&
                         queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) != level3) ||
                        (userMap.get(oldOwnerId).Handling_Level__c == level2 &&
                         queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) == level1) ||
                        (userMap.get(oldOwnerId).Handling_Level__c == level1 &&
                         queueLevelMap.get(allQueueMap.get(newOwnerId).NAME) == level3)
                    ) {
                        records.get(csId)
                            .addError('You are only allowed to escalate to the next level.');
                        continue;
                    }
                    records.get(csId)
                        .addError(
                            'Escalation to SDE Rationale field is required. Please return to the case and add an escalation rationale.'
                        );
                    continue;
                } else if (
                    (isEscalated || isEscalatedLevel3) &&
                    (newHandlingLevel == oldHandlingLevel)
                ) {
                    if (isEscalatedLevel3) {
                        if (newHandlingLevel != level3) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                        }
                    } else if (isEscalated) {
                        if (newHandlingLevel != level2) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                        }
                    }
                    continue;
                }
            } else if (
                newOwnerId.startsWithIgnoreCase('005') &&
                oldOwnerId.startsWithIgnoreCase('00G')
            ) {
                if (
                    userMap.get(newOwnerId).Handling_Level__c !=
                    queueLevelMap.get(allQueueMap.get(oldOwnerId).NAME)
                ) {
                    if (
                        isEscalated &&
                        (((userMap.get(newOwnerId).Handling_Level__c == level2) &&
                          (queueLevelMap.get(allQueueMap.get(oldOwnerId).NAME) == level1)))
                    ) {
                        continue;
                    } else if (
                        isEscalatedLevel3 &&
                        ((userMap.get(newOwnerId).Handling_Level__c == level3) &&
                         (queueLevelMap.get(allQueueMap.get(oldOwnerId).NAME) == level2))
                    ) {
                        continue;
                    } else if (isEscalated || isEscalatedLevel3) {
                        
                        records.get(csId)
                            .addError('You are only allowed to escalate to the next level.');
                        continue;
                    }
                    records.get(csId)
                        .addError(
                            'Escalation Rationale is required. Please return to the case and add Escalation rationale.'
                        );
                    continue;
                } else if (
                    (isEscalated || isEscalatedLevel3) &&
                    (newHandlingLevel == oldHandlingLevel)
                ) {
                    if (isEscalatedLevel3) {
                        if (newHandlingLevel != level3) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                            continue;
                        }
                    } else if (isEscalated) {
                        if (newHandlingLevel != level2) {
                            records.get(csId)
                                .addError(
                                    'You are only allowed to escalate to the next level.'
                                );
                            continue;
                        }
                    }
                    
                    if (
                        (records.get(csId).Complaint_Date_Received__c < DT14) &&
                        (records.get(csId).Complaint_Date_Received__c >= DT50) &&
                        (level1EscalatedIds.contains(csId))
                    ) {
                        Escalatin14DaysCaseIds.add(csId);
                        continue;
                    } else if (
                        (records.get(csId).Complaint_Date_Received__c < DT50) &&
                        (level3EscalatedIds.contains(csId))
                    ) {
                        Escalatin50DaysCaseIds.add(csId);
                        continue;
                    } else if (level1EscalatedIds.contains(csId)) {
                        escalationLevel2CaseIds.add(csId);
                        continue;
                    } else if (level3EscalatedIds.contains(csId)) {
                        escalationLevel3CaseIds.add(csId);
                        continue;
                    }
                    sameLevelTransferCaseIds.add(csId);
                    continue;
                } else {
                    sameLevelTransferCaseIds.add(csId);
                }
            }
            if (
                createdIdList.contains(csId) &&
                !Escalatin14DaysCaseIds.contains(csId) &&
                !Escalatin50DaysCaseIds.contains(csId)
            ) {
                if (
                    newOwnerId.startsWithIgnoreCase('005') &&
                    oldOwnerId.startsWithIgnoreCase('00G') &&
                    !(records.get(csId).Can_I_close_or_resolve_this__c)
                ) {
                    cantResolvedCaseList.add(csId);
                    if (sameLevelTransferCaseIds.contains(csId)) {
                        Integer result = sameLevelTransferCaseIds.indexOf(csId);
                        sameLevelTransferCaseIds.remove(result);
                    }
                }
            }
        }
        list<Messaging.SingleEmailMessage> emailLists = new List<Messaging.SingleEmailMessage>();
        if (!sameLevelTransferCaseIds.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    sameLevelTransferCaseIds,
                    records,
                    oldRecords,
                    userMap,
                    'sameLevelTransferEmail'
                )
            );
        }
        if (!Escalatin14DaysCaseIds.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    Escalatin14DaysCaseIds,
                    records,
                    oldRecords,
                    userMap,
                    '14DaysEscalationEmail'
                )
            );
        }
        if (!Escalatin50DaysCaseIds.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    Escalatin50DaysCaseIds,
                    records,
                    oldRecords,
                    userMap,
                    '50DaysEscalationEmail'
                )
            );
        }
        if (!cantResolvedCaseList.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    cantResolvedCaseList,
                    records,
                    oldRecords,
                    userMap,
                    'cantResolvedCaseEmail'
                )
            );
        }
        if (!escalationLevel2CaseIds.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    escalationLevel2CaseIds,
                    records,
                    oldRecords,
                    userMap,
                    'EscalationEmailLevel2'
                )
            );
        }
        if (!escalationLevel3CaseIds.isEmpty()) {
            emailLists.addAll(
                CaseEmailNotificationHandler.createEmailOnOwnerChange(
                    escalationLevel3CaseIds,
                    records,
                    oldRecords,
                    userMap,
                    'EscalationEmailLevel3'
                )
            );
        }
        if (!emailLists.isEmpty()) {
            CaseEmailNotificationHandler.sendEmails(emailLists);
        }
    }
    public void addIdToSendForEmails(List<Case> records) {
        for (Case c0 : records) {
            insertingIDs.add(c0.id);
            if (
                (c0.Complaint_Date_Received__c < DT14 &&
                 c0.Complaint_Date_Received__c >= DT50)
            ) {
                CaseService.level1EscalatedIds.add(c0.Id);
            } else if (c0.Complaint_Date_Received__c < DT50) {
                CaseService.level3EscalatedIds.add(c0.Id);
            }
        }
    }
    public void UpdateOwnerName(Map<Id, Case> records, Map<Id, Case> oldRecords) {
        
        list<id> userOwnerId = new List<id>();
        
        for (id csID : records.keySet()) {
            string ownerId = records.get(csID).OwnerId;
            if (ownerId.startsWithIgnoreCase('005')) {
                userOwnerId.add(ownerId);
            }
        }
        map<id, user> userMap = new Map<id, user>(
            [
                SELECT id, Handling_Level__c, Title, Business_Unit__c
                FROM user
                WHERE id IN :userOwnerId
            ]
        );
        for (id csID : records.keySet()) {
            string ownerId = records.get(csID).OwnerId;
            if (ownerId.startsWithIgnoreCase('005')) {
                records.get(csID).Complaint_Handling_Level__c = userMap.get(ownerId)
                    .Handling_Level__c;
                //records.get(csID).Complaint_Handler_Title__c = userMap.get(ownerId).Title; -- Updated By Santhosh for field deletion
                records.get(csID).Case_Owner_Business_Unit__c = userMap.get(ownerId)
                    .Business_Unit__c;
            }
        }
    }
    /*
generate Case Status Change History where Case is created
*/
    public void createCaseStatusHistoryInsert(List<Case> newCases) {
        List<Case_Status_History__c> lcs = new List<Case_Status_History__c>();
        
        if (newCases.size() > 0) {
            for (Case cs : newCases) {
                Case_Status_History__c csh = new Case_Status_History__c();
                csh.old_status__c = '';
                csh.Status__c = cs.Status;
                csh.case__c = cs.id;
                csh.Status_Date__c = cs.CreatedDate;
                csh.Status_Set_By__c	= cs.CreatedById;
                csh.Is_Current_Status__c	= true;
                lcs.add(csh);
            }
        }
        
        if (lcs.size() > 0) {
            insert lcs;
        }
    }
    
    /*
generate Case Status Change History when Case Status is changed
*/
    public void createCaseStatusHistoryUpdate(
        List<Case> newCases,
        Map<Id, Case> oldRecords
    ) {
        //updateCaseStatusHistoryIsCurrentStatus(oldRecords.KeySet());
        Set<String> fieldsToCheck = new Set<String>{ 'Status' };
            List<Case_Status_History__c> lcs = new List<Case_Status_History__c>();
        List<Case> ls = (List<Case>) Utils.getChangedObjects(
            newCases,
            oldRecords,
            fieldsToCheck
        );
        //Map<Id, Case> CaseMap = new Map<Id, Case>();
        if (ls.size() > 0) {
            for (Case cs : ls) {
                Case_Status_History__c csh = new Case_Status_History__c();
                csh.old_status__c = oldRecords.get(cs.id).Status;
                csh.Status__c = cs.Status;
                csh.case__c = cs.id;
                csh.Status_Date__c = cs.LastModifiedDate;
                csh.Status_Set_By__c	= cs.LastModifiedById;
                csh.Is_Current_Status__c	= true;
                lcs.add(csh);
            }
            /*
Update 'Is current status' filed to let user know the current status the case updated to 
*/
            List<Case_Status_History__c> caseStatusHistoryRecords = [
                Select Id, Is_Current_Status__c
                FROM Case_Status_History__c
                WHERE case__c IN :oldRecords.KeySet()
            ];
            
            for(Case_Status_History__c caseStatus : caseStatusHistoryRecords){
                caseStatus.Is_Current_Status__c = false;
            }
            
            for(Case_Status_History__c  csh :caseStatusHistoryRecords ){
                lcs.add(csh);
            }
        }
        
        if (lcs.size() > 0) {
            upsert lcs;
        }
        
    }
    
    /*
Store the Date that the Complaint Handling Level is DE when is created.
*/
    public void updateNewFirstEscalatedDate(List<Case> newCases) {
        for (Case cs : newCases) {
            system.debug('Complaint_Handling_Level__c' + cs.Complaint_Handling_Level__c);
            if ((cs.Complaint_Handling_Level__c == HANDLING_LEVEL2) || (cs.Complaint_Handling_Level__c == HANDLING_LEVEL3)) {
                cs.First_Escalated_Date__c = Date.today();
                
            }
        }
    }
    
    // @Author : Naresh Polimera
    // @Date : 09/08/2024
    // Us: 7251, 7252
    public void setHandlingLevelBasedOnUserRole(List<Case> newCases) {
        Set<Id> setOwnerIds = new Set<Id>();
        for (Case cs : newCases) {
            setOwnerIds.add(cs.ownerId);
        }
        
        List<UserRole__c> lstUserRoles = [SELECT ID, User__c, Role__c FROM UserRole__c Where User__c =: setOwnerIds and Available__c = true];
        Map<String, String> userRoleMap = new Map<String, String>();
        for(UserRole__c userRole: lstUserRoles) {
            if(!userRoleMap.containsKey(userRole.User__c) ){
                userRoleMap.put(userRole.User__c, UserRole.Role__c);
            }
        }
        for (Case cs : newCases) {
            string userRole = userRoleMap.get(cs.OwnerId);
            if(cs.Is_this_about_fraud__c){
                cs.Complaint_Handling_Level__c = 'Level 2';
                cs.Complaint_Escalation_Rationale__c = 'This case has been automatically escalated to Level 2';  
                cs.IsEscalated = true;
            }
            if(userRole != '') {
                if(userRole =='DE') {
                    cs.Complaint_Handling_Level__c = 'Level 2';
                    cs.Complaint_Escalation_Rationale__c = 'This case has been automatically escalated to Level 2';               
                }
                if(userRole == 'SDE'){
                    cs.Complaint_Handling_Level__c = 'Level 3';
                    cs.Escalation_to_SDE_Rationale__c  = 'This case has been automatically escalated to Level 3';
                }
                system.debug(' cs.Complaint_Handling_Level__c ::' +  cs.Complaint_Handling_Level__c);
                system.debug(' cs.Escalation_to_SDE_Rationale__c ::' +  cs.Escalation_to_SDE_Rationale__c);
            }    
            
            
            Integer numberDaysDue = cs.Complaint_Date_Received__c.daysBetween(System.Today());
            system.debug('numberDaysDue '+ numberDaysDue);
            if(numberDaysDue >= 14 && numberDaysDue <= 50)
            { 
                cs.Complaint_Handling_Level__c = 'Level 2';
            }
        }
    }
    
    /*
Store the Date that the Complaint Handling Level is first changed to DE.
*/
    public void updateFirstEscalatedDate(
        List<Case> newCases,
        Map<Id, Case> oldRecords
    ) {
        Set<String> fieldsToCheck = new Set<String>{
            'Complaint_Handling_Level__c'
                };
                    List<Case> ls = (List<Case>) Utils.getChangedObjects(newCases, oldRecords,fieldsToCheck);
        
        for (Case cs : ls) {
            if ((cs.Complaint_Handling_Level__c == HANDLING_LEVEL2 || cs.Complaint_Handling_Level__c == HANDLING_LEVEL3) 
                && oldRecords.get(cs.Id).First_Escalated_Date__c == null) {
                    cs.First_Escalated_Date__c = Date.today();
                }
        }
    }
    public void validateEditPermissions( List<Case> newCases, Map<Id, Case> oldRecords) {
        
        // Query the PermissionSetAssignment object to get the PermissionSet names for the logged-in user
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()];
        
        Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
        List<String> skippedFieldsList = new List<String>();
        skippedFieldsList.add('Letters_Sent_to_Client_Indicator__c');
        skippedFieldsList.add('Confirmation_Provided__c');
        skippedFieldsList.add('Email_Review_Status__c');
        skippedFieldsList.add('Resolution_Mail_Status__c');
		skippedFieldsList.add('Complainant_Review_Body__c');
		
        Boolean validationTriggered = true;
        
        for (String str : caseFields.keyset()) {
            System.debug('field Change'+str);
            //validationTriggered = false;
            if (skippedFieldsList.contains(str)) {
                validationTriggered = false;
                break;
            }
        }
        if(validationTriggered) {
            // Extract the permission set names
            List<String> permissionSetNames = new List<String>();
            for (PermissionSetAssignment psa : psaList) {
                permissionSetNames.add(psa.PermissionSet.Name);
            }
            
            for (Case cs : newCases) { 
                Case OldCase = oldRecords.get(cs.Id);
                Boolean isOngoingorReopenedCase = (cs.Status == 'Ongoing' || cs.status == 'Reopened');
                Boolean isFOCUser = permissionSetNames.contains('FPOCs_L1');
                Boolean isFraudCase = cs.Is_this_about_fraud__c;
                // Boolean isSecondLevelPermission = isOngoingorReopenedCase && (permissionSetNames.contains('CR_Team_Lead_L1')  || permissionSetNames.contains('Complaints_Specialist_L1'));
                
                if(oldCase != null  ) {
                    if(!(permissionSetNames.contains('DEs_L2') || permissionSetNames.contains('SDEs_L3'))) {
                        if( isOngoingorReopenedCase  && UserInfo.getUserId() !=  oldCase.OwnerId && isFOCUser ) {
                            System.debug('Case 1');
                            cs.addError('You do not have permission to edit this case. Only the case owner can make changes.');
                            break;
                        }
                        /* else if(!isSecondLevelPermission){
System.debug('Case 2');
cs.addError('You do not have permission to edit this case. Only the case owner can make changes.');
break;
} */
                        else if((isFraudCase && UserInfo.getUserId() !=  oldCase.OwnerId)){
                            System.debug('Case 3');
                            cs.addError('You do not have permission to edit this case. Only the case owner can make changes.');
                            break;
                        } 
                    }
                }
            }
        }
    }
    
    public void validateComplaintResolvedClosedRecords(
        List<Case> newCases,
        Map<Id, Case> oldRecords
    ) {
        for (Case cs : newCases) {
            Boolean validationTriggered = false;
            Case NewCase = cs;
            Case OldCase = oldRecords.get(cs.Id);
            Case CaseObject = new Case();
            Schema.SObjectType objType = CaseObject.getSObjectType();
            Boolean isOtherFieldChanged = false;
            Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
            List<String> skippedFieldsList = new List<String>();
            skippedFieldsList.add('customer_care_call__c');
            skippedFieldsList.add('complainant_satisfaction__c');
            skippedFieldsList.add('complainant_satisfaction_details__c');
            skippedFieldsList.add('customer_care_call_date__c');
            skippedFieldsList.add('root_cause_remediation_actions__c');
            skippedFieldsList.add('root_cause_remediated__c');
            if (
                cs.Opportunity_File__c != null &&
                OldCase.Opportunity_File__c == null 
                //&& cs.Lead_File__c == null &&
                //OldCase.Lead_File__c != null
            ) {
                skippedFieldsList.add('opportunity_file__c');
                //skippedFieldsList.add('lead_file__c');
            }
            for (String str : caseFields.keyset()) {
                validationTriggered = false;
                if (
                    (OldCase.Status == 'Closed' || OldCase.Status == 'Resolved') &&
                    NewCase.Status != 'Reopened'
                ) {
                    if (
                        !skippedFieldsList.contains(str) &&
                        NewCase.get(str) != OldCase.get(str)
                    ) {
                        isOtherFieldChanged = true;
                    }
                    if (isOtherFieldChanged) {
                        
                    }
                    if (validationTriggered) {
                        break;
                    }
                }
            }
            if (validationTriggered) {
                break;
            }
        }
    }
    /*
patch data when Case is generated vis Email to Case
*/
    public void populateEmail2Case(List<Case> newCases) {
        HEB_App_Setting__mdt hs = HEB_App_Setting__mdt.getInstance('App');
        for (Case cs : newCases) {
            
            if (
                cs.OwnerId == hs.Email2Case_Default_Queue__c &&
                cs.Origin == hs.Email2Case_Origin__c &&
                cs.Priority == hs.Email2Case_Priority__c
            ) {
                cs.Ownerid = hs.Email2Case_To_be_Assigned_Queue__c;
                cs.Complaint_Date_Received__c = Date.today();
                cs.Incident_Date__c = cs.Complaint_Date_Received__c;
                cs.Case_Owner_Business_Unit__c = hs.Email2Case_Business_Unit__c;
                cs.Complainant_Type__c = 'Anonymous';
                string detail = cs.Subject + '\r\n' + cs.Description;
                cs.Detail_of_Complaint__c = detail.left(
                    integer.valueof(hs.Email2Case_Max_Length_of_Detail__c)
                );
            }
        }
    }
    
    //Deleting assignNewCaseToQueue as it is not longer needed -- Updated by Santhosh
    
    public void ownerBasevalidateOnUpdate(
        Map<Id, Case> records,
        Map<Id, Case> oldRecords
    ) {
        Boolean RestrictPermissionFpoc = FeatureManagement.checkPermission(
            'FPOCs_L1'
        );
        
        if (!RestrictPermissionFpoc) {
            return;
        }
        Id userId = userinfo.getuserid();
        case casebject = new case(); // This takes all available fields from the required object.
        Schema.SObjectType objType = casebject.getSObjectType();
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Case.fields.getMap();
        for (id recId : records.keyset()) {
            if (oldRecords.get(recId).ownerId == userId) {
                if (
                    !(oldRecords.get(recId).status == 'closed' ||
                      oldRecords.get(recId).status == 'Resolved')
                ) {
                    continue;
                } else if (
                    (oldRecords.get(recId).status == 'closed' ||
                     oldRecords.get(recId).status == 'Resolved') &&
                    (records.get(recId).status == 'Reopened')
                ) {
                    continue;
                }
            }
            if (CaseService.insertingIDs.contains(recId)) {
                continue;
            }
            for (String str : M.keyset()) {
                try {
                    case newCase = records.get(recId);
                    case oldCase = oldRecords.get(recId);
                    System.debug(
                        'Field name: ' +
                        str +
                        '. New value: ' +
                        NewCase.get(str) +
                        '. Old value: ' +
                        OldCase.get(str)
                    );
                    if (NewCase.get(str) != OldCase.get(str)) {
                        string oldOwnerId = oldCase.ownerId;
                        
                        if (
                            (oldOwnerId != UserInfo.getUserId()) &&
                            oldOwnerId.startsWithIgnoreCase('005')
                        ) {
                            newCase.addError(
                                'You are not the owner of the case to edit the record'
                            );
                        } else if (
                            (oldRecords.get(recId).status == 'closed' ||
                             oldRecords.get(recId).status == 'Resolved')
                        ) {
                            newCase.addError(
                                'You are not allowed to edit completed case records'
                            );
                        }
                    }
                } catch (Exception e) {
                    
                }
            }
        }
    }
    
    
    //Updating case status based on customer satisified and can I close or resolved this case in 24 hr fields
    public void setCaseStatus(List<Case> newCases) {
        for (Case cs : newCases) {
            String correspondenceMethod = cs.Correspondence_Method__c;
            boolean Escalation = cs.IsEscalated;
            
            if (cs.Can_I_close_or_resolve_this_complaint__c != null && cs.Is_Customer_Satisfied__c == null) {
                if (correspondenceMethod == 'Email' && Escalation != null) {
                    cs.status = 'Ongoing';
                    cs.Confirmation_Provided__c = 'Yes';
                    cs.Letters_Sent_to_Client_Indicator__c ='Acknowledgement of complaint';
                } else if (correspondenceMethod == 'Mail') {
                    cs.status = 'Ongoing';
                }
            }
            
            if (cs.Can_I_close_or_resolve_this_complaint__c == true) {
                if (cs.Is_Customer_Satisfied__c == 'Yes') {
                    if (correspondenceMethod == 'Email' && Escalation == false) {
                        cs.status = 'Resolved';
                        cs.Letters_Sent_to_Client_Indicator__c ='Combined Acknowledgement & Resolution Letter';
                    } 
                    else if (correspondenceMethod == 'Email' && Escalation == true){
                        cs.status = 'Ongoing';
                        cs.Letters_Sent_to_Client_Indicator__c ='Acknowledgement of complaint';
                    }
                    else if (correspondenceMethod == 'Mail') {
                        cs.status = 'Ongoing';
                        cs.Resolution_Mail_Status__c = 'Pending';
                    }
                } else if (cs.Is_Customer_Satisfied__c == 'No') {
                    if (correspondenceMethod == 'Email' && Escalation == false) {
                        cs.status = 'Closed';
                        cs.Letters_Sent_to_Client_Indicator__c ='Combined Acknowledgement & Resolution Letter';
                    } 
                    else if (correspondenceMethod == 'Email' && Escalation == true){
                        cs.status = 'Ongoing';
                        cs.Letters_Sent_to_Client_Indicator__c ='Acknowledgement of complaint';
                    }
                    else if (correspondenceMethod == 'Mail') {
                        cs.status = 'Ongoing';
                        cs.Resolution_Mail_Status__c = 'Pending';
                    }
                }
            }
        }
    }
    
    public void setEmailOrTaskSubject(List<Case> newCases) {
        for (Case cs : newCases) {
            if (cs.Correspondence_Method__c == 'Email') {
                String subject;
                if (cs.Language__c == 'English') {
                    subject = 'Complaint to HomeEquity Bank Received';
                } else if (cs.Language__c == 'French') {
                    subject = (cs.Is_Customer_Satisfied__c == null)  ? 'Votre plainte à la Banque HomeEquity a été reçue'  : 'Plainte à la Banque HomeEquity reçue';
                }
                cs.Email_Subject__c = subject;
            }

        }
    }
}