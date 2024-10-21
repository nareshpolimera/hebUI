public class CaseEmailNotificationHandler {
  public static list<Messaging.SingleEmailMessage> createEmailOnOwnerChange(
    list<id> CaseIds,
    Map<Id, Case> records,
    Map<Id, Case> oldRecords,
    map<id, user> userMap,
    string type
  ) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    OrgWideEmailAddress[] owea = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'ksohn@chip.ca'
    ];


    group fpoc = new group();
    group complaintsSpecialist = new group();
    group seniorComplaintHandler = new group();
    group seniorDEgroup = new group();
    group DEgroup = new group();
    list<id> fpocUserList = new List<id>();
    list<id> complaintsSpecialistUserList = new List<id>();
    list<id> seniorComplaintHandlerUserList = new List<id>();
    list<string> seniorDesignatedEmployeeUserList = new List<id>();
    list<string> DesignatedEmployeeUserList = new List<id>();
    if (type == 'sameLevelTransferEmail') {
      list<group> allGroups = [
        SELECT id, Name, DeveloperName, CreatedById
        FROM group
        ORDER BY CreatedDate
      ];
      for (group allG : allGroups) {
        if (allG.DeveloperName == 'First_Point_of_Contact') {
          fpoc = allG;
        } else if (allG.DeveloperName == 'Customer_Care_Complaint_Handlers') {
          complaintsSpecialist = allG;
        } else if (allG.DeveloperName == 'Senior_Complaint_Handlers') {
          seniorComplaintHandler = allG;
        }
      }

      list<GroupMember> allGroupList = [
        SELECT GroupId, UserOrGroupId
        FROM GroupMember
        WHERE
          GroupId = :fpoc.id
          OR GroupId = :complaintsSpecialist.id
          OR GroupId = :seniorComplaintHandler.id
      ];
    

      for (GroupMember allG : allGroupList) {
        if (allG.GroupId == fpoc.id) {
          fpocUserList.add(allG.UserOrGroupId);
        }
        if (allG.GroupId == complaintsSpecialist.id) {
          complaintsSpecialistUserList.add(allG.UserOrGroupId);
        }
        if (allG.GroupId == seniorComplaintHandler.id) {
          seniorComplaintHandlerUserList.add(allG.UserOrGroupId);
        }
      }
    }
    if (type == 'EscalationEmailLevel3' || type == '50DaysEscalationEmail') {
      list<group> allGroups = [
        SELECT id, Name, DeveloperName, CreatedById
        FROM group
        ORDER BY CreatedDate
      ];
      for (group allG : allGroups) {
        if (allG.DeveloperName == 'Senior_Designated_Employees') {
          seniorDEgroup = allG;
        }
      }
      system.debug('seniorDEgroup' + seniorDEgroup);
      list<GroupMember> allGroupList = [
        SELECT GroupId, UserOrGroupId
        FROM GroupMember
        WHERE GroupId = :seniorDEgroup.id
      ];
      system.debug('seniorDEgroup' + seniorDEgroup);
      for (GroupMember allG : allGroupList) {
        seniorDesignatedEmployeeUserList.add(allG.UserOrGroupId);
      }
    }

    if (type == 'EscalationEmailLevel2' || type == '14DaysEscalationEmail') {
      list<group> allGroups = [
        SELECT id, Name, DeveloperName, CreatedById
        FROM group
        ORDER BY CreatedDate
      ];
      for (group allG : allGroups) {
        if (allG.DeveloperName == 'Designated_Employees') {
          DEgroup = allG;
        }
      }
      system.debug('DEgroup' + DEgroup);
      list<GroupMember> allGroupList = [
        SELECT GroupId, UserOrGroupId
        FROM GroupMember
        WHERE GroupId = :DEgroup.id
      ];
      system.debug('DEgroup' + DEgroup);
      for (GroupMember allG : allGroupList) {
        DesignatedEmployeeUserList.add(allG.UserOrGroupId);
      }
    }
    for (id caseId : CaseIds) {
      string oldOwnerId = oldRecords.get(caseId).ownerId;
      string newOwnerId = records.get(caseId).ownerId;
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      String[] toAddresses = new List<String>{
        userMap.get((records.get(caseId).ownerId)).Email
      };

      mail.setToAddresses(toAddresses);
      mail.setBccSender(false);
      mail.setUseSignature(false);
      mail.setReplyTo('support@Salesforce.com');
      mail.setOrgWideEmailAddressId(owea.get(0).Id);
      mail.setWhatId(caseId);
      mail.saveAsActivity = false;
      mail.setTargetObjectId((records.get(caseId).ownerId));
      String body = '';
      if (type == 'sameLevelTransferEmail') {
        system.debug('sameLevelTransferEmail');
        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been transferred to you. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        if (records.get(caseId).Is_this_about_fraud__c) {
          body =
            '<html> <body style="font-size: 15px;"><br/>Hello ' +
            userMap.get((records.get(caseId).ownerId)).Name +
            ',<br/><br/> Complaint ' +
            records.get(caseId).CaseNumber +
            ' has been transferred to you because the complaint handler marked it as Fraud, Reputational Risk or Employee Misconduct. <br/><br/>Please visit the complaint to review and conduct an investigation: ' +
            makeCaseLink(
              caseId,
              'Complaint ' + records.get(caseId).CaseNumber
            ) +
            '<br/><br/>Thank you! </body></html>';
        }
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Transferred to you, please resolve'
        );
        if (
          fpocUserList.contains(newOwnerId) &&
          complaintsSpecialistUserList.contains(oldOwnerId)
        ) {
          body =
            '<html> <body style="font-size: 15px;"><br/>Hello ' +
            userMap.get((records.get(caseId).ownerId)).Name +
            ',<br/><br/> Complaint ' +
            records.get(caseId).CaseNumber +
            ' has been transferred to you because the complaint handler could not resolve or close this because they were not the appropriate person. <br/><br/>Please visit the complaint to resolve or close it: ' +
            makeCaseLink(
              caseId,
              'Complaint ' + records.get(caseId).CaseNumber
            ) +
            '<br/><br/>Thank you! </body></html>';
          list<string> ccIds = new List<string>();
          if (userMap.get(newOwnerId).ManagerId != null) {
            ccIds.add(userMap.get(newOwnerId).ManagerId);
          }
          if (userMap.get(oldOwnerId).ManagerId != null) {
            ccIds.add(userMap.get(oldOwnerId).ManagerId);
          }

          mail.setCcAddresses(ccIds);
        }
        if (
          seniorComplaintHandlerUserList.contains(newOwnerId) &&
          (!seniorComplaintHandlerUserList.contains(oldOwnerId))
        ) {
          body =
            '<html> <body style="font-size: 15px;"><br/>Hello ' +
            userMap.get((records.get(caseId).ownerId)).Name +
            ',<br/><br/> Complaint ' +
            records.get(caseId).CaseNumber +
            ' has been transferred to you because the complaint handler could not resolve or close this because a more skilled person is needed. <br/><br/>Please visit the complaint to resolve or close it: ' +
            makeCaseLink(
              caseId,
              'Complaint ' + records.get(caseId).CaseNumber
            ) +
            '<br/><br/>Thank you! </body></html>';
          list<string> ccIds = new List<string>();
          if (userMap.get(newOwnerId).ManagerId != null) {
            ccIds.add(userMap.get(newOwnerId).ManagerId);
          }
          mail.setCcAddresses(ccIds);
        }
      } else if (type == '14DaysEscalationEmail') {
        system.debug('14DaysEscalationEmail');
        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been escalated to you because the complaint is now past 14 days. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        Integer result = DesignatedEmployeeUserList.indexOf(newOwnerId);
        if (!(result < 0)) {
          DesignatedEmployeeUserList.remove(result);
        }
        if (DesignatedEmployeeUserList.size() > 0) {
          mail.setCcAddresses(DesignatedEmployeeUserList);
        }
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Over 14 days escalated to you, please resolve'
        );
      } else if (type == '50DaysEscalationEmail') {
        Integer result = seniorDesignatedEmployeeUserList.indexOf(newOwnerId);
        if (!(result < 0)) {
          seniorDesignatedEmployeeUserList.remove(result);
        }
        if (seniorDesignatedEmployeeUserList.size() > 0) {
          mail.setCcAddresses(seniorDesignatedEmployeeUserList);
        }
        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been escalated to you because the complaint is now past 50 days. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Over 50 days escalated to you, please resolve'
        );
      } else if (type == 'cantResolvedCaseEmail') {
        system.debug('cantResolvedCaseEmail');
        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been transferred to you because the complaint handler could not resolve or close this within 24 hours. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        if (records.get(caseId).Is_this_about_fraud__c) {
          body =
            '<html> <body style="font-size: 15px;"><br/>Hello ' +
            userMap.get((records.get(caseId).ownerId)).Name +
            ',<br/><br/> Complaint ' +
            records.get(caseId).CaseNumber +
            ' has been transferred to you because the complaint handler marked it as Fraud, Reputational Risk or Employee Misconduct. <br/><br/>Please visit the complaint to review and conduct an investigation: ' +
            makeCaseLink(
              caseId,
              'Complaint ' + records.get(caseId).CaseNumber
            ) +
            '<br/><br/>Thank you! </body></html>';
        }
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Transferred to you, please resolve'
        );
      } else if (type == 'EscalationEmailLevel2') {
        system.debug('EscalationEmailLevel2');
        Integer result = DesignatedEmployeeUserList.indexOf(newOwnerId);
        if (!(result < 0)) {
          DesignatedEmployeeUserList.remove(result);
        }

        if (DesignatedEmployeeUserList.size() > 0) {
          mail.setCcAddresses(DesignatedEmployeeUserList);
        }
        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been escalated to you. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Escalated to you, please resolve'
        );
      } else if (type == 'EscalationEmailLevel3') {
        system.debug('EscalationEmailLevel3');
        list<string> ccIds = new List<string>();
        ccIds = ccIds;
        Integer result = seniorDesignatedEmployeeUserList.indexOf(newOwnerId);
        if (!(result < 0)) {
          seniorDesignatedEmployeeUserList.remove(result);
        }
        if (seniorDesignatedEmployeeUserList.size() > 0) {
          mail.setCcAddresses(seniorDesignatedEmployeeUserList);
        }

        body =
          '<html> <body style="font-size: 15px;"><br/>Hello ' +
          userMap.get((records.get(caseId).ownerId)).Name +
          ',<br/><br/> Complaint ' +
          records.get(caseId).CaseNumber +
          ' has been escalated to you. <br/><br/>Please visit the complaint to resolve or close it:  ' +
          makeCaseLink(caseId, 'Complaint ' + records.get(caseId).CaseNumber) +
          '<br/><br/>Thank you! </body></html>';
        mail.setSubject(
          'Complaint ' +
          records.get(caseId).CaseNumber +
          ' Escalated to you, please resolve'
        );
      } else {
        continue;
      }
      mail.setHtmlBody(body);
      emails.add(mail);
    }
    if (emails.size() > 0) {
      //Messaging.sendEmail(emails);
      return emails;
    }
    return null;
  }

  public static void sendEmails(list<Messaging.SingleEmailMessage> emailLists) {
    Messaging.sendEmail(emailLists);
  }

  public static String makeCaseLink(String stringId, string caseNumber) {
    Id id = (Id) stringId;
    return '<a href="' +
      Url.getOrgDomainURL().toExternalForm() +
      '/' +
      id +
      '">' +
      caseNumber +
      '</a>';
  }
}