public without sharing class displayUploadedFilesController {
    @AuraEnabled 
    public static list<ContentVersion> fetchFiles(String recordId){
        Set<ID> relatedEntityIds = new Set<ID>();
        List<LoanApplicant> loanApplicationRec = new List<LoanApplicant>();
        List<LoanApplicationProperty> loanApplicationPropRec = new List<LoanApplicationProperty>();
        list<LoanApplicationLiability> relatedDebtRecords = new list<LoanApplicationLiability>();
        list<ID> documentIDList = new list<ID>();
        list<Appraisal__c> appraisalList = new list<Appraisal__c>();
        list<ContentDocumentLink> contentDocumentLinkRecords = new list<ContentDocumentLink>();
        list<ContentVersion> contentVersionRecords = new list<ContentVersion>();
        List<ResidentialLoanApplication> applicationRec = [Select Id, OpportunityId from ResidentialLoanApplication where OpportunityId =: recordId Order by CreatedDate DESC];    
        if (applicationRec.size() > 0){
            loanApplicationRec = [Select Id, Role__c, LoanApplicationId from LoanApplicant where LoanApplicationId IN :applicationRec Order by CreatedDate]; 
            loanApplicationPropRec = [Select Id from LoanApplicationProperty where LoanApplicationId IN :applicationRec Order by CreatedDate]; 
            relatedDebtRecords = [SELECT Id, Name, LoanApplicationId, LoanType, Debt_Identifier__c FROM LoanApplicationLiability WHERE LoanApplicationId  IN : applicationRec ];
            for(ResidentialLoanApplication a : applicationRec){relatedEntityIds.add(a.Id);}
        }
        relatedEntityIds.add(recordId);
        for(LoanApplicant pm : loanApplicationRec){
            relatedEntityIds.add(pm.id);
        }
        for(LoanApplicationProperty prop : loanApplicationPropRec){
            relatedEntityIds.add(prop.id);
        }
        list<Appraisal__c> relatedAppraisalRecords = [SELECT Id, Name, File__c, Appraisal_Product__c, Appraised_On__c, Active__c FROM Appraisal__c WHERE File__c = :recordId AND Active__c = true] ; 
        for(LoanApplicationLiability debt : relatedDebtRecords){
            relatedEntityIds.add(debt.id);
        }
        for(Appraisal__c appraisal : relatedAppraisalRecords){
            relatedEntityIds.add(appraisal.id);
        }
        contentDocumentLinkRecords = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :relatedEntityIds];
        for(ContentDocumentLink cdLink : contentDocumentLinkRecords){
            documentIDList.add(cdLink.ContentDocumentId);
        }
        contentVersionRecords = [SELECT Id,Title ,ContentDocumentId, Document_Type__c, Related_Entity__c, External_ID__c, isLatest, CreatedDate,Related_Entity_ID__c,Related_Entity_Name__c,ContentDocument.FileType FROM ContentVersion WHERE ContentDocumentId IN :documentIDList AND isLatest = true AND ContentDocument.FileType != 'SNOTE' ];   
        return contentVersionRecords;
    }
    @AuraEnabled
    public static void deleteFiles(String contentVersionId){
        ContentVersion contentVersionRecord = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ID =:contentVersionId];  
        ContentDocument contentDocumentRecord = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentVersionRecord.ContentDocumentId];
        try{
            delete contentDocumentRecord;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }  
    }
}