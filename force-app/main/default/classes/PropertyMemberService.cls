/*
 * Service class for the Property_Member__c object
 */
public class PropertyMemberService {
    public static final String BORROWER_ROLE = 'Borrower';
    public static final String INFLUENCER_ROLE = 'Influencer';
    public static final String POA_ROLE = 'Power of Attorney';
    public static final String GUARANTOR_ROLE = 'Guarantor';
  
    public static final String OCCUPATION_NEVER_EMPLOYED = 'Never Employed';
    public static final String OCCUPATION_HOMEMAKER = 'Homemaker';
    public static final String OCCUPATION_UNEMPLOYED = 'Unemployed';
    public static final String OCCUPATION_RETIRED = 'Retired';
    public static final String OCCUPATION_OTHER = 'Other (please specify)';
  
    public static Boolean syncFromPersonAccount = false;

    public void syncConsentToMarsPlatformEvent(
      List<Contact> records,
      Map<Id, Contact> oldRecords
    ) {
      Set<String> fieldsToCheck = Utils.getFieldSetFields(
        Schema.SObjectType.Contact.fieldSets.Contact_Consent.getFields()
      );
      List<Contact> pms = (List<Contact>) Utils.getChangedObjects(
        records,
        oldRecords,
        fieldsToCheck
      );
      Map<Id, Contact> pmAccts = new Map<Id, Contact>();
  
      for (Contact pm : pms) {
        if (pm.vlocity_ins__IsPersonAccount__c <> null) {
          pmAccts.put(pm.Id, pm);
        }
      }
  
      if (pmAccts.isEmpty())
        return;
  
      List<MARSPlatformEventService.Request> requests = new List<MARSPlatformEventService.Request>();
      for (Contact pm : pmAccts.values())
        requests.add(
          new MARSPlatformEventService.Request(
            pm,
            'Sync Contact Consent',
            MARSPlatformEventService.ACTION_UPDATE,
            MARSPlatformEventService.SYNC_PROPERTY_MEMBER_CONSENT
          )
        );
  
      Boolean errorOccurred = MARSPlatformEventService.publishEvents(requests);
      PropertyMemberService.syncFromPersonAccount = !(errorOccurred);
    }
  }