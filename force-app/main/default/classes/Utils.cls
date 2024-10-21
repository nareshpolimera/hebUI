public class Utils {
    public static final String AFFIRMATIVE = 'Yes';
    public static final String NEGATIVE = 'No';
    public static final Integer FSA_CHAR_LENGTH = 3;

    public static final String CUSTOM_PERMISSION_CIRCUMVENT_LAUNCH_TO_MARS = 'Edit_Launched_to_MARS_Records';
    public static final String CUSTOM_PERMISSION_CIRCUMVENT_DURING_DATA_LOAD = 'Data_Load_Exemption';
    public static final String CUSTOM_PERMISSION_BOOK_INITIAL_CONTACT_MEETING = 'Book_Additional_Initial_Contact_Meeting';
    public static final String CUSTOM_PERMISSION_RESTRICT_INITIAL_CONTACT_MEETING = 'Restrict_Initial_Contact_Meeting';
    public static Map<String, ProvincialData> provinceToTimezoneMap = new Map<String, ProvincialData>{
        'BC' => new ProvincialData(
            TimeZone.getTimeZone('America/Vancouver'),
            false
        ),
        'AB' => new ProvincialData(
            TimeZone.getTimeZone('America/Edmonton'),
            false
        ),
        'SK' => new ProvincialData(
            TimeZone.getTimeZone('America/Winnipeg'),
            false
        ),
        'MB' => new ProvincialData(
            TimeZone.getTimeZone('America/Winnipeg'),
            false
        ),
        'ON' => new ProvincialData(
            TimeZone.getTimeZone('America/Toronto'),
            true
        ),
        'QC' => new ProvincialData(
            TimeZone.getTimeZone('America/Toronto'),
            true
        ),
        'NB' => new ProvincialData(
            TimeZone.getTimeZone('America/Halifax'),
            true
        ),
        'NS' => new ProvincialData(
            TimeZone.getTimeZone('America/Halifax'),
            true
        ),
        'PE' => new ProvincialData(
            TimeZone.getTimeZone('America/Halifax'),
            true
        ),
        'NL' => new ProvincialData(
            TimeZone.getTimeZone('America/St_Johns'),
            true
        )
    };

    public static HEB_App_Setting__mdt hebsetting;

    // Build a local cache so that we don't request this multiple times.
    private static Map<Schema.SObjectType, Map<String, Id>> rtypesCache;
    private static Map<Schema.SObjectType, Map<Id, String>> rtypesNameMapCache;

    /**
     * Returns a map of active RecordType IDs for a given SObjectType, keyed by each RecordType's unique DeveloperName.
     *
     * @param token: The sObject's schema token.
     * @return: A map from a developerName string to its ID.
     */
    public static Map<String, Id> getRecordTypeIdsBySObjectType(
        Schema.SObjectType token
    ) {
        // Pull from cache if available.
        if (rtypesCache != null) {
            return rtypesCache.get(token);
        }

        // Cache not initiated yet, generate cache.
        rtypesCache = new Map<Schema.SObjectType, Map<String, Id>>();

        // Generate sObjectType name to its token.
        // https://success.salesforce.com/issues_view?id=a1p3A000001RXBZQA4&title=sobjecttype-getdescribe-and-sobjectfield-getdescribe-increase-apex-cpu-consumption-in-api-version-44
        Map<String, Schema.SObjectType> sObjTypes = new Map<String, Schema.SObjectType>();
        for (Schema.SObjectType s : Schema.getGlobalDescribe().values()) {
            sObjTypes.put(s.getDescribe().getName(), s);
        }

        // Map all Recordtypes from its DeveloperName to its ID, grouped by the sObjectType.
        for (RecordType rt : [
            SELECT Id, Name, DeveloperName, SObjectType
            FROM RecordType
            WHERE IsActive = TRUE
        ]) {
            Schema.SObjectType sobjType = sObjTypes.get(rt.SobjectType);
            Map<String, Id> mapRecordTypes = rtypesCache.containsKey(sobjType)
                ? rtypesCache.get(sobjType)
                : new Map<String, Id>();

            mapRecordTypes.put(rt.DeveloperName, rt.Id);
            rtypesCache.put(sObjTypes.get(rt.SobjectType), mapRecordTypes);
        }

        return rtypesCache.get(token);
    }

    /**
     * Returns a map of recordtypeIDs to their label names.
     *
     * @param token: The sObject's schema token.
     * @return: A map from a recordtype ID to its string label name.
     */
    /*public static Map<Id, String> getRecordTypeNameBySObjectType(
      Schema.SObjectType token
    ) {
      if (rtypesNameMapCache == null) {
        rtypesNameMapCache = new Map<Schema.SObjectType, Map<Id, String>>();
      }
  
      if (rtypesNameMapCache.containsKey(token)) {
        return rtypesNameMapCache.get(token);
      }
  
      Map<Id, Schema.RecordTypeInfo> rtMapById = token.getDescribe()
        .getRecordTypeInfosById();
  
      Map<Id, String> rtNames = new Map<Id, String>();
      for (Id i : rtMapById.keySet()) {
        rtNames.put(i, rtMapById.get(i).getName());
        rtypesNameMapCache.put(token, rtNames);
      }
  
      return rtypesNameMapCache.get(token);
    }*/

    /**
     * Get the recordtype ID for an sObject via DeveloperName.
     *
     * @param token:
     * @param developerName:
     * @return: The ID of the recordtype.
     */
    public static Id getRecordTypeIdByDeveloperName(
        Schema.SObjectType token,
        String developerName
    ) {
        Map<String, Id> recordTypesBySObjectType = getRecordTypeIdsBySObjectType(
            token
        );
        return recordTypesBySObjectType.get(developerName);
    }

    /**
     * Retrieves field API names from field set member fields.
     *
     * @param fsms: A list of field set members.
     * @return: A set of field API names belonging to field set members.
     */
    public static Set<String> getFieldSetFields(List<FieldSetMember> fsms) {
        Set<String> fieldAPINames = new Set<String>();
        for (FieldSetMember fsm : fsms) {
            fieldAPINames.add(fsm.getFieldPath());
        }

        return fieldAPINames;
    }

    /**
     * Perform a delta of two records to see if a given list of fields have any changes between the two.
     *
     * @param records: A list of records.
     * @param oldRecords: A map to the record's previous version.
     * @param fieldsToCheck: The set of fields to check for changes.
     * @return: A list of records which has a detected change.
     */
    public static List<sObject> getChangedObjects(
        List<SObject> records,
        Map<Id, sObject> oldRecords,
        Set<String> fieldsToCheck
    ) {
        List<SObject> changedObjects = new List<SObject>();
        if (oldRecords == null) {
            return changedObjects;
        }

        SObject tempOldRecord = null;
        for (SObject record : records) {
            if (oldRecords.keyset().contains(record.Id)) {
                tempOldRecord = oldRecords.get(record.Id);
                for (String fieldAPIName : fieldsToCheck) {
                    if (
                        record.get(fieldAPIName) !=
                        tempOldRecord.get(fieldAPIName)
                    ) {
                        changedObjects.add(record);
                        break;
                    }
                }
            }
        }
        return changedObjects;
    }

    public static Map<Id, String> invertMapping(Map<String, Id> mapping) {
        Map<Id, String> invertedMapping = new Map<Id, String>();

        for (String key : mapping.keySet()) {
            invertedMapping.put(mapping.get(key), key);
        }

        return invertedMapping;
    }

    public static Boolean isAffirmativePicklist(String value) {
        return value != null && value == AFFIRMATIVE;
    }

    public static Boolean mapYesNoToBoolean(String value) {
        if (value == null)
            return null;
        return value == AFFIRMATIVE;
    }

    /*
     * HEB-273: Added new Utility method to retrieve the Active Opportunity and related records, since this will be retrieved in multiple integrations / scenarios
     * @deprecated?
     */
    /*DG
    /* XH NEW METHOD BELLOW TO BE USED INSTEAD OF THIS ONE 
    public static Opportunity retrieveActiveOpportunityForProperty(
      Id opportunityId
    ) {
      try {
        return [
          SELECT
            Id,
            File_Number__c,
            File_Type__c,
            Channel__c,
            Partner_Referrer__r.FirstName,
            Partner_Referrer__r.LastName,
            Partner_Referrer__r.Email,
            Annual_Property_Taxes__c,
            Condo_Fees_Current__c,
            Condo_Fees_Owing__c,
            Fire_Insurance_Premium__c,
            Fire_Insurance_in_place_for_12_Months__c,
           
            Property_Value_for_Quote__c,
            Property_Taxes_Current__c,
          
            Language__c,
            StageName,
            Property__c,
            Appraisal_Option__c,
            (
              SELECT
                Id,
                First_Name__c,
                Last_Name__c,
                Preferred_Name__c,
                Date_of_Birth__c,
                Age__c,
                Phone__c,
                Alternate_Phone_Number__c,
                Email__c,
                Is_Primary_Borrower__c,
                Monthly_Pension_Income__c,
                Monthly_Employment_Income__c,
                Monthly_Rental_Income__c,
                Monthly_Investment_Income__c,
                Monthly_Support_Income_Assets__c
              FROM Property_Members__r
            ),
            (
              SELECT Id, Quote_Amount__c, EOT__c
              FROM Quotes__r
              WHERE Selected__c = TRUE
            ),
            (SELECT Id, Amount__c, Secured__c FROM Debts__r)
          FROM Opportunity
          WHERE Id = :opportunityId AND IsClosed = FALSE
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];
      } catch (Exception e) {
        return null;
      }
    }*/

    /*
     * 05/16/2024 Xiomara: Added new Utility method to retrieve the Active Application and related Applicants ,Liabilities and Propertied.
     */
    public static ResidentialLoanApplication retrieveActiveApplicationForProperty(
        Id appId
    ) {
        try {
            return [
                SELECT
                    Id,
                    OpportunityId,
                    OwnerId,
                    LoanPurpose,
                    Appraisal_Option__c,
                    Opportunity.StageName,
                    Opportunity.File_Number__c,
                    Opportunity.Channel__c,
                    Opportunity.Sales_Ops_Coordinator__c,
                    Opportunity.OwnerId,
                    Opportunity.File_Type__c,
                    Opportunity.BDM__c,
                    Opportunity.SyncedQuoteId,
                    Opportunity.SyncedQuote.Name,
                    Opportunity.SyncedQuote.Quote_Amount__c,
                    Opportunity.SyncedQuote.EOT__c,
                    Opportunity.SyncedQuote.Property_Type_Rating__c,
                    Opportunity.SyncedQuote.Location_Code__c,
                    (
                        SELECT
                            id,
                            Contact.Account.FirstName,
                            Contact.Account.LastName,
                            Contact.Account.FinServ__PreferredName__pc,
                            Contact.Date_of_Birth__c,
                            contact.account.PersonBirthdate,
                            Contact.FinServ__Age__c,
                            contact.account.FinServ__Age__pc,
                            Contact.Phone,
                            Contact.OtherPhone,
                            contact.account.PersonMobilePhone,
                            Contact.Account.PersonEmail,
                            Contact.Phone__c,
                            Contact.Alternate_Phone_Number__c,
                            Contact.Age__c,
                            Role__c,
                            Is_Primary_Borrower__c,
                            Total_Pension_Income__c,
                            Total_Employment_Income__c,
                            Total_Investment_Income__c,
                            Total_Rental_Income__c,
                            Total_Support_Income__c
                        FROM LoanApplicants
                    ),
                    (
                        SELECT
                            id
                        FROM LoanApplicationAssets
                    ),
                    (
                        SELECT
                            id,
                            Amount__c,
                            Secured__c,
                            Type__c,
                            Balance_Amount__c,
                            Financial_Institution_Code__c,
                            CreditorName,
                            AccountNumber,
                            Source__c,
                            CreditLimitAmount,
                            Payment_Frequency__c,
                            MonthlyPaymentAmount,
                            Payout_Recommendation__c,
                            Include_Debt__c
                        FROM LoanApplicationLiabilities
                    ),
                    (
                        SELECT
                            id,
                            Annual_Property_Taxes__c,
                            Condo_Fees_Current__c,
                            Condo_Fees_Owing__c,
                            property_value_for_quote__c,
                            Fire_Insurance_Premium__c,
                            PropertyStreet, 
                            PropertyCity,
                            PropertyPostalCode,
                            PropertyState,
                        	Monthly_Condo_Fees__c
                        FROM LoanApplicationProperties
                    )
                FROM ResidentialLoanApplication
                WHERE Id = :appId AND (NOT Opportunity.StageName LIKE 'Closed%')
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            return null;
        }
    }

    /*
     * HEB-273, HEB-449: Added new Utility method to retrieve the Active Lead and related records, since this will be retrieved in multiple integrations / scenarios
     * Xiomara Updated to Retreive Opportunity and related Applications and Quotes.
     */
    /*
    THESE FIELDS ARE MISSING ON THE QUERY, CAN BE HERE OR IN THE METHOD AVOBE
    1 Lead.Channel__c there are 4 different API names.
    2 These doesn't have any mapping:
      Lead.Partner_Referrer__c 
      Lead.Fire_Insurance_Premium__c 
      Lead.Fire_Insurance_in_place_for_12_Months__c 
      Lead.Language__c tampoco
      Lead.BDM__c
    */
    public static Opportunity retrieveOpportunityForProperty(Id oppId) {
        try {
            return [
                SELECT
                    Id,
                    File_Number__c,
                    File_Type__c,
                    OwnerId,
                    (
                        SELECT
                            id,
                            OwnerId,
                            LoanPurpose
                        FROM Lending_Applications
                    ),
                    (
                        SELECT Id, Quote_Amount__c, EOT__c
                        FROM Quotes
                        WHERE isSyncing = TRUE
                    )
                FROM Opportunity
                WHERE Id = :oppId AND (NOT StageName LIKE 'Closed%')
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            return null;
        }
    }
    /*
     * HEB-273: Adding utility function to calculate Quote amount for the Opportunity
     */
    public static Quote getSelectedQuoteFromRelatedRecords(Opportunity opp) {
        return (opp.SyncedQuoteId <> null) ? opp.SyncedQuote : null;
    }

    /* DG public static Quote__c getSelectedQuoteFromRelatedRecords(Lead myLead) {
      return (myLead.Quotes__r <> null &&
        myLead.Quotes__r.size() > 0)
        ? myLead.Quotes__r[0]
        : null;
    }*/

    /*
     * HEB-242 Calculate Age
     */
    public static Integer getAgeFromBirthdate(Date dateOfBirth) {
        return (Integer.valueOf(
            Math.floor(dateOfBirth.daysBetween(Date.today()) / 365.2425)
        ));
    }

    /*
     * Get File record Id for sObject
     */
    public static Id getFileRecordId(sObject objRecord) {
        return (Id) objRecord.get('Opportunity__c') != null
            ? (Id) objRecord.get('Opportunity__c')
            : (Id) objRecord.get('Lead__c');
    }

    /*
     * Allow bypass for Sys Admin and Integration user
     */
    public static Boolean allowBypassForUser() {
        return (isSystemAdminUser() || isIntegrationUser());
    }

    /*
     * Is user System Admin User?
     */
    private static Id sysAdminProfileId;
    public static Boolean isSystemAdminUser() {
        if (sysAdminProfileId == null)
            sysAdminProfileId = [
                SELECT Id
                FROM Profile
                WHERE Name = :Label.SystemAdmin_Profile_Name
            ]
            .Id;

        return UserInfo.getProfileId() == sysAdminProfileId;
    }

    /*
     * Is user Integration User?
     */
    public static Boolean isIntegrationUser() {
        return FeatureManagement.checkPermission(Label.MARS_INTEGRATION_CUSTOM_PERMISSION);
    }

    /**
     * checks if current user is Mars Integration User
     */
    public static Boolean isMarsIntegrationUser() {
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        if (settings == null || String.isEmpty(settings.MARS_Integration_User_Id__c)){
            return false;
        }
        else{
            return settings.MARS_Integration_User_Id__c.equalsIgnoreCase(UserInfo.getUserId());
        }
    }

    /**
     * Formats the integer padding specific number of places with zeros.
     * Pads to the left of the number until we reach the number of places
     * eg. 5 padded to 3 => 005
     */
    public static String padInteger(Integer value, Integer zeroPadPlaces) {

        if (value == null) {
            return null;
        }

        Integer positiveValue = Math.abs(value);
        String result = String.valueOf(positiveValue);
        if (result.length() < zeroPadPlaces) {
            result = '0'.repeat(zeroPadPlaces - result.length()) + result;
        }
        return result;
    }

    /*
     * Get FSA code from Postal code
     */
    public static String fsaCode(String postalCode) {
        return postalCode != null ? postalCode.left(FSA_CHAR_LENGTH) : '';
    }

    /*
     * Parse validation rule error message
     */
    public static Map<Id, String> parseExceptionMessage(Exception e) {
        Map<Id, String> errorMap = new Map<Id, String>();

        for (Integer i = 0; i < e.getNumDml(); i++) {
            errorMap.put((Id) e.getDmlId(i), e.getDmlMessage(i));
        }

        return errorMap;
    }

    /*
     * HEB-405 refactoring
     */
    public static Map<String, Schema.SObjectField> getFieldMap(
        String objectName
    ) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType schema = schemaMap.get(objectName);
        return schema.getDescribe().fields.getMap();
    }

    /*
     * HEB-405: determines if a record's fields are empty for a given Fieldset; returns list of field labels for consumption for the end user
     */
    public static List<String> missingFields(
        Set<String> objectFields,
        Map<String, Schema.SObjectField> fieldMap,
        SObject record
    ) {
        List<String> missingFields = new List<String>();
        // Check the key fields for the "File" are complete
        for (String s : objectFields) {
            if (record.get(s) == null || record.get(s) == '') {
                missingFields.add(fieldMap.get(s).getDescribe().getLabel());
            }
        }
        return missingFields;
    }

    /*
     * 7721: Allows to look up for misisng parent fields
     */
    public static List<String> missingParentFields(
        Set<String> objectFields,
        Map<String, Schema.SObjectField> fieldMap,
        SObject record
    ) {
        List<String> missingFields = new List<String>();
        // Check the key fields for the "File" are complete
        for (String s : objectFields) {
            List<String> levels = s.Split('\\.');
            SObject relatedRecord = record;
            Integer lastIndex = levels.size() -1;
            
            try {
                for(Integer i = 0 ; i < lastIndex ; i++) {
                    relatedRecord = relatedRecord.getSObject(levels[i]);
                }
                if (
                    relatedRecord.get(levels[lastIndex]) == null 
                    || relatedRecord.get(levels[lastIndex]) == '' 
                    // || relatedRecord.get(levels[lastIndex]) == 0 
                    // ||relatedRecord.get(levels[lastIndex]) == false
                ) 
                {
                    s = s.toLowerCase();
                    if(fieldMap.keySet().contains(s)) {
                        missingFields.add(fieldMap.get(s).getDescribe().getLabel());
                    }
                }
            } catch(Exception e) {
                missingFields.add('Error in ' + s);
            }
        }
        return missingFields;
    }

    /*
     * HEB-445
     */
    public static Boolean validateIsLead(Id recordId) {
        String prefix = String.valueOf(recordId).substring(0, 3);
        return (prefix == '00Q');
    }

    public static Decimal getNumeric(Decimal field) {
        return field <> null ? field : 0;
    }

    public static String getString(String field) {
        return field <> null ? field : '';
    }

    public static String getUserEID(Id userId) {
        try {
            User u = [SELECT Id, External_ID__c FROM User WHERE Id = :userId];
            return u.External_ID__c <> null ? u.External_ID__c : '';
        } catch (Exception e) {
            return '';
        }
    }

    public static Map<Id, Id> getUsersEID(List<Id> userIds) {
        Map<Id, Id> userIdToExtId = new Map<Id, Id>();
        try {
            for(User u: [SELECT Id, External_ID__c FROM User WHERE Id = :userIds]) {
                userIdToExtId.put(u.Id, u.External_ID__c);
            }
            return userIdToExtId;
        } catch (Exception e) {
            return userIdToExtId;
        }
    }
    
    /*
     * Utility method to set the error string in the AuraHandledException so it can be displayed in the UI and caught in try/catch blocks
     */
    public static AuraHandledException throwAuraException(String errorStr) {
        AuraHandledException e = new AuraHandledException(errorStr);
        e.setMessage(errorStr);
        return e;
    }
    /*
     * Get the Current Product Quote Set Record
     */
    public static Product_Quote_Set__c getCurrentProductQuoteSetRecord() {
       List<Product_Quote_Set__c> currentPQS = new List <Product_Quote_Set__c>();
            currentPQS = [
            SELECT
                Id,
                Name,
                Available__c,
                External_ID__c,
                Effective_Date__c,
                Current__c
            FROM Product_Quote_Set__c
            WHERE Current__c = TRUE
            ORDER BY Effective_Date__c DESC
            LIMIT 1
        ];
        return !currentPQS.isEmpty() ? currentPQS[0] : NULL;
    }
    /*
     * Get the Current Product Rate Set Record
     */
    public static Product_Rate_Set__c getCurrentProductRateSetRecord() {
        List<Product_Rate_Set__c> currentPRS = new List <Product_Rate_Set__c>();
        currentPRS = [
            SELECT
                Id,
                Name,
                Available__c,
                External_ID__c,
                Effective_Date__c,
                Current__c
            FROM Product_Rate_Set__c
            WHERE Current__c = TRUE
            ORDER BY Effective_Date__c DESC
            LIMIT 1
        ];
        return !currentPRS.isEmpty() ? currentPRS[0] : NULL;
    }

    /*
     * Email Service for batch job results
     * Method to send out a CSV attachment in an email to designated person or group
     */
    /*
    public static void SendEmailForBatchStatus(
      List<String> errorLogs,
      Id apexJobId,
      String emailaddress,
      String msg
    ) {
      // Get the AsyncApexJob that represents the Batch job using the Id from the BatchableContext
      AsyncApexJob a = [
        SELECT
          Id,
          Status,
          NumberOfErrors,
          JobItemsProcessed,
          TotalJobItems,
          CreatedBy.Email,
          ExtendedStatus
        FROM AsyncApexJob
        WHERE Id = :apexJobId
      ];
  
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
  
      // Assign the addresses for the To and CC lists to the mail object.
      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      efa.setFileName(
        'SalesforceBatchError' +
        String.valueOf(System.today()) +
        '.csv'
      );
  
      // CSV generation
      String emailAttachmentText = 'Error Messages';
  
      //if (msg != null) {
      //    emailAttachmentText = emailAttachmentText + '\n' + msg;
      //}
  
      for (String err : errorLogs) {
        emailAttachmentText = emailAttachmentText + '\n' + err;
      }
  
      Blob b = Blob.valueOf(emailAttachmentText);
      efa.setBody(b);
  
      List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
      fileAttachments.add(efa);
  
      String[] toAddresses = emailaddress.split(',');
      system.debug('$$$ Email will be sent to ' + toAddresses);
  
      mail.setFileAttachments(fileAttachments);
      mail.setToAddresses(toAddresses);
      mail.setSubject('Batch Job Status: ' + a.Status);
      mail.setPlainTextBody(
        msg +
        '\n' +
        'The batch job processed ' +
        a.id +
        ' with ' +
        a.NumberOfErrors +
        ' failures. ExtendedStatus: ' +
        a.ExtendedStatus
      );
  
      if (!Test.isRunningTest()) {
        try {
          Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
          System.debug(
            LoggingLevel.ERROR,
            '**Error in sendEmail**' + e.getStackTraceString()
          );
        }
      }
    }*/

    public static HEB_App_Setting__mdt loadHEBSetting() {
        hebsetting = [
            SELECT
                Id,
                DeveloperName,
                DNCL_Acceptable_Days__c,
                Territory_Owner_Chang_Notify_Email__c,
                Appraisal_Cost__c,
                No_SOC_OwnerID__c
            FROM HEB_App_Setting__mdt
            LIMIT 1
        ];
        return hebsetting;
    }


    /*public static Boolean isWeekend(Datetime dateToCheck) {
      DateTime myDateTime = (DateTime) dateToCheck;
      String dayOfWeek = myDateTime.format('E');
      return (dayOfWeek == 'Sun' || dayOfWeek == 'Sat') ? true : false;
    }*/

    public class ProvincialData {
        public TimeZone timezone;
        public Boolean isEastern;

        public ProvincialData(TimeZone timezone, Boolean isEastern) {
            this.timezone = timezone;
            this.isEastern = isEastern;
        }
    }
    public static CreateAccountWrapper parseCreateAccountWrapper(String jsonString) {
        return (CreateAccountWrapper) JSON.deserialize(jsonString, CreateAccountWrapper.class);
    }

}