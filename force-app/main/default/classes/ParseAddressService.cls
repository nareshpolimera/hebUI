public with sharing class ParseAddressService {
    public static String sendRequest(List<ModelParseAddress.Address> listAddress)
    {
        // Generate the request body.
        List<ModelParseAddress.Address> pvr = listAddress;

        // Set up request.
        HttpRequest req = new HttpRequest();        
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.Address_Parse));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setBody(JSON.serialize(pvr[0]));
        system.debug('!!! Address Parser request = ' + req.getBody() );
        // Send request.
        Http http = new Http();
        //req.setTimeout(20);
        HTTPResponse res = http.send(req);
        system.debug('!!! Address Parser response message = ' + res.getBody() );
        system.debug('!!! Address Parser response Status = ' + res.getStatus() );
        return res.getBody();
    }
    
    public static  List<ModelParseAddress.Response> processResponse(String resp)
    {
        List<ModelParseAddress.Response> responseList = new List<ModelParseAddress.Response>();
        // Cast response.
        ModelParseAddress.Response linfo = (ModelParseAddress.Response) JSON.deserialize(resp, ModelParseAddress.Response.class);
        responseList.add(linfo);
        return responseList;
    }
}