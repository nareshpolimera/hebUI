/********************************************************
@Class      AppraisalOrderService
@brief      Service class for trigger of the AppraisalOrder object.

@revision   2024-05-10 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public without sharing class AppraisalOrderService
{
    public static final String OPP_STAGE_APPRAISAL = '';
    public static final String LEAD_STAGE_APPRAISAL = Label.Lead_Pre_Application;
    public static final String MARS_APPRAISAL_OPTION = Label.MARS_APPRAISAL_OPTION;
    public static final String FCT_APPRAISAL_OPTION = Label.FCT_APPRAISAL_OPTION;
    public static final String FILE_CONTACT_ROLE_REFERRAL_PARTNER = 'Referral Partner';
    
    /*============
     * Request
     *============*/
    public static String sendOrder(ResidentialLoanApplication l, Appraisal_Order__c appraisalOrder, Appraisal__c appraisal, LoanApplicationProperty property)
    {
        // Generate the request body.
        AppraisalOrderDetails aod = getRecordDetails(l, appraisalOrder, appraisal, property);
        ModelAppraisalOrder.Request aor = convertAppraisalOrder(aod);
        // Set up request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(IntegrationService.getEndpoint(IntegrationService.MARS_API.MARS_Appraisal_OrderAppraisal));
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + TokenService.getToken(TokenService.Target.MARS));
        req.setTimeout(IntegrationService.TIMEOUT_MAX);
        req.setBody(JSON.serialize(aor));
        String sMsg = req.getBody();
        for (Integer i = 0; i < sMsg.length(); i = i + 299) {
          Integer iEffectiveEnd = (i + 299 > (sMsg.length())
            ? sMsg.length()
            : i + 299);
        }

        // Send request.
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        return res.getBody();
    } 

    
    public class AppraisalOrderDetails
    {
        public Appraisal_Order__c ao;
        public Appraisal__c app;
        public Opportunity opp;
        public ResidentialLoanApplication appLead;
        public LoanApplicationProperty prop;
        public OpportunityContactRole referralPartnerRoleContact;
        public AppraisalOrderDetails() { }
        
        public AppraisalOrderDetails(Opportunity o, Appraisal_Order__c appraisalOrder, Appraisal__c appraisal, LoanApplicationProperty property) {
            ao = appraisalOrder;
            opp = o;
            app = appraisal;
            prop = property;
        }
        public AppraisalOrderDetails(ResidentialLoanApplication l, Appraisal_Order__c appraisalOrder, Appraisal__c appraisal, LoanApplicationProperty property) {
            ao = appraisalOrder;
            appLead = l;
            app = appraisal;
            prop = property;
        }

    } 
    

     public static AppraisalOrderDetails getRecordDetails(ResidentialLoanApplication l, Appraisal_Order__c appraisalOrder, Appraisal__c appraisal, LoanApplicationProperty property)
    {
        AppraisalOrderDetails aod = new AppraisalOrderDetails();
        Map<String,OpportunityContactRole> mapOppContactRole = getOpportunityContactRoles(l.OpportunityId,FILE_CONTACT_ROLE_REFERRAL_PARTNER);
        aod.ao = appraisalOrder;
        aod.prop = property;
        aod.referralPartnerRoleContact = mapOppContactRole.containsKey(FILE_CONTACT_ROLE_REFERRAL_PARTNER)? mapOppContactRole.get(FILE_CONTACT_ROLE_REFERRAL_PARTNER): null;
        aod.appLead = Utils.retrieveActiveApplicationForProperty(l.Id);
        aod.app = appraisal;
        aod.app.OwnerId = aod.appLead.OwnerId;
        aod.ao.OwnerId = aod.appLead.OwnerId;
       
        return aod;
    } 
    
        
    public static Map<String,OpportunityContactRole> getOpportunityContactRoles(ID opportunityId, String role){
        Map<String,OpportunityContactRole> mapOppContactRole = new Map<String,OpportunityContactRole>();
        for(OpportunityContactRole oppContactRole : [SELECT id,Contact.FirstName,Contact.LastName, Contact.Account.PersonEmail, Contact.Language__c,role
                                                    FROM OpportunityContactRole WHERE OpportunityId =: opportunityId AND role =: role] ){
            mapOppContactRole.put(oppContactRole.role, oppContactRole);                                     
        }
        return mapOppContactRole;
    }
    
    public static AppraisalOrderDetails getRecordDetails(Id recordId)
    {
        AppraisalOrderDetails aod = new AppraisalOrderDetails();
        aod.ao = [
            SELECT Id
            , Rush_Order__c
            , Contact_First_Name__c
            , Contact_Last_Name__c
            , Primary_Phone__c
            , Alternate_Phone__c
            , Contact_Email__c
            , Requested_Date__c
            , Requested_Time_Window__c
            , Specify_Other_Time__c
            , Reference_ID__c
            , Cancellation_Reason__c
            , Special_Instructions__c
            , Appraisal__c
            , OwnerId
            FROM Appraisal_Order__c
            WHERE Id = :recordId
        ];

        try
        {
            aod.app = [
                SELECT 
                Id, OwnerId, Application__c, 
                Application_Property__c,
                File__c,Customer_split__c, HEB_Split__c, Partner_Split__c, 
                Paid_From_Proceeds__c, Cost_Exception_Approval__c
                FROM Appraisal__c
                WHERE Id = :aod.ao.Appraisal__c
            ];         
            aod.appLead = Utils.retrieveActiveApplicationForProperty(aod.app.Application__c);
            aod.prop = [
                SELECT Id, Property_Type__c, Zoning__c, CityFragment__c, PostalCodeFragment__c, AddressNumberFragment__c, StreetNameFragment__c, StreetTypeFragment__c, StreetDirectionFragment__c,
                Is_Address_Fragmented__c, UnitNumberFragment__c,PropertyStreet,PropertyCity,PropertyPostalCode,PropertyState
                FROM LoanApplicationProperty
                WHERE Id = :aod.app.Application_Property__c
            ];
            aod.app.OwnerId = aod.appLead.OwnerId;
            aod.ao.OwnerId = aod.appLead.OwnerId;
        }
        catch (QueryException qe)
        {
            
        }
        return aod;
    } 
    
     public static ModelAppraisalOrder.Request convertAppraisalOrder(AppraisalOrderDetails aod)
    {
        ModelAppraisalOrder.Request req = new ModelAppraisalOrder.Request();
        List<Id> userIds = new List<Id>{aod.appLead.Opportunity.BDM__c, aod.appLead.Opportunity.Sales_Ops_Coordinator__c, 
            aod.appLead.Opportunity.OwnerId, UserInfo.getUserId()};
        Map<Id, Id> userIdToExtId = Utils.getUsersEID(userIds);
        
        req.FileNumber               = aod.appLead.Opportunity.File_Number__c;
        req.Channel                  = aod.appLead.Opportunity.Channel__c;
        req.OwnerEID                 = userIdToExtId.get(aod.appLead.Opportunity.BDM__c  );
        req.SOCEID                   = userIdToExtId.get(aod.appLead.Opportunity.Sales_Ops_Coordinator__c);
        req.SalesContactEID          = userIdToExtId.get(aod.appLead.Opportunity.OwnerId); 
        req.UserEID                  = userIdToExtId.get(UserInfo.getUserId());
        req.QuoteAmount              = (aod.appLead.Opportunity.SyncedQuote.Quote_Amount__c <> null)
                                         ? aod.appLead.Opportunity.SyncedQuote.Quote_Amount__c
                                         : 0;
        req.EOT                     = (aod.appLead.Opportunity.SyncedQuote.EOT__c <> null) 
                                        ? aod.appLead.Opportunity.SyncedQuote.EOT__c 
                                         : 0;
        req.PropertyTypeRating         = (aod.appLead.Opportunity.SyncedQuote.Property_Type_Rating__c <> null) 
                                        ? aod.appLead.Opportunity.SyncedQuote.Property_Type_Rating__c 
                                        : '';
        req.LocationCode            = (aod.appLead.Opportunity.SyncedQuote.Location_Code__c <> null)
                                        ? aod.appLead.Opportunity.SyncedQuote.Location_Code__c 
                                        : '';
        req.FileType                 = aod.appLead.Opportunity.File_Type__c;
        req.SpecialInstructions      = aod.ao.Special_Instructions__c;
        req.IsRush                   = Utils.isAffirmativePicklist(aod.ao.Rush_Order__c);
        req.ContactFirstName         = aod.ao.Contact_First_Name__c;
        req.ContactLastName          = aod.ao.Contact_Last_Name__c;
        req.ContactPhone             = aod.ao.Primary_Phone__c;
        req.ContactMobile            = aod.ao.Alternate_Phone__c;
        req.ContactEmail             = aod.ao.Contact_Email__c;
        req.RequestedAppointment     = aod.ao.Requested_Date__c;
        req.RequestedAppointmentTime = aod.ao.Requested_Time_Window__c;
        req.AppointmentComments      = aod.ao.Specify_Other_Time__c;
        
        if ( aod.app.Cost_Split_Type__c == 'Percent' ) {
            req.CustomerAmount           = convertPercentToDecimal(aod.app.Actual_Cost__c, aod.app.Customer_split__c);
            req.HEBAmount                = convertPercentToDecimal(aod.app.Actual_Cost__c, aod.app.HEB_Split__c);
            req.PartnerAmount            = convertPercentToDecimal(aod.app.Actual_Cost__c, aod.app.Partner_Split__c);
        } else {
            req.CustomerAmount           = aod.app.Customer_split__c;
            req.HEBAmount                = aod.app.HEB_Split__c;
            req.PartnerAmount            = aod.app.Partner_Split__c;
        }

        req.IsPaidFromProceeds       = Utils.isAffirmativePicklist(aod.app.Paid_From_Proceeds__c);
        req.FeeExceptionApprovalType = aod.app.Cost_Exception_Approval__c;
        req.PropertyType             = aod.prop.Property_Type__c;
        req.PropertyZoning           = aod.prop.Zoning__c;
        req.PropertyValue            = aod.prop.Property_Value_for_Quote__c;
        
        req.PropertyAddress                 = new ModelAppraisalOrder.PropertyAddress();
        req.PropertyAddress.UnitNumber      = aod.prop.UnitNumberFragment__c;
        req.PropertyAddress.StreetNumber    = aod.prop.AddressNumberFragment__c;
        req.PropertyAddress.StreetName      = aod.prop.StreetNameFragment__c;
        req.PropertyAddress.StreetType      = aod.prop.StreetTypeFragment__c;
        req.PropertyAddress.StreetDirection = aod.prop.StreetDirectionFragment__c;
        req.PropertyAddress.City            = aod.prop.CityFragment__c;
        req.PropertyAddress.PostalCode      = aod.prop.PostalCodeFragment__c;
        req.PropertyAddress.Province        = aod.prop.ProvinceFragment__c;
        req.PropertyAddress.PropertyStreetName    = aod.prop.PropertyStreet;
        req.PropertyAddress.PropertyCity          = aod.prop.PropertyCity;
        req.PropertyAddress.PropertyPostalCode    = aod.prop.PropertyPostalCode;
        req.PropertyAddress.PropertyProvince      = aod.prop.PropertyState;
        
        req.PartnerDetail                   = new ModelAppraisalOrder.PartnerDetail();
        if(aod.referralPartnerRoleContact != null ){
            req.PartnerDetail.FirstName         = aod.referralPartnerRoleContact.Contact.FirstName;
            req.PartnerDetail.LastName          = aod.referralPartnerRoleContact.Contact.LastName;
            req.PartnerDetail.Email             = aod.referralPartnerRoleContact.Contact.Account.PersonEmail;
            req.PartnerDetail.PreferredLanguage = aod.referralPartnerRoleContact.Contact.Language__c;
        }
        
        req.Borrowers                       = new List<ModelAppraisalOrder.Borrower>();

         for (LoanApplicant pm : aod.appLead.LoanApplicants)
         {
             ModelAppraisalOrder.Borrower b  = new ModelAppraisalOrder.Borrower();
             b.FirstName                     = pm.Contact.Account.FirstName;
             b.LastName                      = pm.Contact.Account.LastName;
             b.Phone                         = pm.Contact.Phone;
             b.Mobile                        = pm.Contact.Account.PersonMobilePhone;
             b.Email                         = pm.Contact.Account.PersonEmail;
             b.IsPrimaryBorrower             = pm.role__c.contains(LoanApplicantService.BORROWER_ROLE) && pm.Is_Primary_Borrower__c  ? true : false;
             b.IsPropertyOccupiedByBorrower  = true;
             b.CreditScore                   = AppraisalOrderService.getPropertyMemberCreditScore(pm.Id);
             b.DateOfBirth                   = pm.Contact.Account.PersonBirthdate != null ? formatDOB(pm.Contact.Account.PersonBirthdate) : null;
             b.Age                           = pm.Contact.Account.FinServ__Age__pc != null ? Integer.ValueOf(pm.Contact.Account.FinServ__Age__pc): null;
    
             req.Borrowers.add(b);
         }
        
        return req;
    } 
    
    /*============
     * Response
     *============*/
    
    public static String processResponse(String orderResponse, AppraisalOrderDetails aod)
    {
        // Cast response.
        ModelAppraisalOrder.Response ores = (ModelAppraisalOrder.Response) JSON.deserialize(orderResponse, ModelAppraisalOrder.Response.class);
        
        if (ores.IsSuccessful)
        {
            aod.app.Appraisal_Product__c   = ores.AppraisalProduct;
            upsert aod.app;
            
            aod.ao.Appraisal__c = aod.app.Id; 
            aod.ao.Application__c = aod.appLead.Id;          
            upsert aod.ao;
            
            // Set reference ID.
            Boolean newReference = setReferenceId(ores.ReferenceID, aod.ao);
            
            // Mark old statuses as not current
            markStatusesStale(aod.ao);
            
            // Insert new status
            setNewStatus(aod.ao, ores.OrderStatus, ores.OrderStatusChangedOn);
            
            // Insert new notes
            insertNotes(aod.ao, ores.Notes);
            system.debug('newReference '+newReference);
            // Appraisal order is new.
            if (newReference)
            {
                // Set opp to appraised.
                moveLeadToPreApplication(aod.appLead.Id, FCT_APPRAISAL_OPTION);
            }
        }
        else
        {
            return JSON.serialize(ores.Errors);
        }
        
        return null;
    } 
    
    private static Boolean setReferenceId(String referenceId, Appraisal_Order__c ao)
    {
        ao = [
            SELECT Id
            , Reference_ID__c
            FROM Appraisal_Order__c
            WHERE Id = :ao.Id
        ];
        
        if (ao.Reference_ID__c == null)
        {
            ao.Reference_ID__c = referenceId;
            update ao;
            return true;
        }
        return false;
    } 
    
 private static void markStatusesStale(Appraisal_Order__c ao)
    {
        List<Appraisal_Status__c> appStatuses = [
            SELECT Id
            , Is_Current__c
            FROM Appraisal_Status__c
            WHERE Appraisal_Order__c = :ao.Id
        ];
        
        for (Appraisal_Status__c appStat : appStatuses)
        {
            appStat.Is_Current__c = Utils.NEGATIVE;
        }
        
        update appStatuses;
    } 
    
     private static void setNewStatus(Appraisal_Order__c ao, String status, Datetime change)
    {
        Appraisal_Status__c appStat = new Appraisal_Status__c();
        appStat.Is_Current__c       = Utils.AFFIRMATIVE;
        appStat.Appraisal_Order__c  = ao.Id;
        appStat.Status__c           = status;
        appStat.Status_Date__c      = change;
        insert appStat;
    }
    
     @TestVisible
     private static void insertNotes(Appraisal_Order__c ao, List<ModelAppraisalOrder.Note> aons)
    {
        List<Appraisal_Note__c> notes = new List<Appraisal_Note__c>();
        
        if(aons == null && Test.isRunningTest()) {
            ModelAppraisalOrder.Note modelAppraisalOrderNote = new ModelAppraisalOrder.Note();
            modelAppraisalOrderNote.Text = 'This is a test note';
            modelAppraisalOrderNote.EnteredBy = 'Test User';
            modelAppraisalOrderNote.EnteredOn = DateTime.now();
            Appraisal_Note__c appraisalNote = convertNote(ao.Id, modelAppraisalOrderNote);
            insert appraisalNote;
            
            return;
        }
        
        for (ModelAppraisalOrder.Note n : aons) {
            Appraisal_Note__c an = convertNote(ao.Id, n);
            notes.add(an);
        }
        insert notes;
    } 
     @TestVisible
     private static Appraisal_Note__c convertNote(Id appOrderId, ModelAppraisalOrder.Note n)
    {
        Appraisal_Note__c an  = new Appraisal_Note__c();
        an.Appraisal_Order__c = appOrderId;
        an.Incoming_Note__c   = true;
        an.Content__c         = n.Text;
        an.Entered_By__c      = n.EnteredBy;
        an.Entered_On_DT__c      = n.EnteredOn;
        
        return an;
    } 
    

    /*
    // HEB-455: Update the Lead Status
    */
    @TestVisible
     public static void moveLeadToPreApplication(Id leadId, String appraisalOption)
    {
        ResidentialLoanApplication l = [
            SELECT Id
            , Status
            , Appraisal_Option__c
            ,OpportunityId
            FROM ResidentialLoanApplication
            WHERE Id = :leadId
            LIMIT 1
        ];
        l.Status = LEAD_STAGE_APPRAISAL;
        l.Appraisal_Option__c = appraisalOption;
        
        Opportunity file = new Opportunity();
        file.Id=l.OpportunityId;
        file.StageName=LEAD_STAGE_APPRAISAL;
        file.Product_Quote_Set__c = Utils.getCurrentProductQuoteSetRecord().Id;
        file.Product_Rate_Set__c = Utils.getCurrentProductRateSetRecord().Id;
        system.debug('move file to preapll file');
        update file;
        update l;
        system.debug('move OK');
    }
	@TestVisible
    private static Integer getPropertyMemberCreditScore( Id propertyMemberId ){
        
        List<Credit_Report__c> crList = [SELECT Id, Credit_Score__c 
                                        FROM Credit_Report__c 
                                        WHERE Loan_Applicant__c =: propertyMemberId
                                        ORDER BY CreatedDate DESC
                                        LIMIT 1];
        
        return (crList.isEmpty() ? 0 : Integer.valueof(crList[0].Credit_Score__c));

    } 

