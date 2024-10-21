/******************************************************//**
@Class      ModelParseAddress
@brief      Class to handle the request/response from ParseAddress API.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class ModelParseAddress {
     /*===================================
     * Address Validation Request
     *===================================*/
    
    /**
     * 
    { 
        "Id": "18CharUniqueIdentifier"
        "Address": "5 Andrew Ave", 
        "Address2": null, 
        "City": "Toronto", 
        "Province": "Ontario", 
        "PostalCode": "M1M3G8", 
        "CallSource": null 
    }
     */
    public class Request
    {
        public List<Address> Addresses;
    }
    
    /**
    */
    public class Address
    {        
        public String Id;
        public String Address;
        public String Address2;
        public String City;
        public String Province;
        public String PostalCode;
        public String CallSource;
    }
    
    /*===================================
     * Parse Address Response
     *===================================*/
    /*{  
        "Id": "18CharUniqueIdentifier"
        "AddressNumberFragment": "5", 
        "StreetNameFragment": "ANDREW", 
        "StreetTypeFragment": "AVE", 
        "DirectionalCodeFragment": "", 
        "UnitTypeFragment": "", 
        "UnitNumberFragment": "", 
        "IsPOBox": false, 
        "BoxNumberFragment": "", 
        "CorrectionsDescription": "MUNICIPALITY_NAME_CORRECTION,PROVINCE_NAME_CORRECTION", 
        "CityFragment": "SCARBOROUGH", 
        "ProvinceFragment": "ON", 
        "PostalCodeFragment": "M1M 3G8", 
        "IsSuccessful": true, 
        "Error": null 
    }

    NEW RESPONSE:
    {
    "id": "18CharUniqueIdentifier",
    "isSuccessful": true,
    "address": {
        "unitNumber": "",
        "streetNumber": "5",
        "streetName": "ANDREW",
        "streetType": "AVE",
        "streetDirection": "",
        "city": "SCARBOROUGH",
        "postalCode": "M1M 3G8",
        "province": "ON"
    },
    "errors": []
}
    */
    
    public class Response
    {
        public String     id;
        public String     isSuccessful;
        public AddressInfo Address;
        public List<String> errors;
    }
    
    public class AddressInfo
    {      
        public String UnitNumber;
        public String StreetNumber;
        public String StreetName;
        public String StreetType;
        public String StreetDirection;
        public String City;
        public String PostalCode;
        public String Province;  
   
  }
}