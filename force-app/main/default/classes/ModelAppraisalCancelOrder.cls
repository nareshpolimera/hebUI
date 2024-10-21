public class ModelAppraisalCancelOrder
{
    
    /*
     * {
         "ReferenceID": "20230120612",
         "UserEID": "830",
         "ReasonType": "Client does not want to proceed"
       }
     */
    public class Request
    {
        public String ReferenceID;
        public String userEID;
        public String ReasonType;
    }
    
    /*
     * {
         "ReferenceID": "20230120612",
         "IsSuccessful": true,
         "OrderStatus": "Cancel Requested",
         "OrderStatusChangedOn": "2020-08-17T03:57:53.4690101-04:00",
         "Notes": [
           <Note>
         ],
         "Errors": [
           "error"
         ]
       }
     */
    public class Response
    {
        public String ReferenceId;
        public Boolean IsSuccessful;
        public String OrderStatus;
        public Datetime OrderStatusChangedOn;
        public List<Note> Notes;
        public List<String> Errors;
    }
    
    /*
     * {
         "Text": "HEB Appraisal Cancellation Request Reason: Client does not want to proceed",
         "Type": "Appraisal Note",
         "EnteredOn": "2020-08-17T03:57:24.0402468-04:00",
         "EnteredBy": "pta"
       }
     */
    public class Note
    {
        public String Text;
        public String Type;
        public DateTime EnteredOn;
        public String EnteredBy;
    }
}