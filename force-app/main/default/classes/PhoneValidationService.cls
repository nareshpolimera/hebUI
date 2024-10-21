/******************************************************//**
@Class      PhoneValidationService
@Test Class PhoneValidationServiceTest
@brief      Class with especific-related methods to API Phone validation.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public without sharing class PhoneValidationService
{
    public static String sendRequest(List<ModelPhoneValidation.phone> lPhone)
    {
        // Generate the request body.
        List<ModelPhoneValidation.Phone> pvr = lPhone;

        // Set up request.
        HttpRequest req = new HttpRequest();        
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Phone_Validation));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setBody(JSON.serialize(pvr[0]));
        system.debug('!!! Phone Validation request = ' + req.getBody() );
        system.debug('!!! Phone Validation endpoint = ' + IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Phone_Validation) );
        // Send request.
        Http http = new Http();
        //req.setTimeout(20);
        HTTPResponse res = http.send(req);
        system.debug('!!! Phone Validation response message = ' + res.getBody() );
        system.debug('!!! Phone Validation response Status = ' + res.getStatus() );
        return res.getBody();
    }
    
    public static  List<ModelPhoneValidation.PhoneInfo> processResponse(String resp)
    {
        List<ModelPhoneValidation.PhoneInfo> responseList = new List<ModelPhoneValidation.PhoneInfo>();
        // Cast response.
        ModelPhoneValidation.PhoneInfo linfo = (ModelPhoneValidation.PhoneInfo) JSON.deserialize(resp, ModelPhoneValidation.PhoneInfo.class);
        responseList.add(linfo);
        return responseList;
    }
   
}