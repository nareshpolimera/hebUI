@isTest
global class PhoneValidationRequestMockCallout implements HttpCalloutMock {
    
    // Implement this interface method; returns a successful message for phone validation
    global HTTPResponse respond(HTTPRequest req) {

        ModelPhoneValidation.Phone p =   (ModelPhoneValidation.Phone) JSON.deserialize(req.getBody(), ModelPhoneValidation.Phone.class);
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "id": "'+p.Id+'", "phoneNumber": "6478509875", "status": "Valid", "validatedOn": "2022-09-15T12:17:20.0335686-04:00", "lineType": "Mobile",  "smsAddress": null}');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    
    }
}