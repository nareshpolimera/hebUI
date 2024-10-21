/******************************************************//**
@Class      CMS_Handler
@brief      Handler class for CMS LWC and Aura.

@revision   2024-05-02 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public without sharing class CMS_Handler {
    @AuraEnabled(cacheable=true)
    public static Case getComplaintDetails(string caseId) {
      List<Case> caseList = new List<Case>(
        [
          SELECT
            //Complainant_Preferred_Contact_Method__c,
            Complainant_Email__c,
            //Complainant_Street__c,
            //Complainant_City__c,
            //Complainant_State__c,
            //Complainant_Postal_Code__c,
            Is_Customer_Satisfied__c,
            Language__c,
            Origin,
            Complaint_Date_Received__c,
            Statement_of_Fact__c,
            Resolution_Sought__c,
            Complaint_Category__c,
            Complaint_Subcategory__c,
            Category_Description__c,
            Sub_Category_Description__c,
            Correspondence_Method__c,
            Complainant_Type__c,
            Complaint_Outcome__c,
            Investigation_Details__c,
            Apply_Redress__c,
            Complaint_Handling_Level__c,
            Resolution_Mail_Status__c,
            E_Consent_Indicator__c,
            Status,
            Confirmation_Provided__c,
            Account.PersonMailingCity,
            Account.PersonMailingStreet,
            Account.PersonMailingCountry,
            Account.PersonMailingState,
            Account.PersonMailingPostalCode,
            Account.PersonEmail,
            Is_this_about_fraud__c,
            Account.FirstName, 
            Account.LastName
          FROM Case
          WHERE Id = :caseId
        ]
      );

      return caseList[0];
    }
    
    @AuraEnabled
    public static List<Redress__c> getRedressDetailsByCaseId(string caseId) {
        System.debug(caseId);
        List<Redress__c> returnList =  [select id, Financial_Redress_Type__c, Redress_Method__c, Redress_Amount__c, Resolution_Rationale__c from Redress__c where Case__c =: caseId];
        System.debug(returnList);
        return returnList;
    }
  
    @AuraEnabled
    public static case caseRecMethod( Case caseRec,
                                    list<Redress__c> redressList,
                                    Account complainantData,
                                    Id recordId) {

        system.debug('complainantData' + complainantData);
        system.debug('redressList' + redressList);
        system.debug('caseRec' + caseRec);
       	Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Complainant').getRecordTypeId();
        try {
            if (recordId != null) {
                //2024-05-02 - Joel Ojeda - Temporary disabled until logic gets defined
                Opportunity file = [SELECT id, File_Number__c FROM Opportunity WHERE id = :recordId];
                caseRec.Opportunity_File__c = recordId;
                caseRec.File_Number__c = file.File_Number__c;
            }
            if (complainantData != null) {
                //insert person account
                complainantData.RecordTypeId = recordTypeId;
                upsert complainantData;
                
                //get related person contact to link with the case
                List<Account> accs = [SELECT Id,Language__pc,
                                        PersonContactId 
                                        FROM Account 
                                        WHERE Id = :complainantData.Id];
                if(!accs.isEmpty()){
                    caseRec.Complainant__c = complainantData.Id;
                    caseRec.AccountId = complainantData.Id;
                    caseRec.Language__c = accs[0].Language__pc;
                }
            }

            caseRec.status = 'Ongoing';
            //caseRec.Email_Suppressed__c = String.isNotBlank(caseRec.Is_Customer_Satisfied__c); --Updated By Santhosh

            if (String.isNotBlank(caseRec.Is_Customer_Satisfied__c)) {
                if (caseRec.Correspondence_Method__c != 'Mail') {
                    caseRec.Confirmation_Provided__c = 'Yes';
                }
                //caseRec.Email_Suppressed__c = false;
            }

            insert caseRec;
            case Data = [SELECT Id, CaseNumber FROM case WHERE id = :caseRec.id];
            if (redressList != null) {
                saveRedresses(redressList, caseRec.id);
            }

            return Data;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string getPreview(string reqBody, Boolean isResolution) {
  
  		System.debug(reqBody);
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        IntegrationService.getEndpoint(
          IntegrationService.MARS_API.Complaints_Correspondence_Preview
        )
      );
      system.debug(req.getEndpoint());
      req.setMethod(IntegrationService.METHOD_POST);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
      );
      system.debug(TokenService.getToken(TokenService.Target.MARS));
      req.setBody(reqBody);
      req.setTimeout(2 * 60 * 1000);
      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseStr;
      if (res.getStatusCode() == IntegrationService.HTTP_OK) {
        // update to check on response code
        responseStr = res.getBody();
        system.debug(res.getBody());
      }
      return responseStr;
    }

    //Santhosh
    @AuraEnabled
    public static string getEmailContent(string reqBody) {
  
  
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        IntegrationService.getEndpoint(
          IntegrationService.MARS_API.Complaints_Correspondence_Content
        )
      );
      system.debug(req.getEndpoint());
      req.setMethod(IntegrationService.METHOD_POST);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
      );
      system.debug(TokenService.getToken(TokenService.Target.MARS));
      req.setBody(reqBody);
      req.setTimeout(2 * 60 * 1000);
      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseStr;
        if (res.getStatusCode() == IntegrationService.HTTP_OK) {
            // update to check on response code
            responseStr = res.getBody();
            system.debug(res.getBody());
        }
        else{
            System.debug('getEmailContent :: '+ res);
            // getEmailContent
        }
      return responseStr;
    }
  
    @AuraEnabled
    public static void setBodayandCallGenerateResolvedApi(
      string Id,
      String handlingLevel
    ) {
      try {
        string reqBody =
          '{"SFID":"' +
          Id +
          '","UploadToSF": true, "ComplaintLetterType" : "Resolution letter"}';
          system.debug('Resolution review body '+ reqBody);
        callGenerate(reqBody);
  
        setResolutionField(Id);
      } catch (exception e) {
        system.debug(e.getmessage());
      }
    }
  
    @AuraEnabled
    public static void setBodayandCallGenerateApi(string Id) {
      try {
        system.debug('123');
        Case thisCase = [
          SELECT id, Is_Customer_Satisfied__c
          FROM Case
          WHERE id = :Id
        ];
        string reqBody;
        //added by santhosh
        if (String.isBlank(thisCase.Is_Customer_Satisfied__c)) {
          reqBody =
            '{"SFID":"' +
            Id +
            '","UploadToSF": true,  "ComplaintLetterType" : "Acknowledgement of complaint" }';
            system.debug('Accknowledge complaint review body '+ reqBody);
        } else {
          reqBody = '{"SFID":"' + Id + '","UploadToSF": true, "ComplaintLetterType" : "Combined Acknowledgment & Resolution Letter"}';
        }
  
        callGenerate(reqBody);
      } catch (exception e) {
        system.debug(e.getmessage());
      }
    }
    public static string callGenerate(string reqBody) {
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        IntegrationService.getEndpoint(
          IntegrationService.MARS_API.Complaints_Correspondence_Generate
        )
      );
      req.setMethod(IntegrationService.METHOD_POST);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
      );
      system.debug(TokenService.getToken(TokenService.Target.MARS));
      req.setBody(reqBody);
      req.setTimeout(2 * 60 * 1000);
      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseStr;
      if (res.getStatusCode() == IntegrationService.HTTP_OK) {
        // update to check on response code
        responseStr = res.getBody();
      }
        system.debug('responseStr' + responseStr);
      return responseStr;
    }
    @AuraEnabled
    public static string saveRedresses(list<Redress__c> recList, id caseId) {
      try {
        for (Redress__c rec : recList) {
          rec.Case__c = caseId;
        }
        upsert recList;
        return 'Success';
      } catch (Exception e) {
        return 'Error' + e.getMessage();
      }
    }
  
    @AuraEnabled
    public static void setResolutionField(string caseId) {
      try {
        Case caseToUpdate = new Case(
          Id = caseId,
          Resolution_Mail_Status__c = 'Pending'
        );
        update caseToUpdate;
      } catch (exception e) {
        system.debug(e.getmessage());
      }
    }
  
    @AuraEnabled
    public static void changeCorrespondenceMethod(string caseId, String method) {
      try {
        Case caseToUpdate = new Case(
          Id = caseId,
          Correspondence_Method__c = method
        );
        update caseToUpdate;
      } catch (exception e) {
        system.debug(e.getmessage());
      }
    }
    
    @AuraEnabled
    public static Case getCaseDetails(string caseId){
        return [SELECT ID,Complaint_Handling_Level__c, OwnerId, Is_this_about_fraud__c  FROM CASE WHERE ID =: caseId LIMIT 1];
    }
    
    @AuraEnabled
    public static void esclateToDesignateEmployeeFromLevelOne(string caseId, 
                                                              string role,
                                                              string rationale){
        try {
            // Case Status
            List<String> closedStatus = new List<String> {'Ongoing', 'Resolved', 'Closed' } ;
                
            Case caseToUpdate = [SELECT ID, Complaint_Handling_Level__c, IsEscalated,
                                 Complaint_Escalation_Rationale__c,
                                 Escalation_to_SDE_Rationale__c
                                 FROM CASE WHERE ID =: caseId];
            
            if(role =='DE') {
                caseToUpdate.Complaint_Handling_Level__c = 'Level 2';
                caseToUpdate.Complaint_Escalation_Rationale__c = rationale;
            }
            if(role =='SDE') {
                caseToUpdate.Complaint_Handling_Level__c = 'Level 3';
                caseToUpdate.Escalation_to_SDE_Rationale__c = rationale;
            }
            
            update caseToUpdate;
        } catch (exception e) {
            system.debug(e.getmessage());
        }
    }
    
    private Logger theLogger;
    
    @AuraEnabled
    public static void transferToDesignateEmployeeFromLevelOne(string caseId, string option, string userId) {
        Case updateisTransfer = [Select id,Transfer_to_Role__c,OwnerId from Case where Id =: caseId];
        Case caseToUpdate = new Case(Id = caseId, Transfer_to_Role__c = option);
        if(userId != null){
            caseToUpdate.OwnerId = userId;
        }
        update caseToUpdate;  
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersForHandlingLevel(String caseId) { 
        Case caseRecord = [SELECT Complaint_Handling_Level__c,Case_Owner_Business_Unit__c, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
        String handlingLevel = caseRecord.Complaint_Handling_Level__c;
        User getUser = [SELECT Business_Unit__c from User where Id =: caseRecord.OwnerId];
		    String bussinessUnit = getUser.Business_Unit__c;
        system.debug('handlingLevel'+ handlingLevel);
        system.debug('bussinessUnit'+ bussinessUnit);
        return [
            SELECT Id, Name 
            FROM User
            WHERE Handling_Level__c = :handlingLevel //and Business_Unit__c = :bussinessUnit
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getUserPermissionSets() {
        // Query the PermissionSetAssignment object to get the PermissionSet names for the logged-in user
        List<PermissionSetAssignment> psaList = [
            SELECT PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId()
        ];
        
        // Extract the permission set names
        List<String> permissionSetNames = new List<String>();
        for (PermissionSetAssignment psa : psaList) {
            permissionSetNames.add(psa.PermissionSet.Name);
        }
        return permissionSetNames;
    }

	
    
  }