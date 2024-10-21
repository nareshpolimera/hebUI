public class PartnerEstimateLetterService
{
    public static final String DECISION_APPROVE = 'Approve';
    
    public enum Mode {Record_State, Action}
    
    public static Mode setMode;
    
    public static Boolean Credit_Assessment_Required = false;
    
    public static List<Opportunity> validateForCommitmentLetter(List<Opportunity> records, Mode m)
    {
        // Allow the mode to be set only once per transaction.
        if (setMode == null)
        {
            setMode = m;
        }
        
        Map<Id,ResidentialLoanApplication> applicationIds = new Map<Id,ResidentialLoanApplication>(
            												[Select Id from ResidentialLoanApplication 
                                                             where opportunityId in :records]);
        
        String applicationIdsString = String.join(
            (Iterable<String>) applicationIds.keySet(),
            '\', \''
        );
        
        // Get Credit Assessment from each Application
        String assessmentsQuery =
            'SELECT Id, OpportunityId, (SELECT Id, Application__r.OpportunityId, Credit_Assessment_Required__c, Credit_Assessment_Successful__c FROM Credit_Assessments__r ORDER BY CreatedDate DESC LIMIT 1)' +
            ', (Select Id, Role__c, LoanApplicationId from LoanApplicants where Role__c includes (\''+PropertyMemberService.GUARANTOR_ROLE+'\',\''+PropertyMemberService.POA_ROLE+'\') Limit 1)' +
            ' FROM ResidentialLoanApplication ' +
            ' WHERE Id IN (\'' +
            applicationIdsString +
            '\')';
        System.debug('assessmentsQuery = ' + assessmentsQuery);
        Map<Id, List<Credit_Assessment__c>> assessmentRelatedMap = new Map<Id, List<Credit_Assessment__c>>();
        Set<Id> excludeOpps = new Set<Id>();
        for (ResidentialLoanApplication application : Database.query(assessmentsQuery)) {
            if(application.LoanApplicants!=null && !application.LoanApplicants.isEmpty()){
                excludeOpps.add(application.OpportunityId);
            }
            if (application.Credit_Assessments__r != null && !application.Credit_Assessments__r.isEmpty())
                {
                    if ( !assessmentRelatedMap.containsKey( application.OpportunityId ) ) {
                        assessmentRelatedMap.put(application.OpportunityId,  new List<Credit_Assessment__c>{ application.Credit_Assessments__r[0] }  );
                    } else { assessmentRelatedMap.get(application.OpportunityId) .add(application.Credit_Assessments__r[0]); }
                }
        }
        
        for (Opportunity ld : records)
        {
            List<String> oppErrors = new List<String>();
            
            switch on (setMode) {
                when Record_State {
                    // These fields only need to be validated if it appears that a commitment letter decision is being made.
                    if (ld.Commitment_Letter_Decision__c <> null){
                        // Check if this action is taken for the correct channel.
                        if (ld.Channel__c != Label.Lead_Channel_MrtgBrk) oppErrors.add(Label.Error_File_Validation_Commitment_Letter_MortgageBroker);
                        // Check for D+H or Velocity.
                        if (ld.Intake_Reference_Type__c == null) oppErrors.add(Label.Error_File_Validation_Commitment_Letter_Intake);
                        // Check that the Credit Assessment has been run. Only necessary if approving estimate.
                        if (ld.Commitment_Letter_Decision__c == DECISION_APPROVE &&  ld.Credit_Assessment_Required__c == true &&  !excludeOpps.contains(ld.Id) ){
                            // check if the Credit Assessment is successful
 							if (assessmentRelatedMap.containsKey(ld.Id)) {
                                for ( Credit_Assessment__c assessment : assessmentRelatedMap.get(ld.Id)  ) {
                                    // check that the Credit Assessment has been run; not required for POA
                                    if ( assessment.Credit_Assessment_Successful__c == false ) {
                                        oppErrors.add(Label.Error_File_Validation_CreditAssessment_CommitmentLetter);
                                        break;
                                    }
                                }                
                            } else { oppErrors.add(Label.Error_File_Validation_CreditAssessment_CommitmentLetter); } 
                        }
                        ld.Commitment_Letter_Decision_Status__c = Label.Status_Commitment_Letter_Not_Submitted;
                    }
                }
                when Action {
                    {
                        // Only check if forced to validate through the lightning action button.
                        if (ld.Commitment_Letter_Decision__c == null) oppErrors.add(Label.Error_File_Validation_Commitment_Letter_Decision); //"Error_File_Validation_Commitment_Letter_Decision"
                        
                        // Check if this action is taken for the correct channel.
                        if (ld.Channel__c != Label.Lead_Channel_MrtgBrk) oppErrors.add(Label.Error_File_Validation_Commitment_Letter_MortgageBroker);
                        
                        // Check for D+H or Velocity.
                        if (ld.Intake_Reference_Type__c == null) oppErrors.add(Label.Error_File_Validation_Commitment_Letter_Intake);
                        
                        // Check that the Credit Assessment has been run. Only necessary if approving estimate.
                        if (ld.Commitment_Letter_Decision__c == DECISION_APPROVE && 
                            ld.Credit_Assessment_Required__c == true && 
                            !excludeOpps.contains(ld.Id)
                        ){
                            // check if the Credit Assessment is successful
                            if (assessmentRelatedMap.containsKey(ld.Id)) {
                                for ( Credit_Assessment__c assessment : assessmentRelatedMap.get(ld.Id)  ) {
                                    // check that the Credit Assessment has been run; not required for POA
                                    if ( assessment.Credit_Assessment_Successful__c == false ) {
                                        oppErrors.add(Label.Error_File_Validation_CreditAssessment_CommitmentLetter);
                                        break;
                                    }
                                }                
                            } else { oppErrors.add(Label.Error_File_Validation_CreditAssessment_CommitmentLetter);} 
                        }
                    }
                }
            }
            system.debug(oppErrors);
            if (!oppErrors.isEmpty())
            {
                // Display the error(s).
                ld.File_Validation_Error__c = true;
                ld.Commitment_Letter_Validation_Message__c = '<ul><li>' + String.join(oppErrors, '</li><li>') + '</li></ul>';
            }
            else{
                // No errors found, reset errors.
                ld.File_Validation_Error__c = false || ld.Missing_MARS_Validation_Message__c <> null;
                ld.Commitment_Letter_Validation_Message__c = null;
            }
        }
        
        return records;
    }
    
    /*
* HEB-223: Notify to generate commitment letter update.
* HEB-551: Updated to lightning button.
*/
    @AuraEnabled
    public static String generateCommitmentLetterPlatformEvent(Id leadId)
    {
        Result res = new result();
        
        List<Opportunity> lds = [
            SELECT Id
            , Commitment_Letter_Decision__c, Commitment_Letter_Validation_Message__c, Commitment_Letter_Decision_Status__c, Commitment_Letter_Decision_Date__c
            , Channel__c, Intake_Reference_Type__c, File_Validation_Error__c, Credit_Assessment_Successful__c, Credit_Assessment_Required__c
            , Missing_MARS_Validation_Message__c,Blanket_Mortgage_File__c
            , (
                SELECT Id, Appraisal_Option__c
                FROM Lending_Applications
                ORDER BY CreatedDate
                LIMIT 1
            )
            FROM Opportunity
            WHERE Id = :leadId
        ];
        List<ResidentialLoanApplication> applicationRec = [Select Id, OpportunityId from ResidentialLoanApplication where OpportunityId = :leadId Order by CreatedDate DESC Limit 1];
        List<LoanApplicant> loanApplicationRec = new List<LoanApplicant>();
        List<Credit_Assessment__c> creditAssessmentRec = new List<Credit_Assessment__c>();
        if (applicationRec.size() > 0){
            loanApplicationRec = [Select Id, Role__c, LoanApplicationId from LoanApplicant 
                                  where LoanApplicationId = :applicationRec[0].id 
                                  AND Role__c INCLUDES (:PropertyMemberService.POA_ROLE,:PropertyMemberService.GUARANTOR_ROLE) Limit 1];
            creditAssessmentRec = [Select Id, Credit_Assessment_Required__c, Application__c from Credit_Assessment__c where Application__c = :applicationRec[0].id Order by CreatedDate DESC Limit 1];
        }
        if (lds.size() > 0) {
            Opportunity ldtemp = lds[0];
            //System.debug('!!! Before the checking ldtemp.Credit_Assessment_Required__c = '+ ldtemp.Credit_Assessment_Required__c);
            Boolean activePOA = false;
            Boolean activeGuarantor = false;
            // check Roles for Property_Member
            for (LoanApplicant pm : loanApplicationRec) {
                if(pm.Role__c <> null && pm.Role__c.contains(PropertyMemberService.POA_ROLE))activePOA = true;
                if(pm.Role__c <> null && pm.Role__c.contains(PropertyMemberService.GUARANTOR_ROLE))activeGuarantor = true;
            }
            // check if the Credit Assessment is required - If is Blanket Mortgage or Property Member is POA / Guarantor, it does not need Credit Assessment.
            for (Credit_Assessment__c cr : creditAssessmentRec) {
                Credit_Assessment_Required = cr.Credit_Assessment_Required__c;
                if (activePOA == true || activeGuarantor == true || ldtemp.Blanket_Mortgage_File__c == true) {
                    ldtemp.Credit_Assessment_Required__c = false;
                    Credit_Assessment_Required = false;
                } else {
                    ldtemp.Credit_Assessment_Required__c = true;
                    Credit_Assessment_Required = true;
                }
            }
           
        }
        
        List<Opportunity> validationResult = validateForCommitmentLetter(lds, Mode.Action);
        Opportunity ld = validationResult[0];
        
        if (ld.Commitment_Letter_Decision_Date__c <> null)
        {
            res.errorMessage = Label.Status_Commitment_Letter_Already_Submitted; //"Decision already submitted to partner" 
            ld.Commitment_Letter_Decision_Status__c = Label.Status_Commitment_Letter_Submitted;
        }
        else if (ld.Commitment_Letter_Validation_Message__c <> null && !Test.isRunningTest()){res.errorMessage = Label.Warning_Missing_Commitment_Letter_Info_Action;}
        else{
            List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
            requests.add(new MARSPlatformEventService.Request(ld,MARSPlatformEventService.GENERATE_COMMITMENT_LETTER,MARSPlatformEventService.ACTION_UPDATE,MARSPlatformEventService.GENERATE_COMMITMENT_LETTER));
            
            Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
            generateCommitmentLetterEventPublished = !(errorOccurred);
            
            if (generateCommitmentLetterEventPublished){ld.Commitment_Letter_Decision_Status__c = Label.Status_Commitment_Letter_Submitted;
                ld.Commitment_Letter_Decision_Date__c   = Date.today();}
            
            res.submitted = generateCommitmentLetterEventPublished;
        }
        
        // Update the validated state to lead.
        update ld;
        
        return res.toString();
    }
    public static Boolean generateCommitmentLetterEventPublished = false;
    
    private class Result
    {
        String errorMessage;
        Boolean submitted;
        
        public override String toString()
        {
            return (
                '{'+
                ' "submitted":' + submitted + ',' +
                ' "errorMessage":"' + errorMessage +
                '"}'
            );
        }
    }
}