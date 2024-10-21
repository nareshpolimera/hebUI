@isTest
global class ValidationsRequestMockCallout implements HttpCalloutMock {
    
    // Implement this interface method; returns a successful message for phone validation
    global HTTPResponse respond(HTTPRequest req) {
        if(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Phone_Validation) == req.getEndpoint()){
            ModelPhoneValidation.Phone p =   (ModelPhoneValidation.Phone) JSON.deserialize(req.getBody(), ModelPhoneValidation.Phone.class);
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "id": "'+p.Id+'", "phoneNumber": "6478509875", "status": "Valid", "validatedOn": "2022-09-15T12:17:20.0335686-04:00", "lineType": "Mobile",  "smsAddress": null}');
            res.setStatusCode(IntegrationService.HTTP_OK);
            return res;
        }      
        if(IntegrationService.getEndpoint(IntegrationService.MARS_API.Address_Parse) ==  req.getEndpoint()){
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"IsSuccessful": true, "Address": {"UnitNumber": "21", "StreetNumber": "3065", "StreetName": "LENESTER","StreetType": "DR", "StreetDirection": "", "City": "MISSISSAUGA","PostalCode": "L5C 2B8","Province": "ON" },"Errors": []}');
            res.setStatusCode(IntegrationService.HTTP_OK);
            return res;
        }
        if(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Email_Validation) ==  req.getEndpoint()){
            ModelEmailValidation.Email p =   (ModelEmailValidation.Email) JSON.deserialize(req.getBody(), ModelEmailValidation.Email.class);

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "Id": "'+p.Id+'", "isSuccessful": true, "validationStatus": "Unknown", "isDeliverable": false, "emailAddressIn": "dummy_email@heb.ca",  "emailAddressOut": "dummy_email@heb.ca", "validatedOn": "2022-09-15T12:17:20.0335686-04:00", "emailCorrected": false, "status": "Valid"}');        
            res.setStatusCode(IntegrationService.HTTP_OK);
            return res;
        }
        return null;
        
    }
}