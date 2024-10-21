public class FieldPermissions {

    public static void runPicklistFields(){
        /** Add API names of the objects. 
For eg: If you want to get picklist values for each picklist field type from Account, Case, LoanApplicationProperty and Credit_Assesment__c

List will be as below:

List<String> sObjectApiNames = new List<String>{'Account', 'Case', 'LoanApplicationProperty', 'Credit_Assesment__c' };

**/

List<String> sObjectApiNames = new List<String>{'Case'};

for (String sObjectApiName : sObjectApiNames) {
    SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectApiName);
    String fileName = sObjectApiName + '_PicklistValues';
                
    // Query Picklist Fields from Metadata
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> picklistFields = new List<String>();
    for (Schema.SObjectField field : fieldMap.values()) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            picklistFields.add(fieldDescribe.getName());
        }
    }

    // Query Picklist Values
    Map<String, List<String>> picklistValuesMap = new Map<String, List<String>>();
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
    String csvContent = 'Field Name,Picklist Values\n';
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

    // Upload CSV File
    Blob csvBlob = Blob.valueOf(csvContent);
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = fileName;
    contentVersion.PathOnClient = fileName + '.csv';
    contentVersion.VersionData = csvBlob;
    insert contentVersion;
}

    }

}