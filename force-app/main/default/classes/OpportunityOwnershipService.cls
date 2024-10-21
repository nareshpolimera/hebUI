/* **************************************************************************
* Service: OpportunityOwnershipService
* Created by Joel Ojeda, August 13, 2024
*
* Purpose/Methods: Service class to manage ownership of opportunity and its child records
*
* Unit Test: OpportunityOwnershipServiceTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public with sharing class OpportunityOwnershipService {

    //for unit test purporse
    @TestVisible
    private static boolean throwError = false;
    
    public static void processRelatedRecordsOwnership(Map<Id, Opportunity> oppMap){
        processRelatedRecordsOwnership(oppMap,false);
    }

    public static void processRelatedRecordsOwnership(Map<Id, Opportunity> oppMap,  boolean retry) {
        //log in case of error
        Logger theLogger = new Logger('OpportunityOwnershipService');

        List<Appraisal__c> appraisalList = new List<Appraisal__c>();
        List<Appraisal_Order__c> apprOrderList = new List<Appraisal_Order__c>();
        List<Credit_Report__c> creditReportList = new List<Credit_Report__c>();
        List<ResidentialLoanApplication> applicationsList = new List<ResidentialLoanApplication>();
        
        if(oppMap == null || oppMap.isEmpty()){
            return;
        }

        //get child records by Opportunity
        for (Opportunity file : [ SELECT Id, OwnerId,
                                        (SELECT Id, OwnerId FROM Lending_Applications)
                                        FROM Opportunity
                                        WHERE Id IN :oppMap.keySet()]){
            //applications
            if(file.Lending_Applications != null && !file.Lending_Applications.isEmpty()){
                for(ResidentialLoanApplication application : file.Lending_Applications){
                    if(application.OwnerId != file.OwnerId){
                        application.OwnerId = file.OwnerId;
                        applicationsList.add(application);
                    }
                }
            }
                        
        }
        System.debug('[OpportunityOwnershipService] - processRelatedRecordsOwnership - applicationsList:'+applicationsList.size());

        //get Appraisal by Opportunity
        for (Appraisal__c appraisal : [SELECT Id,
                                            Application__r.Opportunity.OwnerId,
                                            OwnerId
                                            FROM Appraisal__c
                                            WHERE Application__c != null AND
                                            Application__r.OpportunityId != null AND
                                            Application__r.OpportunityId = :oppMap.keySet()]){
            if (appraisal.OwnerId != appraisal.Application__r.Opportunity.OwnerId){
                appraisal.OwnerId = appraisal.Application__r.Opportunity.OwnerId;
                appraisalList.add(appraisal);
            }
        }
        System.debug('[OpportunityOwnershipService] - processRelatedRecordsOwnership - appraisalList:'+appraisalList.size());

        //get Appraisal Orders by Opportunity
        for (Appraisal_Order__c apprOrder : [SELECT Id,
                                            Appraisal__c,
                                            Appraisal__r.Application__r.Opportunity.OwnerId,
                                            OwnerId
                                            FROM Appraisal_Order__c
                                            WHERE Appraisal__c != null AND
                                            Appraisal__r.Application__c != null AND
                                            Appraisal__r.Application__r.OpportunityId != null AND
                                            Appraisal__r.Application__r.OpportunityId = :oppMap.keySet()]){
            if (apprOrder.OwnerId != apprOrder.Appraisal__r.Application__r.Opportunity.OwnerId){
                apprOrder.OwnerId = apprOrder.Appraisal__r.Application__r.Opportunity.OwnerId;
                apprOrderList.add(apprOrder);
            }
        }
        System.debug('[OpportunityOwnershipService] - processRelatedRecordsOwnership - apprOrderList:'+apprOrderList.size());

        // Credit Report
        for (Credit_Report__c creditReport : [SELECT Id,
                                                Loan_Applicant__r.LoanApplication.Opportunity.OwnerId,
                                                OwnerId
                                                FROM Credit_Report__c
                                                WHERE Loan_Applicant__c != null AND
                                                Loan_Applicant__r.LoanApplicationId != null AND 
                                                Loan_Applicant__r.LoanApplication.OpportunityId != null AND
                                                Loan_Applicant__r.LoanApplication.OpportunityId IN :oppMap.keySet()]) {
            if (creditReport.OwnerId != creditReport.Loan_Applicant__r.LoanApplication.Opportunity.OwnerId) {
                creditReport.OwnerId = creditReport.Loan_Applicant__r.LoanApplication.Opportunity.OwnerId;
                creditReportList.add(creditReport);
            }
        }
        System.debug('[OpportunityOwnershipService] - processRelatedRecordsOwnership - creditReportList:'+creditReportList.size());
        
        Boolean reassignmentError = false;
        reassignmentError = saveList(applicationsList,theLogger,'ResidentialLoanApplication');
        reassignmentError = saveList(appraisalList,theLogger,'Appraisal__c');
        reassignmentError = saveList(apprOrderList,theLogger,'Appraisal_Order__c');
        // Temp fix for CreditReport ownership change - Suppress the error indicator change. June 14, 2021
        saveList(creditReportList,theLogger,'Credit_Report__c');
        
        // if there was an eror reassigning any of the records, queue up a retry
        if (reassignmentError) {
            //save log
            LoggerDMLService.saveLog(theLogger);

            //retry if enabled
            if(retry){
                List<Id> oppIds = new List<Id>();
                oppIds.addAll(oppMap.keySet());
                OpportunityOwnershipRetry updateJob = new OpportunityOwnershipRetry(oppIds);
                ID jobID = System.enqueueJob(updateJob);
            }
        }
    }

    private static boolean saveList(List<sObject> recordsToSave,Logger theLogger, string context){        
        try {
            //for unit test purporse
            if(Test.isRunningTest() && throwError){
                throw new DmlException('My custom error');
            }

            update recordsToSave;
            return false;
        } catch (Exception e) {
            system.debug(e.getMessage());
            //log
            theLogger.info('{0} | Error to set owner | {1}.', 
                            new Object[] {context,e.getMessage() + '. '+ e.getStackTraceString()});
        }
        return true;
    }
}