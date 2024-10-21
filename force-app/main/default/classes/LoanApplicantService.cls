/*
 * Service class for the LoanApplicant object
 */
public class LoanApplicantService {
    public static final String BORROWER_ROLE = 'Borrower';
    public static final String COBORROWER_ROLE = 'CoBorrower';
    public static final String INFLUENCER_ROLE = 'Influencer';
    public static final String POA_ROLE = 'Power of Attorney';
    public static final String GUARANTOR_ROLE = 'Guarantor';

    public static final String OCCUPATION_NEVER_EMPLOYED = 'Never Employed';
    public static final String OCCUPATION_HOMEMAKER = 'Homemaker';
    public static final String OCCUPATION_UNEMPLOYED = 'Unemployed';
    public static final String OCCUPATION_RETIRED = 'Retired';
    public static final String OCCUPATION_OTHER = 'Other (please specify)';

    public void generateAutoName(List<LoanApplicant> records) {        
        //AutomatedNameGenerator.generateNextSequenceName(records, LoanApplicant.SobjectType);
    }

    /*
     * HEB-32
     * Get list of Borrowers for a File related to the LoanApplicant
     */
    /* Method called on leadCreditCheckHelper and CreditCheckRequestService (Be aware of the returned variable type)*/
    @AuraEnabled
    public static ApplicantAndApplication getBorrowers(Id fileId) {
        ApplicantAndApplication result = new ApplicantAndApplication();

        list<LoanApplicant> applicants = [
            SELECT
                Id,
                ContactId,
                Contact.FirstName,
                Contact.LastName,
                Contact.Birthdate,
                Income_Documents_Required__c,
                role__c,
                Contact.Account.Name,
                Total_Pension_Income__c,
                Total_Employment_Income__c,
                Total_Investment_Income__c,
                Total_Rental_Income__c,
                Total_Support_Income__c,
                (
                    SELECT
                        Id,
                        Credit_Hit__c,
                        Credit_Score__c,
                        Credit_Score_Type__c,
                        Credit_Summary__c,
                        Credit_Report_Status__c,
                        Credit_Freeze__c,
                        Trades_Info__c,
                        Bankruptcies_Info__c,
                        Collections_Info__c,
                        LegalActions_Info__c
                    FROM Credit_Reports__r
                    WHERE
                        Credit_Hit__c = TRUE
                        AND Credit_Freeze__c = FALSE
                        AND Assessment_Eligible__c = TRUE
                    ORDER BY createddate DESC
                    LIMIT 1
                ),
                (
                    SELECT
                        Id,
                        LoanApplicantId,
                        LoanApplicationId,
                        IncomeSourceType,
                        IncomeExtIdentifier,
                        MonthlyIncomeAmount
                    FROM LoanApplicantIncomes
                ),
                (
                    SELECT
                        Id,
                        CurrentJobAdditionalMonthCount,
                        IsRelToTransactionParty,
                        EmployerAddress,
                        EmployerName,
                        EmployerPhone,
                        EndDate,
                        External_ID__c,
                        JobTitle,
                        EmploymentExtIdentifier,
                        MonthlyBaseIncomeAmount,
                        MonthlyBonusAmount,
                        MonthlyCommissionAmount,
                        MonthlyIncome,
                        MonthlyMilitaryEntlAmt,
                        MonthlyOvertimeAmount,
                        MonthlyOtherIncomeAmount,
                        IsLessThanQuarterShare,
                        IsSelfEmployed,
                        StartDate,
                        MonthlyTotalIncomeAmount,
                        CurrentJobYearCount
                    FROM LoanApplicantEmployments
                )
            FROM LoanApplicant
            WHERE
            	role__c INCLUDES (:LoanApplicantService.BORROWER_ROLE)
                AND Use_For_Quote__c = TRUE
                AND LoanApplication.OpportunityId = :fileId
            ORDER BY Contact.FinServ__Age__c
            LIMIT 2
        ];
        list<ResidentialLoanApplication> application = [
            SELECT
                Id,
                OpportunityId,
                (
                    SELECT
                        id
                    FROM LoanApplicationAssets
                ),
                (
                    SELECT id
                    FROM LoanApplicationProperties
                )
            FROM ResidentialLoanApplication
            WHERE OpportunityId = :fileId
            LIMIT 1
        ];

        result.application = application[0];
        result.applicants = applicants;
        return result;
    }

