@isTest
global class AppraisalFeeMockCallout implements HttpCalloutMock {
    // Implement this interface method; returns a successful message for creating a BP record in SAP
    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "ReferenceID": "20230120612", "IsSuccessful": true, "Notes": [ { "Text": "Appraisal Fee Breakdown: Total Appraisal Fee: $375.00 Customer cost: $275.00 HEB cost: $100.00", "Type": "Appraisal Note", "EnteredOn": "2020-08-17T03:57:24.0402468-04:00", "EnteredBy": "pta" } ], "Errors": []}');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
    
    
}