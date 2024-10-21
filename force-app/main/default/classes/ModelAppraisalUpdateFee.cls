public class ModelAppraisalUpdateFee
{
    /*===================================
     * Order Request
     *===================================*/
    
    /*
     * {
        "FileNumber": "1234567",
        "Channel": "Referred",
        "ReferenceID": "20230120612",
        "UserEID": "830",
        "CustomerAmount": 275,
        "HEBAmount": 100,
        "PartnerAmount": 0,
        "IsPaidFromProceeds": false,
        "FeeExceptionApprovalType": null
       }
     * 
     */
    public class Request
    {
        public String FileNumber;
        public String Channel;
        public String ReferenceID;
        public String UserEID;
        public String SOCEID;
        public String BorrowerLastName;
        public Decimal CustomerAmount;
        public Decimal HEBAmount;
        public Decimal PartnerAmount;
        public Boolean IsPaidFromProceeds;
        public String FeeExceptionApprovalType;
    }
    
    /*===================================
     * Quote Response
     *===================================*/
    
    /*
     * {
         "ReferenceID": "20230120612",
         "IsSuccessful": true,
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
        public String ReferenceID;
        public Boolean IsSuccessful;
        public List<Note> Notes;
        public List<String> Errors;
    }
    
    /*
     * {
         "Text": "Appraisal Fee Breakdown: Total Appraisal Fee: $375.00 Customer cost: $0.00 HEB cost: $375.00",
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