public with sharing class OpportunityContactRoleService {
    private final String REFERRAL_PARTNER = 'Referral Partner';
    private final String SUBMISSION_AGENT = 'Submission Agent';

    private boolean isPrimaryReferral(OpportunityContactRole record, OpportunityContactRole oldRecord){
        if(record == null){
            return false;
        }

        if(oldRecord == null && 
            record.IsPrimary == true && 
            record.Role == REFERRAL_PARTNER){
            return true;
        }

        if(oldRecord != null && 
            record.IsPrimary == true && 
            record.IsPrimary != oldRecord.IsPrimary &&
            record.Role == REFERRAL_PARTNER){
            return true;
        }

        return false;
    }

    public void processPrimaryRole(List<OpportunityContactRole> records, 
                                            Map<Id, OpportunityContactRole> oldMap){
        Map<Id,Id> roleByOpp = new Map<Id,Id>();
        for(OpportunityContactRole ocr : records){
            OpportunityContactRole oldRecord;
            if(oldMap != null){
                oldRecord = oldMap.get(ocr.Id);
            }
            if(isPrimaryReferral(ocr,oldRecord)){
                roleByOpp.put(ocr.OpportunityId,ocr.id);
            }
        } 

        //find othe primary contact roles to deactivate
        List<OpportunityContactRole> rolesToUpdate = new List<OpportunityContactRole>();
        for(OpportunityContactRole ocr : [SELECT Id, IsPrimary, OpportunityId  
                                            FROM OpportunityContactRole 
                                            WHERE Id NOT IN :roleByOpp.values()
                                            AND OpportunityId IN :roleByOpp.keyset()
                                            AND IsPrimary = true
                                            AND Role = :REFERRAL_PARTNER]){
            if(roleByOpp.get(ocr.OpportunityId) != ocr.Id){
                ocr.IsPrimary = false;
                rolesToUpdate.add(ocr);
            }
        }
        if(!rolesToUpdate.isEmpty()){
            update rolesToUpdate;
        }
    }

    private boolean isSubmissionAgent(OpportunityContactRole record, OpportunityContactRole oldRecord){
        if(record == null){
            return false;
        }

        if(oldRecord == null && 
            record.Role == SUBMISSION_AGENT){
            return true;
        }

        if(oldRecord != null && 
            record.Role != oldRecord.Role &&
            record.Role == SUBMISSION_AGENT){
            return true;
        }

        return false;
    }

    public void updateOpportunity(List<OpportunityContactRole> records, 
                                    Map<Id, OpportunityContactRole> newMap){
        Map<Id,OpportunityContactRole> referralsMap = new Map<Id,OpportunityContactRole>();
        Map<Id,OpportunityContactRole> submissionMap = new Map<Id,OpportunityContactRole>();
        Set<Id> contactIds = new Set<Id>();
        for(OpportunityContactRole ocr : records){
            OpportunityContactRole oldRecord;
            if(newMap != null){
                oldRecord = newMap.get(ocr.Id);
            }
            if(isPrimaryReferral(ocr,oldRecord)){
                referralsMap.put(ocr.OpportunityId,ocr);
                contactIds.add(ocr.ContactId);
            }
            if(isSubmissionAgent(ocr,oldRecord)){
                submissionMap.put(ocr.OpportunityId,ocr);
                contactIds.add(ocr.ContactId);
            }
        } 

        //query accounts
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountsMap = getPersonAccounts(contactIds,accountIds);

        //get territory info
        Map<Id,Id> territoryMap = getTerritoryMap(accountIds);

        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();

        //update opportunity with Referral Partner info
        updateFromReferral(opportunities,referralsMap,accountsMap,territoryMap);

         //update opportunity with Submission Agent info
         updateFromSubmission(opportunities,submissionMap,accountsMap);

         if(!opportunities.isEmpty()){
            update opportunities.values();
         }
    }

    private Map<Id,Account> getPersonAccounts(Set<Id> contactIds, Set<Id> accountIds){
        Map<Id,Account> accounts = new Map<Id,Account>();
        for(Account acc : [SELECT Id, CurrentOrganization__c, PersonContactId, OwnerId 
                            FROM Account 
                            WHERE PersonContactId IN :contactIds]){
            accounts.put(acc.PersonContactId,acc);
            accountIds.add(acc.Id);
        }
        return accounts;
    }

    private Map<Id,Id> getTerritoryMap(Set<Id> accountIds){
        Map<Id,Id> result = new Map<Id,Id>();
        for(ObjectTerritory2Association ota : [SELECT ObjectId, Territory2Id
                                                FROM ObjectTerritory2Association 
                                                WHERE ObjectId IN :accountIds
                                                ORDER BY LastModifiedDate DESC]){
            if(!result.containsKey(ota.ObjectId)){
                result.put(ota.ObjectId,ota.Territory2Id);
            }
        }
        return result;
    }

    private void updateFromReferral(Map<Id, Opportunity> opportunities,
                                Map<Id,OpportunityContactRole> referralsMap, 
                                Map<Id,Account> accountsMap,
                                Map<Id,Id> territoryMap){
        for(Id oppId : referralsMap.keyset()){
            OpportunityContactRole ocr = referralsMap.get(oppId);
            Account acc = accountsMap.get(ocr.ContactId);
            Id territotyId = territoryMap!= null && territoryMap.containsKey(acc.Id) ? territoryMap.get(acc.Id) : null;
		system.debug('territoryMap id found = '+territotyId);
            if(acc == null && territotyId == null){
                continue;
            }

            if(!opportunities.containsKey(oppId)){
                opportunities.put(oppId, new Opportunity(Id=oppId));
            }

            if(acc != null){
                opportunities.get(oppId).Referral_Partner__c = acc.Id;
                opportunities.get(oppId).Referral_Organization__c = acc.CurrentOrganization__c;
                opportunities.get(oppId).BDM__c = acc.OwnerId;
            }

           // if(territotyId != null){
                opportunities.get(oppId).Territory2Id = territotyId;
           // }
        }
    }

    private void updateFromSubmission(Map<Id, Opportunity> opportunities,
                                Map<Id,OpportunityContactRole> submissionMap, 
                                Map<Id,Account> accountsMap){
        for(Id oppId : submissionMap.keyset()){
            OpportunityContactRole ocr = submissionMap.get(oppId);
            Account acc = accountsMap.get(ocr.ContactId);

            if(acc == null){
                continue;
            }

            if(!opportunities.containsKey(oppId)){
                opportunities.put(oppId, new Opportunity(Id=oppId));
            }

            if(acc != null){
                opportunities.get(oppId).Submission_Partner__c = acc.PersonContactId;
            }
        }
    }

    public void validateRole(List<OpportunityContactRole> records,
                            Map<Id, OpportunityContactRole> oldRecords){
        Map<Id,OpportunityContactRole> roleByOpp = new Map<Id,OpportunityContactRole>();
                                
        if(oldRecords != null){          
            Set<String> fieldsToCheck = new Set<String>{ 'Role' }; 
            List<OpportunityContactRole> changedRecords = (List<OpportunityContactRole>) Utils.getChangedObjects(
                records,
                oldRecords,
                fieldsToCheck
            );
            records = changedRecords;
        }
                
        if(records.isEmpty()) return;
                                
        for(OpportunityContactRole ocr : records){
            if(isSubmissionAgent(ocr,null)){
                roleByOpp.put(ocr.OpportunityId,ocr);
            }
        } 

        //find othe submission agent roles
        List<OpportunityContactRole> rolesToUpdate = new List<OpportunityContactRole>();
        for(OpportunityContactRole ocr : [SELECT Id, IsPrimary, OpportunityId  
                                            FROM OpportunityContactRole 
                                            WHERE OpportunityId IN :roleByOpp.keyset()
                                            AND Role = :SUBMISSION_AGENT]){
            if(roleByOpp.get(ocr.OpportunityId) != null){
                roleByOpp.get(ocr.OpportunityId).addError(Label.Error_Opp_Contact_Role_Submission);
            }
        }
    }
}