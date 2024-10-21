public with sharing class CaseRoutingService {
    
    public enum UserRole { CCCH, DE, SDE, SCH }
    private Logger theLogger;
    private string classContext;
    
    public CaseRoutingService() {
        this.theLogger = new Logger('CaseRoutingService');
        this.classContext = 'CaseRoutingService';
    }
    
    public CaseRoutingService(Logger log){
        this.theLogger = log;
        this.classContext = 'CaseRoutingService';
    }
    
    public Logger getLog(){
        return this.theLogger;
    }
    
    //Method to validate if file requieres a SOC user
    private boolean isCCCH(Case caseRecord, Case oldCase){
        if(caseRecord == null){
            return false;
        }
        
        if(oldCase != null && caseRecord.Status != oldCase.Status) {
            return true;
        }
        
        return false;
    }
    
    private boolean isCaseEscalated(Case caseRecord, Case oldCase, String handlingLevel) {
        if(caseRecord == null){
            return false;
        }
        if(caseRecord != null && oldCase != null &&
           caseRecord.Complaint_Handling_Level__c != oldCase.Complaint_Handling_Level__c) {
               return true;
           }
        return false;
    }
    
    private boolean isCaseTransfered(Case caseRecord, Case oldCase) {
        if(caseRecord == null){
            return false;
        }
        
        if(oldCase != null && (oldCase.Transfer_to_Role__c !=null || caseRecord.Transfer_to_Role__c != null)
           && oldCase.Complaint_Handling_Level__c == 'Level 1' && caseRecord.Transfer_to_Role__c != 'FPOC') {
               return true;
           }
        return false;
    }
    
    // @Author : Naresh Polimera
    // @Date : 12/08/202      
    public void routeToDEOrSDEUsers(List<Case> records) {
        List<case> riskCases = new List<Case>();
        List<case> escalateSDECases = new List<Case>();
        List<case> cchCases = new List<Case>();
        this.theLogger = new Logger('CaseDomainRouting');

        for(Case caseRec: records) {
            Boolean isCaseToUpdate = false;
            Integer numberDaysDue = caseRec.Complaint_Date_Received__c.daysBetween(System.Today());
            
            // 
            if(!caseRec.Can_I_close_or_resolve_this_complaint__c  
               && !caseRec.Is_this_about_fraud__c && numberDaysDue <= 14 ) {
                cchCases.add(caseRec);
                system.debug('cchCases '+ cchCases);
            }
            
            if(numberDaysDue > 50 ) {                
                caseRec.Complaint_Handling_Level__c = 'Level 3';
                caseRec.Complaint_Escalation_Rationale__c = '';
                caseRec.Escalation_to_SDE_Rationale__c  = 'This case has been automatically escalated to Level 3 as the received date is greater than 50 Days';
                caseRec.IsEscalated = true;
                escalateSDECases.add(caseRec);
            } 
            else if(numberDaysDue > 14 && numberDaysDue <= 50 && (caseRec.Complaint_Handling_Level__c == 'Level 2' || caseRec.Complaint_Handling_Level__c == 'Level 3'))
            {   
                isCaseToUpdate = true;
                caseRec.Complaint_Handling_Level__c = caseRec.Complaint_Handling_Level__c;
                caseRec.IsEscalated = true;
                caseRec.Complaint_Escalation_Rationale__c = 'This case has been automatically escalated to '+ caseRec.Complaint_Handling_Level__c +' as the received date falls between 15 and 50 Days';                
            }
            else if(caseRec.Is_this_about_fraud__c && (caseRec.Complaint_Handling_Level__c == 'Level 2' || caseRec.Complaint_Handling_Level__c == 'Level 3')) {
                isCaseToUpdate = true;
                caseRec.Complaint_Handling_Level__c = caseRec.Complaint_Handling_Level__c;
                caseRec.IsEscalated = true;
                caseRec.Complaint_Escalation_Rationale__c = 'This case has been automatically escalated to '+ caseRec.Complaint_Handling_Level__c +' because of High Risk Complaint ';
            }
            
            if(isCaseToUpdate) {
                riskCases.add(caseRec);
            }  
        }
        
        
        if(riskCases.size() > 0) {
            RFRoutingService rfService =  new RFRoutingService(theLogger);
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(riskCases,'DE');
            processRoutingUser(listOfRoutingUsers, UserRole.DE );
        }        
        
        System.debug(escalateSDECases.size());
        
        if(escalateSDECases.size() > 0) {
            RFRoutingService rfService =  new RFRoutingService(theLogger);
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(escalateSDECases,'SDE');
            System.debug('listOfRoutingUsers '+ listOfRoutingUsers);
            processRoutingUser(listOfRoutingUsers, UserRole.SDE );
        }
        system.debug('cchCases.size() '+ cchCases.size());
        if(cchCases.size() > 0){
            RFRoutingService rfService =  new RFRoutingService(theLogger);
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(cchCases,'CCCH');
            system.debug('listOfRoutingUsers CCCH ::' + listOfRoutingUsers);
            processRoutingUser(listOfRoutingUsers, UserRole.CCCH );
        }
    }
    
    //Method to process each File to find and assign winnign user,
    //based on the Assignemnt Rules defined in the org
    public void routeToUsers(List<Case> records,Map<Id, Case> oldMap) {
        
        RFRoutingService rfService =  new RFRoutingService(theLogger);        
        Map<UserRole,List<Case>> caseMap = new Map<UserRole,List<Case>>();
        List<Case> caseList = new List<Case>();
        if(records != null && records.size() > 0){
            caseList = records;
        }
        
        for(Case caseRecord : records) {
            Case oldCase;
            if(oldMap != null){
                oldCase = oldMap.get(caseRecord.Id);
            }           
            
            if(caseRecord.Complaint_Handling_Level__c == 'Level 2' && isCaseEscalated(caseRecord,oldCase, 'Level 1')) {
                theLogger.info('{0} | Case [{1}] is valid to find DE.', new Object[] {classContext, RFUtils.getRecordId(caseRecord)});
                if(caseMap.get(UserRole.DE) == null){
                    caseMap.put(UserRole.DE,new List<Case>());
                }
                caseMap.get(UserRole.DE).add(caseRecord);
            }
            
            if(caseRecord.Complaint_Handling_Level__c == 'Level 3' && isCaseEscalated(caseRecord,oldCase, 'Level 2')) {
                theLogger.info('{0} | Case [{1}] is valid to find DE.', new Object[] {classContext, RFUtils.getRecordId(caseRecord)});
                if(caseMap.get(UserRole.SDE) == null){
                    caseMap.put(UserRole.SDE,new List<Case>());
                }
                caseMap.get(UserRole.SDE).add(caseRecord);
            }
            
            
            if(isCaseTransfered(caseRecord,oldCase)) {
                
                for(Case ur :caseList){
                    if(ur.Transfer_to_Role__c == 'SCH'){
                        theLogger.info('{0} | Case [{1}] is valid to find SCH.', new Object[] {classContext, RFUtils.getRecordId(caseRecord)});
                        if(caseMap.get(UserRole.SCH) == null){
                            caseMap.put(UserRole.SCH,new List<Case>());
                        }
                        caseMap.get(UserRole.SCH).add(caseRecord);
                    }
                    if(ur.Transfer_to_Role__c == 'CCCH'){
                        theLogger.info('{0} | Case [{1}] is valid to find CCCH.', new Object[] {classContext, RFUtils.getRecordId(caseRecord)});
                        if(caseMap.get(UserRole.CCCH) == null){
                            caseMap.put(UserRole.CCCH,new List<Case>());
                        }
                        caseMap.get(UserRole.CCCH).add(caseRecord);
                    }
                }
                
            } 
            
        }
        
        if(!caseMap.isEmpty() &&  caseMap.get(UserRole.CCCH) != null && !caseMap.get(UserRole.CCCH).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{ classContext });
            theLogger.debug(' {0} | There are {1} Cases to find CCCH.', new Object[] {classContext,caseMap.get(UserRole.CCCH).size()});
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(caseMap.get(UserRole.CCCH),'CCCH');
            processRoutingUser(listOfRoutingUsers,UserRole.CCCH);
            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        }
        
        
        if(!caseMap.isEmpty() &&  caseMap.get(UserRole.DE) != null && !caseMap.get(UserRole.DE).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{ classContext });
            theLogger.debug(' {0} | There are {1} Cases to find DE.', new Object[] {classContext,caseMap.get(UserRole.DE).size()});
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(caseMap.get(UserRole.DE),'DE');
            processRoutingUser(listOfRoutingUsers,UserRole.DE);
            
            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        }
        
        if(!caseMap.isEmpty() &&  caseMap.get(UserRole.SDE) != null && !caseMap.get(UserRole.SDE).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{ classContext });
            theLogger.debug(' {0} | There are {1} Cases to find SDE.', new Object[] {classContext,caseMap.get(UserRole.SDE).size()});
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(caseMap.get(UserRole.SDE),'SDE');
            processRoutingUser(listOfRoutingUsers,UserRole.SDE);
            
            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        }
        if(!caseMap.isEmpty() &&  caseMap.get(UserRole.SCH) != null && !caseMap.get(UserRole.SCH).isEmpty()){
            //log
            theLogger.info(' {0} | START', new Object[]{ classContext });
            theLogger.debug(' {0} | There are {1} Cases to find SCH.', new Object[] {classContext,caseMap.get(UserRole.SCH).size()});
            List<RFRoutingUser> listOfRoutingUsers = rfService.getWinningUser(caseMap.get(UserRole.SCH),'SCH');
            processRoutingUser(listOfRoutingUsers,UserRole.SCH);
            //log
            theLogger.info(' {0} | END', new Object[]{classContext});
        } 
    }
    
    public void processRoutingUser(List<RFRoutingUser> listOfRoutingUsers, UserRole role) {
        
        if(listOfRoutingUsers == null || listOfRoutingUsers.isEmpty()){
            return;
        }
        
        for(RFRoutingUser rUser : listOfRoutingUsers) {
            system.debug('rUser.userRole.userId '+ rUser.userRole.userId);
            if(role == UserRole.CCCH) {
                if(rUser.record != null && rUser.userRole != null && rUser.userRole.userId != null) {
                    rUser.record.put('OwnerId',rUser.userRole.userId);
                } 
            }
            else if(role == UserRole.DE) {
                if(rUser.record != null && rUser.userRole != null && rUser.userRole.userId != null) {
                    rUser.record.put('OwnerId',rUser.userRole.userId);
                } 
            }
            else if(role == UserRole.SDE) {
                if(rUser.record != null && rUser.userRole != null && rUser.userRole.userId != null) {
                    rUser.record.put('OwnerId',rUser.userRole.userId);
                } 
            }
            else if(role == UserRole.SCH) {
                if(rUser.record != null && rUser.userRole != null && rUser.userRole.userId != null) {
                    rUser.record.put('OwnerId',rUser.userRole.userId);
                } 
            }
        }
    }
    
}