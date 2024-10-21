public class AppraisalUpdateFeeService
{
    /*============
     * Request
     *============*/
    
    public static String updateFee(Id recordId, Appraisal__c appraisal)
    {
        // Generate the request body.
        AppraisalFeeUpdateDetails afud = getRecordDetails(recordId, appraisal);
        ModelAppraisalUpdateFee.Request acor = convertAppraisalUpdateFee(afud);
        
        // Set up request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Appraisal_UpdateAppraisalFee));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);
        req.setBody(JSON.serialize(acor));
        
        // Send request.
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        return res.getBody();
    }
    
    public class AppraisalFeeUpdateDetails
    {
        public Appraisal_Order__c ao;
        public Appraisal__c app;
        public ResidentialLoanApplication appLead;
    }
    
    public static AppraisalFeeUpdateDetails getRecordDetails(Id recordId, Appraisal__c appraisal)
    {
        AppraisalFeeUpdateDetails aod = new AppraisalFeeUpdateDetails();
        aod.app = appraisal;
        aod.ao = [
            SELECT Id
            , Reference_ID__c
            , Application__c,
            Appraisal__r.Application_Property__r.LoanApplicationId
            FROM Appraisal_Order__c
            WHERE Id = :recordId
        ];
        aod.appLead = Utils.retrieveActiveApplicationForProperty(aod.ao.Appraisal__r.Application_Property__r.LoanApplicationId);

        return aod;
    }
    
    public static ModelAppraisalUpdateFee.Request convertAppraisalUpdateFee(AppraisalFeeUpdateDetails afud)
    {
        ModelAppraisalUpdateFee.Request req = new ModelAppraisalUpdateFee.Request();
        
        Decimal custSplit = (afud.app.Cost_Split_Type__c == 'Percent') ? convertPercentToDecimal(afud.app.Actual_Cost__c, afud.app.Customer_split__c) : afud.app.Customer_split__c;
        Decimal hebSplit = (afud.app.Cost_Split_Type__c == 'Percent') ? convertPercentToDecimal(afud.app.Actual_Cost__c, afud.app.HEB_Split__c) : afud.app.HEB_Split__c;
        Decimal partnerSplit = (afud.app.Cost_Split_Type__c == 'Percent') ? convertPercentToDecimal(afud.app.Actual_Cost__c, afud.app.Partner_Split__c) : afud.app.Partner_Split__c;
        
         req.FileNumber               = afud.appLead.Opportunity.File_Number__c;
         req.Channel                  = afud.appLead.Opportunity.Channel__c;
         req.ReferenceID              = afud.ao.Reference_ID__c;
         req.UserEID                  = Utils.getUserEID(UserInfo.getUserId());
         req.SOCEID                   = Utils.getUserEID(afud.appLead.Opportunity.Sales_Ops_Coordinator__c);
         req.BorrowerLastName         = afud.appLead.LoanApplicants.size() > 0 ? afud.appLead.LoanApplicants[0].Contact.Account.LastName : '';
         req.CustomerAmount           = custSplit;
         req.HEBAmount                = hebSplit;
         req.PartnerAmount            = partnerSplit;
         req.IsPaidFromProceeds       = Utils.isAffirmativePicklist(afud.app.Paid_From_Proceeds__c);
         req.FeeExceptionApprovalType = afud.app.Cost_Exception_Approval__c;

        return req;
    }
    
    /*============
     * Response
     *============*/
    
    public static String processResponse(String orderResponse, Id appOrderId, Appraisal__c appraisal)
    {
        // Cast response.
        ModelAppraisalUpdateFee.Response ores = (ModelAppraisalUpdateFee.Response) JSON.deserialize(orderResponse, ModelAppraisalUpdateFee.Response.class);
        
        if (ores.IsSuccessful)
        {
            // Insert new notes
            insertNotes(appOrderId, ores.Notes);

            try {
                update appraisal;
            } catch(Exception e) {
                System.debug(e.getMessage());
            }
        }
        else
        {
            return JSON.serialize(ores.Errors);
        }
        
        return null;
    }
    
    private static void insertNotes(Id appOrderId, List<ModelAppraisalUpdateFee.Note> aons)
    {
        List<Appraisal_Note__c> notes = new List<Appraisal_Note__c>();
        for (ModelAppraisalUpdateFee.Note n : aons)
        {
            Appraisal_Note__c an = convertNote(appOrderId, n);
            notes.add(an);
        }
        insert notes;
    }
    private static Appraisal_Note__c convertNote(Id appOrderId, ModelAppraisalUpdateFee.Note n)
    {
        Appraisal_Note__c an  = new Appraisal_Note__c();
        an.Appraisal_Order__c = appOrderId;
        an.Incoming_Note__c   = true;
        an.Content__c         = n.Text;
        an.Entered_By__c      = n.EnteredBy;
        an.Entered_On_DT__c      = n.EnteredOn;
        
        return an;
    }

    /*
     * HEB-310: Convert Percent to Decimal
     */
    @TestVisible
    private static Decimal convertPercentToDecimal(Decimal totalValue, Decimal percent) {
        if (totalValue == null)
            totalValue = 350;
        return (totalValue * percent / 100).setScale(2, RoundingMode.HALF_UP);
    }

}