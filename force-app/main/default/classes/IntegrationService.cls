/******************************************************//**
@Class      IntegrationService
@brief      Class with especific-related methods to API's Integrations.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public with sharing class IntegrationService
{
    public static final Integer HTTP_OK = 200;
    public static final String METHOD_POST = 'POST';
    public static final Integer TIMEOUT_MAX = 120000;
    
    private static HEB_Integration_Config__c endpointsCache;
    private static Remote_Endpoint__mdt remote;
    private static Map<String, String> servicePaths;
    
    public enum Integration_Level {
        DEV,
        QA,
        UAT,
        PROD
    }
    
    public enum MARS_API {
        Authenticate_Token,
        Quote_Request,
        Address_Parse,
        Appraisal_RequestAVM,
        Credit_Assessment,
        Credit_Assessment_Report, 
        MARS_Appraisal_OrderAppraisal,
        MARS_Appraisal_CancelAppraisalOrder,
        MARS_Appraisal_UpdateAppraisalFee,
        MARS_Appraisal_SendAppraisalNote,
        Community_Document_View,
        Authenticate_Community_Token,
        MARS_Application_FastLetter,
        MARS_Application_FinancialIllustration,
        MARS_Application_FirstVisitPackage,
        MARS_Phone_Validation,
        MARS_Email_Validation,
        TDSR_Calculation,
        Complaints_Correspondence_Preview,
        Complaints_Correspondence_Generate,
		Complaints_Correspondence_Content	
        
    }
    
    private static void loadConfig()
    {
        if (endpointsCache == null)
        {
            endpointsCache = HEB_Integration_Config__c.getOrgDefaults();
            
            // in the event it's not initialized, either in a new org or in a test method, return defaults
            if (endpointsCache.Id == null)
                endpointsCache = new HEB_Integration_Config__c(
                    Integration_Level__c = Integration_Level.DEV.name()
                );
            
            remote = [
                SELECT MARS_URL__c, MARS_CUSTOMER_URL__c, MARS_INTERNAL_URL__c
                FROM Remote_Endpoint__mdt
                WHERE Level__c = :endpointsCache.Integration_Level__c
            ];
            
            servicePaths = new Map<String, String>();
            for (Service_Path__mdt sp : [
                SELECT DeveloperName, Path__c
                FROM Service_Path__mdt
            ])
            {
                servicePaths.put(sp.DeveloperName, sp.Path__c);
            }
        }
    }
    
    public static String getEndpoint(MARS_API api)
    {
        
        
        if (endpointsCache == null) loadConfig();
        
        String resource;
      
        
        switch on api {
            when Authenticate_Token,
                Quote_Request,
                Address_Parse,
                Appraisal_RequestAVM,
                Credit_Assessment, 
                Credit_Assessment_Report,
                MARS_Appraisal_OrderAppraisal,
                MARS_Appraisal_CancelAppraisalOrder,
                MARS_Appraisal_UpdateAppraisalFee,
                MARS_Appraisal_SendAppraisalNote,
                MARS_Phone_Validation,
                MARS_Email_Validation,
                TDSR_Calculation,
                Complaints_Correspondence_Preview,
        		Complaints_Correspondence_Generate,
                Complaints_Correspondence_Content	
            {
                resource = remote.MARS_URL__c;
            }
            when Authenticate_Community_Token,
                Community_Document_View
            {
                resource = remote.MARS_CUSTOMER_URL__c;
            }
            when MARS_Application_FastLetter,
                MARS_Application_FinancialIllustration,
                MARS_Application_FirstVisitPackage
            {
                resource = remote.MARS_INTERNAL_URL__c;
            }
            when else
            {
                return null;
            }
        }
        
    
        
        String endpoint = resource + servicePaths.get(api.name());
     
        return endpoint;
    }
    
    public static String getTokenAuth(TokenService.Target t)
    {
        if (endpointsCache == null) loadConfig();
        
        switch on t {
            when MARS {
                AuthData ad = new AuthData(endpointsCache.MARS_User__c, endpointsCache.MARS_Key__c);
                return JSON.serialize(ad);
            }
            when MARS_CUSTOMER {
                return 'grant_type=password' +
                    '&username=' + endpointsCache.MARS_Customer_User__c +
                    '&password=' + endpointsCache.MARS_Customer_Key__c;
            }
        }
        
        return null;
    }
    
    private class AuthData
    {
        public String customerKey;
        public String username;
        
        public AuthData(String usn, String key) {
            this.customerKey = key;
            this.username = usn;
        }
    }
}