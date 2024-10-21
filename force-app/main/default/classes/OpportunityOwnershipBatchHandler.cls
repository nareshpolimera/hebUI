public class OpportunityOwnershipBatchHandler {

    public static String MARS_INTEGRATION_USER_ID = getMARSIntegrationUserId();
    
    public static void setOpportunityQueueToInitialContactQueue(List<Opportunity> opportunityRecords, OpportunityBatchProcessEnums.Process batchProcess){ 
        List<Opportunity> oppRecordsToUpdateOwnership = new List<Opportunity>();
        try{
            for(Opportunity oppRecord : opportunityRecords){

                Boolean ownerOrQueueNeedsUpdate = false;

                if(oppRecord.File_Queue__c != 'Initial Contact'){
                    oppRecord.File_Queue__c = 'Initial Contact';
                    ownerOrQueueNeedsUpdate = true;
                }
                
                if(String.isNotBlank(MARS_INTEGRATION_USER_ID) && oppRecord.OwnerId != MARS_INTEGRATION_USER_ID){
                    oppRecord.OwnerId = MARS_INTEGRATION_USER_ID;
                    ownerOrQueueNeedsUpdate = true;
                }

                if(ownerOrQueueNeedsUpdate){
                    oppRecord.File_Ownership_Update_Batch_Error__c = null;
                    oppRecord.File_Ownership_Update_Error_Code__c = null;

                    oppRecordsToUpdateOwnership.add(oppRecord);
                }
            }

            if(!oppRecordsToUpdateOwnership.isEmpty()){

                Database.SaveResult[] oppUpdateResults = Database.update(oppRecordsToUpdateOwnership, false);
                List<Opportunity> failedOppsToUpdate = new List<Opportunity>();

                for(Integer i=0; i<oppRecordsToUpdateOwnership.size(); i++){

                    Database.SaveResult result = oppUpdateResults[i];

                    if(!result.isSuccess()){

                        String errorMessage;
                        String errorCode = 'Error updating owner';

                        if(OpportunityBatchProcessEnums.Process.INACTIVE_OWNER == batchProcess){
                            errorCode = 'Inactive Owner Update Failed ';
                        }

                        if(OpportunityBatchProcessEnums.Process.DORMANT == batchProcess){
                            errorCode = 'Dormant Opportunity Update Failed ';
                        }

                        for(Database.Error err : result.getErrors()){
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());

                            errorMessage = 'Error occured while updating ownership to Intial Contact Queue: ' + err.getStatusCode() + ': ' + err.getMessage() + ' Field that affected this error: ' + err.getFields();

                        }

                        Opportunity oppRec = new Opportunity();
                        oppRec.Id = oppRecordsToUpdateOwnership.get(i).Id;
                        oppRec.File_Ownership_Update_Batch_Error__c = errorMessage;
                        oppRec.File_Ownership_Update_Error_Code__c = errorCode;
                        failedOppsToUpdate.add(oppRec);
                    }
                }

                if(!failedOppsToUpdate.isEmpty()){
                    Database.update(failedOppsToUpdate, false);
                }
            }

        }catch(Exception ex){
            System.debug('Exception in setOpportunityQueueToInitialContactQueue : ' + ex.getMessage() + ' Stack Trace : ' + ex.getStackTraceString());
        }
    }

    public static String getMARSIntegrationUserId(){
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();

        return ( settings != null ? settings.MARS_Integration_User_Id__c : null );
    }
}