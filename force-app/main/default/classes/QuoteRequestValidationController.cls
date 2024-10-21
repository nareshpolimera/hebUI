public class QuoteRequestValidationController {
  public static final String BORROWER_MISSING = Label.Error_Quote_Borrower_Missing;
  public static final String MISSING_PROP_VALUES = Label.Error_Quote_Missing_Property_Values;
  public static final String PROPERTY_REQUIRED = Label.Error_Quote_Missing_Property;
  public static final String INVALID_POSTALCODE_CITY = Label.Error_Invalid_PostalCode_City;
  public static Opportunity contextRec;

  /*
   * HEB-208 Validate Quote request
   */
  @AuraEnabled
  public static String validateQuote(Id recordId) {
    String errorMessage = '';
    Boolean validQuote = true; // assuming valid quote so that in unidentified cases it fails silently

    List<LoanApplicant> propMembers = new List<LoanApplicant>();
    LoanApplicationProperty property = new LoanApplicationProperty();

    if (contextRec == null)
      contextRec = getRecordsInContext(recordId);

    ResidentialLoanApplication application = QuoteRequestService.getApplication(
      contextRec
    );
    property = QuoteRequestService.getLoanApplicationProperty(application);
    propMembers = QuoteRequestService.getLoanApplicants(application);

    errorMessage += validateProperty(property);
    errorMessage += validatePropertyMembers(propMembers);

    if (
      String.isNotBlank(errorMessage) &&
      String.isNotBlank(contextRec.File_Number__c)
    ) {
      validQuote = false;
    }

    return ('{' +
    ' "validQuote":' +
    validQuote +
    ',' +
    ' "errorMessage":"' +
    errorMessage +
    '"}');
  }

  @AuraEnabled
  @future(callout=true)
  public static void getQuoteForTrigger(Id recordId) {
    quoteMain(recordId);
  }

  @AuraEnabled
  public static String getQuote(Id recordId) {
    quoteMain(recordId);

    return null;
  }

  private static void quoteMain(Id recordId) {
    if (contextRec == null)
      contextRec = getRecordsInContext(recordId);

    // Send request and obtain response.
    String marsQuote = QuoteRequestService.sendRequest(contextRec);

    // Parse for quotes.
      if(String.isNotBlank(marsQuote)){
        String result = QuoteRequestService.processResponse(marsQuote, contextRec);
      }
  }

  private static String validatePropertyMembers(
    List<LoanApplicant> propMembers
  ) {
    String errorMessage = '';
    // Property Member validation
    if (propMembers <> null) {
      Boolean hasBorrower = false;
      for (LoanApplicant pm : propMembers) {
        hasBorrower |= pm.role__c.contains(PropertyMemberService.BORROWER_ROLE) && pm.Is_Primary_Borrower__c ;
      //  hasborrower = true;
        if ( (pm.Use_For_Quote__c && pm.role__c.contains(PropertyMemberService.BORROWER_ROLE) ) && (
          (pm.Contact.Birthdate == null && pm.Contact.Age__c == null) ||
          String.isEmpty(pm.Contact.Gender__c) )
        ) {
          errorMessage +=
            ' ' +
            pm.Name +
            ' : ' +
            Label.Error_Quote_Missing_DOB_Age_Gender;
        }
      }

      if (!hasBorrower) {
        errorMessage += ' ' + BORROWER_MISSING;
      }
    } else {
      errorMessage += ' ' + BORROWER_MISSING;
    }
    return errorMessage;
  }

  public static String validateProperty(LoanApplicationProperty property) {
    String errorMessage = '';
    // Property validation
    if (property <> null) {
      Map<String, Schema.SObjectType> mapSobjects = Schema.getGlobalDescribe();
      Map<String, Schema.SObjectField> fieldMap = mapSobjects.get(
          'LoanApplicationProperty'
        )
        .getDescribe()
        .fields.getMap();

      String missingfields = '';
      if (property.Property_Type__c == null)
        missingfields +=
          fieldMap.get('Property_Type__c').getDescribe().getLabel() + ' ';
      if (property.PropertyPostalCode == null)
        missingfields +=
          ', ' + fieldMap.get('PropertyPostalCode').getDescribe().getLabel();
      if (property.PropertyCity == null)
        missingfields +=
          ', ' + fieldMap.get('PropertyCity').getDescribe().getLabel();

      if (String.isNotBlank(missingfields)) {
        missingfields = missingfields.removeStart(', ');
        errorMessage += MISSING_PROP_VALUES + missingfields;
      } else if (
        property.PropertyPostalCode <> null &&
        property.PropertyCity <> null
      ) {
        String fsa = Utils.fsaCode(property.PropertyPostalCode);
        Set<String> validFSA = LoanApplicationPropertyService.validFSAValues(
          new Set<String>{ fsa },
          new Set<String>{ property.PropertyCity }
        );

        errorMessage += validFSA.contains(
          LoanApplicationPropertyService.fsaKeyGenerator(fsa, property.PropertyCity)
          )
          ? ''
          : INVALID_POSTALCODE_CITY;
      }
    } else {
      errorMessage += ' ' + PROPERTY_REQUIRED;
    }

    return errorMessage;
  }

  public static Opportunity getRecordsInContext(Id recordId) {
    return [
      SELECT
        Id,
        Term__c,
        Product_Type__c,
        Product_Type__r.Name,
        File_Number__c,
        CHIP_Max_Qualified__c,
        Product_Quote_Set__c,
        Product_Quote_Set__r.External_ID__c,
        Product_Quote_Set__r.Effective_Date__c,
        Product_Rate_Set__c,
        Product_Rate_Set__r.External_ID__c,
        Product_Rate_Set__r.Effective_Date__c
      FROM Opportunity
      WHERE Id = :recordId
    ];
  }
}