public class TokenService
{
    // Additional services outside of MARS will be added to this over time.
    public enum Target {MARS, MARS_CUSTOMER}
    
    public static String getToken(Target t)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getEndpoint(t));
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(IntegrationService.getTokenAuth(t));
        
        System.debug(getEndpoint(t));
        System.debug(IntegrationService.getTokenAuth(t));
        
        Http http = new Http();
        if (Test.isRunningTest()) 
            return 'a0b1c2d3e4f5';
        
        HTTPResponse res = http.send(req);
        return res.getBody();
    }

    public static String getEndpoint(Target t) {
        switch on t {
            when MARS {
                return IntegrationService.getEndpoint(IntegrationService.MARS_API.Authenticate_Token);
            }
            when MARS_CUSTOMER {
                return IntegrationService.getEndpoint(IntegrationService.MARS_API.Authenticate_Community_Token);
            }
        }
		return null;
    }

    public class TokenResponse {
        public String access_token;
        public String token_type;
        public Integer expires_in;
        public String refresh_token;
        public String userName;
        public Datetime issued;
        public Datetime expires;

        public TokenResponse() {
            access_token = '';
            token_type = '';
            expires_in = 0;
            refresh_token = '';
            userName = '';
            issued = null;
            expires = null;

        }
    }

}