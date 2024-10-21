public with sharing class RFUtils {
    public static String getRecordId(sObject record){
        //describe record
        String nameField = getNameField(record);
        if(record.Id != null){
            return record.Id;
        }
        else if(record.get(nameField) != null){
            return (String)record.get(nameField);
        }
        else{
            return 'NO_ID_FOUND';
        }
    }

    private static string getNameField(sObject record){
        Schema.sObjectType rType = record.getSObjectType();
        if(Schema.Case.getSObjectType() == rType){
            return 'CaseNumber';
        }
        else if(Schema.Contract.getSObjectType() == rType){
            return 'ContractNumber';
        }
        else{
            return 'Name';
        }
    }
}