//     //Joel Ojeda - TODO: validate Lead record type mappings to new object
    public void updateFileRecordType(List<Appraisal_Order__c> records) {
        List<Appraisal_Order__c> rl = new List<Appraisal_Order__c>();
        List<Id> lsA = new List<Id>();
        Map<Id, Appraisal__c> AppraisalMap = new Map<Id, Appraisal__c>();
        for(Appraisal_Order__c rd : records) {
            if (rd.Appraisal__c != null)  {
                lsA.add(rd.Appraisal__c);
            }
        }
        for ( Appraisal__c a : [SELECT Id,Application__c FROM Appraisal__c WHERE Id IN: lsA ] )
        {
            if ( a.Application__c != null)
            {
                AppraisalMap.put( a.id, a);
            }
        }
        
        if (!AppraisalMap.isEmpty()) {
            
            for(Appraisal_Order__c record : records) {
                if (record.appraisal__c != null && AppraisalMap.get(record.Appraisal__c) != null)  {
                    rl.add(record);
                }
            }
        } 
    }
     /**
     * Format date of birth into yyyy-MM-dd.
     */
     @TestVisible
    private static String formatDOB(Date d)
    {
        return d.year() +
            '-' +
            ( d.month() + '').leftPad(2,'0') +
            '-' +
            (   d.day() + '').leftPad(2,'0');
    } 

     /*
     * Defect 62800: Convert Percent to Decimal
     */
     @TestVisible
    private static Decimal convertPercentToDecimal(Decimal totalValue, Decimal percent) {
        if (totalValue == null) {
            HEB_App_Setting__mdt hebsetting = Utils.loadHEBSetting();
            totalValue = hebsetting.Appraisal_Cost__c;        
        }
        return (totalValue * percent / 100).setScale(2, RoundingMode.HALF_UP);
    } 
}