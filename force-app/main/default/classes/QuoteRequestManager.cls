public with sharing class QuoteRequestManager {

    private static boolean SKIP_QUOTE_REQUEST_SERVICE = false;

    public static void startSkipQuoteService(){
        SKIP_QUOTE_REQUEST_SERVICE = true;
    }

    public static void stopSkipQuoteService(){
        SKIP_QUOTE_REQUEST_SERVICE = false;
    }

    public static boolean doSkipQuoteService(){
        return SKIP_QUOTE_REQUEST_SERVICE;
    }
}