public class GenerateEstimateLetterService
{
    public static final String DECISION_APPROVE = 'Approve';
    /*
* HEB-223: Notify to generate commitment letter update.
* HEB-551: Updated to lightning button.
*/
    @AuraEnabled
    public static String generateEstimateLetterPlatformEvent(Id leadId)
    {
        Result res = new result();
        
        Opportunity ld = [
            SELECT Id
            , Commitment_Letter_Decision__c, Commitment_Letter_Validation_Message__c, Commitment_Letter_Decision_Status__c, Commitment_Letter_Decision_Date__c
            , Channel__c, Intake_Reference_Type__c, File_Validation_Error__c, Credit_Assessment_Successful__c
            , Missing_MARS_Validation_Message__c  
            FROM Opportunity
            WHERE Id = :leadId limit 1
        ];
        
        if (ld.Channel__c != Label.Lead_Channel_MrtgBrk) {
            res.errorMessage = Label.Error_File_Validation_Estimate_Letter_MortgageBroker;   
        } 
        if (ld.Channel__c == Label.Lead_Channel_MrtgBrk && ld.Commitment_Letter_Decision_Status__c != Label.Status_Commitment_Letter_Submitted) {
            if (String.isblank(res.errorMessage)) {
                res.errorMessage = Label.Error_File_Validation_Estimate_Letter_Require_PartnerResponse;
            } else {
                res.errorMessage += ' / ' +Label.Error_File_Validation_Estimate_Letter_Require_PartnerResponse;
            }
        }
        if (String.isBlank(res.errorMessage)) {
            List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
            requests.add(new MARSPlatformEventService.Request(
                ld,
                MARSPlatformEventService.GENERATE_ESTIMATE_LETTER,
                MARSPlatformEventService.ACTION_UPDATE,
                MARSPlatformEventService.GENERATE_ESTIMATE_LETTER
            ));
            
            Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
            generateEstimateLetterEventPublished = !(errorOccurred);
            
            res.submitted = generateEstimateLetterEventPublished;
        }
        
        return res.toString();
    }
    
    public static Boolean generateEstimateLetterEventPublished = false;
    
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