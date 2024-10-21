public without sharing class BDMService {

    public BDMService(){

    }

    public static void shareRecordswithBDM ( Map<Id, sObject> newMap, Schema.sObjectType sObjectType )
    {

        
    }

    public static String quotedRecordString( Set<Id> recordIds )
    {
        List<String> quotedRecordIds = new List<String>();
        for ( Id recordId : recordIds )
        {
            quotedRecordIds.add( '\'' + String.valueOf( recordId ) + '\'' );
        }

        return String.join( quotedRecordIds, ',' );
    }
}