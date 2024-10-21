global class QuoteRequestServiceMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"fileNumber":"12345","locationCode":"001","propertyTypeRating":"A","isDowngraded":false,"eot":"2023-12-31","productQuotes":[{"productType":"Test Product Type","term":"30 Years","rate":3.5,"amount":200000.00,"isEligible":true,"ineligibleReason":null}]}');
        res.setStatusCode(200);
        return res;
    }
}