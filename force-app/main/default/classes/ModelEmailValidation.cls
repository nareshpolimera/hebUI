/******************************************************//**
@Class      ModelEmailValidation
@brief      Class to handle the request/response from Email validation API.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class ModelEmailValidation {
    
    /*===================================
     * Email Validation Request
     *===================================*/
    
    /**
     * 
       "EmailEmailAddress": "test@heb.ca"
     */
    public class Request
    {
        public List<Email> EmailAddresses;
    }
    
    /**
    */
    public class Email
    {        
        public String Id;
        public String EmailAddress;
    }
    
    /*===================================
     * Email Validation Response
     *===================================*/
    /*[ 
        {  "isSuccessful": true, "validationStatus": "Unknown", "isDeliverable": false, "emailAddressIn": "test@heb.ca",  "emailAddressOut": "test@heb.ca",  "validatedOn": "2024-er01-22T14:23:06.5708464-05:00", "emailCorrected": false, "status": "Unknown", "errors": [] },
        {  "isSuccessful": true, "validationStatus": "Unknown", "isDeliverable": false, "emailAddressIn": "test22@heb.ca", "emailAddressOut": "test22@heb.ca",  "validatedOn": "2024-er01-22T14:23:06.5708464-05:00", "emailCorrected": false, "status": "Unknown", "errors": [] }
      ]
    */
    
    public class Response
    {
        public List<EmailInfo> ValidatedEmails;
    }
    
    public class EmailInfo
    {
      public String     id;
      public String     isSuccessful;
      public String     validationStatus;
      public Boolean    isDeliverable;
      public String     emailAddressIn;
      public String     emailAddressOut;
      public Datetime   validatedOn;  
      public Boolean    emailCorrected;    
      public String     status;
      public List<String> errors;
  }
}