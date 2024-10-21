@IsTest
global class ParseAddressMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        // Simulate a response from the ParseAddressService
        res.setBody('{"addresses":[{"Id":"1234567890","isSuccessful":"true","Address":{"UnitNumber":"1A","StreetNumber":"123","StreetName":"Test St","StreetType":"St","StreetDirection":"NW","City":"Test City","Province":"TS","PostalCode":"T3S 2A1"}}]}');
        return res;
    }
}