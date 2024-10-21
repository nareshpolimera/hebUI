@isTest
global class AppraisalOrderErrorsMockCallout implements HttpCalloutMock {
    // Implement this interface method; returns a successful message for creating a BP record in SAP
    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"ReferenceID": "20230120612", "IsSuccessful": true, "AppraisalProduct": "NVIP-Flex", "AppraisalProductChangedOn": "2020-08-17T03:57:53.4690101-04:00", "OrderStatus": "Appraisal Required", "OrderStatusChangedOn": "2020-08-17T03:57:53.4690101-04:00", "Notes": [ { "Text": "Appraisal Fee Breakdown: Total Appraisal Fee: $375.00 Customer cost: $0.00 HEB cost: $375.00", "Type": "Appraisal Note", "EnteredOn": "2020-08-17T03:57:24.0402468-04:00", "EnteredBy": "pta" }, { "Text": "Dev testing with TestClient: [Appraisal/OrderAppraisal] [08/16/2020 12:07:48 PM]", "Type": "Appraisal Note", "EnteredOn": "2020-08-17T03:57:24.0402468-04:00", "EnteredBy": "pta" } ], "Errors": ["Error String 1", "Error String 2"] }');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
}