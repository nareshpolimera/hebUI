public class MARSPlatformEventService
{
    public static final String ACTION_UPDATE                        = 'Update';
    public static final String ACTION_INSERT                        = 'Insert';    
    public static final String UPDATED_ACCOUNT                      = 'Referral Organization Updated';
    public static final String UPDATED_CONTACT                      = 'Referral Partner Updated';
    public static final String UPDATED_PERSON_ACCOUNT_CLIENT        = 'Referral Organization Updated';
    public static final String CONSENT_SYNC                         = 'Sync Consent';
    public static final String UPDATED_PERSON_ACCOUNT_PARTNER       = 'Referral Partner Updated';
    public static final String SNAIL_MAIL_ACTION                    = 'Send Letter';
    public static final String MARS_READY_OPP                       = 'Import File';
    public static final String GENERATE_COMMITMENT_LETTER           = 'Generate Commitment Letter';
    public static final String SYNC_PROPERTY_MEMBER_CONSENT         = 'Sync Consent';
    public static final String GENERATE_ESTIMATE_LETTER             = 'Generate Estimate Letter';
    public static final String IMPORT_COMPLAINT                     = 'Import Complaint';
    
    public class Request
    {
        public Id recordId;
        public String sobjectName;
        public String description;
        public String operation;
        public String action;
            
        public Request(sObject so, String d, String o, String a)
        {
            this.recordId    = so.Id;
            this.sobjectName = so.getSobjectType().getDescribe().getName();
            this.description = d;
            this.operation   = o;
            this.action      = a;
        }
    }
    
    public class Result
    {
        public Boolean isSuccess;
        public List<String> errors;
        
        public Result(Database.SaveResult sr)
        {
            this.isSuccess = sr.isSuccess();
            if (!sr.isSuccess())
            {
                this.errors = new List<String>();
                for (Database.Error err : sr.getErrors())
                {
                    this.errors.add(err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }
    
    public static Boolean publishEvents(List<Request> requests)
    {
        List<MARS_Ready_Event__e> marsEvents = new List<MARS_Ready_Event__e>();
        for (Request r : requests)
        {
            MARS_Ready_Event__e myEvent = new MARS_Ready_Event__e(
                SFDC_Id__c     = r.recordId,
                SObject__c     = r.sobjectName,
                Description__c = r.description,
                Operation__c   = r.operation,
                Action__c      = r.action
            );
            marsEvents.add(myEvent);
        }
        
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(marsEvents);
        
        List<Result> publishResults = new List<Result>();
        for (Database.SaveResult sr : results)
        {
            publishResults.add(new Result(sr));
        }
        
        // Inspect publishing result
        Boolean errorOccurred = false;
        for (MARSPlatformEventService.Result result : publishResults)
        {
            if (!result.isSuccess)
            {
                errorOccurred = true;
                for (String err : result.errors)
                {
                    System.debug('Error returned: ' + err);
                }
            }
        }
        
        return errorOccurred;
    }
    
    public static void consume(List<MARS_Ready_Event__e> events)
    {
        List<MARS_Ready_Record__c> records = new List<MARS_Ready_Record__c>();
        
        for (MARS_Ready_Event__e event : events)
        {
            records.add(new MARS_Ready_Record__c(
                SFDC_Id__c         = event.SFDC_Id__c,
                Description__c     = event.Description__c,
                Operation__c       = event.Operation__c,
                Event_Timestamp__c = datetime.now(),
                SObject__c         = event.SObject__c,
                Action__c          = event.Action__c
            ));
        }
        
        insert records;
    }
}