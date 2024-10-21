public class AppraisalCancelOrderService
{
    public static final String CANCEL_REASON_FILE_CLOSED_LOST = 'File Cancelled';
    
    /*============
     * Request
     *============*/
    
    public static String sendCancellation(Id recordId)
    {
        // Generate the request body.
        Appraisal_Order__c ao = getRecordDetails(recordId);
        ModelAppraisalCancelOrder.Request acor = convertAppraisalCancelOrder(ao);
        
        // Set up request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Appraisal_CancelAppraisalOrder));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);
        req.setBody(JSON.serialize(acor));
        
        // Send request.
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('SBT req: ' + req);
        system.debug('SBT req: ' + req.getBody());
        system.debug('### marsAppraisalCancelOrder' + res.getBody());
        return res.getBody();
    }
    
    public static Appraisal_Order__c getRecordDetails(Id recordId)
    {
        Appraisal_Order__c ao = [
            SELECT Id
            , Reference_ID__c
            , Cancellation_Reason__c 
            FROM Appraisal_Order__c
            WHERE Id = :recordId
        ];
        
        return ao;
    }
    
    public static ModelAppraisalCancelOrder.Request convertAppraisalCancelOrder(Appraisal_Order__c ao)
    {
        ModelAppraisalCancelOrder.Request req = new ModelAppraisalCancelOrder.Request();
		
        req.ReferenceID = ao.Reference_ID__c;
        req.UserEID     = Utils.getUserEID(UserInfo.getUserId()); 
        req.ReasonType  = ao.Cancellation_Reason__c;
        
        return req;
    }
    
    /*============
     * Response
     *============*/
    
    public static String processResponse(String orderResponse, Id appOrderId)
    {
        // Cast response.
        ModelAppraisalCancelOrder.Response ores = (ModelAppraisalCancelOrder.Response) JSON.deserialize(orderResponse, ModelAppraisalCancelOrder.Response.class);
        
        
        if (ores.IsSuccessful)
        {
            // Mark old statuses as not current
            markStatusesStale(appOrderId);
            
            // Insert new status
            setNewStatus(appOrderId, ores.OrderStatus, ores.OrderStatusChangedOn);
            
            // Insert new notes
            insertNotes(appOrderId, ores.Notes);
        }
        else
        {
            return JSON.serialize(ores.Errors);
        }
        
        return null;
    }
    
    @TestVisible
    private static void markStatusesStale(Id appOrderId)
    {
        List<Appraisal_Status__c> appStatuses = [
            SELECT Id
            , Is_Current__c
            FROM Appraisal_Status__c
            WHERE Appraisal_Order__c = :appOrderId
        ];
        
        for (Appraisal_Status__c appStat : appStatuses)
        {
            appStat.Is_Current__c = Utils.NEGATIVE;
        }
        
        update appStatuses;
    }
    
    @TestVisible
    private static void setNewStatus(Id appOrderId, String status, Datetime change)
    {
        Appraisal_Status__c appStat = new Appraisal_Status__c();
        appStat.Is_Current__c       = Utils.AFFIRMATIVE;
        appStat.Appraisal_Order__c  = appOrderId;
        appStat.Status__c           = status;
        appStat.Status_Date__c      = change;
        insert appStat;
    }
    
    @TestVisible
    private static void insertNotes(Id appOrderId, List<ModelAppraisalCancelOrder.Note> aons)
    {
        List<Appraisal_Note__c> notes = new List<Appraisal_Note__c>();
        for (ModelAppraisalCancelOrder.Note n : aons)
        {
            Appraisal_Note__c an = convertNote(appOrderId, n);
            notes.add(an);
        }
        insert notes;
    }
    
    @TestVisible
    private static Appraisal_Note__c convertNote(Id appOrderId, ModelAppraisalCancelOrder.Note n)
    {
        Appraisal_Note__c an = new Appraisal_Note__c();
        an.Appraisal_Order__c = appOrderId;
        an.Incoming_Note__c   = true;
        an.Content__c         = n.Text;
        an.Entered_By__c      = n.EnteredBy;
        an.Entered_On_DT__c      = n.EnteredOn;
        
        return an;
    }
}