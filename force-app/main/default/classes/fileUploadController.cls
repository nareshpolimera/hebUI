public without sharing class fileUploadController {
    
    // Method to return all the Document Classification records on load of the component
    @AuraEnabled
    public static list<Document_Classification__c> getDocumentClassificationRecords(){
        list<Document_Classification__c> documentClassificationRecords = new list<Document_Classification__c>();   
        try {
            documentClassificationRecords = [SELECT Id, Document_Type__c, Related_Entity__c, External_ID__c 
                                             FROM Document_Classification__c
                                             WHERE Expired__c != true ORDER BY Document_Type__c];
         
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
        return documentClassificationRecords;
    }
    
    @AuraEnabled
    public static list<Account> getRelatedPropertyMemberRecords(String oppId){
       
        list<Account> relatedPropertyMemberRecords = new list<Account>();
        try {
            Opportunity fileRecord = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId];
            relatedPropertyMemberRecords = [SELECT Id, Name, Opportunity__pc 
                                            FROM Account 
                                            WHERE Id = :fileRecord.AccountId];                                
            
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage()); }
    
        return relatedPropertyMemberRecords;
    }

    @AuraEnabled
    public static list<LoanApplicant> getRelatedApplicantRecords(String oppId){
       
        list<ResidentialLoanApplication> relatedApplicationRecord = new list<ResidentialLoanApplication>();
        list<LoanApplicant> relatedApplicantRecords = new list<LoanApplicant>();
        try {            
            relatedApplicationRecord = [SELECT Id FROM ResidentialLoanApplication
                                  WHERE OpportunityId = :oppId];

            relatedApplicantRecords = [SELECT Id, Name  
                                            FROM LoanApplicant  
                                            WHERE LoanApplicationId IN :relatedApplicationRecord];                                
           
        } catch (Exception e) {   throw new AuraHandledException(e.getMessage()); }
    
        return relatedApplicantRecords;
    }
    
    @AuraEnabled
    public static list<LoanApplicationLiability> getRelatedDebtRecords(String oppId){
       
        list<ResidentialLoanApplication> relatedApplicationRecord = new list<ResidentialLoanApplication>();
        list<LoanApplicationLiability> relatedDebtRecords = new list<LoanApplicationLiability>();
        try {            
            relatedApplicationRecord = [SELECT Id FROM ResidentialLoanApplication
                                  WHERE OpportunityId = :oppId];

            relatedDebtRecords = [SELECT Id, Name, LoanApplicationId, LoanType, Debt_Identifier__c 
                                  FROM LoanApplicationLiability 
                                  WHERE LoanApplicationId  IN :relatedApplicationRecord];
                                  
          
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
    
        return relatedDebtRecords;
    }
    
    @AuraEnabled
    public static list<Appraisal__c> getRelatedAppraisalRecords(String oppId){
    
        list<Appraisal__c> relatedAppraisalRecords = new list<Appraisal__c>();
        try {
            relatedAppraisalRecords = [SELECT Id, Name, File__c, Appraisal_Product__c, Appraised_On__c, Active__c 
                                        FROM Appraisal__c 
                                        WHERE File__c = :oppId AND Active__c = true] ;
           
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
    
        return relatedAppraisalRecords;
    }
    
    @AuraEnabled
    public static list<LoanApplicationProperty> getRelatedPropertyRecords(String oppId){
      
        Lead leadRecord = new Lead();
        list<ResidentialLoanApplication> relatedApplicationRecord = new list<ResidentialLoanApplication>();
        list<LoanApplicationProperty> relatedPropertyRecord = new list<LoanApplicationProperty>();       
        
        try {
                relatedApplicationRecord = [SELECT Id FROM ResidentialLoanApplication
                                            WHERE OpportunityId = :oppId];
    
                relatedPropertyRecord = [SELECT Id, Name, Property_Type__c, Property_Identifier__c,Propertystreet,Propertystate,PropertypostalCode,Propertycountry,Propertycity
                                          FROM LoanApplicationProperty 
                                          WHERE LoanApplicationId IN :relatedApplicationRecord];
            
           
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
    
        return relatedPropertyRecord;
    }
    
    @AuraEnabled
    public static list<Lead> getLeadRecords(String leadId){

        list<Lead> listRecord = new list<Lead>();
        try {
                    listRecord = [SELECT Id, LastName, FirstName  
                                  FROM Lead 
                                  WHERE Id = :leadId];
                    
          
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
    
        return listRecord;
    }
    
    @AuraEnabled
    public static list<Opportunity> getFileRecords(String oppId){
 
        list<Opportunity> listRecord = new list<Opportunity>();
        try {                   
                    listRecord = [SELECT Id, Name//remove, File_Number__c 
                                  FROM Opportunity 
                                  WHERE Id = :oppId];
         
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());  }
    
        return listRecord;
    }
    
    @AuraEnabled
    public static HEB_App_Setting__mdt getFileProperties(){
        HEB_App_Setting__mdt fileProperites = [SELECT Id, DeveloperName, File_Upload_Limit__c, Accepted_File_Extension__c   FROM HEB_App_Setting__mdt LIMIT 1];
    
        return fileProperites;
    }
        
    // Code related to saving document into salesforce
    
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId, String documentType, String relatedEntity) {
        
            ContentVersion cv = createContentVersion(base64, filename, documentType, relatedEntity);
            ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
            if (cv == null || cdl == null) { return null; }
            return cdl.Id;
      }
    
    private static ContentVersion createContentVersion(String base64, String filename, String documentType, String relatedEntity) {
            String relatedTo;
            String relatedName;
 
            if(relatedEntity.startsWith('001')){
                relatedTo = 'Account';
                relatedName = [SELECT Name FROM Account WHERE ID = :relatedEntity].Name;
            }
            else if(relatedEntity.startsWith('003')){
                relatedTo = 'Contact';
                relatedName = [SELECT Name FROM Contact WHERE ID = :relatedEntity].Name;
            }
            else if(relatedEntity.startsWith('0ch')){
                relatedTo = 'LoanApplicationLiability';
                relatedName = [SELECT Debt_Identifier__c FROM LoanApplicationLiability WHERE ID = :relatedEntity].Debt_Identifier__c;
            }
            else if(relatedEntity.startsWith('0cU')){
                relatedTo = 'LoanApplicant';
                relatedName = [SELECT Name FROM LoanApplicant WHERE ID = :relatedEntity].Name;
            }
            else if(relatedEntity.startsWith('a87')){
                relatedTo = 'Appraisal__c';
                relatedName = [SELECT Appraisal_Product__c FROM Appraisal__c WHERE ID = :relatedEntity].Appraisal_Product__c;
            }
            else if(relatedEntity.startsWith('0cP')){ 
                relatedTo = 'LoanApplicationProperty';
                LoanApplicationProperty  lapRecord = [SELECT Id, Name, Property_Identifier__c,Propertystreet,Propertystate,PropertypostalCode,Propertycountry,Propertycity FROM LoanApplicationProperty WHERE ID = :relatedEntity];
                relatedName = lapRecord.Propertystreet +' '+ lapRecord.Propertycity +' '+  lapRecord.Propertystate +' '+ lapRecord.PropertypostalCode +' '+ lapRecord.PropertyCountry; 
                if(relatedName.length() >= 200){  relatedName = relatedName.subString(0,200);  }
            }
            else if(relatedEntity.startsWith('006')){
                relatedTo = 'Opportunity';
                Opportunity ld = [SELECT Id, Name/*remove, File_Number__c*/, File_Identifier__c FROM Opportunity WHERE ID = :relatedEntity];
            
                relatedName = ld.File_Identifier__c;
            }
    
            Document_Classification__c DC = [SELECT Id,Document_Type__c, External_ID__c, Expired__c 
                                             FROM Document_Classification__c
                                             WHERE Document_Type__c =:documentType ];
    
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(base64);
            cv.Title = filename;
            cv.PathOnClient = filename;
            cv.Document_Type__c = documentType;    
            cv.Related_Entity__c = relatedTo;      
            cv.Related_Entity_ID__c = relatedEntity;    
            cv.Related_Entity_Name__c = relatedName;    
            cv.External_ID__c = DC.External_ID__c; 
            try {
                insert cv;
                return cv;
            } catch(DMLException e) {   return null; }
      }  
        
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
            if (contentVersionId == null || recordId == null) { return null; }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId 
                                    FROM ContentVersion 
                                    WHERE Id =: contentVersionId].ContentDocumentId;
            cdl.LinkedEntityId = recordId;
     
            cdl.ShareType = 'I';
            try {
                insert cdl;
                return cdl;
            } catch(DMLException e) {  return null; }
        }
    }