public with sharing class AutomatedNameGenerator {
    
    public static final Integer ZERO_PADDING_COUNT = 8;
    
    public static final Map<SobjectType, String> typeToPrefixMap = new Map<SobjectType, String>
    {
        ResidentialLoanApplication.SobjectType =>  'LA-',
        LoanApplicationProperty.SObjectType =>  'AP-',
        LoanApplicationLiability.SObjectType =>  'AL-',
        LoanApplicationFinancial.SobjectType =>  'LAF-',
        LoanApplicant.SObjectType =>  'PM-',
        ContactPointTypeConsent.SObjectType =>   'CC-' 
    };

    private static boolean isValidToSetName(SObject record){
        if(record == null){
            return false;
        }
        
        if(record.get('Name') == null ||
            String.isEmpty((String)record.get('Name'))){
            return true;
        }

        return false;
    }

    public static void generateNextSequenceName(List<SObject> records, SobjectType pType) 
    {
        if (records.isEmpty() || pType == null) {
            return;
        }

        //get list of valid records to set name
        List<SObject> validRecords = new List<Sobject>();
        for(SObject record : records){
            if(isValidToSetName(record)){
                validRecords.add(record);
            }
        }   
        System.debug('[AutomatedNameGenerator] generateNextSequenceName  validRecords: ' + validRecords);

        if(validRecords.isEmpty()){
            return;
        }

        String query = buildQuery(pType);
        Integer prefix;
        List<SObject> latestRecord;
        try {
            latestRecord = Database.query(query);
        } 
        catch (Exception ex) {
            System.debug('An error occured while retrieving the records : ' + ex.getMessage());
        }

        if (latestRecord == null || latestRecord.isEmpty() || latestRecord[0].get('Generated_Number__c') == null) {
            // If query can't find previousRecord, then GeneratedNumber__c for the new record should be 1
            prefix = 1;
        } else {
            prefix = Integer.valueOf(latestRecord[0].get('Generated_Number__c'));
            prefix++;
        }
        
        for (SObject record : validRecords) {
            String newName = typeToPrefixMap.get(pType) + Utils.padInteger(prefix, ZERO_PADDING_COUNT);
            record.put('Name', newName);
            record.put('Generated_Number__c', prefix);
            prefix++;
        }
    }

    @TestVisible
    private static String buildQuery(SObjectType pType) 
    {
        String query = 'SELECT Generated_Number__c FROM ';
        query += String.valueOf(pType);
        query += ' WHERE Generated_Number__c != null OR Generated_Number__c = 0';
        query += ' ORDER BY Generated_Number__c Desc';
        query += ' LIMIT 1';

        return query;
    }
}