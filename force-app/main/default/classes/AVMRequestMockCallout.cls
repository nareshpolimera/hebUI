@isTest
global class AVMRequestMockCallout implements HttpCalloutMock {
    // Implement this interface method; returns a successful message for creating a BP record in SAP
    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "OrderedFrom": "FCT", "ReferenceID": "20230120613", "IsSuccessful": true, "AVMValue": 635000.0, "LowerValueLimit": 587000.0, "UpperValueLimit": 682000.0,"ConfidenceRating": "Medium","Errors": []}');
        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
}