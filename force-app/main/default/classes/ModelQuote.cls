public class ModelQuote
{
    
    /*===================================
     * Quote Request
     *===================================*/
    
    /**
     * "FileNumber": "1809162",
       "GenerateFileNumber": true,
       "ProductType": "CHIP",
       "TermType": "3-YEAR",
       "TotalSecuredDebt": 100000.00,
       "Property": <QuoteRequestProperty>,
       "Custumer": [
         <Customer>
       ]
     */
    public class Request
    {
        public String FileNumber;
        public Boolean GenerateFileNumber;
        public String ProductType;
        public String TermType;
        public Decimal TotalSecuredDebt;
        public integer ProductRateSetID;//Product Rate Set External ID
        public Date    RateCommitmentDate; // Product Rate Effective Date        
        public integer ProductQuoteSetID; // Product Quote Set External ID
        public Date    QuoteCommitmentDate; // Product Quote Effective Date
        public Property Property;
        
        public List<Customer> Customers;
    }
    
    /**
     * {
         "PostalCode": "L3P6P4",
         "City": "Markham",
         "Province": "ON",
         "PropertyType": "Single Family Dwelling",
         "HomeValue": 295000.0,
         "Acreage": "< 2 ACRES",
         "Zoning": "Residential",
         "WaterSupply": "Municipal",
         "OwnsProperty": true,
         "IsLeasePaid": true,
         "IsFixedToGround": true,
         "IsFourSeasons": true,
         "DoDowngrade": true
       }
     */
    public class Property
    {
        public String PostalCode;
        public String City;
        public String Province;
        public String PropertyType;
        public Decimal HomeValue;
        public String Acreage;
        public STring Zoning;
        public String WaterSupply;
        public Boolean OwnsProperty;
        public Boolean IsLeasePaid;
        public Boolean IsFixedToGround;
        public Boolean IsFourSeasons;
        public Boolean DoDowngrade;
    }
    
    /**
     * {
          "Age": null,
          "DateOfBirth": "1944-07-23",
          "Gender": "F"
       }
     */
    public class Customer
    {
        public Integer Age;
        public String DateOfBirth;
        public String Gender;
    }
    
    /*===================================
     * Quote Response
     *===================================*/
    
    /**
     *
      "fileNumber": "1809162",
      "locationCode": "A",
      "propertyTypeRating": "A",
      "isDowngraded": false,
      "eot": 8.4801,
      "ProductQuotes": [
        <ProductQuote>
      ]
    */
    public class Response
    {
        public String fileNumber;
        public String locationCode;
        public String propertyTypeRating;
        public Boolean isDowngraded;
        public Decimal eot;
        public integer ProductRateSetID;//Product Rate Set External ID
        public Date    RateCommitmentDate; // Product Rate Effective Date        
        public integer ProductQuoteSetID; // Product Quote Set External ID
        public Date    QuoteCommitmentDate; // Product Quote Effective Date
        public List<ProductQuote> productQuotes;
    }
    
    /**
     *
      {
        "isSelected": false,
        "productType": "CHIP Open",
        "term": "Variable",
        "rate": 6.450000,
        "amount": 0.0,
        "isEligible": false,
        "ineligibleReason": "home value"
      }
    */
    public class ProductQuote
    {
        public Boolean isSelected;
        public String productType;
        public String term;
        public Decimal rate;
        public Decimal amount;
        public Boolean isEligible;
        public String ineligibleReason;
    }
}