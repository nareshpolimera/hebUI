/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 07-09-2021
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log 
* Ver   Date         Author                               Modification
* 1.0   07-09-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
* @revision   2024-05-14 Xiomara Hernandez
Porting from legacy SF org.
**/
public without sharing class LoanApplicationPropertyService {

    public static Boolean bypassThisTrigger = false;
    /*
    * HEB-405: Update method to run for all users, and flag record if Property FSA is valid (used later in File Validation)
    */
    public void validatePropertyLendingArea ( List<LoanApplicationProperty> propertyRecords, Map<Id, LoanApplicationProperty> oldRecords )
    {
        Set<String> fsaSet          = new Set<String>();
        Set<String> citySet         = new Set<String>();
        
        for ( LoanApplicationProperty property : propertyRecords )
        {
            String fsa = Utils.fsaCode( property.PropertyPostalCode );
            
            if ( fsa <> '' )               fsaSet.add( fsa );
            if ( property.PropertyCity <> '' ) citySet.add( property.PropertyCity );
        }
        
        Set<String> validFSAKey = validFSAValues( fsaSet, citySet );
        
        for ( LoanApplicationProperty property : propertyRecords ) 
        {

            	String fsa = Utils.fsaCode( property.PropertyPostalCode );
            	String propertyFSAKey = fsaKeyGenerator( fsa, property.PropertyCity );
            	property.Valid_FSA__c = validFSAKey.contains( propertyFSAKey );

            // Allowing Integation user and System Admin to bypass validation
            // do not execute if the Owner is being changed as a reassignment from Call Centre to Specialist
            if ( 
                !Utils.allowBypassForUser() && 
                !validFSAKey.contains( propertyFSAKey ) && 
                (
                    oldRecords == null //||
                    //oldRecords.get(property.Id).OwnerId == property.OwnerId
                ) && !property.CreatedFromLeadUI__c
            ) {
                property.addError(Label.Error_Invalid_PostalCode_City);
            }
        }
        setCreatedFromNewLeadUItoFalse(propertyRecords);
    }
    
    // Get the valid FSA and City combinations from the table based on the fsa and city
    public static Set<String> validFSAValues ( Set<String> fsaSet, Set<String> citySet )
    { 
        Set<String> validFSAKey = new Set<String>();
        for ( FSA__c fsa : [
            SELECT Id
            , FSA__c
            , City__c
            FROM FSA__c
            WHERE Is_Active__c = true // only active FSA
            AND FSA__c IN: fsaSet
            AND City__c IN: citySet
        ]
            ) {
                String key = fsaKeyGenerator( fsa.FSA__c, fsa.City__c );
                validFSAKey.add( key );
            }
        
        return validFSAKey;
    }
    
    public static String fsaKeyGenerator ( String fsa, String city )
    {
        String key = (fsa + '-' + city).toUpperCase() ;
        return key;
    }
    
    public void checkRequote(List<LoanApplicationProperty> records, Map<Id, LoanApplicationProperty> oldRecords)
    {
        // do not run for Integration user; MARS will update the flag directly when all related records complete
        if(Utils.isIntegrationUser())
            return;
        
        Set<String> fieldsToCheck = Utils.getFieldSetFields(Schema.SObjectType.LoanApplicationProperty.fieldSets.Influences_Quote.getFields());
        List<LoanApplicationProperty> ps = (List<LoanApplicationProperty>) Utils.getChangedObjects(records, oldRecords, fieldsToCheck);
        Set<Id> relatedOpps = new Set<Id> ();
        Set<Id> relatedApps = new Set<Id> ();
        for (LoanApplicationProperty record : ps) {
            relatedApps.add(record.LoanApplicationId);
        }
        
        map<Id,ResidentialLoanApplication> opps = new map<Id,ResidentialLoanApplication>([select id,OpportunityID from ResidentialLoanApplication where id in : relatedApps]);
        for(ResidentialLoanApplication app : opps.values()){
            relatedOpps.add(app.OpportunityID);
        }
        
        List<Opportunity> ls = [
            SELECT Id, Quote_Parameters_Updated__c
            FROM Opportunity
            WHERE Quote_Parameters_Updated__c = FALSE            
            AND Id IN :relatedOpps            
        ];
        for (Opportunity l : ls)
        {
            l.Quote_Parameters_Updated__c = true;
        }
        update ls;
    }
    
    
    @AuraEnabled
    public static LoanApplicationProperty getFileProperty(Id propertyId) {
        try {
            return [
                SELECT Id, PropertyStreet , PropertyCity,PropertyState, PropertyPostalCode 
                FROM LoanApplicationProperty 
                WHERE Id = :propertyId
            ];
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
        return null;
    }
    
    public static void setCreatedFromNewLeadUItoFalse(List<LoanApplicationProperty> records){
        for(LoanApplicationProperty property: records){
            property.CreatedFromLeadUI__c=false;
        }
    }
    
    public void updateTDSR(
        List<LoanApplicationProperty> records,
        Map<Id, LoanApplicationProperty> oldRecords
    ) {
        if (
            !TDSRCalculationService.runTDSROnce &&
            !System.isFuture() &&
            !System.isBatch() &&
            !Test.isRunningTest()
        ) {
            Set<String> fieldsToCheck = new Set<String>{
                'Annual_Property_Taxes__c',
                    'Fire_Insurance_Premium__c'
                    };
                        List<LoanApplicationProperty> pms = (List<LoanApplicationProperty>) Utils.getChangedObjects(
                            records,
                            oldRecords,
                            fieldsToCheck
                        );
            Set<Id> oppIds = new Set<Id>();
            Map<Id, String> appIds = new Map<Id, String>();
            for (LoanApplicationProperty record : pms) {
                oppIds.add(record.LoanApplication.OpportunityId);
                appIds.put(
                    record.LoanApplication.OpportunityId,
                    record.LoanApplicationId
                );
            }
            
            for (String oppId : oppIds) {
                TDSRCalculationService.runTDSROnce = true;
                TDSRCalculationService.runTDSRCalculation(
                    oppId,
                    appIds.get(oppId)
                );
            }
        }
    }
    
    /** HEB- When new application property is inserted a new quote is requested */
    public void updateQuote(
        List<LoanApplicationProperty> records,
        Map<Id, LoanApplicationProperty> oldRecords
    ) {
        if (System.isBatch())
            return;
        
        if (
            FeatureManagement.checkPermission(
                Utils.CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD
            )
        )
            return;
        
        //Return early if this is a mass update
        if (records.size() > 1)
            return;
        
        // Prevents future recursion
        if (system.isFuture())
            return;

        //validate if quote request must be skipped
        if(QuoteRequestManager.doSkipQuoteService()){
            return;
        }
        
        //get newly created Property
        LoanApplicationProperty newLoanApplicationProperty = oldRecords == null ? records[0] : null;
        
        //get Opportunity Out of the property
        ResidentialLoanApplication app = [SELECT OpportunityId, Opportunity.Quote_Parameters_Updated__c
                                          FROM ResidentialLoanApplication 
                                          WHERE id = :newLoanApplicationProperty.LoanApplicationId];
        
        
        if(app != null && app.OpportunityId != null && !Test.isRunningTest()) {
            QuoteRequestValidationController.getQuoteForTrigger(app.opportunityId);
        }
    }

    //Method to auto-generate Name
    //Format: AP-00000001
    public void generateAutoName(List<LoanApplicationProperty> records) {
        AutomatedNameGenerator.generateNextSequenceName(records, LoanApplicationProperty.SobjectType);
    }

    public void fileValidation(List<LoanApplicationProperty> records) {
        LeadService lService = new LeadService();
        List<Id> fileIDs = new List<Id>();
        List<Id> appIds = new List<Id>();

        for (LoanApplicationProperty record : records) {
            appIds.add(record.LoanApplicationId);
        }

        map<Id,ResidentialLoanApplication> opps = new map<Id,ResidentialLoanApplication>([select id,OpportunityID from ResidentialLoanApplication where id in : appIds]);
        for(ResidentialLoanApplication app : opps.values()){
          fileIDs.add(app.OpportunityId);
        }
        if (fileIDs.size() == 1) {
            List<Opportunity> fileList = [
                SELECT
                    id,
                    Product_Rate_Set__c,
                    PRS_Current__c,
                    PQS_Current__c,
                    Product_Quote_Set__c,
                    Additional_File_Validation_Error__c,
                    Warning_Message__c,
                    Mismatch_Acknowledgement__c
                FROM Opportunity
                WHERE Id IN :fileIDs
            ];

            new LoanApplicantService().additionalFileValidation(fileList);
            update fileList;
        }
    }

    public void useAvm(List<LoanApplicationProperty> records,
                        Map<Id,LoanApplicationProperty> oldRecords
                        ) {
           
        Map<Id,double> filteredApps = new Map<Id,double>();
        Map<Id,Id> opportunitiesIds = new Map<Id,Id>();

        for (LoanApplicationProperty record : records) {
            boolean ischanged = record.Use_AVM_Value__c != oldRecords.get(record.id).Use_AVM_Value__c ||
            record.AVM_Value__c != oldRecords.get(record.id).AVM_Value__c;
            if(record.Use_AVM_Value__c && ischanged){
                if(!filteredApps.containskey(record.LoanApplicationId))
                    filteredApps.Put(record.LoanApplicationId,record.AVM_Value__c);
            }
        }


        for(ResidentialLoanApplication application : [SELECT opportunityId 
                                                         FROM ResidentialLoanApplication 
                                                         WHERE Id in :filteredApps.keySet()]){
                opportunitiesIds.put(application.opportunityId,application.Id);
        }


        List<Quote> quotesToUpdate = [SELECT id, Home_Value_for_Quote__c,OpportunityId
                                      FROM Quote
                                      WHERE IsSyncing = true
                                      AND opportunityId in :opportunitiesIds.keySet()
                                      FOR UPDATE];
                                      
        if(!quotesToUpdate.isEmpty()){
            for(Quote q : quotesToUpdate){
                Id identifier = opportunitiesIds.get(q.opportunityId); 
                q.Home_Value_for_Quote__c = filteredApps.get(identifier); 
            }
            bypassThisTrigger = true;
            update quotesToUpdate ;
            bypassThisTrigger = false;
        }
         
    }

    //Start code to Avoid recursion
    private static final Map<String, Set<Id>> processedRecords = new Map<String, Set<Id>>();
 
    public static boolean runOnce(Set<Id> newRecordIds,Set<Id> oldRecordIds, TriggerOperation operation)
    {
        Set<Id>recordIds=newRecordIds;
        if(newRecordIds==null)
            recordIds=oldRecordIds;
        //
        if(recordIds==null)
            return false;
 
        for(Id recordId:recordIds)
        {
            if(validateRecursive(recordId,operation.name()))
            {
                return true;
            }
        }
        return false;
    }
 
    private static boolean validateRecursive(Id recordId,String operation){
        Boolean recursive=false;
        if(processedRecords.containsKey(operation))
        {
            Set<Id> records=processedRecords.get(operation);
            if(records.contains(recordId))
            {
                recursive=true;
                return recursive;
            }
            records.add(recordId);
        }
        else{
            Set<Id> records=new Set<Id>();
            records.add(recordId);
            processedRecords.put(operation, records);
        }
        return recursive;
    }
}