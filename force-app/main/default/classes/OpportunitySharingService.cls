public without sharing class OpportunitySharingService {
    
    private boolean hasBDMChanged(Opportunity opp, Opportunity oldOpp){

        if(opp == null){
            return false;
        }

        if(oldOpp == null && 
            opp.BDM__c != null){
            return true;
        }

        if(oldOpp != null && 
            opp.BDM__c != oldOpp.BDM__c){
            return true; 
        }

        return false;
    }

    //Process Files to validate is record must be shared with BDM user
    //it will also delete old access when the BDM is changed to a new user
    public void processBDMSharing(List<Opportunity> records,Map<Id, Opportunity> oldMap){

        List<Opportunity> oldToRemove = new List<Opportunity>();
        List<Opportunity> newToShare = new List<Opportunity>();

        for(Opportunity opp : records){
            Opportunity oldOpp;
            if(oldMap != null){
                oldOpp = oldMap.get(opp.Id);
            }
            if(hasBDMChanged(opp,oldOpp)){
                newToShare.add(opp);
                if(oldOpp != null){
                    oldToRemove.add(oldOpp);
                }
            }
        }

        //create new sharing records
        createSharingRecords(newToShare);

        //delete old access for old records
        deleteSharingRecords(oldToRemove);
    }

    private void createSharingRecords(List<Opportunity> records){
        if(records == null || records.isEmpty()){
            return;
        }

        //check if users
        Set<String> existingShares = getBDMSharingKeys(records);

        List<OpportunityShare> oppSharetoInsert = new list<OpportunityShare>();

        for(Opportunity opp : records){         
            if(opp.BDM__c != null &&
                opp.BDM__c != opp.ownerId){
                String key = getSharingKey(opp.Id,opp.BDM__c);

                //create sharing record for users without access
                if(!existingShares.contains(key)){
                    OpportunityShare oppShare = new OpportunityShare();
                    oppShare.OpportunityId = opp.Id;
                    oppShare.UserOrGroupId = opp.BDM__c;
                    oppShare.OpportunityAccessLevel = 'Edit';
                    oppShare.RowCause = 'Manual';
                    oppSharetoInsert.add(oppShare);
                }
            }
        }
        
        if(!oppSharetoInsert.isEmpty()){
            insert oppSharetoInsert;
        }
    }

    private void deleteSharingRecords(List<Opportunity> records){
        if(records == null || records.isEmpty()){
            return;
        }

        //get opprtunity sharing records to delete
        List<OpportunityShare> oppShareToDelete = getBDMSharing(records,'Manual');
        
        if(!oppShareToDelete.isEmpty()){
            delete oppShareToDelete;
        }
    }

    private List<OpportunityShare> getBDMSharing(List<Opportunity> records, String cause){
        Set<Id> userIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        List<OpportunityShare> results = new List<OpportunityShare>();

        for(Opportunity opp : records){
            if(opp.BDM__c != null){
                oppIds.add(opp.Id);
                userIds.add(opp.BDM__c);
            }
        }

        //get opprtunity sharing records 
        results = [SELECT Id
                    FROM OpportunityShare
                    WHERE OpportunityId IN: oppIds AND 
                    UserOrGroupId IN :userIds AND
                    RowCause = :cause];
        return results;
    }

    private Set<String> getBDMSharingKeys(List<Opportunity> records){
        Set<Id> userIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<String> results = new Set<String>();

        for(Opportunity opp : records){
            if(opp.BDM__c != null){
                oppIds.add(opp.Id);
                userIds.add(opp.BDM__c);
            }
        }

        //get opprtunity sharing records 
        for(OpportunityShare oppShare : [SELECT Id, OpportunityId, UserOrGroupId
                                        FROM OpportunityShare
                                        WHERE OpportunityId IN: oppIds AND 
                                        UserOrGroupId IN :userIds]){
            String key = getSharingKey(oppShare.OpportunityId,oppShare.UserOrGroupId);
            results.add(key);          
        }
        return results;
    }

    private String getSharingKey(String recordId, String userId){
        return recordId.subString(15) + '_' + userId.subString(15);
    }
}