  /*
     * HEB-220 - Only one Primary Borrower allowed
     * This method runs 'before' insert and update. It removes the multiple primary borrowers against a property in the list
     */
   public void onePrimaryBorrowerBefore(List<LoanApplicant> records, Map<Id, LoanApplicant> oldRecords) {
    Map<Id, LoanApplicant> propertyPrimaryPMMap = new Map<Id, LoanApplicant>();

    // Iterate through the records and determine the primary borrower
    for (LoanApplicant pm : records) {
        if (pm.Role__c != null && pm.Role__c.contains(LoanApplicantService.BORROWER_ROLE) &&  pm.Is_Primary_Borrower__c && 
            (oldRecords.get(pm.Id) == null || !(oldRecords.get(pm.Id).Role__c.contains(LoanApplicantService.BORROWER_ROLE) && oldRecords.get(pm.Id).Is_Primary_Borrower__c)))
        {
            Id fileId = pm.LoanApplicationId;
            if (propertyPrimaryPMMap.get(fileId) == null) {
                propertyPrimaryPMMap.put(fileId, pm);
            } else {
                // If another primary borrower for a property is present in the list, update that borrower to be non-primary
                LoanApplicant updateBorrower = propertyPrimaryPMMap.get(fileId);
                updateBorrower.Is_Primary_Borrower__c = false;
                propertyPrimaryPMMap.put(fileId, pm);
            }
        }
    }

    if (propertyPrimaryPMMap.isEmpty()) {
        return;
    }

    List<LoanApplicant> pmUpdateList = new List<LoanApplicant>();

    // Reset any existing primary borrowers for the property
    for (LoanApplicant existingPrimarypm : [
        SELECT Id, Role__c, LoanApplicationId, Is_Primary_Borrower__c
        FROM LoanApplicant
        WHERE
            Role__c != null AND 
            Role__c INCLUDES(:LoanApplicantService.BORROWER_ROLE) AND
            Is_Primary_Borrower__c = true AND
            LoanApplicationId IN :propertyPrimaryPMMap.keySet()
            AND Id NOT IN :propertyPrimaryPMMap.values() // Excludes the Property members in context
    ]) {
        existingPrimarypm.Is_Primary_Borrower__c = false;
        pmUpdateList.add(existingPrimarypm);
    }

    try {
        if (!pmUpdateList.isEmpty()) {
            update pmUpdateList;
        }
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, e.getMessage());
    }
}


    /*
     * HEB-325 - Validate
     * This method runs 'before' delete. It validated deletion of property members
     */
    public void validatePropertyMemberDeletion(
        Map<Id, LoanApplicant> oldRecords
    ) {
        list<id> oppIds = new List<id>();
        list<LoanApplicant> oldApplicants = [
            SELECT
                Id,
                LoanApplication.OpportunityId,
                LoanApplication.Opportunity.AccountId,
                Contact.AccountId,
                Contact.Name,
            	role__c,
                Is_Primary_Borrower__c
            FROM LoanApplicant
            WHERE Id = :oldRecords.keySet()
        ];

        for (LoanApplicant pm : oldApplicants) {
            oppIds.add(pm.LoanApplication.OpportunityId);
        }
        //Query to opportunityContactRole

        list<opportunityContactRole> oppContacts = [
            SELECT OpportunityId, ContactId, Contact.Name, IsPrimary
            FROM opportunityContactRole
            WHERE OpportunityId IN :oppIds
        ];
        for (LoanApplicant pm : oldApplicants) {
            LoanApplicant propMRecord = oldRecords.get(pm.Id);
            for (opportunityContactRole ocr : oppContacts) {
                if ( pm.LoanApplication.OpportunityId != null &&  pm.ContactId == ocr.ContactId && pm.LoanApplication.OpportunityId == ocr.OpportunityId && pm.Contact.Name.deletewhitespace().containsIgnoreCase(  ocr.Contact.Name.deletewhitespace() ) &&  ocr.IsPrimary == true ) {
                    propMRecord.addError(  Label.Error_PropertyMem_OnFileNotDelete  );
                }
            }
            // cannot delete Primary borrower
            if(pm.role__c != null && pm.role__c.contains(BORROWER_ROLE) && pm.Is_Primary_Borrower__c == true){
                pm.addError(Label.Error_PropMem_PrimaryNotDeleted);
            }
        }
    }

      /*
     * HEB-386 - Select Quotable Property Member
     * This method runs before insert and auto-corrects first two borrowers to useable for quote
     */
    public void checkUseForQuoteBeforeInsert(
        List<LoanApplicant> records,
        Map<Id, LoanApplicant> oldRecords
    ) {
        //List of new records mapped to their lead ID
        Map<Id, List<LoanApplicant>> newPMCIdMap = new Map<Id, List<LoanApplicant>>();
        List<LoanApplicant> newPMCList = new List<LoanApplicant>();
     
        for (LoanApplicant pmcSetRecord : records) {
            // Add an error if the user is trying to insert / update a non borrower quotable PMC
            if (
                (pmcSetRecord.Use_For_Quote__c == true) &&
                ((pmcSetRecord.role__c == null || !pmcSetRecord.role__c.contains(LoanApplicantService.BORROWER_ROLE)))) {
                  pmcSetRecord.addError(Label.Error_PropMem_MustBeBorrower);
            } else if (
              (pmcSetRecord.role__c != null && !pmcSetRecord.role__c.contains(LoanApplicantService.BORROWER_ROLE))
            ) {
                // Ignore non borrowers
            } else {
                //Add to the borrower list of new pmcs
                newPMCList.add(pmcSetRecord);

                //If the map contains this Lead__c, add this to the list
                if (newPMCIdMap.get(pmcSetRecord.LoanApplicationId) != null) {
                    List<LoanApplicant> tempPMCList = newPMCIdMap.get(
                        pmcSetRecord.LoanApplicationId
                    );
                    tempPMCList.add(pmcSetRecord);
                    newPMCIdMap.put(
                        pmcSetRecord.LoanApplicationId,
                        tempPMCList
                    );
                } else {
                    // If the map does not contain this leadId, create a new value
                    List<LoanApplicant> tempPMCList = new List<LoanApplicant>();
                    tempPMCList.add(pmcSetRecord);
                    newPMCIdMap.put(
                        pmcSetRecord.LoanApplicationId,
                        tempPMCList
                    );
                }
            }
        }

        // Store updated Lead and PMC ids for our selector
        List<Id> leadIds = new List<Id>();
        List<Id> pmcIds = new List<Id>();
        for (LoanApplicant pmc : records) {
            leadIds.add(pmc.LoanApplicationId);
            pmcIds.add(pmc.Id);
        }

        // Get all old PMCs related to the current updated pmcs
        List<LoanApplicant> oldPMCList = [
            SELECT Id, LoanApplicationId, role__c, Use_For_Quote__c, ContactId, Is_Primary_Borrower__c
            FROM LoanApplicant
            WHERE LoanApplicationId IN :leadIds AND Id NOT IN :pmcIds
            AND role__c INCLUDES(:LoanApplicantService.BORROWER_ROLE)
        ];

        // Create map storage for all old pmcs
        Map<Id, List<LoanApplicant>> oldPMCIdMap = new Map<Id, List<LoanApplicant>>();
        //Add old pmcs to map
        for (LoanApplicant pmcSetRecord : oldPMCList) {           
                //If the map contains this leadId get it and add
                if (oldPMCIdMap.get(pmcSetRecord.LoanApplicationId) != null) {
                    List<LoanApplicant> tempPMCList = oldPMCIdMap.get( pmcSetRecord.LoanApplicationId );
                    tempPMCList.add(pmcSetRecord);
                    oldPMCIdMap.put( pmcSetRecord.LoanApplicationId,  tempPMCList );
                } else {
                    // If the map does not contain this leadId, create a new value
                    List<LoanApplicant> tempPMCList = new List<LoanApplicant>();
                    tempPMCList.add(pmcSetRecord);
                    oldPMCIdMap.put(
                        pmcSetRecord.LoanApplicationId,
                        tempPMCList
                    );
                }            
        }

        // Loop through new records and perform the use for quote counter check and auto assignment for first two borrowers
        for (LoanApplicant newPMC : newPMCList) {
            //Count new use for quotes
            List<LoanApplicant> tempNewPMCList = newPMCIdMap.get(
                newPMC.LoanApplicationId
            );
            Integer newUseForQuoteCounter = 0;
            for (LoanApplicant newPMCTemp : tempNewPMCList) {
                if (newPMCTemp.Use_For_Quote__c == true) {
                    newUseForQuoteCounter++;
                }
            }
            system.debug('newUseForQuoteCounter::' + newUseForQuoteCounter);
            //Count old use for quotes
            Integer oldUseForQuoteCounter = 0;
            List<LoanApplicant> tempOldPMCList = new List<LoanApplicant>();
            //Account for an empty list
            if (oldPMCIdMap.get(newPMC.LoanApplicationId) != null) {
                tempOldPMCList = oldPMCIdMap.get(newPMC.LoanApplicationId);
                for (LoanApplicant oldPMCTemp : tempOldPMCList) {
                    if (oldPMCTemp.Use_For_Quote__c == true) {
                        oldUseForQuoteCounter++;
                    }
                }
            }
            system.debug('oldUseForQuoteCounter::' + oldUseForQuoteCounter);
            // Error out on greater than two quoteable members per lead
            if ((newUseForQuoteCounter + oldUseForQuoteCounter) > 2) {
                system.debug(
                    'newUseForQuoteCounter + oldUseForQuoteCounter = ' +
                        newUseForQuoteCounter +
                        oldUseForQuoteCounter
                );
                newPMC.addError(Label.Error_PropMem_OnlyTwoQuoteableMembers);
            }
            // Check if the size of old borrower pmcs is less than two, if so we should flag this as quoteable by default
            if (
                (tempOldPMCList.size() < 2) &&
                ((newUseForQuoteCounter + oldUseForQuoteCounter) < 2)
            ) {
                newPMC.Use_For_Quote__c = true;
            }
        }
    }

    /*
     * HEB-386 - Select Quotable Property Member
     * This method runs before update
     */
    public void checkUseForQuoteBeforeUpdate(
        List<LoanApplicant> records,
        Map<Id, LoanApplicant> oldRecords
    ) {
        if (System.isBatch())
            return;

        //Create Property Member map and validate the borrower role
        Map<Id, LoanApplicant> pmcIdMap = new Map<Id, LoanApplicant>();
        // Store updated Lead and PMC ids for our selector
        List<Id> appsId = new List<Id>();
        List<Id> pmcIds = new List<Id>();
        List<id> contactIds = new List<id>();
        for (LoanApplicant pmcSetRecord : records) {
            contactIds.add(pmcSetRecord.ContactId);
            appsId.add(pmcSetRecord.LoanApplicationId);
        }

        for (LoanApplicant pmcSetRecord : records) {
            // Record is locked once Lead is converted. It should not run quotes
            pmcIdMap.put(pmcSetRecord.Id, pmcSetRecord);
            if (pmcSetRecord.Use_For_Quote__c == true && (pmcSetRecord.role__c == null || !pmcSetRecord.role__c.contains(BORROWER_ROLE))) {
                  pmcSetRecord.addError(Label.Error_PropMem_MustBeBorrower);
            }
            pmcIds.add(pmcSetRecord.Id);
        }

        if (pmcIds.isEmpty())
            return;

        // Select all related property members not in the updated list
        List<LoanApplicant> pmcList = [
            SELECT Id, LoanApplicationId, Use_For_Quote__c, Is_Primary_Borrower__c
            FROM LoanApplicant
            WHERE LoanApplicationId IN :appsId AND Id NOT IN :pmcIds
        ];
        // Combine non updated property members with updated property members
        pmcList.addAll(records);

        // A map of all property members and their ids
        Map<Id, List<LoanApplicant>> pmcLeadIdMap = new Map<Id, List<LoanApplicant>>();

        //Iterate through all property members and add errors if they have more than two quoteable related members
        for (LoanApplicant pmc : pmcList) {
            if (!pmcLeadIdMap.containsKey(pmc.LoanApplicationId)) {
                List<LoanApplicant> newPmcList = new List<LoanApplicant>();
                newPmcList.add(pmc);
                pmcLeadIdMap.put(pmc.LoanApplicationId, newPmcList);
            } else {
                List<LoanApplicant> currPmcList = pmcLeadIdMap.get(
                    pmc.LoanApplicationId
                );
                currPmcList.add(pmc);
                Integer useForQuoteCounter = 0;
                if (currPmcList.size() >= 2) {
                    for (LoanApplicant tempPmc : currPmcList) {
                        if (tempPmc.Use_For_Quote__c == true) {
                            useForQuoteCounter++;
                        }
                    }
                    if (useForQuoteCounter > 2) {
                        for (LoanApplicant pmcCheck : currPmcList) {
                            if (pmcIdMap.get(pmcCheck.Id) != null) {  pmcIdMap.get(pmcCheck.Id).addError(  Label.Error_PropMem_OnlyTwoQuoteableMembers ); }
                        }
                    }
                }
                pmcLeadIdMap.put(pmc.LoanApplicationId, currPmcList);
            }
        }
    }
    
    public void setContactId(List<LoanApplicant> records, Map<Id, LoanApplicant> oldMap){
        Set<Id> clientIdSet = new Set<Id>();
        Set<Id> changedClientIdSet = new Set<Id>();
        Map<Id, Id> clientIdContactIdMap = new Map<Id, Id>();
        Map<Id, LoanApplicant> changedApplicantClientMap = new Map<Id, LoanApplicant>();
        for(LoanApplicant record : records){
            clientIdSet.add(record.Client__c);
            if(oldMap != null && oldMap.get(record.Id).Client__c != record.Client__c){
                changedApplicantClientMap.put(record.Id, record);
                changedClientIdSet.add(record.Client__c);
            }
        }
        
        Set<Id> clientIdQuerySet = (changedClientIdSet != null && !changedClientIdSet.isEmpty()) ? changedClientIdSet : ((clientIdSet != null && !clientIdSet.isEmpty()) ? clientIdSet : new Set<Id>());
            
            if(clientIdQuerySet != null && clientIdQuerySet.size() > 0){
                for (Account record : [SELECT Id, PersonContactId FROM Account WHERE Id IN : clientIdQuerySet]){
                	clientIdContactIdMap.put(record.Id, record.PersonContactId);
            	}
                for(LoanApplicant record : records){
                    record.ContactId = clientIdContactIdMap.get(record.Client__c);
                }
            }
    }
    /*
     * Keep record ownership in sync with file ownership and ContactId from Client__c information.
     */
    public void setOwnerId(List<LoanApplicant> records) {
        Set<Id> appIdSet = new Set<Id>();
        for(LoanApplicant record : records){
            appIdSet.add(record.LoanApplicationId);
        }
        
        Map<Id, ResidentialLoanApplication> apps = new Map<Id, ResidentialLoanApplication>(
            [
                SELECT Id, Opportunity.OwnerId
                FROM ResidentialLoanApplication
                WHERE Id IN :appIdSet
            ]
        );

        for (LoanApplicant record : records){
            if(apps.get(record.LoanApplicationId).Opportunity.OwnerId != null){
                record.OwnerId = apps.get(record.LoanApplicationId).Opportunity.OwnerId;
            }
        }
    }

    public void leadValidation(List<LoanApplicant> records) {
        LeadService lService = new LeadService();
        List<Id> leadIDs = new List<Id>();
        List<Id> appIds = new List<Id>();

        for (LoanApplicant record : records) {
            appIds.add(record.LoanApplicationId);
        }

        map<Id,ResidentialLoanApplication> opps = new map<Id,ResidentialLoanApplication>([select id,OpportunityID from ResidentialLoanApplication where id in : appIds]);
        for(ResidentialLoanApplication app : opps.values()){
          leadIDs.add(app.OpportunityID);
        }
        if (leadIDs.size() == 1) {
            List<Opportunity> leadList = [
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
                WHERE Id IN :leadIDs
            ];

            additionalFileValidation(leadList);
            update leadList;
        }
    }

    /*
     * Validate If a Lead link to valid/current PQS and/or PQS.
     */
    public void additionalFileValidation(List<Opportunity> records) {
        List<Opportunity> addValid = new List<Opportunity>();
        List<String> leadAlerts = new List<String>();
        List<String> creditBureauMismatch = new List<String>();
        Boolean mismatchAcknowledged = false;
        //PRS_Availability__c /PRS_Current__c /PQS_Availability__c/PQS_Current__c
        Map<String, Decimal> leadAgeMap = new Map<String, Decimal>();

        Product_Quote_Set__c currentPQS = new Product_Quote_Set__c();
            currentPQS = Utils.getCurrentProductQuoteSetRecord();
        Product_Rate_Set__c currentPRS = new Product_Rate_Set__c();
            currentPRS = Utils.getCurrentProductRateSetRecord();
        for (Opportunity l : records) {
            if (l.Product_Rate_Set__c != null && currentPRS != NULL && currentPRS.Id != l.Product_Rate_Set__c) {
                leadAlerts.add(Label.Warning_Message_Not_Current_PRS);
            }
            if (l.Product_Quote_Set__c != null && currentPQS != NULL && currentPQS.Id != l.Product_Quote_Set__c) {
                leadAlerts.add(Label.Warning_Message_Not_Current_PQS);
            }
            if (records.size() == 1) {
                list<LoanApplicationProperty> properties = [
                    SELECT
                        id,
                        CityFragment__c,
                        PropertyPostalCode,
                        PropertyCity,
                        PropertyStreet,
                        PropertyState,
                        PropertyStateCode,
                        LoanApplication.OpportunityId
                    FROM LoanApplicationProperty
                    WHERE LoanApplication.OpportunityId = :l.id
                ];

                List<LoanApplicant> propertyMembers = [
                    SELECT
                        id,
                        Contact.Date_of_Birth__c,
                        Contact.FinServ__Age__c,
                    	role__c,
                        Is_Primary_Borrower__c,
                        Contact.Name,
                        Contact.Birthdate,
                        Income_Documents_Required__c,
                        LoanApplication.OpportunityId,
                        (
                            SELECT id, Date_Of_Birth__C, city__c, Postal_Code__c
                            FROM Credit_Reports__r
                            WHERE
                                Assessment_Eligible__c = TRUE
                                AND Credit_hit__c = TRUE
                            ORDER BY createddate DESC
                            LIMIT 1
                        )
                    FROM LoanApplicant
                    WHERE LoanApplication.OpportunityId = :l.id
                ];

                //String creditBureauMismatch = '';
                for (LoanApplicant propertyMember : propertyMembers) {
                    Boolean incomeDocsRequired = propertyMember.Income_Documents_Required__c;
                    mismatchAcknowledged = l.Mismatch_Acknowledgement__c;
                    if (propertyMember.Credit_Reports__r.size() > 0) {
                        Datetime crDOB = propertyMember.Credit_Reports__r[0] .Date_Of_Birth__C;
                        Datetime pmDOB = propertyMember.Contact.Birthdate;

                        String crCity = propertyMember.Credit_Reports__r[0] .City__c;
                        String pmCity = properties[0].PropertyCity;
                        String pmAVMCity = properties[0].CityFragment__c;

                        String crPostalCode = propertyMember.Credit_Reports__r[0] .Postal_Code__c;
                        String pmPostalCode = properties[0].PropertyPostalCode;

                        if (crDOB != null && crDOB != pmDOB) {
                            creditBureauMismatch.add( 'Date of birth mismatch (' + propertyMember.Contact.Name + ', ' + crDOB.format('MMM d, yyyy') + ')'  );
                        }

                        if ( (crPostalCode != null && !crPostalCode.equalsIgnoreCase(pmPostalCode.replace(' ', ''))) || (crCity != null && !crCity.equalsIgnoreCase(pmCity))  ) {
                            creditBureauMismatch.add( 'Applicant address city and postal code mismatch (' +  propertyMember.Contact.Name +  ', ' + crCity +  ', ' + crPostalCode + ')'  );
                        }
                    }

                    if (incomeDocsRequired) {  leadAlerts.add( 'Income documents required (' + propertyMember.Contact.Name +  ')'  ); }

                    if (
                        leadAgeMap.containsKey(
                            propertyMember.LoanApplication.OpportunityId
                        )
                    ) {
                        Decimal oldestAge = leadAgeMap.get(
                            propertyMember.LoanApplication.OpportunityId
                        );
                        l.Primary_Borrower_Age__c = (oldestAge >=
                            propertyMember.Contact.FinServ__Age__c)
                            ? oldestAge
                            : propertyMember.Contact.FinServ__Age__c;
                    } else {
                        l.Primary_Borrower_Age__c = propertyMember.Contact.FinServ__Age__c;
                        leadAgeMap.put(
                            propertyMember.LoanApplication.OpportunityId,
                            propertyMember.Contact.FinServ__Age__c
                        );
                    }
                }
            }
            l.Warning_Message__c = null;
            if (
                (creditBureauMismatch.isEmpty() || mismatchAcknowledged) &&
                leadAlerts.isEmpty() && !Test.isRunningTest()
            ) {
                l.Additional_File_Validation_Error__c = false;
            } else {
                l.Additional_File_Validation_Error__c = true;
                if (!leadAlerts.isEmpty()) {
                    l.Warning_Message__c = '<ul><li>' + String.join(leadAlerts, '</li><li>') + '</li></ul>';
                }

                if (!creditBureauMismatch.isEmpty() && !mismatchAcknowledged) {
                    /*for(String error : creditBureauMismatch) {
                        System.debug(error);
                    }*/
                    l.Warning_Message__c =
                        (String.IsNotEmpty(l.Warning_Message__c)
                            ? l.Warning_Message__c
                            : '') +
                        ';' +
                        '<ul style="margin-left: 30px;" ><li style="list-style-type: circle;">' +
                        String.join(
                            creditBureauMismatch,
                            '</li><li style="list-style-type: circle;">'
                        ) +
                        '</li></ul>';
                }
            }
            leadAlerts.clear();
        }
    }

    public class ApplicantAndApplication {
        @AuraEnabled
        public ResidentialLoanApplication application;
        @AuraEnabled
        public list<LoanApplicant> applicants;
    }

    /** HEB- When new applicant is inserted a new quote is requested */
    public void updateQuote(
        List<LoanApplicant> records,
        Map<Id, LoanApplicant> oldRecords
    ) {
        if (System.isBatch() || system.isFuture() || records.size() > 1 || FeatureManagement.checkPermission(Utils.CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD)){
            return;
        }

        //validate if quote request must be skipped
        if(QuoteRequestManager.doSkipQuoteService()){
            return;
        }

        //get newly created Property
        LoanApplicant newLoanApplicant = oldRecords == null ? records[0] : null;

        //get Opportunity Out of the property
        ResidentialLoanApplication app = [SELECT OpportunityId, Opportunity.Quote_Parameters_Updated__c
                                         FROM ResidentialLoanApplication 
                                         WHERE id = :newLoanApplicant.LoanApplicationId];
        if(app != null && app.OpportunityID != null && !Test.isRunningTest()){
            QuoteRequestValidationController.getQuoteForTrigger(app.opportunityId);
        }

    }


}