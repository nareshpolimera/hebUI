/*
 * Used for AVM Requests, to first parse the address then make the AVM Request itself
 * HEB-105 
 */
public without sharing class AVMRequestService {
    private static String previousOpportunityId;
	private static Opportunity previousOpportunity;
    
    private static String previousLoanApplicationId;
	private static LoanApplicationProperty previousLoanApplication;
    private static Map<String, Id> appraisalRecordTypes = Utils.getRecordTypeIdsBySObjectType(
                Appraisal__c.SObjectType
            );
    
    @AuraEnabled
    public static LoanApplicationProperty queryProperty(Id recordId) {
        if (recordId != null && recordId != previousLoanApplicationId) {
            previousLoanApplication = [SELECT Id, Name, AddressNumberFragment__c, AddressTimeZone__c, BoxNumberFragment__c, CityFragment__c, Is_Address_Fragmented__c, Is_Land_Owned__c, Is_PO_Box__c, PostalCodeFragment__c, PropertyCity, PropertyCountry, PropertyPostalcode, PropertyState, PropertyStreet, Property_Type__c, ProvinceFragment__c, StreetDirectionFragment__c, StreetNameFragment__c, StreetTypeFragment__c, UnitNumberFragment__c, UnitTypeFragment__c, Water_Filtration_Installed__c, Water_Type__c, Zoning__c, LoanApplicationId, Property_Value_for_Quote__c, LoanApplication.Opportunity.File_Number__c, AVM_Ordered_From__c, AVM_Reference_Id__c, AVM_Value__c, AVM_Lower_Value_Limit__c, AVM_Upper_Value_Limit__c, AVM_Confidence_Rating__c, AVM_Request_Succeeded__c, AVM_Last_Requested__c, Use_AVM_Value__c 
                                       FROM LoanApplicationProperty
                                       WHERE LoanApplicationId = :recordId 
                                       Order By CreatedDate DESC 
                                       limit 1];
        }
        return previousLoanApplication;
    }
    
    public static Opportunity queryOpportunity(String opportunityId) {
        if (opportunityId != null && opportunityId != previousOpportunityId) {
            previousOpportunityId = opportunityId;
            previousOpportunity = [SELECT File_Number__c 
                                   FROM Opportunity 
                                   WHERE Id = :OpportunityId];
        }
        return previousOpportunity;
    }

    /*
     * HEB-105 
     * Called from Lightning Aura Component; sends a Property Id, and calls out to HEB endpoint to parse the address.
     * Returns the response to the end user to review / update, who will then commit to the database.
     */
    @AuraEnabled
    public static Boolean runAddressParse(  Id recordId,String sObjectName)
    {
        LoanApplicationProperty p  = queryProperty(recordId);
        ParseAddressResponse parsedAddress  = parseAddress(p);
        
        if (parsedAddress <> null)
        {
            p.UnitNumberFragment__c         = parsedAddress.Address.UnitNumber;
            p.AddressNumberFragment__c      = parsedAddress.Address.StreetNumber;
            p.StreetNameFragment__c         = parsedAddress.Address.StreetName;
            p.StreetTypeFragment__c         = parsedAddress.Address.StreetType;
            p.StreetDirectionFragment__c    = parsedAddress.Address.StreetDirection;
            p.CityFragment__c               = parsedAddress.Address.City;
            p.PostalCodeFragment__c         = parsedAddress.Address.PostalCode;
            p.ProvinceFragment__c           = parsedAddress.Address.Province;
            p.Is_Address_Fragmented__c      = Utils.AFFIRMATIVE;
            update p;
        }
        else
        {
            throw Utils.throwAuraException(Label.Error_AVM_NoParsedAddress);
        }
        
        if ( recordId !=null )
        {
            sObject requestObj = getRecordsInContext(recordId, sObjectName);
			if (requestObj== null) return false;
            return (Boolean)requestObj.get('AVM_Request_Succeeded__c');
        } else {
            return true;
        }
    }

    /*
    * Method to use Address Parse for other requests like Appraisal Order
    */
    public static void runAddressParse(Id recordId)
    {
        runAddressParse(recordId, null);
    }

    /*
     * HEB-105 
     * Called from Lightning Aura Component; sends a Property Id, and calls out to HEB endpoint to parse the address.
     * Returns the response to the end user to review / update, who will then commit to the database.
     */
    @AuraEnabled
    public static LoanApplicationProperty runAVMCheck(String opportunityId, String sObjectName, Id recordId)
    {  
        string fileNumber = queryOpportunity(OpportunityId).File_Number__c;
        sObject requestObj = getRecordsInContext(recordId, sObjectName);     
        LoanApplicationProperty property  = queryProperty(recordId);

        AVMResponse avm = avmRequestCallout(fileNumber, property);
        if (avm <> null)
        {
            if (avm.Errors <> null && avm.Errors.size() > 0)
            {
                throw Utils.throwAuraException(Label.Error_AVM_Request + ': ' + String.join(avm.Errors, '; '));
            }

            Appraisal__c appraisal = new Appraisal__c(
                RecordTypeId = appraisalRecordTypes.get('FCT_AVM'),
                File__c = opportunityId,
                Application__c = property.LoanApplicationId,
                Application_Property__c = property.Id,
                AVM_Ordered_From__c = avm.OrderedFrom, 
                AVM_Reference_Id__c = avm.ReferenceID, 
                Appraised_Amount__c = avm.AVMValue, 
                AVM_Lower_Value_Limit__c = avm.LowerValueLimit, 
                AVM_Upper_Value_Limit__c = avm.UpperValueLimit, 
                AVM_Confidence_Rating__c = avm.ConfidenceRating, 
                AVM_Request_Succeeded__c = avm.IsSuccessful, 
                AVM_Last_Requested__c = Datetime.now(),
                // Cost_Split_Type__c = 'Amount',
                Customer_Split__c = 0,
                Partner_Split__c = 0,
                HEB_Split__c = 0
                // Paid_From_Proceeds__c = 'Yes',
                // Cost_Exception_Approval__c = 'Written'
            );
      
            if(requestObj!=null){
                requestObj.put('AVM_Ordered_From__c', avm.OrderedFrom);
                requestObj.put('AVM_Reference_Id__c', avm.ReferenceID);
                requestObj.put('Appraised_Amount__c', avm.AVMValue);
                requestObj.put('AVM_Lower_Value_Limit__c', avm.LowerValueLimit);
                requestObj.put('AVM_Upper_Value_Limit__c', avm.UpperValueLimit);
                requestObj.put('AVM_Confidence_Rating__c', avm.ConfidenceRating);
                requestObj.put('AVM_Request_Succeeded__c', avm.IsSuccessful);
                requestObj.put('AVM_Last_Requested__c', datetime.now());
                update requestObj;
            }
            property.AVM_Ordered_From__c = avm.OrderedFrom;
            property.AVM_Reference_Id__c = avm.ReferenceID;
            property.AVM_Value__c = avm.AVMValue;
            property.AVM_Lower_Value_Limit__c = avm.LowerValueLimit;
            property.AVM_Upper_Value_Limit__c = avm.UpperValueLimit;
            property.AVM_Confidence_Rating__c = avm.ConfidenceRating;
            property.AVM_Request_Succeeded__c = avm.IsSuccessful;
            property.AVM_Last_Requested__c = datetime.now();
            property.Use_AVM_Value__c = true;
            
            update property;

            insert appraisal;
            return property;
        }
        else
        {
            throw Utils.throwAuraException(Label.Error_No_AVM);
        }
    }
    
    /*
     * HEB-105 
     * Callout to HEB Endpoint to parse the Property's Address
     */
    public static ParseAddressResponse parseAddress(LoanApplicationProperty p)
    {
        ParseAddressRequest request = new ParseAddressRequest(p);
        
        // add custom setting for  endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.Address_Parse));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setBody(JSON.serialize(request));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == IntegrationService.HTTP_OK)
        {
            // update to check on response code 
            String responseStr              = res.getBody();
            ParseAddressResponse response   = (ParseAddressResponse)JSON.deserialize(responseStr, ParseAddressResponse.class);
            if (response.Errors <> null && response.Errors.size() > 0)
            {
                throw Utils.throwAuraException(Label.Error_AVM_ParsingAddress + ': ' + String.join(response.Errors, '; '));
            }
            return response;
        }
        throw Utils.throwAuraException(Label.Error_HTTP_Code + ': ' + res.getStatusCode());
    }

    /*
     * HEB-105 
     * Callout to HEB Endpoint to get AVM on Address
     */
    public static AVMResponse avmRequestCallout(String fileNumber, LoanApplicationProperty p)
    {
        AVMRequest request     = new AVMRequest(fileNumber, p);
        // add custom setting for  endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.Appraisal_RequestAVM));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setBody(JSON.serialize(request));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == IntegrationService.HTTP_OK)
        {
            // update to check on response code
            String responseStr      = res.getBody();
            
            AVMResponse response    = (AVMResponse) JSON.deserialize(responseStr, AVMResponse.class);
            return response;
        }
        throw Utils.throwAuraException(Label.Error_HTTP_Code + ': ' + res.getStatusCode());
    }

    @AuraEnabled
    public static LoanApplicationProperty runAVMCheckClone(String opportunityId,  String sObjectName, Id recordId,String City,String StreetName,String StreetType,String AddressNumber,String Province, String PostalCode)
    {
        String fileNumber=queryOpportunity(OpportunityId).File_Number__c;
        //sObject requestObj = getRecordsInContext(recordId, sObjectName);  
        LoanApplicationProperty p  = queryProperty(recordId);
        p.AddressNumberFragment__c = AddressNumber;
        p.StreetNameFragment__c = StreetName;
        p.StreetTypeFragment__c = StreetType;
        p.CityFragment__c = City.toUpperCase();
        p.PostalCodeFragment__c = PostalCode;
        p.ProvinceFragment__c = Province;
        AVMResponse avm = avmRequestCallout(fileNumber, p);
        if (avm <> null) {
            if (avm.Errors <> null && avm.Errors.size() > 0) {
                throw Utils.throwAuraException(Label.Error_AVM_Request + ': ' + String.join(avm.Errors, '; '));
            }
           /* if(requestObj != null){
                requestObj.put('AVM_Ordered_From__c', avm.OrderedFrom);
                requestObj.put('AVM_Reference_Id__c', avm.ReferenceID);
                requestObj.put('AVM_Value__c', avm.AVMValue);
                requestObj.put('AVM_Lower_Value_Limit__c', avm.LowerValueLimit);
                requestObj.put('AVM_Upper_Value_Limit__c', avm.UpperValueLimit);
                requestObj.put('AVM_Confidence_Rating__c', avm.ConfidenceRating);
                requestObj.put('AVM_Request_Succeeded__c', avm.IsSuccessful);
                requestObj.put('AVM_Last_Requested__c', datetime.now());
                update requestObj;
            }*/
            p.AVM_Ordered_From__c = avm.OrderedFrom;
            p.AVM_Reference_Id__c = avm.ReferenceID;
            p.AVM_Value__c = avm.AVMValue;
            p.AVM_Lower_Value_Limit__c = avm.LowerValueLimit;
            p.AVM_Upper_Value_Limit__c = avm.UpperValueLimit;
            p.AVM_Confidence_Rating__c = avm.ConfidenceRating;
            p.AVM_Request_Succeeded__c = avm.IsSuccessful;
            p.AVM_Last_Requested__c = datetime.now();
            p.Use_AVM_Value__c = true;
           
            update p;
            Appraisal__c appraisal = new Appraisal__c(
                RecordTypeId = appraisalRecordTypes.get('FCT_AVM'),
                File__c = opportunityId,
                Application__c = p.LoanApplicationId,
                Application_Property__c = p.Id,
                AVM_Ordered_From__c = avm.OrderedFrom, 
                AVM_Reference_Id__c = avm.ReferenceID, 
                Appraised_Amount__c = avm.AVMValue, 
                AVM_Lower_Value_Limit__c = avm.LowerValueLimit, 
                AVM_Upper_Value_Limit__c = avm.UpperValueLimit, 
                AVM_Confidence_Rating__c = avm.ConfidenceRating, 
                AVM_Request_Succeeded__c = avm.IsSuccessful, 
                AVM_Last_Requested__c = Datetime.now(),
                // Cost_Split_Type__c = 'Amount',
                Customer_Split__c = 0,
                Partner_Split__c = 0,
                HEB_Split__c = 0
                // Paid_From_Proceeds__c = 'Yes',
                // Cost_Exception_Approval__c = 'Written'
            );
            insert appraisal;
            return p;
        }
        else
        {
            throw Utils.throwAuraException(Label.Error_No_AVM);
        }
    }
    @AuraEnabled
    public static sObject getRecordsInContext( Id recordId, String sObjectName)
    {
        LoanApplicationProperty p  = queryProperty(recordId);
        Appraisal__c apr = new Appraisal__c();
        sObject record;

        if  (sObjectName == 'ResidentialLoanApplication' )
        {
            List<Appraisal__c>aprs = [
                SELECT Id 
                , Application_Property__c
                , Application__r.Id
                , File__r.File_Number__c
                , AVM_Ordered_From__c
                , AVM_Reference_Id__c
                , Appraised_Amount__c
                , AVM_Lower_Value_Limit__c
                , AVM_Upper_Value_Limit__c
                , AVM_Confidence_Rating__c
                , AVM_Request_Succeeded__c
                , AVM_Last_Requested__c
                , Application_Property__r.Use_AVM_Value__c
                , RecordTypeId
                FROM Appraisal__c
                WHERE Application__c = :recordId AND Active__c=true
                ORDER BY CreatedDate DESC
            ];
            if (aprs.size() >= 1) {
                apr = aprs[0];
                record = (Appraisal__c) apr;
            }
            // else if (aprs.size() > 1) {
            //     throw Utils.throwAuraException(Label.Error_Multiple_Appraisals);
            // }
        }
        return record;
    }
    
    public class ParseAddressRequest
    {
        String Address;
        String City;
        String Province;
        String PostalCode;

        public ParseAddressRequest(LoanApplicationProperty p)
        {
            this.Address    = p.PropertyStreet;
            this.City       = p.PropertyCity;
            this.Province   = p.PropertyState;
            this.PostalCode = p.PropertyPostalcode;
        }
    }
    
    public class ParseAddressResponse
    {
        public Boolean IsSuccessful;
        public AVMAddress Address;
        public List<String> Errors;
    }

    public class AVMAddress
    {
        public String UnitNumber;
        public String StreetNumber;
        public String StreetName;
        public String StreetType;
        public String StreetDirection;
        public String City;
        public String PostalCode;
        public String Province;
        
        public AVMAddress(LoanApplicationProperty p)
        {
            this.UnitNumber           = p.UnitNumberFragment__c;
            this.StreetNumber         = p.AddressNumberFragment__c;
            this.StreetName           = p.StreetNameFragment__c;
            this.StreetType           = p.StreetTypeFragment__c;
            this.StreetDirection      = p.StreetDirectionFragment__c;
            this.City                 = p.CityFragment__c;
            this.PostalCode           = p.PostalCodeFragment__c;
            this.Province             = p.ProvinceFragment__c;
        }
    }
    
    public class AVMRequest
    {
        public String FileNumber;
        public AVMAddress PropertyAddress;
        
        public AVMRequest(String fileNum, LoanApplicationProperty p)
        {
            this.FileNumber      = fileNum;
            AVMAddress address   = new AVMAddress(p);
            this.PropertyAddress = address;
        }
    }

    public class AVMResponse
    {
        @AuraEnabled
        public String OrderedFrom;
        @AuraEnabled
        public String ReferenceID;
        @AuraEnabled
        public Boolean IsSuccessful;
        @AuraEnabled
        public Decimal AVMValue;
        @AuraEnabled
        public Decimal LowerValueLimit;
        @AuraEnabled
        public Decimal UpperValueLimit;
        @AuraEnabled
        public String ConfidenceRating;
        @AuraEnabled
        public List<String> Errors;
    }

}