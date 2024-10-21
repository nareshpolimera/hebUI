/******************************************************//**
@Class      AppraisalSendNoteService
@brief      Service class for trigger of the AppraisalNote object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalSendNoteService
{
    /*============
     * Request
     *============*/
    
    @future(callout=true)
    public static void sendNote(Id recordId)
    {
        // Generate the request body.
        Appraisal_Note__c an = getRecordDetails(recordId);
        ModelAppraisalSendNote.Request asn = convertAppraisalNote(an);
        
        // Set up request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Appraisal_SendAppraisalNote));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);
        req.setBody(JSON.serialize(asn));
        
        // Send request.
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        
        /* better to use a Mock test, but currently getting Uncommitted Work Pending errors */
        //if (!Test.IsRunningTest()) 
            res = http.send(req);

        system.debug(res.getStatusCode());
        if (res.getStatusCode() == IntegrationService.HTTP_OK)
        {
            ModelAppraisalSendNote.Response asnRes = (ModelAppraisalSendNote.Response) Json.deserialize(res.getBody(), ModelAppraisalSendNote.Response.class);
            
            ModelAppraisalSendNote.Note n = asnRes.Notes[0];
            
            an.Entered_By__c       = n.EnteredBy;
            an.Entered_On_DT__c      = n.EnteredOn;
            an.Send_Note_Status__c = asnRes.Errors <> null && !asnRes.Errors.isEmpty()
                                        ? AppraisalNoteService.APPRAISAL_SEND_STATUS_SEND_ERROR + String.join(asnRes.Errors, ', ')
                                        : AppraisalNoteService.APPRAISAL_SEND_STATUS_SENT;
            update an;
        }
        else
        {
            an.Send_Note_Status__c = 
                AppraisalNoteService.APPRAISAL_SEND_STATUS_SEND_ERROR +
                AppraisalNoteService.APPRAISAL_SEND_STATUS_FAILED +
                'HTTP ' + res.getStatusCode();
        }
    }
    
    public static Appraisal_Note__c getRecordDetails(Id recordId)
    {
        Appraisal_Note__c an = [
            SELECT Id
            , Appraisal_Order__r.Reference_Id__c
            , Content__c
            FROM Appraisal_Note__c
            WHERE Id = :recordId
        ];

        return an;
    }
    
    public static ModelAppraisalSendNote.Request convertAppraisalNote(Appraisal_Note__c an)
    {
        ModelAppraisalSendNote.Request req = new ModelAppraisalSendNote.Request();
        
        req.ReferenceId       = an.Appraisal_Order__r.Reference_Id__c;
        req.UserEID           = Utils.getUserEID(UserInfo.getUserId());
        req.Text              = an.Content__c;
        
        return req;
    }
}