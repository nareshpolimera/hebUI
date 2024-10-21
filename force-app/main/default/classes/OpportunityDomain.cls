public class OpportunityDomain {
    private OpportunityService service = new OpportunityService();

    //init routing service class and log
    private OpportunityRoutingService routingService = new OpportunityRoutingService();

    //init sharing service to process sharing records for files
    private OpportunitySharingService sharingService =  new OpportunitySharingService();

    public void afterInsert(List<Opportunity> records) {
        service.switchCaseLink2Opportuinty(records);
        //service.updateRollups();

        //SOC apex sharing
        routingService.processSharingRecords(records, null);
        
        //five9 related
        service.checkDialListConditions(records, null);

        //BDM sharing
        sharingService.processBDMSharing(records, null);
    }

    public void beforeUpdate(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        //#6446 //priority 1
        service.checkRequote(records, oldRecords);
        service.UpdateOpportunityNameWithFileNumber(records, oldRecords);
        OpportunityService.snailMailPlatformEvent(records, oldRecords);
        service.setReadyToMars(records, oldRecords);
        
        //call routing services to get SOC and Broker Underwriter
        routingService.routeToUsers(records,oldRecords);
        //save rounting log
        LoggerDMLService.saveLog(routingService.getLog());

        
        //service.updateActiveQuote(records, oldRecords);
        service.fileValidationPriorToMARS(records, oldRecords);
        service.fileValidationPriorToCommitmentLetter(records, oldRecords);
        service.ensureFileComplete(records, oldRecords);
        service.checkCASLConsentUser(records, oldRecords);
        
        //five9 related
        service.checkDialListConditions(records, oldRecords);

        //validate PRS and PQS
        service.refreshProductError(records, oldRecords);
    }

    public void afterUpdate(
        List<Opportunity> records,
        Map<Id, Opportunity> oldRecords
    ) {
        //service.updateRollups();
        // service.sendApprovedOppToMarsPlatformEvent(records, oldRecords);

        service.UpdateApplicationNameWithFileNumber(records, oldRecords);
        //#6446
        OpportunityService.mapRelatedRecordsOwnership(records, oldRecords);
        //service.updateSelectedQuote(records, oldRecords);
        service.updateQuote(records, oldRecords);
        service.createCampaignInfluenceRecords(records, oldRecords);
        OpportunityService.mapRelatedRecordsFileRecordType(records, oldRecords);
        service.cancelAppraisals(records, oldRecords);
        //OpportunityService.startMarsReadyRecordPostConversion(records, oldRecords);

        //SOC apex sharing
        routingService.processSharingRecords(records, oldRecords);

        //BDM sharing
        sharingService.processBDMSharing(records, oldRecords);
    }

    public void beforeInsert(List<Opportunity> records) {
        service.setRecordTypeCheck(records);
        OpportunityService.snailMailPlatformEvent(records, new Map<Id, Opportunity>());
        
        //#6446
        service.mapUserBio(records, null);
        service.initialValues(records); // NeverBounce Verify_Email indicator / Most_Recent_Inquiry_Date initialiation
        service.setFileQueue(records);

        //call routing services to get SOC and Broker Underwriter
        routingService.routeToUsers(records,null);
        //save rounting log
        LoggerDMLService.saveLog(routingService.getLog());

        service.UpdateOpportunityNameWithFileNumber(records, null);
    }

    public class ReferralDomain {
        private OpportunityService service = new OpportunityService();

        public void beforeUpdate(
            List<Opportunity> records,
            Map<Id, Opportunity> oldRecords
        ) {
            service.fileValidationPriorToCommitmentLetter(records, oldRecords);
        }

        public void beforeInsert(List<Opportunity> records) {
            service.setRecordTypeCheck(records);
        }

        public void afterInsert(List<Opportunity> records) {
            service.switchCaseLink2Opportuinty(records);
        }

    }
}