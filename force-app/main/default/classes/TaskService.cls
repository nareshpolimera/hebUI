/*
* @Class      TaskService
* @brief      Class with especific-related methods to the Task object.
*
* @revision   2024-05-14 Juan Carlos Contreras
*                Porting from legacy SF org.
*/
public without sharing class TaskService {
  public void assignAssociatedCampaign(List<Task> records) {
    List<Task> taskList = records;
    //List of campaign members to create
    List<CampaignMember> cmList = new List<CampaignMember>();
    List<Id> whoIdList = new List<Id>();
    List<Id> contactList = new List<Id>(); //Full Match Contact ID list

    for (Task t : taskList) {
      if (t.WhoId <> null) {
        whoIdList.add(t.WhoId);
      }
    }

    //Map campaign phone numbers to ids
    Map<String, Id> campaignIdNumberList = new Map<String, Id>();
    for (Campaign c : [
      SELECT Id, Phone_Label__c
      FROM Campaign
      WHERE IsActive = TRUE
    ]) {
      if (
        (campaignIdNumberList.get(c.Phone_Label__c) == null) &&
        (c.Phone_Label__c <> null)
      ) {
        campaignIdNumberList.put(c.Phone_Label__c, c.Id);
      }
    }

    //Map a list of campaignmembers to a contactid
    //get a list of campaigns to check for duplicates
    Map<Id, List<CampaignMember>> contactIdCampaignMembersMap = new Map<Id, List<CampaignMember>>();
    for (CampaignMember cm : [
      SELECT Id, CampaignId, ContactId 
      FROM CampaignMember
      WHERE ContactId IN :whoIdList
    ]) {
      if (contactIdCampaignMembersMap.get(cm.ContactId) == null) {
        List<CampaignMember> newCMList = new List<CampaignMember>();
        newCMList.add(cm);
        contactIdCampaignMembersMap.put(cm.ContactId, newCMList);
      } else {
        List<CampaignMember> oldCMList = contactIdCampaignMembersMap.get(
          cm.ContactId
        );
        oldCMList.add(cm);
        contactIdCampaignMembersMap.put(cm.ContactId, oldCMList);
      }
    }

    for (Task t : taskList) {
      //Skip tasks without contactIds or with non contact whoIds
      if (
        (t.WhoId == null) ||
        (t.WhoId.getSObjectType().getDescribe().getName() <> 'Contact')
      ) {
        continue;
      }

      //Check if there is an existing campaign member
      Boolean foundFullMatch = false;
      String serviceName = (t.Service_Name__c != null)
        ? t.Service_Name__c
        : '';
      if (contactIdCampaignMembersMap.get(t.WhoId) <> null) {
        for (CampaignMember cm : contactIdCampaignMembersMap.get(t.WhoId)) {
          if (cm.CampaignId == campaignIdNumberList.get(serviceName)) {
            foundFullMatch = true; //Camaign Memeber is found under an active Campaign based on Service Name.
            contactList.add(t.whoid);
          }
        }
      }
      if (foundFullMatch) {
        contactList.add(t.whoid);
        System.debug('!!! Match found - related Contact ID = ' + t.whoid);
      } else if (campaignIdNumberList.get(serviceName) <> null) {
        //Check if there is a corresponding campaign to this number and assign if yes
        CampaignMember cm = new CampaignMember(
          CampaignId = campaignIdNumberList.get(serviceName),
          ContactId = t.WhoId,
          Activity_Generated_Campaign_Member__c = true
        );
        System.debug(
          '!!! new Campaign Memeber - related Contact ID = ' + cm.contactId
        );
        cmList.add(cm);
      }
    }

    insert cmList;

    List<Contact> llt = [
      SELECT Id, Most_Recent_Inquiry_Date__c
      FROM Contact
      WHERE Id IN :contactList
    ];
    if (!llt.isEmpty()) {
      for (Contact ld : llt) {
        ld.Most_Recent_Inquiry_Date__c = Datetime.now();
      }
      update llt; // Update Contact with current datetime on Most Recent Inquiry Date field
    }
  }

    /* HEB-620 Moving status from new to contacted on logging first call */
    public void updateOppStatusToContacted(List<Task> records) {
        List<Id> oppIdList = new List<Id>();
        //check if a contact is associated
        for (Task e : records) {
            if ((e.WhatId != null) && 
                (String.valueOf(e.WhatId).startsWith('006')) &&
                (e.Outcome__c == null ||
                !e.Outcome__c.contains('Meeting Booked'))) {
                oppIdList.add(e.WhatId);
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        //if a Opportunity is associated check its in 'new'
        for (Opportunity o : [SELECT Id, StageName 
                                FROM Opportunity 
                                WHERE id IN :oppIdList]) {
            if (o.StageName == 'New') {
                o.StageName = 'Contacted';
                oppsToUpdate.add(o);
            }
        }

        //update the opp
        try {
            update oppsToUpdate;
        } catch (DmlException e) {
            System.debug(e.getMessage());
        }
    }

   /*Commetned by santhosh as it is not required*/
  /*public void restrictTaskCreation(List<Task> records) {
    Boolean RestrictPermissionFpoc = FeatureManagement.checkPermission(
      'FPOCs_L1'
    );
    if (!RestrictPermissionFpoc) {
      return;
    }
    Id userId = userinfo.getuserid();
    list<string> caseIDList = new List<string>();
    map<id, Task> errorrecords = new Map<id, Task>();
    for (Task t : records) {
      string caseId = t.whatid;
      if (caseId != null && caseId.startsWithIgnoreCase('500')) {
        caseIDList.add(caseId);
        errorrecords.put(caseId, t);
      }
    }
    if (caseIDList.size() > 0) {
      list<case> casemap = [
        SELECT Id, ownerId
        FROM case
        WHERE id IN :caseIDList
      ];
      for (case c : casemap) {
        if (
          c.OwnerId != UserInfo.getUserId() &&
          !CaseService.insertingIDs.contains(c.id) &&
          !CaseService.updatingIDs.contains(c.id)
        ) {
          errorrecords.get(c.id)
            .adderror(
              'You cannot create a task for a case which you do not own'
            );
        }
      }
    }
  }*/
  /* HEB-xxx Sync Categroty/Outcome/Reason values from data captured byNVM Log A Call widget */
  public void initialPicklistValuestoDefaultFields(List<Task> records) {
    for (Task t : records) {
      if (t.Category_Specialists__c != null) {
        t.Category__c = t.Category_Specialists__c;
      }
      if (t.Outcome_Specialists__c != null) {
        t.Outcome__c = t.Outcome_Specialists__c;
      }
      if (t.Category_Consultants__c != null) {
        t.Category__c = t.Category_Consultants__c;
      }
      if (t.Outcome_Consultants__c != null) {
        t.Outcome__c = t.Outcome_Consultants__c;
      }
      if (t.Reason_Consultants__c != null) {
        t.Call_Reason__c = t.Reason_Consultants__c;
      }
    }
  }

  public void assignPicklistValuestoDefaultFields(
    List<Task> records,
    Map<Id, Task> oldRecords
  ) {
    for (Task t : records) {
      Task oldt = oldRecords.get(t.Id);
      if (
        t.Category_Specialists__c != null &&
        t.Category_Specialists__c != oldt.Category_Specialists__c
      ) {
        t.Category__c = t.Category_Specialists__c;
      }
      if (
        t.Outcome_Specialists__c != null &&
        t.Outcome_Specialists__c != oldt.Outcome_Specialists__c
      ) {
        t.Outcome__c = t.Outcome_Specialists__c;
      }
      if (
        t.Category_Consultants__c != null &&
        t.Category_Consultants__c != oldt.Category_Consultants__c
      ) {
        t.Category__c = t.Category_Consultants__c;
      }
      if (
        t.Outcome_Consultants__c != null &&
        t.Outcome_Consultants__c != oldt.Outcome_Consultants__c
      ) {
        t.Outcome__c = t.Outcome_Consultants__c;
      }
      if (
        t.Reason_Consultants__c != null &&
        t.Reason_Consultants__c != oldt.Reason_Consultants__c
      ) {
        t.Call_Reason__c = t.Reason_Consultants__c;
      }
    }
  }

    /* Owner: Naresh Polimera
    * Date: 07-29-2024
    * US: 7596 : Mark Acknowledgement Letter for New Complaint as Sent
    * US: 7800 : Mark Resolution/Close Letter for On-Going Complaint as Sent */
    public void setCommunicationLettersSenttoClientIndicatorValues(List<Task> records, Map<Id, Task> oldRecords){
        Set<String> fieldsToCheck = new Set<String>{ 'Status' };
        List<Task> changedTasks = (List<Task>) Utils.getChangedObjects(records, oldRecords, fieldsToCheck);
        Set<Id> caseIds = new Set<Id>();
        List<Task> CompletedTasks = New List<Task>();
        for (Task thisTask : changedTasks) {
            if (thisTask.status == 'Completed') {
                caseIds.add(thisTask.WhatId);
                CompletedTasks.add(thisTask);
            }
        }
        
        Map<Id, string> mapTaskCaseIdWithValue = new map<Id,string>();
        for(Task task : CompletedTasks) {
            mapTaskCaseIdWithValue.put(task.WhatId, task.Case_Letter_Type_Sent__c);
        }
        
        if (caseIds.size() > 0) {
            List<Id> caseIDList = new List<Id>(caseIds);
            List<Case> caseList = [
                SELECT
                id,
                Is_Customer_Satisfied__c,
                Letters_Sent_to_Client_Indicator__c,
                Resolution_Mail_Status__c,
                Confirmation_Provided__c
                FROM Case
                WHERE id IN :caseIDList
            ];
            
            for (Case thisCase : caseList) {
                
                string taskStatus = mapTaskCaseIdWithValue.get(thisCase.Id);
                string assignCaseIndicator ='';
                if(taskStatus == 'Acknowledge') {
                    assignCaseIndicator = 'Acknowledgement of complaint';
                    thisCase.Confirmation_Provided__c = 'Yes';
                }
                else if(taskStatus == 'Combined'){
                    assignCaseIndicator = 'Combined Acknowledgement & Resolution Letter';
                    thisCase.Resolution_Mail_Status__c = 'Sent';
                }
                else if(taskStatus == 'Resolve/Close'){
                    assignCaseIndicator = 'Resolution Letter'; 
                    thisCase.Resolution_Mail_Status__c = 'Sent';
                }
                thisCase.Letters_Sent_to_Client_Indicator__c = String.isNotBlank(thisCase.Letters_Sent_to_Client_Indicator__c)? thisCase.Letters_Sent_to_Client_Indicator__c +';'+ assignCaseIndicator: assignCaseIndicator;
            }
            update caseList;
        }
    }

    
  public void resolveCase(List<Task> records, Map<Id, Task> oldRecords) {
    List<Task> lsActive = new List<Task>();
    Set<String> fieldsToCheck = new Set<String>{ 'Status' };
    List<Task> changedTasks = (List<Task>) Utils.getChangedObjects(
      records,
      oldRecords,
      fieldsToCheck
    );
    Set<Id> caseIds = new Set<Id>();
    Map<String, String> completedTaskMap = new Map<String, String>();

    for (Task thisTask : changedTasks) {
      if (thisTask.status == 'Completed') {
        if (
          thisTask.Resolution_Mail_Status__c == 'Pending' &&
          thisTask.Acknowledgement_Mail_Status__c == 'Pending'
        ) {
          thisTask.Resolution_Mail_Status__c = 'Sent';
          thisTask.Acknowledgement_Mail_Status__c = 'Sent';
          caseIds.add(thisTask.WhatId);
          completedTaskMap.put('Combined', thisTask.WhatId + ';');
        } else if (thisTask.Resolution_Mail_Status__c == 'Pending') {
          thisTask.Resolution_Mail_Status__c = 'Sent';
          caseIds.add(thisTask.WhatId);
          completedTaskMap.put('Resolution', thisTask.WhatId + ';');
        } else if (thisTask.Acknowledgement_Mail_Status__c == 'Pending') {
          thisTask.Acknowledgement_Mail_Status__c = 'Sent';
          caseIds.add(thisTask.WhatId);
          completedTaskMap.put('Acknowledgement', thisTask.WhatId + ';');
        }
      }
    }

    if (caseIds.size() > 0) {
      List<Id> caseIDList = new List<Id>(caseIds);
      List<Case> caseList = [
        SELECT
          id,
          Is_Customer_Satisfied__c,
          Status,
          Resolution_Mail_Status__c,
          Letters_Sent_to_Client_Indicator__c,
          Acknowledgement_Mail_Status__c,
          Confirmation_Provided__c
        FROM Case
        WHERE id IN :caseIDList
      ];
      String resolvedCaseIDs = completedTaskMap.get('Resolution');
      String acknowledgementCaseIDs = completedTaskMap.get('Acknowledgement');
      String combinedCaseIds = completedTaskMap.get('Combined');

      for (Case thisCase : caseList) {
        if (combinedCaseIds != null && combinedCaseIds.contains(thisCase.id)) {
          thisCase.Acknowledgement_Mail_Status__c = 'Sent';
          thisCase.Resolution_Mail_Status__c = 'Sent';

          thisCase.Letters_Sent_to_Client_Indicator__c = String.isNotBlank(
              thisCase.Letters_Sent_to_Client_Indicator__c
            )
            ? thisCase.Letters_Sent_to_Client_Indicator__c +
              ';Combined Acknowledgement & Resolution Letter'
            : 'Combined Acknowledgement & Resolution Letter';
          thisCase.Confirmation_Provided__c = 'Yes';
        }

        if (
          acknowledgementCaseIDs != null &&
          acknowledgementCaseIDs.contains(thisCase.id)
        ) {
          thisCase.Acknowledgement_Mail_Status__c = 'Sent';
          thisCase.Letters_Sent_to_Client_Indicator__c = String.isNotBlank(
              thisCase.Letters_Sent_to_Client_Indicator__c
            )
            ? thisCase.Letters_Sent_to_Client_Indicator__c +
              ';Acknowledgement of complaint'
            : 'Acknowledgement of complaint';
          thisCase.Confirmation_Provided__c = 'Yes';
        }

        if (resolvedCaseIDs != null && resolvedCaseIDs.contains(thisCase.id)) {
          thisCase.Resolution_Mail_Status__c = 'Sent';
          thisCase.Letters_Sent_to_Client_Indicator__c = String.isNotBlank(
              thisCase.Letters_Sent_to_Client_Indicator__c
            )
            ? thisCase.Letters_Sent_to_Client_Indicator__c +
              ';Resolution letter'
            : 'Resolution letter';
        }

        if (
          thisCase.Acknowledgement_Mail_Status__c == 'Sent' &&
          thisCase.Resolution_Mail_Status__c == 'Sent' &&
          thisCase.Confirmation_Provided__c == 'Yes'
        ) {
          System.debug('Updatre case status');
          if (thisCase.Is_Customer_Satisfied__c == 'Yes') {
            thisCase.status = 'Resolved';
          }
          if (thisCase.Is_Customer_Satisfied__c == 'No') {
            thisCase.status = 'Closed';
          }
        }
      }

      update caseList;
    }
  }
}