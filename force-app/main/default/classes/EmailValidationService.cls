/******************************************************//**
@Class      EmailValidationService
@Test Class EmailValidationServiceTest
@brief      Class with especific-related methods to API Email validation.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public with sharing class EmailValidationService {
    public static String sendRequest(List<ModelEmailValidation.Email> lEmail)
    {
        // Generate the request body.
        List<ModelEmailValidation.Email> pvr = lEmail;

        // Set up request.
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Email_Validation));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setBody(JSON.serialize(pvr[0]));
        system.debug('!!! Email Validation request = ' + req.getBody() );
        // Send request.
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    
    public static  List<ModelEmailValidation.EmailInfo> processResponse(String resp)
    {
        List<ModelEmailValidation.EmailInfo> responseList = new List<ModelEmailValidation.EmailInfo>();
        // Cast response.
        ModelEmailValidation.EmailInfo linfo = (ModelEmailValidation.EmailInfo) JSON.deserialize(resp, ModelEmailValidation.EmailInfo.class);
        responseList.add(linfo);
        return responseList;
    }
}