public class QuoteRequestService {
    
    public static Logger F;
    public static string classContext;
    public static boolean bypassThisTrigger = false;

    public static String sendRequest(Opportunity sobj) {
        // Generate the request body.
        ModelQuote.Request qr = QuoteRequestService.generateQuoteRequest(sObj);
        system.debug('!!! Quote JSON = ' + JSON.serialize(qr) );
        // Set up request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            IntegrationService.getEndpoint(
                IntegrationService.MARS_API.Quote_Request
            )
        );
        req.setMethod(IntegrationService.METHOD_POST);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader(
            'Authorization',
            'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
        );
        req.setBody(JSON.serialize(qr));
        req.setTimeOut(IntegrationService.TIMEOUT_MAX);

        // Send request.
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('!!! Quote response message = ' + res.getBody() );
        system.debug('!!! Quote response Status = ' + res.getStatus() );
        //save callout log
        if(res.getStatusCode()!=200){
            F = new Logger('QuoteRequestService');
            classContext = 'QuoteRequestService';
            F.info('Generate quotes on Opportunity : '+sobj.id+' MARS callout response code '+res.getStatusCode());
            LoggerDMLService.saveLog(F);
        }
        return res.getBody();
    }

    /*============
     * Conversions
     *============*/

    public static ModelQuote.Request generateQuoteRequest(
        Opportunity reqObject
    ) {
        ModelQuote.Request req = new ModelQuote.Request();
        req.FileNumber = reqObject.File_Number__c;
        req.GenerateFileNumber = true;
        req.ProductType = reqObject.Product_Type__c!=null?reqObject.Product_Type__r.Name:'';
        req.TermType = reqObject.Term__c;

        ResidentialLoanApplication application = getApplication(reqObject);

        if (reqObject.Product_Rate_Set__c != null) {
            req.ProductRateSetID = Integer.valueof(
                reqObject.Product_Rate_Set__r.External_ID__c
            );
            req.RateCommitmentDate = reqObject.Product_Rate_Set__r.Effective_Date__c;
        } else {
            Product_Rate_Set__c currentPRS = Utils.getCurrentProductRateSetRecord();
            if (currentPRS != null) {
                req.ProductRateSetID = Integer.valueof(
                    currentPRS.External_ID__c
                );
                req.RateCommitmentDate = currentPRS.Effective_Date__c;
            }
        }

        if (reqObject.Product_Quote_Set__c != null) {
            req.ProductQuoteSetID = Integer.valueof(
                reqObject.Product_Quote_Set__r.External_ID__c
            );
            req.QuoteCommitmentDate = reqObject.Product_Quote_Set__r.Effective_Date__c;
        } else {
            Product_Quote_Set__c currentPQS = Utils.getCurrentProductQuoteSetRecord();
            if (currentPQS != null) {
                req.ProductQuoteSetID = Integer.valueof(
                    currentPQS.External_ID__c
                );
                req.QuoteCommitmentDate = currentPQS.Effective_Date__c;
            }
        }

        Decimal securedDebt = 0;
        for (
            LoanApplicationLiability liability : application
                ?.LoanApplicationLiabilities
        ) {
            if (liability.Secured__c && liability.Include_Debt__c) {
              securedDebt += liability.CreditLimitAmount != null ? liability.CreditLimitAmount : 0;
            }
        }

        req.TotalSecuredDebt = securedDebt;

        ModelQuote.Property p = getProperty(application);
        req.Property = p;

        List<ModelQuote.Customer> cs = getPropertyMembers(application);
        req.Customers = cs;

        return req;
    }

    /**
     * Format date of birth into yyyy-MM-dd.
     */
    private static String formatDOB(Date d) {
        return d.year() +
            '-' +
            (d.month() + '').leftPad(2, '0') +
            '-' +
            (d.day() + '').leftPad(2, '0');
    }

    private static final String INELIGIBLE_VALIDATION = 'Validation';
    public static String processResponse(
        String marsQuote,
        Opportunity requestObj
    ) {
        try{
            // Cast response.
            ModelQuote.Response qres = (ModelQuote.Response) JSON.deserialize(
                marsQuote,
                ModelQuote.Response.class
            );
    
    
            // Process response.
            List<Quote> newQuotes = getQuotes(qres, requestObj);
            system.debug('[QuoteRequestService] insert quotes: ' + newQuotes );
            insert newQuotes;

            List<Quote> oldQuotes = getOldActiveQuotes(newQuotes, requestObj.Id);
    
            // Update the SObject
            system.debug('[QuoteRequestService] processResponse File_Number__c: ' + requestObj.File_Number__c );
            if (requestObj.File_Number__c == null) {
                requestObj.File_Number__c = qres.fileNumber;
            }
    
            requestObj.Quote_Parameters_Updated__c = false;
    
            Boolean eligibleQ = false;
            Boolean quoteValidationFail = false;
            Boolean chipMaxQualified = false;
            Boolean chipQualified = false;
            String syncedQuoteId='';
    
            if (!newQuotes.isEmpty()) {
                for (Quote newQ : [
                    SELECT
                        Id,
                        Is_Eligible__c,
                        Product_Type__c,
                        Is_Ineligible_Reason__c
                    FROM Quote
                    WHERE Active_Quote__c = TRUE AND Id IN :newQuotes
                    ORDER BY CreatedDate DESC
                ]) {
    
                    if (newQ.Is_Eligible__c)
                        eligibleQ = true;
                    else if (
                        newQ.Is_Ineligible_Reason__c != null &&
                        newQ.Is_Ineligible_Reason__c.startsWithIgnoreCase(
                            INELIGIBLE_VALIDATION
                        )
                    )
                        quoteValidationFail = true;
    
                    if (newQ.Product_Type__c == 'CHIP Max' && newQ.Is_Eligible__c)
                        chipMaxQualified = true;
                    if (newQ.Product_Type__c == 'CHIP' && newQ.Is_Eligible__c)
                        chipQualified = true;
                    if(requestObj.Product_Type__c != null && (newQ.Product_Type__c == requestObj.Product_Type__r.Name))
                        requestObj.SyncedQuoteId = newQ.Id;
                }
    
                if (eligibleQ) {
                    requestObj.Quote_Status__c = Label.Quote_Status_Qualified;
                } else if (quoteValidationFail) {
                    requestObj.Quote_Status__c = Label.Quote_Status_Unqualified;
                } else {
                    requestObj.Quote_Status__c = Label.Quote_Status_Disqualified;
                }
                requestObj.CHIP_Max_Qualified__c = chipMaxQualified;
                requestObj.CHIP_Qualified__c = chipQualified;
            } 
            bypassThisTrigger = true;
            update requestObj;
            bypassThisTrigger = false;
            // Updating Old Quotes after File update to prevent lookup filter error
            update oldQuotes;
            return null;
        }
        catch(Exception ex)
        {
            system.debug('[QuoteRequestService] Generate quotes on Opportunity : '+requestObj.Id+' process MARS response '+ ex.getMessage()+'. '+ex.getStackTraceString() );
            F = new Logger('QuoteRequestService');
            classContext = 'QuoteRequestService';
            F.error('Generate quotes on Opportunity : '+requestObj.Id+' process MARS response '+ ex.getMessage());
            LoggerDMLService.saveLog(F);
            return null;
        }
    }
	
    private static List<Quote> getQuotes(
        ModelQuote.Response res,
        Opportunity requestObj
    ) {
        List<Quote> quotes = new List<Quote>();

        // Skip if no quotes returned.
        if (res.productQuotes == null)
            return quotes;

        ModelQuote.Request qReq = QuoteRequestService.generateQuoteRequest(
            requestObj
        );
        
        // Transform quotes in response to SF Quotes.
        for (ModelQuote.ProductQuote pq : res.productQuotes) {
            Quote q = new Quote();
            q.Name = 'Quote' + (requestObj.File_Number__c != null ? ' - ' + requestObj.File_Number__c : '-WaitingNumber');
            q.OpportunityId = requestObj.Id;
            q.Location_Code__c = res.locationCode;
            q.Property_Type_Rating__c = res.propertyTypeRating;
            q.Property_Downgraded__c = res.isDowngraded;
            q.EOT__c = res.eot;
            q.Product_Type__c = pq.productType;
            q.Term__c = pq.term;
            q.Rate__c = pq.rate;
            q.Quote_Amount__c = pq.amount;
            q.Is_Eligible__c = pq.isEligible;
            q.Is_Ineligible_Reason__c = pq.ineligibleReason;
            //q.Selected__c = pq.productType == requestObj.Product_Type__r.Name;
            q.Active_Quote__c = true;

            // HEB-291 Adding response values to capture quotes
            q.Property_Type__c = qReq.Property.PropertyType;
            q.Property_Postal_Code__c = qReq.Property.PostalCode;
            q.Property_City__c = qReq.Property.City;
            q.Home_Value_for_Quote__c = qReq.Property.HomeValue;

            //system.debug('!!! How many PMs  '+ qReq.Customers.size() );
            if (qReq.Customers.size() > 0) {
                if (qReq.Customers[0] <> null) {
                    q.Age_First_Borrower__c = qReq.Customers[0].Age;
                    q.Gender_First_Borrower__c = qReq.Customers[0].Gender;
                }
            }

            if (qReq.Customers.size() > 1) {
                q.Age_Second_Borrower__c = qReq.Customers[1].Age;
                q.Gender_Second_Borrower__c = qReq.Customers[1].Gender;
            }

            //system.debug('!!! response = ' + res.ProductQuoteSetID );
            if (res.ProductQuoteSetID != null && res.ProductQuoteSetID != 0) {
                Product_Quote_Set__c pqs = new Product_Quote_Set__c(
                    External_ID__c = String.valueof(res.ProductQuoteSetID)
                );
                q.Product_Quote_Set__r = pqs;
            }
            if (res.ProductRateSetID != null && res.ProductRateSetID != 0) {
                Product_Rate_Set__c prs = new Product_Rate_Set__c(
                    External_ID__c = String.valueof(res.ProductRateSetID)
                );
                q.Product_Rate_Set__r = prs;
            }

            quotes.add(q);
        }

        return quotes;
    }

    private static List<Quote> getOldActiveQuotes(
        List<Quote> newQuotes,
        Id oppId
    ) {
        List<Quote> oldActiveQuotes = new List<Quote>();

        // Assuming never should be more than 4 active quotes at a time. But still setting a limit to the query.
        for (Quote oldq : [
            SELECT Id, Active_Quote__c
            FROM Quote
            WHERE
                Id NOT IN :newQuotes
                AND Active_Quote__c = TRUE
                AND OpportunityId = :oppId
            LIMIT 80
        ]) {
            oldq.Active_Quote__c = false;
            oldActiveQuotes.add(oldq);
        }

        return oldActiveQuotes;
    }

    public static ResidentialLoanApplication getApplication(Opportunity opp) {
        // Query the lastest Application
        List<ResidentialLoanApplication> applicationList = [
            SELECT
                Id,
                Term__c,
                (
                    SELECT Id, Secured__c, Include_Debt__c, CreditLimitAmount
                    FROM LoanApplicationLiabilities
                ),
                (
                    SELECT
                        Id,
                        Name,
                        Contact.Birthdate,
                        Contact.Age__c,
                        Contact.Gender__c,
                        role__c,
                        Is_Primary_Borrower__c,
                        Use_For_Quote__c
                    FROM LoanApplicants
                )
            FROM ResidentialLoanApplication
            WHERE OpportunityId = :opp.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        ResidentialLoanApplication application = new ResidentialLoanApplication();
        if (applicationList.size() > 0) {
            application = applicationList[0];
        }

        return application;
    }

    public static LoanApplicationProperty getLoanApplicationProperty(
        ResidentialLoanApplication contextRec
    ) {
        // Query the lastest Property
        List<LoanApplicationProperty> propertyList = [
            SELECT
                Id,
                PropertyPostalCode,
                PropertyCity,
                PropertyState,
                PropertyStateCode,
                PropertyStreet,
                Property_Type__c,
                Acreage__c,
                Zoning__c,
                Water_Type__c,
                Is_Land_Owned__c,
                Can_Lease_be_Paid_Off__c,
                Property_Value_for_Quote__c,
                Fixed_To_Ground__c,
                Four_Seasons_Home__c,
                Fire_Insurance_in_place_for_12_Months__c,
                Fire_Insurance_Premium__c,
                Annual_Property_Taxes__c,
                Monthly_Condo_Fees__c,
                Condo_Fees_Owing__c,
                Property_Tax_Owing__c,
                Property_Taxes_Current__c,
                Condo_Fees_Current__c,
                LoanApplicationId
            FROM LoanApplicationProperty
            WHERE LoanApplicationId = :contextRec.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        LoanApplicationProperty propertyRec = new LoanApplicationProperty();
        if (propertyList.size() > 0) {
            propertyRec = propertyList[0];
        }

        return propertyRec;
    }

    private static ModelQuote.Property getProperty(
        ResidentialLoanApplication contextRec
    ) {
        ModelQuote.Property p = new ModelQuote.Property();

        LoanApplicationProperty propertyRec = getLoanApplicationProperty(
            contextRec
        );

        if (propertyRec != null) {
            p.PostalCode = propertyRec.PropertyPostalCode;
            p.City = propertyRec.PropertyCity;
            p.Province = propertyRec.PropertyState;
            p.PropertyType = propertyRec.Property_Type__c;
            p.HomeValue = propertyRec.Property_Value_for_Quote__c;
            p.Acreage = propertyRec.Acreage__c;
            p.Zoning = propertyRec.Zoning__c;
            p.WaterSupply = propertyRec.Water_Type__c;
            p.OwnsProperty = Utils.mapYesNoToBoolean(
                propertyRec.Is_Land_Owned__c
            );
            p.IsLeasePaid = Utils.mapYesNoToBoolean(
                propertyRec.Can_Lease_be_Paid_Off__c
            );
            p.IsFixedToGround = Utils.mapYesNoToBoolean(
                propertyRec.Fixed_To_Ground__c
            );
            p.IsFourSeasons = Utils.mapYesNoToBoolean(
                propertyRec.Four_Seasons_Home__c
            );
            p.DoDowngrade = true; // TODO: Dummy value.
        }

        return p;
    }

    public static List<LoanApplicant> getLoanApplicants(
        ResidentialLoanApplication contextRec
    ) {
        return contextRec.LoanApplicants;
    }

    private static List<ModelQuote.Customer> getPropertyMembers(
        ResidentialLoanApplication contextRec
    ) {
        List<ModelQuote.Customer> cs = new List<ModelQuote.Customer>();
        List<LoanApplicant> propMembers = getLoanApplicants(contextRec);

        for (LoanApplicant pm : propMembers) {
            ModelQuote.Customer c = new ModelQuote.Customer();

            c.DateOfBirth = pm.Contact.Birthdate != null
                ? formatDOB(pm.Contact.Birthdate)
                : null;

            c.Age = pm.Contact.Birthdate !=
                null // HEB-242- To use date of birth if that exists for quote req
                ? Utils.getAgeFromBirthdate(pm.Contact.Birthdate)
                : pm.Contact.Age__c != null
                      ? Integer.valueOf(pm.Contact.Age__c)
                      : null;

            c.Gender = pm.Contact.Gender__c != null
                ? pm.Contact.Gender__c.left(1)
                : null;
            cs.add(c);
        }

        return cs;
    }
}