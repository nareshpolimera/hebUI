public class AppraisalOrderController
{
  //error messages
    public static final String ALREADY_SUBMITTED = Label.Error_Already_Submitted;
    public static final String ALREADY_COMPLETED = Label.Error_ALREADY_COMPLETED;
    public static final String CANNOT_CANCEL = Label.Error_CANNOT_CANCEL;
    public static final String CANNOT_UPDATE_FEE = Label.Error_CANNOT_UPDATE_FEE;
    public static final String BORROWER_MISSING = Label.Error_BORROWER_MISSING;
    public static final String PRIMARY_BORROWER_MISSING = Label.Error_PRIMARY_BORROWER_MISSING;
    public static final String MISSING_APP_VALUES = Label.Error_MISSING_APP_VALUES;
    public static final String MISSING_APP_ORDER_VALUES = Label.Error_MISSING_APP_ORDER_VALUES;
    public static final String MISSING_OPP_VALUES = Label.Error_MISSING_OPP_VALUES;
    public static final String MISSING_PROP_VALUES = Label.Error_MISSING_PROP_VALUES;
    public static final String MISSING_PROP_MEM_VALUES = Label.Error_MISSING_PROP_MEM_VALUES;
    public static final String OPPORTUNITY_REQUIRED = Label.Error_OPPORTUNITY_REQUIRED;
    public static final String AVM_REQUIRED = Label.Error_AVM_REQUIRED;
    public static final String FEES_CANNOT_BE_UPDATED = Label.Error_Appraisal_Fees_Cannot_Be_Updated_on_Opp;

//     /*
//      * HEB-445: new method to retrieve the File details and Appraisal
//      */
     @AuraEnabled
     public static AppraisalFile retrieveAppraisalFile(Id recordId) {
         return new AppraisalFile(recordId);
     }
    
    public class AppraisalFile {
        @AuraEnabled
        public ResidentialLoanApplication app;
        //@AuraEnabled 
        //public Lead appLead;
        @AuraEnabled
        public String fileStatus;
        @AuraEnabled
        public Id propertyId;
        @AuraEnabled
        public Boolean isLead;
         @AuraEnabled 
        public String appraisalOption;
         
        public AppraisalFile(Id recordId) {
            if(Utils.validateIsLead(recordId)) {
                this.isLead = true;
            }
            else {
                this.isLead = false;
                this.app = Utils.retrieveActiveApplicationForProperty(recordId);
               this.fileStatus = this.app.Opportunity.StageName;                
                this.propertyId = !this.app.LoanApplicationProperties.isEmpty() ? this.app.LoanApplicationProperties[0].Id : null;
                this.appraisalOption = this.app.Appraisal_Option__c;
            }
        }
    }

    
    /*
     * HEB-310: return existing Appraisal and Appraisal Orders for given Opportunity
     */
    @AuraEnabled
    public static List<Appraisal_Order__c> retrieveOrders(Id recordId) {
        List<Appraisal_Order__c> orders = [
            SELECT 
                Id, Name,
                Alternate_Phone__c, Primary_Phone__c,
                Contact_First_Name__c, Contact_Last_Name__c, Contact_Email__c, 
                Appraisal__c, Reference_ID__c, 
                Cancellation_Reason__c, 
                Appraisal__r.Application__c,  
                Requested_Date__c, Requested_Time_Window__c, Rush_Order__c, Specify_Other_Time__c, Special_Instructions__c,
                (
                    SELECT Id, Status__c, Status_Date__c
                    FROM Appraisal_Status__r
                    WHERE Is_Current__c = :Utils.AFFIRMATIVE
                )
            FROM Appraisal_Order__c 
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId = :recordId
            ORDER BY CreatedDate DESC
        ];
        return orders;
    }

    /* 
     * HEB-310: Check for existing active order
     */
    @AuraEnabled
    public static Boolean allowOrder(Id recordId) {

        /*
         * Check if the user previously selected "Order from MARS" and allow them to back out
         */
        ResidentialLoanApplication rla = [
            SELECT Id, Status, Appraisal_Option__c
            FROM ResidentialLoanApplication
            WHERE Id = :recordId
        ];
        if (rla.Status == AppraisalOrderService.LEAD_STAGE_APPRAISAL && rla.Appraisal_Option__c == AppraisalOrderService.MARS_APPRAISAL_OPTION)
        
        return true;

        /*
         * Check for an existing active order and if none exists, allow them to order
         */
        return (retrieveOrders(recordId).size() == 0);
    }

    
    public class AppraisalProperty { 
        @AuraEnabled
        public LoanApplicationProperty p;
        @AuraEnabled
        public String error;
        
        public AppraisalProperty(LoanApplicationProperty prop, String e) {
            this.p = prop;
            this.error = e;
        }
    }
    
    /*
     * HEB-310: retrieve the Property details,and run the parseAddress service if it hasn't already run
     * HEB-739: use new wrapper class to return warning around AVM
     */
    @AuraEnabled 
    public static AppraisalProperty retrieveProperty(Id propertyId, Boolean runParseAddress) {
        List<LoanApplicationProperty> pLoans = [
            SELECT Id, Is_Address_Fragmented__c, LoanApplicationId
            FROM LoanApplicationProperty
            WHERE Id = :propertyId
            LIMIT 1
        ];
        LoanApplicationProperty p = !pLoans.isEmpty()? pLoans[0] : new LoanApplicationProperty();
        String errorStr;
        if (!pLoans.isEmpty() && p.Is_Address_Fragmented__c <> Utils.AFFIRMATIVE && runParseAddress) { 
            try {
            AVMRequestService.runAddressParse(p.LoanApplicationId);
            } catch (Exception e) {
                errorStr = e.getMessage();
            }
        }

        List<LoanApplicationProperty> pLoans2 = [
            SELECT
                Id, Name,
                AddressNumberFragment__c, AddressTimeZone__c, BoxNumberFragment__c, 
                CityFragment__c, Country__c, 
                Is_Address_Fragmented__c, Is_Land_Owned__c, Is_PO_Box__c,
                PostalCodeFragment__c, Property_Type__c, ProvinceFragment__c,
                StreetNameFragment__c, StreetTypeFragment__c, StreetDirectionFragment__c, Property_Value_for_Quote__c,
                UnitNumberFragment__c, UnitTypeFragment__c, Water_Filtration_Installed__c, Water_Type__c, Zoning__c,
                PropertyStreet,PropertyCity,PropertyPostalCode,PropertyState
            FROM LoanApplicationProperty 
            WHERE
                Id = :propertyId
        ];
        p = !pLoans2.isEmpty() ? ploans2[0] : new LoanApplicationProperty();
        return new AppraisalProperty(p, errorStr);
    }

    
    /*
     * HEB-310: Validate Appraisal Can be Ordered
     *     - no POA must exist on the file
     */
    @AuraEnabled
    public static Boolean activePOAs(Id recordId) {
        List<LoanApplicant> members = [SELECT id FROM LoanApplicant WHERE LoanApplicationId = :recordId];
        if(!members.isEmpty()){
            List<Property_Member_Relationship__c> poaRelations = [SELECT id FROM Property_Member_Relationship__c 
                                                                  WHERE Property_Member__c IN :members 
                                                                  AND Relationship_Type__c = 'POA'];
            return !(poaRelations.isEmpty());
        }
        return false;
    }

    /*
     * HEB-310: Create Appraisal Order to order from MARS
     */
    @AuraEnabled
    public static Boolean appraisalOrderFromMars(Id recordId) {
        if(!allowOrder(recordId))
            throw new AuraHandledException(Label.Error_Appraisal_Cannot_Be_Ordered);
        try {
            AppraisalOrderService.moveLeadToPreApplication(recordId, AppraisalOrderService.MARS_APPRAISAL_OPTION);
        } catch(DmlException e) {
           throw new AuraHandledException(e.getMessage());
        }
        return true;
    }

    
    /*
     * HEB-310: Create Appraisal Order to order from FCT
     */
    @AuraEnabled
    public static Boolean appraisalOrderFromFCT(ResidentialLoanApplication l, LoanApplicationProperty property, Appraisal__c appraisal, Appraisal_Order__c appraisalOrder) {
        // start by validating 
        try {
            // update Property__c for Address Fragments changed by the end user
            AppraisalOrderService.AppraisalOrderDetails aod = AppraisalOrderService.getRecordDetails(l, appraisalOrder, appraisal, property);
            System.debug('aod > ' + aod);
            OrderValidationReport ovr = validateOrder(aod.appLead, aod.ao, aod.app, aod.prop);
            System.debug('ovr > ' + ovr);
            if (ovr.valid) {
                String orderResponse = AppraisalOrderService.sendOrder(aod.appLead, aod.ao, aod.app, aod.prop);
                 System.debug('orderResponse > ' + orderResponse);
                ModelAppraisalOrder.Response ores = (ModelAppraisalOrder.Response) JSON.deserialize(orderResponse, ModelAppraisalOrder.Response.class);
				System.debug('ores > ' + ores);
                if (ores.errors <> null && !ores.errors.isEmpty()) {
                    String errorStr = String.join(ores.errors, ';');
                    throw new AuraHandledException(errorStr);
                }
                String processResponse = AppraisalOrderService.processResponse(orderResponse, aod);
                System.debug('processResponse > ' + processResponse);
                update property;
                
            } else {
                String ovrErrors = String.join(ovr.errors, ';');
                System.debug('ovrErrors > ' + ovrErrors);
                AuraHandledException e = new AuraHandledException(ovrErrors);
                e.setMessage(ovrErrors);
                throw e;
            }
            
            
        } catch(DmlException e) {
            System.debug('e > ' + e);
            AuraHandledException ae = new AuraHandledException(e.getMessage());
            ae.setMessage(e.getMessage());
            throw ae;
        }
        return true;
    }
    
    /*
     * HEB-310: Update method below to construct AppraisalOrderDetails based on Opportunity and uncommitted data
     * - lightning component will send Opportunity details, along w/ uncommitted Appraisal and Appraisal Order
     */
    @AuraEnabled
    public static OrderValidationReport validateOrder(ResidentialLoanApplication l, Appraisal_Order__c appraisalOrder, Appraisal__c appraisal, LoanApplicationProperty prop) {
        AppraisalOrderService.AppraisalOrderDetails aod = AppraisalOrderService.getRecordDetails(l, appraisalOrder, appraisal, prop);
        OrderValidationReport ovr = new OrderValidationReport();
        
        // Order validation.
        if (aod.ao != null)
        {
            if (aod.ao.Reference_ID__c != null)
            {
                ovr.addError(ALREADY_SUBMITTED);
            }
            
            // Validate Appraisal record fields.
            String orderMissingfields = '';
            if (aod.app.Customer_Split__c      == null) orderMissingfields += 'Customer Split';
            if (aod.app.HEB_Split__c           == null) orderMissingfields += ', HEB Split';
            if (aod.app.Partner_Split__c       == null) orderMissingfields += ', Partner Split';
            if ((aod.app.Paid_From_Proceeds__c == Utils.AFFIRMATIVE 
                 || aod.app.HEB_Split__c > 0
                )
                && String.isBlank(aod.app.Cost_Exception_Approval__c)) orderMissingfields += ', Cost Exception Approval';
            if (String.isNotBlank(orderMissingfields))
            {
                ovr.addError(MISSING_APP_VALUES + orderMissingfields.removeStart(', '));
            }
            
            // Validate Property record fields.
            orderMissingfields = '';
            if (String.isBlank(aod.prop.Property_Type__c)) orderMissingfields += 'Property Type';
            if (String.isBlank(aod.prop.Zoning__c)) orderMissingfields += ', Zoning';
            if (String.isNotBlank(orderMissingfields))
            {
                ovr.addError(MISSING_PROP_VALUES + orderMissingfields.removeStart(', '));
            }
            
        }
        
        // Opportunity validation.
        if (aod.appLead != null)
        {
            // Validate Opportunity record fields.
            String missingfields = '';
             if (String.isBlank(aod.appLead.Opportunity.File_Number__c)) missingfields += 'File Number ';
             if (String.isBlank(aod.appLead.Opportunity.Channel__c)) missingfields += ', Channel ';
             if (aod.prop.Property_Value_for_Quote__c == null) missingfields += ', Property Value';
             if (aod.appLead.Opportunity.File_Type__c == null) missingfields += ', File Type';
            
            if (String.isNotBlank(missingfields))
            {
                ovr.addError(MISSING_OPP_VALUES + missingfields.removeStart(', '));
            }
            
            // Check if the application list is null or empty
            if (aod.appLead == null || aod.appLead.LoanApplicants == null || aod.appLead.LoanApplicants.isEmpty())
            {
                ovr.addError(BORROWER_MISSING);
            }
            // Check if the first element of the list is null
            else if (aod.appLead.LoanApplicants[0] == null)
            {
                ovr.addError(BORROWER_MISSING);
            }
            else
            {
                missingfields = '';
                for (LoanApplicant la : aod.appLead.LoanApplicants)
                {
                    if (String.isBlank(la.Contact.Account.FirstName)) missingfields += 'First Name ';
                    if (String.isBlank(la.Contact.Account.LastName)) missingfields += ', Last Name ';
                    if (String.isBlank(la.Contact.Phone)) missingfields += ', Phone ';
                }
                if (String.isNotBlank(missingfields))
                {
                    ovr.addError(MISSING_PROP_MEM_VALUES + missingfields.removeStart(', '));
                }
            }
        }
        else
        {
            ovr.addError(OPPORTUNITY_REQUIRED);
        }
        
        return ovr;
    }
 
    @AuraEnabled
    public static String validateCancellation(Id recordId)
    {
        AppraisalOrderService.AppraisalOrderDetails aod = AppraisalOrderService.getRecordDetails(recordId);
        
        OrderValidationReport ovr = new OrderValidationReport();
        
        // Order validation.
        if (aod.ao != null)
        {
            if (String.isBlank(aod.ao.Reference_ID__c)) ovr.addError(CANNOT_CANCEL);
            if (aod.ao.Requested_Date__c      <= Date.today()) ovr.addError(ALREADY_COMPLETED);
            
            // Validate Appraisal record fields.
            String missingfields = '';
            if (String.isBlank(aod.ao.Cancellation_Reason__c)) missingfields += 'Cancellation Reason';
            if (String.isNotBlank(missingfields))
            {
                ovr.addError(MISSING_APP_ORDER_VALUES + missingfields.removeStart(', '));
            }
        }
        
        return JSON.serialize(ovr);
    }
    
    @AuraEnabled
    public static String validateUpdateFee(Id recordId, Appraisal__c appraisal)
    {
        AppraisalUpdateFeeService.AppraisalFeeUpdateDetails afud = AppraisalUpdateFeeService.getRecordDetails(recordId, appraisal);
        
        OrderValidationReport ovr = new OrderValidationReport();
        // Order validation.
        if (afud.ao != null)
        {
            if (String.isBlank(afud.ao.Reference_ID__c))
            {
                ovr.addError(CANNOT_UPDATE_FEE);
            }
            
            // Validate Appraisal record fields.
            String appraisalMissingfields = '';
            if (afud.app.Customer_Split__c             == null) appraisalMissingfields += 'Customer Split';
            if (afud.app.HEB_Split__c                  == null) appraisalMissingfields += ', HEB Split';
            if (afud.app.Partner_Split__c              == null) appraisalMissingfields += ', Partner Split';
            if ((afud.app.Paid_From_Proceeds__c        == Utils.AFFIRMATIVE 
                 || afud.app.HEB_Split__c > 0
                )
                && String.isBlank(afud.app.Cost_Exception_Approval__c)) appraisalMissingfields += ', Cost Exception Approval';
            if (String.isNotBlank(appraisalMissingfields))
            {
                ovr.addError(MISSING_APP_VALUES + appraisalMissingfields.removeStart(', '));
            }
            // Opportunity validation.
            if (afud.appLead.Opportunity != null)
            {
                // Validate Opportunity record fields.
                String missingfields = '';
                if (String.isBlank(afud.appLead.Opportunity.File_Number__c)) missingfields += 'File Number ';
                if (String.isBlank(afud.appLead.Opportunity.Channel__c)) missingfields += ', Channel ';
                
                if (String.isNotBlank(missingfields))
                {
                    ovr.addError(MISSING_OPP_VALUES + missingfields.removeStart(', '));
                }
                
                // Property Member record fields.
                if (afud.appLead.LoanApplicants == null)
                {
                    ovr.addError(PRIMARY_BORROWER_MISSING);
                }
                else
                {
                    missingfields = '';
                    for (LoanApplicant pm : afud.appLead.LoanApplicants)
                    {
                        if (String.isBlank(pm.Contact.Account.LastName)) missingfields += 'Last Name ';
                    }
                    if (String.isNotBlank(missingfields))
                    {
                        ovr.addError(MISSING_PROP_MEM_VALUES + missingfields.removeStart(', '));
                    }
                }
            }
            else
            {
                ovr.addError(OPPORTUNITY_REQUIRED);
            }
        }
        return JSON.serialize(ovr);
    }
    
    public class OrderValidationReport
    {
        public Boolean valid = true;
        public List<String> errors = new List<String>();
        
        public void addError(String error)
        {
            errors.add(error);
            valid = false;
        }
    }
    
    @AuraEnabled
    public static String cancelAppraisalOrder(Id recordId)
    {
        String cancelResponse = AppraisalCancelOrderService.sendCancellation(recordId);
        String result = AppraisalCancelOrderService.processResponse(cancelResponse, recordId);
        return null;
    }
    
    /*
     * wrapper method to be called from triggers to allow callout to external system
     */
    @future(callout=true)
    public static void cancelAppraisalOrderPostClosedLost(Id recordId) {
        AppraisalOrderController.cancelAppraisalOrder(recordId);
    }

    
    @AuraEnabled
    public static String sendNote(Id recordId)
    {
        return null;
    }
    
    @AuraEnabled
    public static String updateFee(Id recordId, Appraisal__c appraisal)
    {
       
        String orderResponse = AppraisalUpdateFeeService.updateFee(recordId, appraisal);
        String result = AppraisalUpdateFeeService.processResponse(orderResponse, recordId, appraisal);
        if (result <> null) 
            throw new AuraHandledException(result);
        return null;
    }

    /*
     * HEB-310: get list of notes associated with an Appraisal Order
     */
    @AuraEnabled 
    public static List<Appraisal_Note__c> getNotes(Id appraisalOrderId) {
       return [
            SELECT Id, Content__c, Entered_By__c, Entered_On_DT__c, Incoming_Note__c, Send_Note_Status__c 
            FROM Appraisal_Note__c
            WHERE Appraisal_Order__c = :appraisalOrderId
            ORDER BY Entered_On_DT__c DESC
        ];
    }

    /*
     * HEB-310: get list of statuses associated with an Appraisal Order
     */
    @AuraEnabled 
    public static List<Appraisal_Status__c> getStatuses(Id appraisalOrderId) {
        return [
            SELECT Id, Is_Current__c, Status__c, Status_Date__c
            FROM Appraisal_Status__c
            WHERE Appraisal_Order__c = :appraisalOrderId
            ORDER BY Status_Date__c DESC
        ];
    }

    /*
     * BUG-8352: Appraisal Cancel Order Check Sales users
     */
    @AuraEnabled
    public static Boolean hasSalesPermission(){
        List<PermissionSetGroup> salesPMGroup = [SELECT ID FROM PermissionSetGroup 
                                                 WHERE DeveloperName IN ('HEB_Sales_PSG','HEB_Broker_Underwriter_PSG','BDA','BDM',
                                                                        'HEB_BDA_PSG','HEB_BDM_PSG','HEB_SOC') ];
        List<PermissionSetAssignment> salesPermissions = [SELECT ID FROM PermissionSetAssignment 
                                                          WHERE AssigneeId = :Userinfo.getUserId() 
                                                          AND PermissionSetGroupId IN :salesPMGroup];
        return salesPermissions.size()>0? true:false;
    }

    /*
     * HEB-605 - retrieve the default borrower to use for default values in Appraisal
     */
    @AuraEnabled
    public static ResidentialLoanApplication retrievePrimaryBorrower(Id appId) {
        List<ResidentialLoanApplication> applications = [
            SELECT Id,
                Opportunity.Account.PersonContact.Alternate_Phone_Number__c,
                Opportunity.Account.PersonContact.FirstName,
                Opportunity.Account.PersonContact.LastName,
                Opportunity.Account.PersonContact.Phone,
                Opportunity.Account.PersonContact.Email,
                Opportunity.Account.Phone
            FROM ResidentialLoanApplication
            WHERE Id =: appId  
            LIMIT 1
        ];
        if (!applications.isEmpty())  {
           for (ResidentialLoanApplication application: applications)    {
                if (application.Opportunity!=null &&
					application.Opportunity.Account!=null &&
					application.Opportunity.Account.PersonContact!=null &&
					String.isBlank(application.Opportunity.Account.PersonContact.Alternate_Phone_Number__c) && 
                    String.isNotBlank(application.Opportunity.Account.Phone)) {
                    application.Opportunity.Account.PersonContact.Alternate_Phone_Number__c = application.Opportunity.Account.Phone;
                }

                // Required for validation in the API expecting 10 digits phones
                if(!string.isBlank(application.Opportunity.Account.PersonContact.Phone))
                	application.Opportunity.Account.PersonContact.Phone = UserManagement.formatPhoneNumber('1',application.Opportunity.Account.PersonContact.Phone)?.substringAfter('+1 ')?.right(10);
                if(!string.isBlank(application.Opportunity.Account.PersonContact.Alternate_Phone_Number__c))
                    application.Opportunity.Account.PersonContact.Alternate_Phone_Number__c = UserManagement.formatPhoneNumber('1',application.Opportunity.Account.PersonContact.Alternate_Phone_Number__c)?.substringAfter('+1 ')?.right(10);
           }

        }
        return (applications.isEmpty() ? new ResidentialLoanApplication() : applications[0]);
    
    }  
    
    /*
     * HEB-- retrieve File Quote Amount
     */
    @AuraEnabled
    public static List<ResidentialLoanApplication> retriveLeadQuoteAmount(Id appId) {
        List<ResidentialLoanApplication> resultSet = [SELECT Id,OpportunityId, Opportunity.SyncedQuoteId, Opportunity.SyncedQuote.Quote_Amount__c FROM ResidentialLoanApplication WHERE Id =:appId  limit 1];        
        return resultSet;
    }
}