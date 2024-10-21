public class OpportunitySendEmailController {
    @AuraEnabled(cacheable=false)
    public static Boolean createMarsRecord(String recordId, String type){
        Opportunity opp = [SELECT Id FROM Opportunity where id =: recordId limit 1];
        List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
        requests.add(new MARSPlatformEventService.Request(
            opp,
            type,
            MARSPlatformEventService.ACTION_UPDATE,
            MARSPlatformEventService.SNAIL_MAIL_ACTION
        ));      
        Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
        return errorOccurred;
    }
}