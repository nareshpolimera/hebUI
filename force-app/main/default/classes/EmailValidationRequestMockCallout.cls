@isTest
global class EmailValidationRequestMockCallout implements HttpCalloutMock {
    // Implement this interface method; returns a successful message for email validation
    global HTTPResponse respond(HTTPRequest req) {
        if(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Email_Validation) !=  req.getEndpoint()){
            return null;
        }
        ModelEmailValidation.Email p =   (ModelEmailValidation.Email) JSON.deserialize(req.getBody(), ModelEmailValidation.Email.class);

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "Id": "'+p.Id+'", "isSuccessful": true, "validationStatus": "Unknown", "isDeliverable": false, "emailAddressIn": "dummy_email@heb.ca",  "emailAddressOut": "dummy_email@heb.ca", "validatedOn": "2022-09-15T12:17:20.0335686-04:00", "emailCorrected": false, "status": "Valid"}');        
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
}