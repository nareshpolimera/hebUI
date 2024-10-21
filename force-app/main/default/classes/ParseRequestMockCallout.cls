@isTest
global class ParseRequestMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        if(IntegrationService.getEndpoint(IntegrationService.MARS_API.Address_Parse) !=  req.getEndpoint()){
            return null;
        }            
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"IsSuccessful": true, "Address": {"UnitNumber": "21", "StreetNumber": "3065", "StreetName": "LENESTER","StreetType": "DR", "StreetDirection": "", "City": "MISSISSAUGA","PostalCode": "L5C 2B8","Province": "ON" },"Errors": []}');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
    
}