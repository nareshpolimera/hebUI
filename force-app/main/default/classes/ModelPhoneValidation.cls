public class ModelPhoneValidation {
    
    /*===================================
     * Phone Umber Validation Request
     *===================================*/
    
    /**
     * "ID": "1809162",
       "PhoneNumber": "6478509875"
     */
    public class Request
    {
        public Phone PhoneNumbers;
    }
    
    /**
    */
    public class Phone
    {
        public String Id;
        public String PhoneNumber;
    }
    
    /*===================================
     * Phone Umber Validation Response
     *===================================*/
    /*[ 
        { "id": "1", "phoneNumber": "6478509875", "status": "Valid", "validatedOn": "2022-09-13T14:52:18.3583815-04:00", "lineType": "Mobile", "smsAddress": null }
        
      ]
    */
    
    public class Response
    {
        public PhoneInfo ValidatedPhones;
    }
    
    public class PhoneInfo
    {
      public String     id;
      public String     phoneNumber;
      public String     status;
      public Datetime   validatedOn;      
      public String     lineType; 
      public String     smsAddress;
  }
}