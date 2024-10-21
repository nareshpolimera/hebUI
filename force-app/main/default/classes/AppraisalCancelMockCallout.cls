@isTest
global class AppraisalCancelMockCallout implements HttpCalloutMock {
    // Implement this interface method; returns a successful message for creating a BP record in SAP
    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"ReferenceID": "20230120612", "IsSuccessful": true, "OrderStatus": "Cancel Requested", "OrderStatusChangedOn": "2020-08-17T03:57:53.4690101-04:00", "Notes": [ { "Text": "HEB Appraisal Cancellation Request Reason: Client does not want to proceed", "Type": "Appraisal Note", "EnteredOn": "2020-08-17T03:57:24.0402468-04:00",  "EnteredBy": "pta" } ], "Errors": [] }');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
    
}