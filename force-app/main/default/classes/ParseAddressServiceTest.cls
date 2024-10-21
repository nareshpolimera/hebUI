@isTest
public class ParseAddressServiceTest {
    
    @isTest
    static void testSendRequest() {
        // Create a mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new ParseAddressServiceMockCallout());
        
        // Create a sample address to pass to the method
        ModelParseAddress.Address address = new ModelParseAddress.Address();
        address.city = 'Anytown';
        
        List<ModelParseAddress.Address> addressList = new List<ModelParseAddress.Address>{ address };
        
        // Call the sendRequest method
        String responseBody = ParseAddressService.sendRequest(addressList);
        
        // Verify the response
        System.assertNotEquals(null, responseBody, 'Response body should not be null');
        System.assert(responseBody.contains('parsedAddress'), 'Response should contain parsedAddress');
    }
    
    @isTest
    static void testProcessResponse() {
        // Sample JSON response (mocked)
        String mockResponse = '{"street":"123 Main St","city":"Anytown","state":"CA","zip":"12345"}';
        
        // Call the processResponse method
        List<ModelParseAddress.Response> responseList = ParseAddressService.processResponse(mockResponse);
        
        // Verify the response
        System.assertNotEquals(0, responseList.size(), 'Response list should not be empty');
    }
    
    // Mock callout class for testing
    private class ParseAddressServiceMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Mock a response body similar to what the real service might return
            res.setBody('{"parsedAddress":{"street":"123 Main St","city":"Anytown","state":"CA","zip":"12345"}}');
            res.setStatusCode(200);
            return res;
        }
    }
}