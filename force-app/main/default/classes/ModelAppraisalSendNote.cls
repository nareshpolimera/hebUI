public class ModelAppraisalSendNote
{
    /*
     * {
         "ReferenceID": "20230120612",
         "UserEID": "830",
         "Text": "Please provide update on the status of this appraisal"
       }
     */
    public class Request
    {
        public String ReferenceId;
        public String UserEID;
        public String Text;
    }
    
    /*
     * {
         "ReferenceID": "20230120612",
         "IsSuccessful": true,
         "Notes": [
           <Note>
         ],
         "Errors": []
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
         "Text": "Please provide update on the status of this appraisal",
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