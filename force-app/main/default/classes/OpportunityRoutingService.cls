public without sharing class OpportunityRoutingService {
    
    public enum UserRole {SOC, BU}
    private Logger theLogger;
    private string classContext;

    public OpportunityRoutingService(){
        this.theLogger = new Logger('OpportunityRoutingService');
        this.classContext = 'OpportunityRoutingService';
    }

    public OpportunityRoutingService(Logger log){
        this.theLogger = log;
        this.classContext = 'OpportunityRoutingService';
    }

    public Logger getLog(){
        return this.theLogger;
    }

    //Method to validate if file requieres a SOC user
    private boolean isSOC(Opportunity opp, Opportunity oldOpp){
        if(opp == null){
            return false;
        }

        if(oldOpp == null && 
            opp.Sales_Ops_Coordinator__c == null){
            return true;
        }

        if(oldOpp != null && 
            opp.Sales_Ops_Coordinator__c == null &&
            opp.StageName != oldOpp.StageName){
            return true;
        }

        return false;
    }

    //Method to validate if file requieres a BU user
    private boolean isBU(Opportunity opp, Opportunity oldOpp){
        String role;
        if(opp == null){
            return false;
        }

        //assign BU only on creation
        //when File Queue = 'Unassigned' or blank
        if(oldOpp == null && 
            opp.Id == null &&
            (String.isBlank(opp.File_Queue__c) ||
            opp.File_Queue__c == 'Unassigned')){
            return true;
        }

        return false;
    }

    //Method to process each File to find and assign winnign user,
    //based on the Assignemnt Rules defined in the org
    public void routeToUsers(List<Opportunity> records,Map<Id, Opportunity> oldMap){
        //init routing service
        RFRoutingService rfService =  new RFRoutingService(theLogger);

        //validate list of opprotunities
        //valida which role is needed per opportunity
        Map<UserRole,List<Opportunity>> oppMap = new Map<UserRole,List<Opportunity>>();
        for(Opportunity opp : records){
            Opportunity oldOpp;
            if(oldMap != null){
                oldOpp = oldMap.get(opp.Id);
            }
            if(isSOC(opp,oldOpp)){
                //log
                theLogger.info('{0} | Opportunity [{1}] is valid to find SOC.', 
                            new Object[] {classContext,RFUtils.getRecordId(opp)});

                if(oppMap.get(UserRole.SOC) == null){
                    oppMap.put(UserRole.SOC,new List<Opportunity>());
                }
                oppMap.get(UserRole.SOC).add(opp);
            }
            if(isBU(opp,oldOpp)){
                theLogger.info('{0} |  Opportunity [{1}] is valid to find BU.', 
                                new Object[] {classContext, RFUtils.getRecordId(opp)});

                if(oppMap.get(UserRole.BU) == null){
                    oppMap.put(UserRole.BU,new List<Opportunity>());
                }
                oppMap.get(UserRole.BU).add(opp);
            }
        }

        //route to SOC
        if(!oppMap.isEmpty() && 
            oppMap.get(UserRole.SOC) != null && 
            !oppMap.get(UserRole.SOC).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{classContext});
            
            theLogger.debug(' {0} | There are {1} Opportunities to find SOC.',
                            new Object[] {classContext,oppMap.get(UserRole.SOC).size()});

            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(oppMap.get(UserRole.SOC),'SOC');
            processRoutingUser(listOfRoutingUsers,UserRole.SOC);

            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        }

        //route to Broker Underwriter
        if(!oppMap.isEmpty() && 
            oppMap.get(UserRole.BU) != null && 
            !oppMap.get(UserRole.BU).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{classContext});

            theLogger.debug(' {0} | There are {1} Opportunities to find BU.',
                            new Object[] {classContext, oppMap.get(UserRole.BU).size()});

            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(oppMap.get(UserRole.BU),'BU');
            processRoutingUser(listOfRoutingUsers,UserRole.BU);

            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        }        
    }

    private void processRoutingUser(List<RFRoutingUser> listOfRoutingUsers, UserRole role){

        if(listOfRoutingUsers == null || listOfRoutingUsers.isEmpty()){
            return;
        }

        theLogger.info(' {0} | START | processRoutingUser() to save winner users.', new Object[]{classContext});

        //process each user to assign in proper field 
        for(RFRoutingUser rUser : listOfRoutingUsers){
            if(rUser.record != null && 
                rUser.userRole != null && 
                rUser.userRole.userId != null){
                if(role == UserRole.SOC){

                    theLogger.debug(' {0} | User [{1}] was selected as SOC for Opportunity: {2}.',
                                    new Object[] {classContext,rUser.userRole.userId,RFUtils.getRecordId(rUser.record)});

                    rUser.record.put('Sales_Ops_Coordinator__c',rUser.userRole.userId);
                }
                else if(role == UserRole.BU){
                    theLogger.debug(' {0} | User [{1}] was selected as BU for Opportunity: {2}.',
                                    new Object[] {classContext,rUser.userRole.userId,RFUtils.getRecordId(rUser.record)});

                    rUser.record.put('OwnerId',rUser.userRole.userId);

                    //set File Queue to blank
                    rUser.record.put('File_Queue__c',null);
                }
            }
        }
    }

    private boolean hasSOCChanged(Opportunity opp, Opportunity oldOpp){

        if(opp == null){
            return false;
        }

        if(oldOpp == null && 
            opp.Sales_Ops_Coordinator__c != null){
            return true;
        }

        if(oldOpp != null && 
            opp.Sales_Ops_Coordinator__c != oldOpp.Sales_Ops_Coordinator__c){
            return true; 
        }

        return false;
    }

    //Process Files to validate is record must be shared with SOC user
    //it will also delete old access when the SOC is changed to a new user
    public void processSharingRecords(List<Opportunity> records,Map<Id, Opportunity> oldMap){

        List<Opportunity> oldToRemove = new List<Opportunity>();
        List<Opportunity> newToShare = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();

        for(Opportunity opp : records){
            Opportunity oldOpp;
            if(oldMap != null){
                oldOpp = oldMap.get(opp.Id);
            }
            if(hasSOCChanged(opp,oldOpp)){
                newToShare.add(opp);
                accountIds.add(opp.AccountId);
                if(oldOpp != null){
                    oldToRemove.add(oldOpp);
                }
            }
        }

        //create new sharing records
        createSharingRecords(newToShare,accountIds);

        //delete old access for old records
        deleteSharingRecords(oldToRemove);
    }

    private void createSharingRecords(List<Opportunity> records, Set<Id> accountIds){
        if(records == null || records.isEmpty()){
            return;
        }

        //load accounts to validate owner
        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id, OwnerID FROM Account WHERE Id IN :accountIds]);

        List<OpportunityShare> oppSharetoInsert = new list<OpportunityShare>();
        List<AccountShare> accSharetoInsert = new list<AccountShare>();

        for(Opportunity opp : records){
            if(opp.Sales_Ops_Coordinator__c != null &&
                opp.Sales_Ops_Coordinator__c != opp.ownerId){
                OpportunityShare oppShare = new OpportunityShare();
                oppShare.OpportunityId = opp.Id;
                oppShare.UserOrGroupId = opp.Sales_Ops_Coordinator__c;
                oppShare.OpportunityAccessLevel = 'Edit';
                oppShare.RowCause = 'Manual';
                oppSharetoInsert.add(oppShare);

                //validate owner
                Account acc = accountMap.get(opp.AccountId);
                if(acc != null && 
                    opp.Sales_Ops_Coordinator__c != acc.ownerId){                    
                    AccountShare accShare = new AccountShare();
                    accShare.AccountId = opp.AccountId;
                    accShare.UserOrGroupId = opp.Sales_Ops_Coordinator__c;
                    accShare.AccountAccessLevel = 'Edit';
                    accShare.OpportunityAccessLevel = 'Read';
                    accShare.CaseAccessLevel = 'Edit';
                    accShare.RowCause = 'Manual';
                    accSharetoInsert.add(accShare);
                }
            }
        }
        
        if(!oppSharetoInsert.isEmpty()){
            insert oppSharetoInsert;
        }

        if(!accSharetoInsert.isEmpty()){
            insert accSharetoInsert;
        }
    }

    private void deleteSharingRecords(List<Opportunity> records){
        if(records == null || records.isEmpty()){
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        for(Opportunity opp : records){
            oppIds.add(opp.Id);
            if(opp.AccountId != null){
                accIds.add(opp.AccountId);
            }
            if(opp.Sales_Ops_Coordinator__c != null){
                userIds.add(opp.Sales_Ops_Coordinator__c);
            }
        }

        //get opprtunity sharing records to delete
        List<OpportunityShare> oppShareToDelete = [SELECT Id
                                                    FROM OpportunityShare
                                                    WHERE OpportunityId IN: oppIds AND 
                                                    UserOrGroupId IN :userIds AND
                                                    RowCause = 'Manual'];
        
        if(!oppShareToDelete.isEmpty()){
            delete oppShareToDelete;
        }

         //get opprtunity sharing records to delete
        List<AccountShare> accShareToDelete = [SELECT Id
                                                FROM AccountShare
                                                WHERE AccountId IN: accIds AND 
                                                UserOrGroupId IN :userIds AND
                                                RowCause = 'Manual'];
        
        if(!accShareToDelete.isEmpty()){
            delete accShareToDelete;
        }
    }
}