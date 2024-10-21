public without sharing class OpportunityService {
    public static final String DEFAULT_OPP_STAGE = 'Pre-Application';
    
    public static final String APPLICATION_OPP_STAGE = 'Application';
    public static final String APPLICATION_MARS_STAGE = 'Processing';
    
    public static final String OPP_RT_CONSUMER = 'Consumer';
    public static final String OPP_RT_REFERRAL = 'Referred';
    
    public static final String LOST_OPP = 'Closed Lost';
    
    public static final String OPPORTUNITY_STATUS_PREAPPLICATION = 'Pre-Application';
    
    public static final String OPPORTUNITY_CHANNEL_MBD = Label.Lead_Channel_MrtgBrk;
    
    public static final String CONTACT_CHANNEL_BUSINESS = Label.Contact_Channel_Business;
    public static final String CONTACT_CHANNEL_INDIVIDUAL = Label.Contact_Channel_Individual;
    
    public static Boolean inhibitQuoteCallout = false;
    public static Boolean isLeadConversion = false;
    
    public static Map<String, String> contactPC = new Map<String, String>{
        ContactHandler.CONTACT_RT_BUSINESS => CONTACT_CHANNEL_BUSINESS,
            ContactHandler.CONTACT_RT_INDIVIDUAL => CONTACT_CHANNEL_INDIVIDUAL
            };
                
                public class OpportunityRequest {
                    @InvocableVariable(label='Opportunity' required=true)
                    public Opportunity opportunity;
                }
    
    @InvocableMethod(label='Send Opportunity to MARS')
    public static void sendOppotunitiesToMarsPlatformEventInvocable(
        List<OpportunityRequest> opportunityRequests
    ) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (OpportunityRequest opportunityRequest : opportunityRequests) {
            opportunities.add(opportunityRequest.opportunity);
        }
        OpportunityService.sendOpportunitiesToMarsPlatformEvent(opportunities);
    }
    public static Boolean sendOpportunitiesToMarsPlatformEvent(
        List<Opportunity> records
    ) {
        System.debug('sendApprovedOppToMarsPlatformEvent: start');
        
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        
        for (Opportunity opportunity : records) {
            // if (opportunity.StageName == 'Converted') {
            requests.add(
                new MARSPlatformEventService.Request(
                    opportunity,
                    'Ready for MARS',
                    MARSPlatformEventService.ACTION_UPDATE,
                    MARSPlatformEventService.MARS_READY_OPP
                )
            );
            // }
        }
        
        System.debug('requests? ' + requests);
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        System.debug('errorOccurred? ' + errorOccurred);
        
        //Update Opprtunity Stage to Converted after records are sent to MARS #4721
        if (!errorOccurred) {
            for (Opportunity opportunity : records) {
                opportunity.StageName = APPLICATION_OPP_STAGE;
                opportunity.Send_to_Mars_Clicked__c=true;
                opportunity.MARS_Validation_Run__c = true; // to allow setting to Converted since its already sent to MARS
            }
        }
        update records;
        
        return errorOccurred;
    }

    
   /* public static Boolean sendToMarsEventPublished = false;
    public void sendToMarsPlatformEvent(List<Opportunity> records) {
        System.debug('sendToMarsPlatformEvent: start');

        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Opportunity o : records){
            requests.add(
                new MARSPlatformEventService.Request(
                    o,
                    'Ready for MARS',
                    MARSPlatformEventService.ACTION_UPDATE,
                    MARSPlatformEventService.MARS_READY_OPP
                )
            );
            o.MARS_Stage__c = APPLICATION_MARS_STAGE;
        }
        System.debug('requests? ' + requests);
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        System.debug('errorOccurred? ' + errorOccurred);
        if(!errorOccurred){
            update records;
        }
        OpportunityService.sendToMarsEventPublished = !(errorOccurred);
    } DEPRECATED - BUG 9820*/
    
    /* HEB-531 Setting opportunity record type to lead record type */
    public void setRecordTypeCheck(List<Opportunity> records) {
        Map<String, Id> rtIds = Utils.getRecordTypeIdsBySObjectType(
            Opportunity.sObjectType
        );
        
        for (Opportunity o : records) {
            if (o.Record_Type_Name__c != null) {
                if (o.Record_Type_Name__c.contains('Consumer')) {
                    Id rtId = rtIds.get('Consumer');
                    o.RecordTypeId = rtId;
                } else if (o.Record_Type_Name__c.contains('Referred')) {
                    Id rtId = rtIds.get('Referred');
                    o.RecordTypeId = rtId;
                }
            }
        }
    }
    /* Switch the Complain Case link Lead to Opportunity when Lead is converted
*/
    
    //Method to assign proper File Queue, based on File values
    public void setFileQueue(List<Opportunity> records) {
        Boolean hasCustomPermissionCC = FeatureManagement.checkPermission('HEB_Call_Center_Member');
        if(hasCustomPermissionCC ){ 
            for (Opportunity opp : records){           
                opp.File_Queue__c = 'Inbound In-Progress'; 
            } 
        }
    }
    
    public void switchCaseLink2Opportuinty(List<Opportunity> records) {
        Map<String, Opportunity> oMap = new Map<String, Opportunity>();
        for (Opportunity o : records) {
            if (o.File_Number__c != null) {
                oMap.put(o.File_Number__c + '', o);
            }
        }
        
        List<Case> lc = [
            SELECT Id, File_Number__c, //Lead_File__c,
            Opportunity_File__c, MARS_File__c
            FROM Case
            WHERE File_Number__c IN :oMap.keySet()
        ];
        system.debug('!!! - Number of related Cases = ' + lc.size());
        
        if (lc.size() > 0) {
            for (Case c : lc) {
                c.Opportunity_File__c = oMap.get(c.File_Number__c).Id;
                //c.Lead_File__c = null;
            }
            system.debug('!!! - Qualitfied Cases ' + lc.size());
            update lc;
        }
    }
    
   /* public void updateRollups() {
        if (!Test.isRunningTest()) { dlrs.RollupService.triggerHandler(Opportunity.SObjectType); }
    }*/
    
    /*
* HEB-: Updates the Name on File when the  File Number gets updated
*/
    public void UpdateOpportunityNameWithFileNumber(
        List<Opportunity> records,
        Map<ID, Opportunity> oldRecords
    ) {
        List<Opportunity> opportunityIds = new List<Opportunity>(); 
        Map<Id, Account> accountMap = new Map<Id, Account>(); 
        Set<Id> accountIdSet = new Set<Id>(); 
        
        if(oldRecords != null){
            Set<String> fieldsToCheck = new Set<String>{ 'File_Number__c' , 'AccountId', 'Name'};
                opportunityIds = (List<Opportunity>) Utils.getChangedObjects(
                    records,
                    oldRecords,
                    fieldsToCheck
                );
            for (Opportunity opp : opportunityIds) {
                accountIdSet.add(opp.AccountId);
            }
            if(!accountIdSet.isEmpty()) {
             	accountMap = new Map<Id, Account>([Select Id, LastName from Account where Id in :accountIdSet]);   
            }            
            // Update the Opportunity name with Account's last name and File_Number__c field
        } else {
            opportunityIds = records;
            for (Opportunity opp : opportunityIds) {
                accountIdSet.add(opp.AccountId); 
            }
            if(!accountIdSet.isEmpty()) {
            	accountMap = new Map<Id, Account>([Select Id, LastName from Account where Id in :accountIdSet]);
            }
        }
        
        for (Opportunity opp : opportunityIds) {
            if(opp.AccountId != null || opp.File_Number__c != null){
                opp.Name =
                    'OP' +
                    (accountMap.get(opp.AccountId) != null ? ' - ' +accountMap.get(opp.AccountId).LastName : '') +
                    (opp.File_Number__c != null ? ' - ' +opp.File_Number__c : ''); 
            }
        } 
    }
    /*
* HEB-: set residential loan application Name
*/
public void UpdateApplicationNameWithFileNumber(
    List<Opportunity> records,
    Map<ID, Opportunity> oldRecords
) {
    List<Opportunity> opportunityIds = new List<Opportunity>(); 
    
    if(oldRecords != null){
        Set<String> fieldsToCheck = new Set<String>{ 'File_Number__c'};
            opportunityIds = (List<Opportunity>) Utils.getChangedObjects(
                records,
                oldRecords,
                fieldsToCheck
            );
    }
       
    if (!opportunityIds.isEmpty()) {
        List<ResidentialLoanApplication> applicationsToUpdate = new List<ResidentialLoanApplication>();
        Map<Id, String> oppNameMap = new Map<Id, String>();
        for (Opportunity opp : opportunityIds) {
            oppNameMap.put(opp.Id, opp.Name);
        }

        if(!oppNameMap.isEmpty()){
            applicationsToUpdate = [SELECT id,OpportunityId,Name FROM ResidentialLoanApplication WHERE opportunityId IN :oppNameMap.keySet()];
            for (ResidentialLoanApplication app : applicationsToUpdate) {
                String name = oppNameMap.get(app.opportunityID).replace('OP','LA');
                app.Name = app.Name!=name?name:app.Name;
            }
            update applicationsToUpdate;
        }
    }

}

    
    
    /*
* HEB-284: Platform Event for Snail Mail update to Opportunity
*/
    public static Boolean snailMailEventPublished = false;
    public static void snailMailPlatformEvent(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        Map<Id, Opportunity> mailLeads = new Map<Id, Opportunity>();
        Set<Id> accountIdSet = new Set<Id>();
        List<Task> newTasks = new List<Task>();
        for (Opportunity l : records) {
            if (l.Send_Mail_Communcation__c == true) {
                if ( !Utils.allowBypassForUser() && l.Mail_Communication_Type__c == 'EST' &&  !l.CHIP_Qualified__c ) {
                    l.addError('The file must have a valid quote to send an EST letter');
                } else if (  !Utils.allowBypassForUser() && l.Mail_Communication_Type__c == 'MAX EST' && !l.CHIP_Max_Qualified__c ) {
                    l.addError( 'The file must have a valid CHIP Max quote to send a MAX EST letter' );
                } else {
                    l.Send_Mail_Communcation__c = false; // unset this flag for subsequent communications
                    mailLeads.put(l.Id, l);
                    accountIdSet.add(l.AccountId);
                }
            }
        }
        if (mailLeads.isEmpty())
            return;
        Map<String, String> contactIdMap = new Map<String, String>();
        if(!accountIdSet.isEmpty()) {
        	for (Contact c : [ SELECT id, AccountId FROM contact WHERE accountId IN :accountIdSet ]) {
            	contactIdMap.put(c.AccountId, c.id);
        	}
        }
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        for (Opportunity l : mailLeads.values()) {
            String contactId;
            if (contactIdMap.containsKey(l.accountId)) {
                contactId = contactIdMap.get(l.accountId);
            }
            requests.add(  new MARSPlatformEventService.Request(  l, l.Mail_Communication_Type__c,  MARSPlatformEventService.ACTION_UPDATE, MARSPlatformEventService.SNAIL_MAIL_ACTION  )  );
            newTasks.add(  new Task(  Subject = Label.Lead_Mail_Comm_Request + ' (' +  l.Mail_Communication_Type__c + ')',  WhoId = contactId, WhatId = l.Id,  Status = 'Completed',  Priority = 'Normal', Description = Label.Lead_Mail_Comm_Summary ) );
        }
        
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        OpportunityService.snailMailEventPublished = !(errorOccurred);
        try {  insert newTasks; }
        catch (DmlException e) {  System.debug(e.getMessage()); }
    }
    
    //#4721 updates
    
    public void setReadyToMars(
        List<Opportunity> records,
        Map<Id, Opportunity> oldMap
    ) {
        for (Opportunity oppRecord : records) {
            Opportunity oldRecord = oldMap.get(oppRecord.Id);
            
            if ( (oppRecord.File_Validation_Error__c != oldRecord.File_Validation_Error__c || oppRecord.StageName != oppRecord.StageName) &&  !oppRecord.File_Validation_Error__c && oppRecord.StageName != APPLICATION_OPP_STAGE && oppRecord.StageName != 'Closed Lost' && !oppRecord.Ready_for_MARS__c ) {
                oppRecord.Ready_for_MARS__c = true;
            }
        }
    }
    
    /////////
    //#6446
    /////////
    
    /*
HEB-561: Update the Owner on Related records
*/
    public static void mapRelatedRecordsOwnership(List<Opportunity> newOpps,
                                                  Map<Id, Opportunity> oldRecords) {
                                                      //check if file owner has changed
                                                      Set<String> fieldsToCheck = new Set<String>{ 'OwnerId' }; 
                                                          List<Opportunity> changedOpps = (List<Opportunity>) Utils.getChangedObjects(
                                                              newOpps,
                                                              oldRecords,
                                                              fieldsToCheck
                                                          );
                                                      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
                                                      for (Opportunity opp : changedOpps){
                                                          oppMap.put(opp.Id, opp);
                                                      }
                                                      
                                                      if (oppMap.isEmpty()){
                                                          return;
                                                      }
                                                      
                                                      OpportunityOwnershipService.processRelatedRecordsOwnership(oppMap,true);
                                                  }
    
    /*
* HEB-878: re-fire ownership assignment if it fails
*/
    @future
    public static void retryRelatedRecordsOwership(List<Id> oppIds) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId 
                                                                FROM Opportunity WHERE Id IN :oppIds]);
        OpportunityOwnershipService.processRelatedRecordsOwnership(oppMap);
    }
    
    public void checkRequote(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        // do not run for Integration user; MARS will update the flag directly when all related records complete
        if (Utils.isIntegrationUser())
            return;
        
        Set<String> fieldsToCheck = Utils.getFieldSetFields(
            Schema.SObjectType.Opportunity.fieldSets.Influences_Quote.getFields()
        );
        List<Opportunity> opportunities = (List<Opportunity>) Utils.getChangedObjects(
            records,
            oldRecords,
            fieldsToCheck
        );
        
        for (Opportunity opportunity : opportunities) {
            opportunity.Quote_Parameters_Updated__c = true;
        }
    }
    
    @future(callout=true)
    public static void setRequote(Set<Id> oppIDs) {
        // do not run for Integration user; MARS will update the flag directly when all related records complete
        if (Utils.isIntegrationUser() && !Test.isRunningTest())
            return;
        
        List<Opportunity> opportunities = [ SELECT Id, Quote_Parameters_Updated__c FROM Opportunity WHERE Id IN :oppIDs ];
        
        for (Opportunity opportunity : opportunities) {
            opportunity.Quote_Parameters_Updated__c = true;
        }
        
        update opportunities;
    }
    
    /** HEB-367 When Opp details are updated a new quote is requested */
    public void updateQuote(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        if (System.isBatch())
            return;
        
        if (
            FeatureManagement.checkPermission(
                Utils.CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD
            )
        )
            return;
        
        //Return early if this is a mass update
        if (records.size() > 1)
            return;
        
        // Prevents future recursion
        if (system.isFuture())
            return;
        
        //validate if quote request must be skipped
        if(QuoteRequestManager.doSkipQuoteService()){
            return;
        }
        
        //Check if quote paramters are updated
        Opportunity updatedOpp = records[0];
        
        // If updated get a new quote
        if ( updatedOpp.Quote_Parameters_Updated__c && !Test.isRunningTest() && !inhibitQuoteCallout ) {
            system.debug('testing the future callout');
            QuoteRequestValidationController.getQuoteForTrigger(updatedOpp.Id);
        }
    }
    
    /*
* HEB-14: Create Campaign Influence record for New Opportunity
*/
    public void createCampaignInfluenceRecords(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        Map<Id, Id> oppContactMap = new Map<Id, Id>();
        for (Opportunity o : records) {
            if (o.Account.PersonContactId != null) {
                oppContactMap.put(o.id, o.Account.PersonContactId);
            }
        }
        System.debug(
            'createCampaignInfluenceRecords: oppContactMap = ' + oppContactMap
        );
        
        // if no opprtunities, no action
        if (oppContactMap.isEmpty())
            return;
        
        /*
* Get relevant Campaigns to the converted lead(s)
*/
        Map<Id, List<CampaignMember>> contactCampaignMembers = new Map<Id, List<CampaignMember>>();
        for (CampaignMember cm : [ SELECT Id, CampaignId, ContactId FROM CampaignMember WHERE ContactId IN :oppContactMap.values()  ]) {
            List<CampaignMember> tmpList = contactCampaignMembers.get(cm.ContactId) <> null ? contactCampaignMembers.get(cm.ContactId) : new List<CampaignMember>();
            tmpList.add(cm);
            contactCampaignMembers.put(cm.ContactId, tmpList);
        }
        System.debug(
            'createCampaignInfluenceRecords: contactCampaignMembers = ' +
            contactCampaignMembers
        );
        
        // if no campaign members, no action
        if (contactCampaignMembers.isEmpty())
            return;
        
        List<CampaignInfluenceModel> influenceModelList = [ SELECT Id FROM CampaignInfluenceModel WHERE IsDefaultModel = TRUE  ];
        
        // if no influence models, no action.
        if (influenceModelList.isEmpty())
            return;
        
        List<CampaignInfluence> influenceList = new List<CampaignInfluence>();
        for (Id opportunityId : oppContactMap.keySet()) {
            for (  CampaignMember cm : contactCampaignMembers.get( oppContactMap.get(opportunityId)  ) ) {
                Double influenceShare = 100 / contactCampaignMembers.get(oppContactMap.get(opportunityId)).size();
                influenceList.add( new CampaignInfluence( CampaignId = cm.CampaignId, ContactId = oppContactMap.get(opportunityId), Influence = influenceShare, ModelId = influenceModelList[0].Id, OpportunityId = opportunityId )  );
            }
        }
        System.debug(
            'createCampaignInfluenceRecords: influenceList = ' + influenceList
        );
        
        try { insert influenceList;
             System.debug(
                 'createCampaignInfluenceRecords: influenceList = ' + influenceList
             );
            } catch (DmlException e) { }
    }
    
    /*
* Map the contact recordtype to the territory channel type.
*/
    public static String getContactPC(Id recordTypeID) {
        Map<String, ID> rtIDs = Utils.getRecordTypeIdsBySObjectType(
            Contact.sObjectType
        );
        Map<ID, String> RTs = Utils.invertMapping(rtIDs);
        
        String RT = RTs.get(recordTypeID);
        return contactPC.get(RT);
    }
    
    /*
* HEB-223: File Validation prior to Commitment Letter
* - ensure the Lead and Credit Report are all in good standing before finalizing commitment letter.
*/
    public void fileValidationPriorToCommitmentLetter(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        List<Opportunity> validateFiles = new List<Opportunity>();
        for (Opportunity ld : records) { 
            if (
                ld.Commitment_Letter_Decision_Date__c == null &&  (ld.Commitment_Letter_Decision__c <> null ||  (ld.Commitment_Letter_Decision__c == null &&  oldRecords.get(ld.Id).Commitment_Letter_Decision__c <> null) || ld.Commitment_Letter_Validation_Message__c <> null)
            ) {
                validateFiles.add(ld);
            }
        }
        
        if (validateFiles.isEmpty())
            return;
        
        //if (!PartnerEstimateLetterService.generateCommitmentLetterEventPublished)
        PartnerEstimateLetterService.validateForCommitmentLetter(
            validateFiles,
            PartnerEstimateLetterService.Mode.Record_State
        );
    }

    /*BUG:9508*/
    public void refreshProductError(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        new LoanApplicantService().additionalFileValidation(records);
    }
    
    /*
* Assumption: Opps are never closed lost in bulk.
* If this is not the case, then the appraisal cancellations will need to be handled in batch.
*/
    public void cancelAppraisals(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        // Defect 75671 - Closed Lost Opps do not need to be Cancelled.
        
        Set<Id> closedLostOpps = new Set<Id>();
        List<Appraisal_Order__c> aos = new List<Appraisal_Order__c>();
        for (Opportunity o : records) {
            // Opp is now closed lost.
            if (  o.StageName == LOST_OPP &&  o.StageName <> oldRecords.get(o.Id).StageName ) {
                closedLostOpps.add(o.Id);
            }
        }
        if(closedLostOpps.isEmpty()) { 
            return;
        }
         aos = [
            SELECT
            Id,
            Cancellation_Reason__c,
            Reference_ID__c,
            (
                SELECT id, status__c
                FROM Appraisal_Status__r
                WHERE Is_Current__c = 'Yes'
            )
            FROM Appraisal_Order__c
            WHERE
            Appraisal__r.Application__r.OpportunityId IN :closedLostOpps
            AND Cancellation_Reason__c = NULL
        ];
        
        for (Appraisal_Order__c ao : aos) {
            Boolean isAppraisalRequested = false;
            
            if (ao.Appraisal_Status__r.size() > 0) {
                if (  ao.Appraisal_Status__r[0].status__c == 'Report Pending' || ao.Appraisal_Status__r[0].status__c == 'Completed' ) {
                    isAppraisalRequested = true;
                }
            }
            
            if (!isAppraisalRequested) {
                ao.Cancellation_Reason__c = AppraisalCancelOrderService.CANCEL_REASON_FILE_CLOSED_LOST;
            }
        }
        update aos;
        
        for (Appraisal_Order__c ao : aos) {
            if (  ao.Reference_ID__c != null && ao.Cancellation_Reason__c ==  AppraisalCancelOrderService.CANCEL_REASON_FILE_CLOSED_LOST  ) {
                AppraisalOrderController.cancelAppraisalOrderPostClosedLost(ao.Id);
            }
        }
    }
    
    /*
* HEB-405: File Valdiation prior to Launch to MARS
* HEB-443: File Validation moved from Opportunity to Lead
* - ensure the Lead and related records (Property, Property Member, Quote) are all in good standing before trying to integrate w/ MARS
*/
    public void fileValidationPriorToMARS(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        Map<Id, Opportunity> marsFiles = new Map<Id, Opportunity>();
        
        // get relevant records; return if none
        for (Opportunity l : records) {
            if (
                l.StageName == OPPORTUNITY_STATUS_PREAPPLICATION ||
                l.Missing_MARS_Validation_Message__c <> null ||
                l.Commitment_Letter_Validation_Message__c <> null
            ) {
                marsFiles.put(l.Id, l);
            }
        }
        if (marsFiles.isEmpty())
            return;
        
        Set<String> oppFields = Utils.getFieldSetFields(
            Schema.SObjectType.Opportunity.fieldSets.File_Validation.getFields()
        );
        Set<String> appFields = Utils.getFieldSetFields(
            Schema.SObjectType.ResidentialLoanApplication.fieldSets.File_Validation.getFields()
        );
        Set<String> propertyFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicationProperty.fieldSets.File_Validation.getFields()
        );
        Set<String> propertyMemberFields = Utils.getFieldSetFields(
            Schema.SObjectType.Contact.fieldSets.File_Validation_Borrowers.getFields()
        );
        Set<String> propertyMemberConsent = Utils.getFieldSetFields(
            Schema.SObjectType.Account.fieldSets.File_Validation_Consent.getFields()
        );
        Set<String> propertyMemberAMLOccupationFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_Occupation.getFields()
        );
        
        Set<String> propertyMemberAMLUnempOtherFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_Unemployed_Other.getFields()
        );
        Set<String> propertyMemberAMLUnempHomemakerFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_Unemployed_Homemaker.getFields()
        );
        Set<String> propertyMemberAMLUnempNoPrevFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_Unemployed_No_Prev.getFields()
        );
        Set<String> propertyMemberAMLRetiredOtherFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_Retired_Other.getFields()
        );
        Set<String> propertyMemberAMLAllOtherFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_All_Other.getFields()
        );
        Set<String> propertyMemberAMLFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML.getFields()
        );
        Set<String> employmentFields = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation.getFields()
        );
        Set<String> employmentFieldsAll = Utils.getFieldSetFields(
            Schema.SObjectType.LoanApplicantEmployment.fieldSets.File_Validation_AML_All.getFields()
        );
        
        Map<String, Schema.SObjectField> accFieldMap = Utils.getFieldMap(
            'Account'
        );
        Map<String, Schema.SObjectField> oppFieldMap = Utils.getFieldMap(
            'Opportunity'
        );
        Map<String, Schema.SObjectField> appFieldMap = Utils.getFieldMap(
            'ResidentialLoanApplication'
        );
        Map<String, Schema.SObjectField> propertyFieldMap = Utils.getFieldMap(
            'LoanApplicationProperty'
        );
        Map<String, Schema.SObjectField> propertyMemberFieldMap = Utils.getFieldMap(
            'Contact'
        );
        Map<String, Schema.SObjectField> employmentFieldMap = Utils.getFieldMap(
            'LoanApplicantEmployment'
        );
        Map<String, Schema.SObjectField> applicantFieldMap = Utils.getFieldMap(
            'LoanApplicant'
        );
        // Aux required due to as Schema.SObjectType fields.getMap() doesn't include parent records
        Map<String, Schema.SObjectField> auxMap = new Map<String, Schema.SObjectField>();
        for(String key : employmentFieldMap.keySet()) {
            auxMap.put(key, employmentFieldMap.get(key));
        } 
        auxMap.put('loanapplicant.pep__c', applicantFieldMap.get('PEP__c'));
        auxMap.put('loanapplicant.age__c', applicantFieldMap.get('Age__c'));
        
        String oppIds = String.join(
            (Iterable<String>) marsFiles.keySet(),
            '\', \''
        );
        
        List<Id> applicationIds = new List<Id>();
        Map<Id, ResidentialLoanApplication> applicationMap = new Map<Id, ResidentialLoanApplication>();
        // Get more recent Application from each Opportunity
        for (Opportunity opportunity : [
            SELECT
            Id,
            (
                SELECT Id, Appraisal_Option__c
                FROM Lending_Applications
                ORDER BY CreatedDate
                LIMIT 1
            )
            FROM Opportunity
            WHERE Id IN :marsFiles.keySet()
        ]) {
            if (opportunity.Lending_Applications.size() > 0) {
                applicationIds.add(opportunity.Lending_Applications[0].Id);
                applicationMap.put(opportunity.Id, opportunity.Lending_Applications[0]);
            }
        }
        
        String applicationIdsString = String.join(
            (Iterable<String>) applicationIds,
            '\', \''
        );
        String propertyFieldsQuery = '';
        for (String s : propertyFields) {
            propertyFieldsQuery += (propertyFieldsQuery == '') ? s : ', ' + s;
        }
        // Get Properties from each Application
        String propertiesQuery =
            'SELECT Id, LoanApplicationId, LoanApplication.OpportunityId, LoanApplication.Loan_Purpose__c, Loan_Purpose__c, Valid_FSA__c, ' +
            propertyFieldsQuery +
            ' FROM LoanApplicationProperty  ' +
            ' WHERE LoanApplicationId IN (\'' +
            applicationIdsString +
            '\')';
        System.debug('propertiesQuery = ' + propertiesQuery);
        Map<Id, ResidentialLoanApplication> applicationRelatedMap = new Map<Id, ResidentialLoanApplication>();
        Map<Id, LoanApplicationProperty> propertyRelatedMap = new Map<Id, LoanApplicationProperty>();
        for (LoanApplicationProperty property : Database.query(propertiesQuery)) {
            propertyRelatedMap.put(property.LoanApplication.OpportunityId, property);
            applicationRelatedMap.put(property.LoanApplication.OpportunityId, property.LoanApplication);
        }
        
        String propertyMemberFieldsQuery = 'Contact.Account.Name, ContactId, Contact.Name, Contact.Email, Use_For_Quote__c, Contact.FinServ__Age__c, On_Title__c';
        for (String s : propertyMemberFields) {
            propertyMemberFieldsQuery += (propertyMemberFieldsQuery == '')
                ? 'Contact.' + s
                : ', Contact.' + s;
        }
        for (String s : propertyMemberConsent) {
            propertyMemberFieldsQuery += (propertyMemberFieldsQuery == '')
                ? 'Contact.Account.' + s
                : ', Contact.Account.' + s;
        }        
        String employmentFieldsQuery = '';
        for (String s : employmentFieldsAll) {
            employmentFieldsQuery += (employmentFieldsQuery == '') ? s : ', ' + s;
        }
        // Get Applicants from each Application
        String applicantQuery =
            'SELECT Id, LoanApplication.OpportunityId, Account_Id__c, Role__c, ' +
            '(SELECT Id, EmployerAddress, EmployerCountry, EmployerState, EmployerCity, EmployerPostalCode, EmployerStreet, ' + employmentFieldsQuery + ' FROM LoanApplicantEmployments ORDER BY Employment_Status__c ASC, StartDate DESC), ' +
            propertyMemberFieldsQuery +
            ' FROM LoanApplicant  ' +
            ' WHERE LoanApplicationId IN (\'' +
            applicationIdsString +
            '\')';
        System.debug('applicantQuery = ' + applicantQuery);
        Set<Id> applicantContactIds = new Set<Id>();
        Map<Id, List<LoanApplicant>> applicantRelatedMap = new Map<Id, List<LoanApplicant>>();
        for (LoanApplicant applicant : Database.query(applicantQuery)) {
            applicantContactIds.add(applicant.ContactId);
            if (
                !applicantRelatedMap.containsKey(
                    applicant.LoanApplication.OpportunityId
                )
            ) {
                applicantRelatedMap.put(
                    applicant.LoanApplication.OpportunityId,
                    new List<LoanApplicant>{ applicant }
                );
            } else {
                applicantRelatedMap.get(applicant.LoanApplication.OpportunityId)
                    .add(applicant);
            }
        }
        
        // Query Account Contact Relation records from Applicant to get their roles
        Map<String, AccountContactRelation> accountContactRelation = new Map<String, AccountContactRelation>();
        for (AccountContactRelation relation : [
            SELECT AccountId, ContactId, Roles
            FROM AccountContactRelation
            WHERE ContactId IN :applicantContactIds ]) {
                String key = relation.AccountId + '|' + relation.ContactId;
                accountContactRelation.put(key, relation);
            }
        
        // Get Credit Assessment from each Application
        String assessmentsQuery =
            'SELECT Id, OpportunityId, (SELECT Id, Application__r.OpportunityId, Credit_Assessment_Required__c, Credit_Assessment_Successful__c FROM Credit_Assessments__r ORDER BY CreatedDate DESC LIMIT 1)' +
            ' FROM ResidentialLoanApplication ' +
            ' WHERE Id IN (\'' +
            applicationIdsString +
            '\')';
        System.debug('assessmentsQuery = ' + assessmentsQuery);
        Map<Id, List<Credit_Assessment__c>> assessmentRelatedMap = new Map<Id, List<Credit_Assessment__c>>();
        for (ResidentialLoanApplication application : Database.query(assessmentsQuery)) {
            if (application.Credit_Assessments__r != null && !application.Credit_Assessments__r.isEmpty())
            {
                if ( !assessmentRelatedMap.containsKey( application.OpportunityId ) ) {
                    assessmentRelatedMap.put(  application.OpportunityId,  new List<Credit_Assessment__c>{ application.Credit_Assessments__r[0] }  );
                } else {
                    assessmentRelatedMap.get(application.OpportunityId) .add(application.Credit_Assessments__r[0]);
                }
            }
        }
        
        String oppFieldString = 'Id, SyncedQuote.Is_Eligible__c, Account.Campaign_Member_Count__pc, RecordType.DeveloperName, Blanket_Mortgage_File__c';
        
        String eventQuery =
            ' (SELECT Id FROM Events WHERE Type_of_Meeting__c IN (\'' +
            EventService.INITIAL_CONTACT_MEETING +
            '\', \'' +
            EventService.INITIAL_CONTACT_FOLLOWUP +
            '\') AND Dispositioned__c = true) ';
        /*
* Let's grab the relevant records - we will grab all, rather than piecemeal, to return as robust an error to the end user as possible
*/
        String oppQuery =
            'SELECT ' +
            oppFieldString +
            ', ' +
            eventQuery +
            ' FROM Opportunity WHERE Id IN (\'' +
            oppIds +
            '\')';
        //System.debug('oppQuery = ' + oppQuery);
        List<Opportunity> opp1=[Select Id, Channel__c, SyncedQuote.Is_Eligible__c, Account.Campaign_Member_Count__pc, RecordType.DeveloperName, Blanket_Mortgage_File__c,(SELECT Id,Type_of_Meeting__c from Events where Type_of_Meeting__c in('Initial Contact','Initial Contact Follow-up')) FROM Opportunity WHERE Id IN :marsFiles.keySet()];
        Map<Id, Opportunity> oppRelatedMap = new Map<Id, Opportunity>();
        for (Opportunity l : opp1) {
            oppRelatedMap.put(l.Id, l);
        }
        
        //get campaing influence records related to files to validate
        Set<Id> filesWithCampaign = new Set<Id>();
        for(CampaignInfluence ci : [SELECT Id,OpportunityId 
                                    FROM CampaignInfluence 
                                    WHERE OpportunityId IN :marsFiles.keySet()]){
                                        filesWithCampaign.add(ci.OpportunityId);
                                    }
        
        for (Opportunity l : marsFiles.values()) {
            system.debug(oppRelatedMap.get(l.Id));
            List<String> oppErrors = new List<String>();
            
            List<String> missingLeadFields = Utils.missingFields(
                oppFields,
                oppFieldMap,
                l
            );
            if (!missingLeadFields.isEmpty())
                oppErrors.add(
                    Label.Error_Opportunity_File_Field +
                    ': ' +
                    String.join(missingLeadFields, ', ')
                );
            
            List<String> missingAppFields = Utils.missingFields(
                appFields,
                appFieldMap,
                applicationRelatedMap.get(l.Id) ?? new ResidentialLoanApplication() 
            );
            if (!missingAppFields.isEmpty())
                oppErrors.add(
                    Label.Error_Opportunity_File_Field +
                    ': ' +
                    String.join(missingAppFields, ', ')
                );
            
            // check the key fields on the Property record are complete
            List<String> missingPropertyFields = new List<String>();
            if (!propertyRelatedMap.containsKey(l.Id)) {
                oppErrors.add(Label.Error_File_No_Property);
            } else {
                for (String s : propertyFields) {
                    if (
                        propertyRelatedMap.get(l.Id).get(s) == null ||
                        propertyRelatedMap.get(l.Id).get(s) == ''
                    ) {
                        missingPropertyFields.add(
                            propertyFieldMap.get(s).getDescribe().getLabel()
                        );
                    }
                }
                
                if (
                    propertyRelatedMap.get(l.Id).Property_Type__c == 'Mobile Home' &&  propertyRelatedMap.get(l.Id).Fixed_To_Ground__c != Utils.AFFIRMATIVE
                ) {
                    oppErrors.add(Label.Error_File_Validation_Mobile_Home);
                }
                
                if (!propertyRelatedMap.get(l.Id).Valid_FSA__c) {
                    oppErrors.add(Label.Error_FileValidation_PropertyFSA);
                }
            }
            
            if (!missingPropertyFields.isEmpty())
                oppErrors.add(
                    Label.Error_Property_Field +
                    ': ' +
                    String.join(missingPropertyFields, ', ')
                );
            // end Property check
            
            // Start Property Member check
            if (!applicantRelatedMap.containsKey(l.Id)) {
                oppErrors.add(Label.Error_File_Validation_Borrower_Exists);
            }
            
            Boolean onTitleMissing = true;
            Boolean activePOA = false;
            Boolean activeGuarantor = false;
            // check that the key fields for the Borrower are complete, along with the AML fields
            if (applicantRelatedMap.containsKey(l.Id)) {
                for (LoanApplicant pm : applicantRelatedMap.get(l.Id)) {
                    String applicantKey = pm.Account_Id__c + '|' + pm.ContactId;
                    if (
                        accountContactRelation.get(applicantKey)?.Roles <> null && accountContactRelation.get(applicantKey) .Roles.contains(PropertyMemberService.POA_ROLE)
                    )
                        activePOA = true;
                    if (
                        accountContactRelation.get(applicantKey)?.Roles <> null && accountContactRelation.get(applicantKey).Role__c.contains(PropertyMemberService.GUARANTOR_ROLE)
                    )
                        activeGuarantor = true;
                    
                    if (pm.Use_For_Quote__c && pm.Contact!=null) {
                        List<String> missingPropertyMemberFields = Utils.missingFields(
                            propertyMemberFields,
                            propertyMemberFieldMap,
                            pm.Contact
                        );
                        if (!missingPropertyMemberFields.isEmpty())
                            oppErrors.add(
                                Label.Error_Property_Member_Borrower_Field +
                                ': ' +
                                String.join(missingPropertyMemberFields, ', ')
                            );
                        
                        if (pm?.Contact?.AccountId <> null) {
                            List<String> missingPropertyMemberConsentFields = Utils.missingFields( propertyMemberConsent, accFieldMap, pm.Contact.Account  );
                            if (!missingPropertyMemberConsentFields.isEmpty())
                                oppErrors.add( Label.Error_Property_Member_Borrower_Field +  ' (' +  pm.Contact.Name +  '): ' + String.join(missingPropertyMemberConsentFields, ', ') );
                        }
                        
                        if (
                            pm.Role__c != null && 
                            pm.Role__c.contains('Borrower')
                        ) {
                            if(pm.LoanApplicantEmployments == null || (pm.LoanApplicantEmployments != null && pm.LoanApplicantEmployments.size() == 0)) {
                                oppErrors.add(
                                    Label.Error_Property_Member_Occupation +
                                    ' ' +
                                    pm.Contact.Name +
                                    ' '
                                );
                            } else if(pm?.Contact?.FinServ__Age__c < 70 || pm?.Contact?.FinServ__Age__c == null){
                                List<String> missingEmploymentFields = new List<String>();
                                Boolean isUnemployed = false;
                                Boolean isNeverEmployed = false;
                                Boolean hasPreviousOccupation = false;
                                Boolean showWarningMessage = true;
                                for(LoanApplicantEmployment employment : pm.LoanApplicantEmployments) {
                                    if(employment.Employment_Status__c == 'Current'){
                                        missingEmploymentFields.addAll(Utils.missingFields(
                                            employmentFields,
                                            employmentFieldMap,
                                            employment
                                        ));
                                        if(employment.Occupation__c == 'Unemployed' || employment.Occupation__c == 'Retired') {
                                            isUnemployed = true;
                                        }
                                        if(employment.Occupation__c == 'Never Employed' || employment.Occupation__c == 'Homemaker') {
                                            isNeverEmployed = true;
                                        }
                                    } else if(employment.Employment_Status__c == 'Previous') {
                                        //Don't show warning message for certain occupations (combination of previous and current)
                                        if(isUnemployed && employment.Occupation__c == 'Homemaker') {
                                            showWarningMessage = false;                                            
                                        }
                                    }
                                    if(employment.Occupation__c != 'Unemployed' && employment.Occupation__c != 'Retired') {
                                        hasPreviousOccupation = true;
                                    }
                                    if(employment.EmployerAddress == null) {
                                        missingEmploymentFields.add(employmentFieldMap.get('EmployerAddress').getDescribe().getLabel());
                                    }
                                }
                                
                                if(isUnemployed && !hasPreviousOccupation) {
                                    missingEmploymentFields.add('Previous Occupation');
                                }
                                if (!missingEmploymentFields.isEmpty() && showWarningMessage && !isNeverEmployed)
                                    oppErrors.add( Label.Error_Property_Member_AML_Field + ' (' +  pm.Contact.Name +  '): ' + String.join(missingEmploymentFields, ', ') );
                            }
                        }
                        
                        if (pm.On_Title__c)
                            onTitleMissing = false;
                    }
                }
            }
            
            if (onTitleMissing) {
                oppErrors.add(Label.Error_File_Validation_OnTitle);
            }
            // check if the Credit Assessment is required - If is Blanket Mortgage or Property Member is POA / Guarantor, it does not need Credit Assessment.
            if (
                activePOA == true ||
                activeGuarantor == true ||
                l.Blanket_Mortgage_File__c == true
            ) {
                l.Credit_Assessment_Required__c = false;
            } else {
                l.Credit_Assessment_Required__c = true;
            }
            System.debug( 
                '!!!!- Credit_Assessmemt-required =' + l.Credit_Assessment_Required__c
            );
            
            // check if the Credit Assessment is successful
            if( !activePOA && !activeGuarantor){
                if (assessmentRelatedMap.containsKey(l.Id)) {
                    for ( Credit_Assessment__c assessment : assessmentRelatedMap.get(l.Id)  ) {
                        // check that the Credit Assessment has been run; not required for POA
                        if ( l.Credit_Assessment_Required__c == true && assessment.Credit_Assessment_Successful__c == false ) {
                            oppErrors.add(Label.Error_File_Validation_CreditAssessment);
                            break;
                        }
                    }                
                } else { // If not Credit Assessment created
                    oppErrors.add(Label.Error_File_Validation_CreditAssessment);
                }
            }
            
            // End Property Member Check
            if (applicationMap.containsKey(l.Id)) {
                // check that an Appraisal has been ordered or flagged to order later
                if (String.isBlank(applicationMap.get(l.Id).Appraisal_Option__c)) {
                    oppErrors.add(Label.Error_File_Validation_Appraisal);
                }
                
                // the Active Quote must be flagged as Eligible
                if (
                    oppRelatedMap.get(l.Id).SyncedQuoteId != null && !oppRelatedMap.get(l.Id).SyncedQuote.Is_Eligible__c
                ) {
                    oppErrors.add(Label.Error_File_Validation_ActiveQuote);
                }
                
                //Joel Ojeda - 08/29/24 - Bug 8832
                //Capaing validation must be on the file level
                //each file must be related to at least one campaign AKA ( 1 Campaign Influence Record)
                /*
// must have at least one Campaign Member record
if (
oppRelatedMap.get(l.Id)?.Account?.Campaign_Member_Count__pc == null ||  oppRelatedMap.get(l.Id).Account.Campaign_Member_Count__pc == 0
) {
oppErrors.add(Label.Error_Lead_MissingCampaign);
}
*/
                
                if (OPP_RT_CONSUMER.equalsIgnoreCase(oppRelatedMap.get(l.Id).Channel__c) && oppRelatedMap.get(l.Id).Events.size() == 0) {
                    oppErrors.add(Label.Error_Consumer_Missing_InitialContact);
                }
            } else {
                oppErrors.add(Label.Error_Opportunity_File_Field);
            }
            
            //Joel Ojeda - 08/29/24 - Bug 8832
            //Capaing validation must be on the file level
            //each file must be related to at least one campaign AKA ( 1 Campaign Influence Record)
            if(!filesWithCampaign.contains(l.Id)){
                oppErrors.add(Label.Error_Lead_MissingCampaign);
            }
            
            if (!oppErrors.isEmpty()) {
                l.File_Validation_Error__c = true;
                l.Missing_MARS_Validation_Message__c =
                    '<ul><li>' +
                    String.join(oppErrors, '</li><li>') +
                    '</li></ul><br>';
            } else {
                l.File_Validation_Error__c = false;
                l.Missing_MARS_Validation_Message__c = null;
            }
            l.MARS_Validation_Run__c = true;
        }
    }
    
    /*
* HEB-405: File Valdiation prior to Launch to MARS
* HEB-443: File Validation moved from Opportunity to Lead
* - ensure the Lead and related records (Property, Property Member, Quote) are all in good standing before trying to integrate w/ MARS
*/
    public void ensureFileComplete(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        List<Opportunity> requireMarsValidation = new List<Opportunity>();
        for (Opportunity l : records) {
            if (!l.MARS_Validation_Run__c && !Utils.isIntegrationUser() && !OPPORTUNITY_CHANNEL_MBD.equalsIgnoreCase(l.Channel__c)) {
                l.StageName = OPPORTUNITY_STATUS_PREAPPLICATION;
                requireMarsValidation.add(l);
            }
        }
        
        if (!requireMarsValidation.isEmpty())
            fileValidationPriorToMARS(requireMarsValidation, oldRecords);
        
        // get relevant records; return if none
        for (Opportunity l : records) {
            System.debug(l);
            if (l.Missing_MARS_Validation_Message__c <> null) {
                System.debug(l.Missing_MARS_Validation_Message__c);
                //l.addError(Label.Error_Lead_FileIncomplete);
            }
            System.debug(l.Warning_Message__c);
            if (l.Warning_Message__c <> null) {
                l.Warning_Message__c.contains('Credit bureau mismatch information');
                if (l.Warning_Message__c.contains('mismatch')) {
                    System.debug(
                        l.Warning_Message__c.contains('Credit bureau mismatch information')
                    );
                    // l.addError('Credit bureau information mismatch must be acknowledged. ' + l.Warning_Message__c.stripHtmlTags());
                }
            }
        }
    }
    
    /*
* HEB-596: Only currently active user can be set to CASL consent
*/
    public void checkCASLConsentUser(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        if (Utils.allowBypassForUser())
            return;
        
        for (Opportunity l : records) {
            if (
                l.Account.CASL_Consent_Obtained_By__pc <> UserInfo.getUserId() && l.Account.PersonEmail <> null && l.Account.PersonEmail <> ''
            ) {
                if ( oldRecords == null || (l.Account.CASL_Consent_Obtained_By__pc <> oldRecords.get(l.Id).Account.CASL_Consent_Obtained_By__pc) ) {
                    l.addError(Label.Error_Only_Active_CASL_User_Can_Conset);
                }
            }
        }
    }
    
    /*
HEB-832: post-conversion, callout to generate MARS Ready Record
*/
   /* public static void startMarsReadyRecordPostConversion(
        List<Opportunity> newOpps,
        Map<Id, Opportunity> oldLeadMap
    ) {
        List<Id> oppIds = new List<Id>();
        for (Opportunity l : newOpps) {
            if (oldLeadMap == null) {
                oppIds.add(l.Id);
            }
        }
        
        // if no converted leads, no action
        if (oppIds.isEmpty())
            return;
        
        List<Opportunity> oppList = [ SELECT Id, Name FROM Opportunity  WHERE Id IN :oppIds ];
        
        OpportunityService service = new OpportunityService();
        service.sendToMarsPlatformEvent(oppList);
    } DEPRECATED - BUG 9820*/
    
    /*
Moved from process builder; set Bio fields for user
*/
    public void mapUserBio(
        List<Opportunity> newOpps,
        Map<Id, Opportunity> oldRecords
    ) {
        Set<String> fieldsToCheck = new Set<String>{ 'OwnerId' };
            
            List<Opportunity> ls = (oldRecords == null)  ? newOpps : (List<Opportunity>) Utils.getChangedObjects(  newOpps, oldRecords, fieldsToCheck  );
        
        List<Id> userIds = new List<Id>();
        
        for (Opportunity ld : ls) {
            String ownerId = ld.OwnerId;
            if (ownerId.startsWith('005'))
                userIds.add(ld.OwnerId);
        }
        
        if (userIds.isEmpty())
            return;
        
        Map<Id, User> userMap = new Map<Id, User>(
            [
                SELECT Id, English_Bio_URL__c, French_Bio_URL__c
                FROM User
                WHERE Id IN :userIds
            ]
        );
        
        List<Account> accounts = new List<Account>();
        for (Opportunity ld : ls) {
            if (ld.AccountId != null && userMap.containsKey(ld.OwnerId)) {
                Account account = new Account(Id = ld.AccountId);
                account.Owners_English_Bio_URL__c = userMap.get(ld.OwnerId)
                    .English_Bio_URL__c;
                account.Owners_French_Bio_URL__c = userMap.get(ld.OwnerId)
                    .French_Bio_URL__c;
                
                accounts.add(account);
            }
        }
        update accounts;
    }
    
    /*
* New Lead -
* Set Verify_Email__c to true if Email field has value.
* Set Most Recent Inquiry Date to Datetime.now() if it doesn't have value.
*/
    public void initialValues(List<Opportunity> records) {
        List<Account> accounts = new List<Account>();
        for (Opportunity ld : records) {
            if (ld.AccountId != null) {
                Account account = new Account(Id = ld.AccountId);
                if (ld.Account.PersonEmail != null) {
                    account.FinServ__EmailVerified__pc = true;
                }
                if (
                    ld.Account.IsPersonAccount && ld.Account.Most_Recent_Inquiry_Date__pc == null
                ) {
                    account.Most_Recent_Inquiry_Date__pc = Datetime.now();
                }
                accounts.add(account);
            }
        }
        update accounts;
    }
    
    public static void mapRelatedRecordsFileRecordType(
        List<Opportunity> newOpps,
        Map<Id, Opportunity> oldRecords
    ) {
        Set<String> fieldsToCheck = new Set<String>{ 'Type' };
            
            List<Opportunity> ls = (List<Opportunity>) Utils.getChangedObjects(
                newOpps,
                oldRecords,
                fieldsToCheck
            );
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        for (Opportunity ld : ls)
            oppMap.put(ld.Id, ld);
        
        if (oppMap.isEmpty())
            return;
        processRelatedRecordsFileRecordType(oppMap);
    }
    
    /*
* HEB-890:
*/
    
    public static void processRelatedRecordsFileRecordType(
        Map<Id, Opportunity> oppMap
    ) {
        List<LoanApplicationLiability> debtList = new List<LoanApplicationLiability>();
        List<Quote> quoteList = new List<Quote>();
        List<Appraisal__c> appraisalList = new List<Appraisal__c>();
        List<Appraisal_Order__c> apprOrderList = new List<Appraisal_Order__c>();
        List<LoanApplicant> propertyMemList = new List<LoanApplicant>();
        List<Credit_Report__c> creditReportList = new List<Credit_Report__c>();
        List<LoanApplicationAsset> assetList = new List<LoanApplicationAsset>();
        
        // Get LoanApplicationLiabilities by Opportunity
        Map<Id, List<LoanApplicationLiability>> liabilityMap = new Map<Id, List<LoanApplicationLiability>>();
        for (LoanApplicationLiability liability : [
            SELECT Id, LoanApplication.OpportunityId, OwnerId
            FROM LoanApplicationLiability
            WHERE LoanApplication.OpportunityId IN :oppMap.keySet() ]) {
                if (!liabilityMap.containsKey(liability.LoanApplication.OpportunityId)) {
                    liabilityMap.put( liability.LoanApplication.OpportunityId, new List<LoanApplicationLiability>{ liability }  );
                } else {
                    liabilityMap.get(liability.LoanApplication.OpportunityId) .add(liability);
                }
            }
        
        // Get Assets by Opportunity
        Map<Id, List<LoanApplicationAsset>> assetMap = new Map<Id, List<LoanApplicationAsset>>();
        for (LoanApplicationAsset asset : [
            SELECT Id, LoanApplication.OpportunityId, OwnerId
            FROM LoanApplicationAsset
            WHERE LoanApplication.OpportunityId IN :oppMap.keySet() ]) {
                if (!assetMap.containsKey(asset.LoanApplication.OpportunityId)) {
                    assetMap.put( asset.LoanApplication.OpportunityId,  new List<LoanApplicationAsset>{ asset } );
                } else {
                    assetMap.get(asset.LoanApplication.OpportunityId).add(asset);
                }
            }
        
        // Get Appraisals by Opportunity
        Map<Id, List<Appraisal__c>> appraisalMap = new Map<Id, List<Appraisal__c>>();
        for (Appraisal__c appraisal : [
            SELECT Id, Application__r.OpportunityId, OwnerId
            FROM Appraisal__c
            WHERE Application__r.OpportunityId IN :oppMap.keySet()
        ]) {
            if (!appraisalMap.containsKey(appraisal.Application__r.OpportunityId)) {
                appraisalMap.put(
                    appraisal.Application__r.OpportunityId,
                    new List<Appraisal__c>{ appraisal }
                );
            } else {
                appraisalMap.get(appraisal.Application__r.OpportunityId).add(appraisal);
            }
        }
        
        // Get LoanApplicant by Opportunity
        Map<Id, List<LoanApplicant>> applicantMap = new Map<Id, List<LoanApplicant>>();
        for (LoanApplicant applicant : [
            SELECT Id, LoanApplication.OpportunityId, OwnerId
            FROM LoanApplicant
            WHERE LoanApplication.OpportunityId IN :oppMap.keySet()
        ]) {
            if (!applicantMap.containsKey(applicant.LoanApplication.OpportunityId)) {
                applicantMap.put(
                    applicant.LoanApplication.OpportunityId,
                    new List<LoanApplicant>{ applicant }
                );
            } else {
                applicantMap.get(applicant.LoanApplication.OpportunityId)
                    .add(applicant);
            }
        }
        
        for (Opportunity l : [
            SELECT Id, (SELECT Id, OpportunityId FROM Quotes)
            FROM Opportunity
            WHERE Id IN :oppMap.keySet()
        ]) {
            if (liabilityMap.containsKey(l.Id)) {
                for (LoanApplicationLiability debt : liabilityMap.get(l.Id)) {
                    debtList.add(debt);
                }
            }
            
            if (assetMap.containsKey(l.Id)) {
                for (LoanApplicationAsset asset : assetMap.get(l.Id)) {
                    assetList.add(asset);
                }
            }
            
            for (Quote quote : l.Quotes) {
                quoteList.add(quote);
            }
            
            if (appraisalMap.containsKey(l.Id)) {
                for (Appraisal__c appraisal : appraisalMap.get(l.Id)) {
                    appraisalList.add(appraisal);
                }
            }
            
            if (applicantMap.containsKey(l.Id)) {
                for (LoanApplicant propM : applicantMap.get(l.Id)) {
                    propertyMemList.add(propM);
                }
            }
        }
        
        for (Appraisal_Order__c apprOrder : [
            SELECT
            Id,
            Appraisal__c,
            Appraisal__r.Application__r.OpportunityId,
            OwnerId
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application__r.OpportunityId IN :oppMap.keySet()
        ]) {
            apprOrderList.add(apprOrder);
        }
        
        for (Credit_Report__c creditReport : [
            SELECT
            Id,
            Person__c,
            Loan_Applicant__r.LoanApplication.OpportunityId,
            OwnerId
            FROM Credit_Report__c
            WHERE Loan_Applicant__r.LoanApplication.OpportunityId IN :oppMap.keySet()
        ]) {
            creditReportList.add(creditReport);
        }
        
        Boolean reassignmentError = false;
        
        try { update debtList; } 
        catch (Exception e) { reassignmentError = true; }
        
        try { update assetList; } 
        catch (Exception e) { reassignmentError = true; }
        
        try { update quoteList; } 
        catch (Exception e) { reassignmentError = true; }
        
        try { update appraisalList; } 
        catch (Exception e) { reassignmentError = true; }
        
        try { update apprOrderList; } 
        catch (Exception e) { reassignmentError = true;  }
        
        try {  update propertyMemList;}
        catch (Exception e) { reassignmentError = true;  }
        
        try { update creditReportList;}
        catch (Exception e) { reassignmentError = true;  }
        
    }
    
    /*
To populate Add_to_Dial_List__c and Dial_List_Main__c on the related account, based on File fiels values
*/
    public void checkDialListConditions(List<Opportunity> records,
                                        Map<Id, Opportunity> oldRecords){
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> accIds = new Set<Id>();
        for (Opportunity oppItem : records) {
            accIds.add(oppItem.AccountId);
        }
        
        for (Account  accItem : [Select Id, Local_Date_Time_Numeric__c, CreatedDate, Most_Recent_Inquiry_Date__pc,
                                    In_Nurture_Stream__c,  Phone_Verification_Status__c, Not_Interested_Yet__c, 
                                    Dialer_Dormant__c, Add_to_Dial_List__c, Dial_List_Main__c, Dialer_DNC__c
                                    FROM Account Where Id IN :accIds]) {
            accountMap.put(accItem.Id, accItem);
        }
        
        Map<Id, Decimal> oppToPropertyValueMap = new Map<Id, Decimal>();
        for (ResidentialLoanApplication application : [SELECT 
                                                        Id,
                                                        OpportunityId,
                                                        (SELECT
                                                        Id,
                                                        Property_Value_for_Quote__c
                                                        FROM LoanApplicationProperties
                                                        ORDER BY CreatedDate Desc
                                                        LIMIT 1)
                                                        FROM ResidentialLoanApplication
                                                        WHERE OpportunityId in :records]){
            if (application.LoanApplicationProperties?.size() == 0) {
                // application isnt linked to a property
                continue;
            }
            oppToPropertyValueMap.put(application.OpportunityId, application.LoanApplicationProperties[0].Property_Value_for_Quote__c);
        }
        
        if(accountMap!=null){
            for (Opportunity opp : records) {
                Boolean accountChanged = false;
                Account oppAccount = accountMap.get(opp.AccountId);
                Decimal propertyValue = oppToPropertyValueMap.get(opp.Id);
                if(oppAccount!=null){
                    Boolean currentAddtoDialListValue = oppAccount.Add_to_Dial_List__c;
                    Boolean currentDialListMainValue = oppAccount.Dial_List_Main__c;
                    
                    //Add_to_Dial_List__c     
                    oppAccount.Add_to_Dial_List__c = Five9ServiceUtils.checkAddtoDialList(oppAccount,opp);     
                    if(currentAddtoDialListValue != oppAccount.Add_to_Dial_List__c){
                        accountChanged = true;
                    }
                    
                    //Dial_List_Main__c          
                    oppAccount.Dial_List_Main__c = Five9ServiceUtils.checkDialListMain(oppAccount,opp,propertyValue);
                    if(currentDialListMainValue != oppAccount.Dial_List_Main__c){
                        accountChanged = true;
                    }
                    
                    if(accountChanged){
                        accountsToUpdate.add(oppAccount);
                    }
                }
            }
            if(!accountsToUpdate.isEmpty()){  
                try{
                    update accountsToUpdate;
                }catch(Exception ex){
                    system.debug(ex.getMessage());
                }
            }
        }
    }
}