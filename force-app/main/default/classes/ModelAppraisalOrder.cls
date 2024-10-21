public class ModelAppraisalOrder
{
    /*===================================
     * Order Request
     *===================================*/
    
    /*
     * {
        "FileNumber": "1234567",
        "Channel": "Referred",
        "OwnerEID": "830",
        "SalesContactEID": "",
        "UserEID": "831",
        "QuoteAmount": 201200,
        "EOT": 100,
        "PropertyTypeRating": "A",
        "LocationCode" : "B"
        "FileType": "Purchase",
        "SpecialInstructions": "Dev testing with TestClient: [Appraisal/OrderAppraisal] [08/16/2020 12:07:48 PM]",
        "IsRush": false,
        "ContactFirstName": "FirstName",
        "ContactLastName": "LastName",
        "ContactPhone": "1234567890",
        "ContactMobile": "1234567890",
        "ContactEmail": "testcontact@testheb.ca",
        "RequestedAppointment": "2020-08-18",
        "RequestedAppointmentTime": "11:00 AM - 2:00 PM",
        "AppointmentComments": "",
        "CustomerAmount": 375,
        "HEBAmount": 0,
        "PartnerAmount": 0,
        "IsPaidFromProceeds": false,
        "FeeExceptionApprovalType": null,
        "PropertyType": "Single Family Dwelling",
        "PropertyZoning": "Residential",
        "PropertyValue": 301200.25,
        "PropertyAddress": <PropertyAddress>,
        "PartnerDetail": <PartnerDetail>,
         "Borrowers": [
           <Borrower>
         ]
       }
     * 
     */
    public class Request
    {
        public String FileNumber;
        public String Channel;
        public String OwnerEID;
        public String SOCEID;
        public String SalesContactEID;
        public String UserEID;
        public Decimal QuoteAmount;
        public Decimal EOT;
        public String PropertyTypeRating;
        public String LocationCode;
        public String FileType;
        public String SpecialInstructions;
        public Boolean IsRush;
        public String ContactFirstName;
        public String ContactLastName;
        public String ContactPhone;
        public String ContactMobile;
        public String ContactEmail;
        public DateTime RequestedAppointment;
        public String RequestedAppointmentTime;
        public String AppointmentComments;
        public Decimal CustomerAmount;
        public Decimal HEBAmount;
        public Decimal PartnerAmount;
        public Boolean IsPaidFromProceeds;
        public String FeeExceptionApprovalType;
        public String PropertyType;
        public String PropertyZoning;
        public Decimal PropertyValue;
        
        public PropertyAddress PropertyAddress;
        public PartnerDetail PartnerDetail;
        public List<Borrower> Borrowers;
    }
    
    /*
     * "PropertyAddress": {
         "UnitNumber": "",
         "StreetNumber": "167",
         "StreetName": "Blantyre",
         "StreetType": "Ave",
         "StreetDirection": "",
         "City": "Scarborough",
         "PostalCode": "M1N2R6",
         "Province": "ON"
       }
     */
    public class PropertyAddress
    {
        public String UnitNumber;
        public String StreetNumber;
        public String StreetName;
        public String StreetType;
        public String StreetDirection;
        public String City;
        public String PostalCode;
        public String Province;
        public String PropertyStreetName;
        public String PropertyCity;
        public String PropertyPostalCode;
        public String PropertyProvince;

    }
    
    /*
     * "PartnerDetail": {
         "FirstName": "PartnerFirstName",
         "LastName": "PartnerLastName",
         "Email": "partnertestcontact@testheb.ca",
         "PreferredLanguage": "English"
       }
     */
    public class PartnerDetail
    {
        public String FirstName;
        public String LastName;
        public String Email;
        public String PreferredLanguage;
    }
    
    /*
     * {
         "FirstName": "FirstName",
         "LastName": "LastName",
         "Phone": "1234567890",
         "Mobile": "1234567890",
         "Email": "testborrower@testheb.ca",
         "IsPrimaryBorrower": true,
         "IsPropertyOccupiedByBorrower": true,
         "CreditScore": 630,
         "Age" : 77,
         "DateOfBirth:: "1944-07-01"
       }
     */
    public class Borrower
    {
        public String FirstName;
        public String LastName;
        public String Phone;
        public String Mobile;
        public String Email;
        public Boolean IsPrimaryBorrower;
        public Boolean IsPropertyOccupiedByBorrower;
        public Integer CreditScore;
        public Integer Age;
        public String  DateOfBirth;
    }
    
    /*===================================
     * Quote Response
     *===================================*/
    
    /*
     * {
         "ReferenceID": "20230120612",
         "IsSuccessful": true,
         "AppraisalProduct": "NVIP-Flex",
         "AppraisalProductChangedOn": "2020-08-17T03:57:53.4690101-04:00",
         "OrderStatus": "Appraisal Required",
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
        public String ReferenceID;
        public Boolean IsSuccessful;
        public String AppraisalProduct;
        public DateTime AppraisalProductChangedOn;
        public String OrderStatus;
        public DateTime OrderStatusChangedOn;
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