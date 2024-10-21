//@IsTest
global class QuoteRequestMockCallout implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"fileNumber":"1809162","locationCode":"A","propertyTypeRating":"A","isDowngraded":false,"eot":8.4801,"ProductRateSetID":9876543,"RateCommitmentDate":"2021-03-12","ProductQuoteSetID":4321987,"QuoteCommitmentDate":"2021-05-01","productQuotes":[{"isSelected":true,"productType":"CHIP","term":"3-Year","rate":4.59,"amount":0,"isEligible":true,"ineligibleReason":"home value"},{"isSelected":false,"productType":"Income Advantage","term":"3-Year","rate":4.59,"amount":0,"isEligible":false,"ineligibleReason":"home value"}, {"isSelected":false,"productType":"CHIP Max","term":"3-Year","rate":5.89,"amount":0,"isEligible":true,"ineligibleReason":""},{"isSelected":false,"productType":"CHIP Open","term":"Variable","rate":6.45,"amount":0,"isEligible":false,"ineligibleReason":"home value"}]}');

        res.setStatusCode(IntegrationService.HTTP_OK);
        return res;
    }
    
}