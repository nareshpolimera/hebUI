public without sharing class CustomMetadataLWCServices {

    @AuraEnabled(cacheable=true)
    public static List<sObject> getCustomMetadata(String metadataName, String[] fields, String filters) {
        String query = 'SELECT {{fields}} FROM '+metadataName+ ' WHERE {{filters}}';

        //add fields
        query = query.replace('{{fields}}',String.join(fields,','));

        //add filters
        query = query.replace('{{filters}}',filters);

        if(Test.isRunningTest()){
			query = query + ' LIMIT 10';
		}

        List<sObject> results = Database.query(query);

        return results;
    }
    
}