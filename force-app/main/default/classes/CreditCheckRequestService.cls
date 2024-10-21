public class CreditCheckRequestService {
  @TestVisible
  private static LoanApplicationProperty queryProperty(Id propertyId) {
    return [
      SELECT
        Id,
        Property_Type__c,
        PropertyStreet,
        PropertyCity,
        PropertyState,
        PropertyStateCode,
        PropertyPostalCode
      FROM LoanApplicationProperty
      WHERE Id = :propertyId
    ];
  }

  /*
   * HEB-32
   * Get list of Borrowers for a Property__c related to the Property_Member__c
   */
  @AuraEnabled
  public static LoanApplicantService.ApplicantAndApplication getBorrowers(
    Id oppId
  ) {
    return LoanApplicantService.getBorrowers(oppId);
  }

  @AuraEnabled
  public static LoanApplicationProperty getProperty(
    ResidentialLoanApplication application
  ) {
    try {
      // Get latest Property from Application
      LoanApplicationProperty property = QuoteRequestService.getLoanApplicationProperty(
        application
      );
      return property;
      // return queryProperty(property.id);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Credit_Assessment__c getAssessment(
    ResidentialLoanApplication application
  ) {
    try {
      List<Credit_Assessment__c> assessmentList = [
        SELECT
          Id,
          Credit_Assessment_Additional_Information__c,
          Application__c,
          Credit_Assessment_Reviewed_By__c,
          Credit_Assessment_Reviewed_On__c,
          Capacity__c,
          CreatedById,
          Name,
          Credit_Assessment_Required__c,
          Credit_Assessment_Status__c,
          Credit_Assessment_Successful__c,
          Holdback_Amount__c,
          Holdback_Number_Of_Payments__c,
          Holdback_Number_Of_Years__c,
          Holdback_Payment_Amount__c,
          Credit_Assessment_Requested_By__c,
          Credit_Assessment_Requested_On__c,
          Required_File_Documents__c,
          Credit_Assessment_Review_Comments__c,
          Willingness__c
        FROM Credit_Assessment__c
        WHERE Application__c = :application.Id
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];
      Credit_Assessment__c assessment = new Credit_Assessment__c();
      if (assessmentList.size() > 0) {
        assessment = assessmentList[0];
      }
      return assessment;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*
   * HEB-273
   * Called from Lightning Aura Component; retrieve Property details and call MARS endpoint.
   */
  @AuraEnabled
  public static Credit_Assessment__c runCreditAssessment(
    ResidentialLoanApplication l
  ) {
    System.debug(l);
    LoanApplicationProperty p = getProperty(l);

    Map<Id, LoanApplicant> applicantsMap = new Map<Id, LoanApplicant>(
      [
        SELECT Id, ContactId
        FROM LoanApplicant
        WHERE LoanApplicationId = :l.Id
      ]
    );

    CreditAssessment creditAssessment = new CreditAssessment(l.Id, p);
    if (creditAssessment <> null) {
      // add custom setting for  endpoint
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        IntegrationService.getEndpoint(
          IntegrationService.MARS_API.Credit_Assessment
        )
      );
      req.setMethod(IntegrationService.METHOD_POST);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
      );
      req.setBody(JSON.serialize(creditAssessment));
      System.debug('body?');
      String rMsg = req.getBody();
      for (Integer i = 0; i < rMsg.length(); i = i + 299) {
        Integer iEffectiveEnd = (i + 299 > (rMsg.length())
          ? rMsg.length()
          : i + 299);
        System.debug(rMsg.substring(i, iEffectiveEnd));
      }

      req.setTimeout(IntegrationService.TIMEOUT_MAX);

      Http http = new Http();
      HTTPResponse res = http.send(req);

      if (res.getStatusCode() == IntegrationService.HTTP_OK) {
        // update to check on response code
        String responseStr = res.getBody();
        CreditResponse response = (CreditResponse) JSON.deserialize(
          responseStr,
          CreditResponse.class
        );
        if (response.Errors <> null && response.Errors.size() > 0) {
          String errorMessage = String.join(response.Errors, '; ');
          throw new AuraHandledException(
            'Error Occurred Running AVM Request: ' + errorMessage
          );
        }
        String sMsg = responseStr;
        for (Integer i = 0; i < sMsg.length(); i = i + 300) {
          Integer iEffectiveEnd = (i + 300 > (sMsg.length())
            ? sMsg.length()
            : i + 300);
          System.debug(sMsg.substring(i, iEffectiveEnd));
        }
        try {
          Credit_Assessment__c assessment = new Credit_Assessment__c();
          assessment.Application__c = l.Id;
          assessment.Credit_Assessment_Successful__c = response.IsSuccessful;
          assessment.Willingness__c = response.Willingness; // Field Removed
          assessment.Capacity__c = response.Capacity; // Field Removed
          assessment.Annual_Property_Obligation__c = response.AnnualPropertyObligation;
          assessment.Holdback_Amount__c = response.HoldbackAmount;
          assessment.Holdback_Number_Of_Years__c = response.HoldbackNumberOfYears; // Field Removed
          assessment.Holdback_Number_Of_Payments__c = response.HoldbackNumberOfPayments; // Field Removed
          assessment.Holdback_Payment_Amount__c = response.HoldbackPaymentAmount; // Field Removed
          assessment.Credit_Assessment_Status__c = response.Status; 
          assessment.Credit_Assessment_Requested_By__c = UserInfo.getUserId(); // Assigning current user id to Requested ID
          assessment.Credit_Assessment_Requested_On__c = System.now();

          Opportunity opportunity = new Opportunity();
          opportunity.id = l?.OpportunityId;
          opportunity.Credit_Bureau_Status__c = response.IsSuccessful // Opportunity
            ? 'Complete'
            : 'Incomplete';
          opportunity.Credit_Assessment_Successful__c = response.IsSuccessful;
          system.debug('opportunity =' + opportunity);

          List<Credit_Report__c> creditReportList = new List<Credit_Report__c>();
          List<Contact> contactList = new List<Contact>();
          List<LoanApplicationLiability> debtList = new List<LoanApplicationLiability>();
          Set<String> checkForDuplicateDebts = new Set<String>();

          if (response.debts != null) {
            for (debts debt : response.debts) {
              String debtKey =
                debt.type +
                ';' +
                debt.amount +
                ';' +
                debt.financialInstitutionName +
                ';' +
                debt.accountNumber;
              if (!checkForDuplicateDebts.contains(debtKey)) {
                debtList.add(
                  new LoanApplicationLiability(
                    LoanApplicationId = l.id,
                    Include_debt__c = true,
                    Type__c = debt.type,
                    Secured__c = debt.isSecured,
                    Amount__c = debt.amount,
                    Financial_Institution_Code__c = debt.financialInstitutionCode,
                    CreditorName = debt.financialInstitutionName,
                    Source__c = debt.source,
                    CreditLimitAmount = debt.creditLimit,
                    Balance_Amount__c = debt.balance,
                    MonthlyPaymentAmount = debt.paymentAmount,
                    Payment_Frequency__c = debt.frequency,
                    AccountNumber = debt.accountNumber
                  )
                );
                checkForDuplicateDebts.add(debtKey);
              }
            }
          }

          List<LoanApplicationLiability> oldManualDebt = [
            SELECT id, Include_debt__c
            FROM LoanApplicationLiability
            WHERE
              LoanApplicationId = :l.id
              AND (source__c = 'Manual'
              OR source__c = 'External Partner')
              AND type__c != 'Private Mortgage'
              AND Include_debt__c = TRUE
          ];
          List<LoanApplicationLiability> oldCreditBureauDebt = [
            SELECT id, Include_debt__c
            FROM LoanApplicationLiability
            WHERE LoanApplicationId = :l.id AND source__c = 'Credit Bureau'
          ];
          for (LoanApplicationLiability debt : oldManualDebt) {
            debt.Include_debt__c = false;
            debtList.add(debt);
          }

          try {
            delete oldCreditBureauDebt;
          } catch (Exception e) {
            System.debug(e.getMessage());
          }
          upsert debtList;

          update l;
          update contactList;
          insert assessment;
          if (opportunity.Id <> null) {
            update opportunity;
            system.debug('opportunity updated');
          }

          // Insert new notes
          if (response.Notes != null) {
            insertNotes(l.id, response.Notes);
          }

          return assessment;
        } catch (Exception e) {
          System.debug(e.getMessage());
          System.debug(e.getLineNumber());
          System.debug(e.getStackTraceString());
          throw new AuraHandledException('Error Occurred: ' + e.getMessage());
        }
      }
      throw new AuraHandledException(
        'Error Occurred: HTTP Status Code ' + res.getStatusCode()
      );
    } else {
      throw new AuraHandledException('Error Occurred: CreditRequest returned');
    }
  }

  @AuraEnabled
  public static List<Credit_Report__c> runCreditRequest(
    ResidentialLoanApplication l
  ) {
    // Get latest Property from Application
    LoanApplicationProperty property = QuoteRequestService.getLoanApplicationProperty(
      l
    );
    LoanApplicationProperty p = queryProperty(property.id);
    Map<Id, LoanApplicant> applicantsMap = new Map<Id, LoanApplicant>(
      [
        SELECT Id, ContactId
        FROM LoanApplicant
        WHERE LoanApplicationId = :l.Id
      ]
    );

    CreditRequest creditRequest = new CreditRequest(l.Id, p);
    if (creditRequest <> null) {
      // add custom setting for  endpoint
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        IntegrationService.getEndpoint(
          IntegrationService.MARS_API.Credit_Assessment_Report
        )
      );
      req.setMethod(IntegrationService.METHOD_POST);
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
      );
      req.setBody(JSON.serialize(creditRequest));
      System.debug('body?');
      System.debug(req.getBody());

      req.setTimeout(IntegrationService.TIMEOUT_MAX);

      Http http = new Http();
      HTTPResponse res = http.send(req);

      if (res.getStatusCode() == IntegrationService.HTTP_OK) {
        // update to check on response code
        String responseStr = res.getBody();
        System.debug(responseStr);
        CreditResponse response = (CreditResponse) JSON.deserialize(
          responseStr,
          CreditResponse.class
        );
        if (response.Errors <> null && response.Errors.size() > 0) {
          String errorMessage = String.join(response.Errors, '; ');
          throw new AuraHandledException(
            'Error Occurred Running AVM Request: ' + errorMessage
          );
        }
        String sMsg = responseStr;
        for (Integer i = 0; i < sMsg.length(); i = i + 299) {
          Integer iEffectiveEnd = (i + 299 > (sMsg.length())
            ? sMsg.length()
            : i + 299);
          System.debug(sMsg.substring(i, iEffectiveEnd));
        }

        try {
          List<Credit_Report__c> creditReportList = new List<Credit_Report__c>();
          List<LoanApplicant> pmList = new List<LoanApplicant>();
          List<Contact> contactList = new List<Contact>();
          List<LoanApplicationLiability> debtList = new List<LoanApplicationLiability>();
          Set<String> checkForDuplicateDebts = new Set<String>();

          for (CreditReport cr : response.CreditReports) {
            String clientCreditAssessmentStatus;
            if (!cr.IsCreditHit || cr.hasCreditFreeze) {
              clientCreditAssessmentStatus = (!cr.IsCreditHit)
                ? 'No Hit'
                : 'Credit Freeze';
            } else {
              clientCreditAssessmentStatus = 'Hit';
            }

            if (String.IsBlank(cr.ExternalID)) {
              creditReportList.add(
                new Credit_Report__c(
                  Loan_Applicant__c = (Test.isRunningTest()) ? null : cr.id, // when running a test, can't used the value returned from the mock endpoint
                  Person__c = l?.AccountId,
                  Credit_Hit__c = cr.IsCreditHit,
                  Credit_Score__c = cr.CreditScore,
                  Credit_Score_Type__c = cr.CreditScoreType,
                  Credit_Summary__c = cr.CreditSummary,
                  Credit_Report_Status__c = clientCreditAssessmentStatus,
                  Credit_Freeze__c = cr.hasCreditFreeze,
                  Trades_Info__c = JSON.serialize(cr.Trades),
                  Bankruptcies_Info__c = JSON.serialize(cr.Bankruptcies),
                  Collections_Info__c = JSON.serialize(cr.Collections),
                  LegalActions_Info__c = JSON.serialize(cr.LegalActions),
                  Assessment_Eligible__c = true,
                  Date_Of_Birth__c = (String.isBlank(cr.DateOfBirth))
                    ? null
                    : Date.valueOf(cr.DateOfBirth),
                  Street__c = cr.StreetAddress,
                  City__c = cr.City,
                  Province__c = cr.Province,
                  Postal_Code__c = cr.PostalCode
                )
              );

              if (!Test.isRunningTest()) {
                Boolean incomeDocumentRequired = false;
                if (response.borrowerResult != null) {
                  for (borrowerResult br : response.borrowerResult) {
                    if (cr.id == br.Id) {
                      incomeDocumentRequired = br.incomeDocumentRequired;
                    }
                  }
                }

                LoanApplicant pm = new LoanApplicant(
                  Id = cr.id,
                  Credit_Score__c = cr.CreditScore,
                  Income_Documents_Required__c = incomeDocumentRequired
                );
                pmList.add(pm);

                Contact contact = new Contact(
                  Id = applicantsMap.get(cr.ID).ContactId
                );
                contactList.add(contact);
              }
            }
          }
          update l;
          insert creditReportList;
          update pmList;
          update contactList;

          // Insert new notes
          if (response.Notes != null) {
            insertNotes(l.id, response.Notes);
          }

          return creditReportList;
        } catch (Exception e) {
          System.debug(e.getMessage());
          System.debug(e.getLineNumber());
          System.debug(e.getStackTraceString());
          throw new AuraHandledException('Error Occurred: ' + e.getMessage());
        }
      }
      throw new AuraHandledException(
        'Error Occurred: HTTP Status Code ' + res.getStatusCode()
      );
    } else {
      throw new AuraHandledException('Error Occurred: CreditRequest returned');
    }
  }

  /*
   * HEB-308
   * As part of UI refactoring, pass in Property Members to update
   */
  @AuraEnabled
  public static Boolean updatePropertyMembers(
    List<Contact> contacts
  ) {
    System.debug(contacts);
    try {
      update contacts;
      return true;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*
   * HEB-449
   */
  @AuraEnabled
  public static Boolean updateProperty(LoanApplicationProperty property) {
    try {
      system.debug('!!!! Property' + property);

      update property;
      return true;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Boolean updateAssessment(Credit_Assessment__c assessment) {
    try {
      system.debug('!!!! Assessment' + assessment);

      update assessment;
      return true;
    } catch (DmlException e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @TestVisible
  private static void insertNotes(Id applicationId, List<Note> asNotes) {
    List<ContentNote> cnotes = new List<ContentNote>();
    List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();

    for (Note n : asNotes) {
      ContentNote objCntNote = new ContentNote();
      objCntNote.Title = n.TextTitle;
      objCntNote.Content = Blob.valueOf(n.Text);
      cnotes.add(objCntNote);
    }

    insert cnotes;

    for (ContentNote cn : cnotes) {
      //create ContentDocumentLink  record to link with parentId
      ContentDocumentLink objCntDocLink = new ContentDocumentLink();
      objCntDocLink.LinkedEntityId = applicationId; // Specify Application Id
      objCntDocLink.ContentDocumentId = cn.Id; //Content Note Id
      objCntDocLink.shareType = 'V'; // Specify your sharing type
      cdls.add(objCntDocLink);
      System.debug('!!! Credit Assessment new SF ContentNote ID = ' + cn.Id);
      System.debug(
        '!!! Credit Assessment new SF ContentNote Title = ' + cn.Title
      );
    }
    insert cdls;
  }

  /*
   * Documentation reference : https://hebdiscovery.atlassian.net/wiki/spaces/HEBBUILD/pages/89653286/Credit+Integration
   */
  public class CreditRequest {
    public List<Customer> Customers;

    public CreditRequest(Id appId, LoanApplicationProperty property) {
      ResidentialLoanApplication ld = Utils.retrieveActiveApplicationForProperty(
        appId
      );

      this.Customers = new List<Customer>();
      for (LoanApplicant pm : getBorrowers(ld?.OpportunityId)?.applicants) {
        this.Customers.add(new Customer(pm, property));
      }
      System.debug(this.Customers);
    }
  }

  public class CreditAssessment {
    public String SFID;
    public String FileNumber;
    public String OwnerEID;
    public String SalesContactEID;
    public String UserEID;
    public String Channel;
    public String LoanPurpose;
    public String PropertyType;
    public String PropertyProvince;
    public Decimal HomeValue;
    public Decimal QuoteAmount;
    public Decimal EOT;
    public Boolean HasFireInsurance;
    public Decimal AnnualPropertyTax;
    public Decimal AnnualFireInsurancePremium;
    public Decimal MonthlyCondoFees;
    public Decimal CondoFeesOwing;
    public Decimal PropertyTaxOwing;
    public Boolean IsPropertyTaxCurrent;
    public Boolean IsCondoFeesCurrent;
    public Decimal SecuredDebt;
    public Decimal UnsecuredDebt;
    public String AdditionalInformation;

    public List<CreditBorrower> Borrowers;

    public CreditAssessment(Id appId, LoanApplicationProperty property) {
      ResidentialLoanApplication ld = Utils.retrieveActiveApplicationForProperty(
        appId
      );
      List<Credit_Assessment__c> assesstment = [
        SELECT Credit_Assessment_Additional_Information__c
        FROM Credit_Assessment__c
        WHERE Application__c = :appId
        ORDER BY CreatedDate DESC
      ];
      this.SFID = ld.Id;
      this.FileNumber = ld.Opportunity.File_Number__c;

      this.OwnerEID = Utils.getUserEID(ld.Opportunity.BDM__c);
      this.SalesContactEID = Utils.getUserEID(ld.OwnerId);
      this.UserEID = Utils.getUserEID(UserInfo.getUserId());
      this.Channel = ld.Opportunity.Channel__c;
      this.LoanPurpose = ld.LoanPurpose;

      this.PropertyType = Utils.getString(property.Property_Type__c);
      this.PropertyProvince = Utils.getString(property.PropertyStateCode);

      this.HomeValue = Utils.getNumeric(property.Property_Value_for_Quote__c);
      this.HasFireInsurance = property.Fire_Insurance_in_place_for_12_Months__c;
      this.AnnualPropertyTax = Utils.getNumeric(
        property.Annual_Property_Taxes__c
      );
      this.AnnualFireInsurancePremium = Utils.getNumeric(
        property.Fire_Insurance_Premium__c
      );
      this.MonthlyCondoFees = Utils.getNumeric(property.Monthly_Condo_Fees__c);
      this.CondoFeesOwing = Utils.getNumeric(property.Condo_Fees_Owing__c);
      this.PropertyTaxOwing = Utils.getNumeric(property.Property_Tax_Owing__c);
      this.IsPropertyTaxCurrent = property.Property_Taxes_Current__c;
      this.IsCondoFeesCurrent = property.Condo_Fees_Current__c;

      this.AdditionalInformation = assesstment.size() > 1
        ? assesstment[0].Credit_Assessment_Additional_Information__c
        : null;

      this.Borrowers = new List<CreditBorrower>();
      for (LoanApplicant pm : getBorrowers(ld.OpportunityId).applicants) {
        this.Borrowers.add(new CreditBorrower(pm, property));
      }
      System.debug(this.Borrowers);

      this.SecuredDebt = 0;
      this.UnsecuredDebt = 0;
      Quote quote;
      if (ld <> null && ld?.OpportunityId <> null) {
        quote = Utils.getSelectedQuoteFromRelatedRecords(ld.Opportunity);
        this.calculateDebts(ld);
      }

      this.QuoteAmount = Utils.getNumeric(quote?.Quote_Amount__c);
      this.EOT = Utils.getNumeric(quote?.EOT__c);
    }

    private void calculateDebts(ResidentialLoanApplication ld) {
      this.SecuredDebt = 0; // rolled up?
      this.UnsecuredDebt = 0; // rolled up?

      for (LoanApplicationLiability debt : ld.LoanApplicationLiabilities) {
        Decimal amount = (debt.CreditLimitAmount != null)
          ? debt.CreditLimitAmount
          : 0;
        if (debt.Secured__c) {
          this.SecuredDebt += amount;
        } else {
          this.UnsecuredDebt += amount;
        }
      }
    }
  }

  public class CreditBorrower {
    public String Id;
    public String FirstName;
    public String LastName;
    public String PreferredFirstName;
    public String PreferredLastName;
    public Datetime DateOfBirth;
    public String StreetAddress;
    public String City;
    public String Province;
    public String PostalCode;
    public Decimal PensionIncome;
    public Decimal EmploymentIncome;
    public Decimal InvestmentIncome;
    public Decimal RentalIncome;
    public Decimal SupportIncome;
    // public CreditReport creditReport;
    public String ExternalID = '';
    public Boolean IsCreditHit = false;
    public Integer CreditScore = 0;
    public String CreditScoreType = '';
    public String CreditSummary = '';
    public Boolean hasCreditFreeze = false;
    public Trades[] Trades = new List<Trades>();
    public Bankruptcies[] Bankruptcies = new List<Bankruptcies>();
    public Collections[] Collections = new List<Collections>();
    public LegalActions[] LegalActions = new List<LegalActions>();

    public CreditBorrower(LoanApplicant pm, LoanApplicationProperty p) {
      this.ID = pm.Id;
      this.FirstName = Utils.getString(pm.Contact.FirstName);
      this.LastName = Utils.getString(pm.Contact.LastName);
      this.DateOfBirth = pm.Contact.Birthdate;
      this.StreetAddress = Utils.getString(p.PropertyStreet);
      this.City = Utils.getString(p.PropertyCity);
      this.Province = Utils.getString(p.PropertyStateCode);
      this.PostalCode = Utils.getString(p.PropertyPostalCode);

      this.PensionIncome = Utils.getNumeric(pm.Total_Pension_Income__c);
      this.EmploymentIncome = Utils.getNumeric(pm.Total_Employment_Income__c);
      this.InvestmentIncome = Utils.getNumeric(pm.Total_Investment_Income__c);
      this.RentalIncome = Utils.getNumeric(pm.Total_Rental_Income__c);
      this.SupportIncome = Utils.getNumeric(pm.Total_Support_Income__c);
      if (pm.Credit_Reports__r.size() > 0) {
        this.ExternalID = pm.Credit_Reports__r[0].Id;
        this.IsCreditHit = pm.Credit_Reports__r[0].Credit_Hit__c;
        this.CreditScore = Integer.valueOf(
          Utils.getNumeric(pm.Credit_Reports__r[0].Credit_Score__c)
        );
        this.CreditScoreType = Utils.getString(
          pm.Credit_Reports__r[0].Credit_Score_Type__c
        );
        this.CreditSummary = Utils.getString(
          pm.Credit_Reports__r[0].Credit_Summary__c
        );
        this.hasCreditFreeze = pm.Credit_Reports__r[0].Credit_Freeze__c;

        if (String.isNotBlank(pm.Credit_Reports__r[0].Trades_Info__c)) {
          this.Trades = (List<Trades>) JSON.deserialize(
            pm.Credit_Reports__r[0].Trades_Info__c,
            List<Trades>.class
          );
        }
        if (String.isNotBlank(pm.Credit_Reports__r[0].Bankruptcies_Info__c)) {
          this.Bankruptcies = (List<Bankruptcies>) JSON.deserialize(
            pm.Credit_Reports__r[0].Bankruptcies_Info__c,
            List<Bankruptcies>.class
          );
        }
        if (String.isNotBlank(pm.Credit_Reports__r[0].Collections_Info__c)) {
          this.Collections = (List<Collections>) JSON.deserialize(
            pm.Credit_Reports__r[0].Collections_Info__c,
            List<Collections>.class
          );
        }
        if (String.isNotBlank(pm.Credit_Reports__r[0].LegalActions_Info__c)) {
          this.LegalActions = (List<LegalActions>) JSON.deserialize(
            pm.Credit_Reports__r[0].LegalActions_Info__c,
            List<LegalActions>.class
          );
        }
      }
    }
  }

  public class Customer {
    public String ID;
    public String FirstName;
    public String LastName;
    public Datetime DateOfBirth;
    public String StreetAddress;
    public String City;
    public String Province;
    public String PostalCode;

    public Customer(LoanApplicant pm, LoanApplicationProperty p) {
      this.ID = pm.Id;
      this.FirstName = Utils.getString(pm.Contact.FirstName);
      this.LastName = Utils.getString(pm.Contact.LastName);
      this.DateOfBirth = pm.Contact.Birthdate;
      this.StreetAddress = Utils.getString(p.PropertyStreet);
      this.City = Utils.getString(p.PropertyCity);
      this.Province = Utils.getString(p.PropertyStateCode);
      this.PostalCode = Utils.getString(p.PropertyPostalCode);
    }
  }

  @SuppressWarnings('PMD.VariableNamingConventions')
  public class CreditResponse {
    public Boolean IsSuccessful;
    public String Willingness;
    public String Capacity;
    public Decimal AnnualPropertyObligation;
    public Decimal HoldbackAmount;
    public Integer HoldbackNumberOfYears;
    public Integer HoldbackNumberOfPayments;
    public Decimal HoldbackPaymentAmount;
    public Boolean isComplete;

    public String Status;
    public List<Note> Notes;
    List<CreditReport> CreditReports;
    List<borrowerResult> borrowerResult;
    List<debts> debts;
    List<String> Errors;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  class Trades {
    public String Type;
    public Decimal CreditLimit;
    public Integer Balance;
    public String PaymentPattern;
    public Integer HighestMOP;
    public String MOP;
    public String DateLastActivity;
    public String Narrative1;
    public Long HighCredit;
    public String MemberCode;
    public String MemberName;
    public String Account;
    public String Frequency;
    public Decimal PaymentAmount;
    public String DateOpened;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  class Bankruptcies {
    public String Narrative;
    public String StatusCode;
    public String ReportedDate;
    public Long Liabilities;
    public Long Assets;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  class Collections {
    public Decimal CurrentBalance;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  class LegalActions {
    public String Type;
    public Decimal OriginalAmount;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  public class CreditReport {
    public String Id;
    public String ExternalID;
    public Boolean IsCreditHit;
    public Integer CreditScore;
    public String CreditScoreType;
    public String CreditSummary;
    public Boolean hasCreditFreeze;
    public Trades[] Trades;
    public Bankruptcies[] Bankruptcies;
    public Collections[] Collections;
    public LegalActions[] LegalActions;
    public String DateOfBirth;
    public String StreetAddress;
    public String City;
    public String Province;
    public String PostalCode;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  public class borrowerResult {
    public String Id;
    public Boolean incomeDocumentRequired;
  }
  @SuppressWarnings('PMD.VariableNamingConventions')
  public class debts {
    public String type;
    public Boolean isSecured;
    public Decimal amount;
    public String financialInstitutionCode;
    public String financialInstitutionName;
    public String accountNumber;
    public String source;
    public Decimal creditLimit;
    public Decimal balance;
    public Decimal paymentAmount;
    public String frequency;
  }

  @SuppressWarnings('PMD.VariableNamingConventions')
  public class Note {
    public String Text;
    public String TextType;
    public String TextTitle;
    public DateTime EnteredOn;
    public String EnteredBy;
  }
}