@isTest
public class QuoteRequestServiceMockCalloutTest {
    
    @isTest
    static void testQuoteRequestServiceMockCallout() {
        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new QuoteRequestServiceMockCallout());
        
        // Create a HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/quote');
        req.setMethod('GET');
        
        // Perform the HTTP callout
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Verify the response
        System.assertEquals(200, res.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/json', res.getHeader('Content-Type'), 'Content-Type should be application/json');
        
        String expectedBody = '{"fileNumber":"12345","locationCode":"001","propertyTypeRating":"A","isDowngraded":false,"eot":"2023-12-31","productQuotes":[{"productType":"Test Product Type","term":"30 Years","rate":3.5,"amount":200000.00,"isEligible":true,"ineligibleReason":null}]}';
        System.assertEquals(expectedBody, res.getBody(), 'Response body should match the expected JSON');
        
        // Parse the JSON response to verify its structure and content
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        System.assertEquals('12345', responseMap.get('fileNumber'), 'File number should be 12345');
        System.assertEquals('001', responseMap.get('locationCode'), 'Location code should be 001');
        System.assertEquals('A', responseMap.get('propertyTypeRating'), 'Property type rating should be A');
        System.assertEquals(false, responseMap.get('isDowngraded'), 'isDowngraded should be false');
        System.assertEquals('2023-12-31', responseMap.get('eot'), 'EOT should be 2023-12-31');

        List<Object> productQuotes = (List<Object>) responseMap.get('productQuotes');
        System.assertEquals(1, productQuotes.size(), 'There should be one product quote');

        Map<String, Object> productQuote = (Map<String, Object>) productQuotes[0];
        System.assertEquals('Test Product Type', productQuote.get('productType'), 'Product type should be Test Product Type');
        System.assertEquals('30 Years', productQuote.get('term'), 'Term should be 30 Years');
        System.assertEquals(3.5, productQuote.get('rate'), 'Rate should be 3.5');
        System.assertEquals(200000.00, productQuote.get('amount'), 'Amount should be 200000.00');
        System.assertEquals(true, productQuote.get('isEligible'), 'isEligible should be true');
    }
}