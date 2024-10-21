public class ObjectsPicklistFieldValuesExporter {
    
    public static void exportPicklistFieldValues(String objectsApiNames){
        
        List<ContentVersion> csvFilesToInsert = new List<ContentVersion>();
        List<String> sObjectApiNamesList = new List<String>();

        for(String objectName : objectsApiNames.split(',')){
            sObjectApiNamesList.add(objectName.trim());
        }

        for (String sObjectApiName : sObjectApiNamesList) {
            System.debug('sObjectApiName ===>  '+ sObjectApiName  );
            SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectApiName);
            String fileName = sObjectApiName + '_PicklistValues';
            Map<String, List<String>> picklistValuesMap = new Map<String, List<String>>();
            List<String> picklistFields = new List<String>();
                        
            // Query Picklist Fields from Metadata
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            for (Schema.SObjectField field : fieldMap.values()) {

                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                    picklistFields.add(fieldDescribe.getName());
                }
            }

            // Query Picklist Values
            for (String fieldName : picklistFields) {
                
                Schema.SObjectField field = fieldMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

                List<String> picklistValues = new List<String>();
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    picklistValues.add(entry.getLabel());
                }
                picklistValuesMap.put(fieldName, picklistValues);
            }

            // Generate CSV File
            String csvContent = 'Field API Name,Picklist Values\n';
            for (String fieldName : picklistValuesMap.keySet()) {
                String picklistValues = '';
                List<String> picklistValuesList = picklistValuesMap.get(fieldName);

                for (Integer i = 0; i < picklistValuesList.size(); i++) {
                    if (i > 0) {
                        picklistValues += '; ';
                    }
                    picklistValues += picklistValuesList[i];
                }

                csvContent += fieldName + ',"' + picklistValues + '"\n';
            }

            // Add CSV File
            Blob csvBlob = Blob.valueOf(csvContent);
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName + '.csv';
            contentVersion.VersionData = csvBlob;
            csvFilesToInsert.add(contentVersion);
        }

        if(csvFilesToInsert != null && !csvFilesToInsert.isEmpty()){
            insert csvFilesToInsert;
        }
    }
}