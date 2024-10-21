public class MembershipController {
    @AuraEnabled
    public static List<Marketing_Association__c> setAllAssociations() {
      return [
        SELECT Id, Name, Effective_Date__c, Expiration_Date__c
        FROM Marketing_Association__c
        WHERE
          (Effective_Date__c = NULL
          OR Effective_Date__c <= TODAY)
          AND (Expiration_Date__c = NULL
          OR Expiration_Date__c >= TODAY)
          AND Is_Active__c = TRUE
      ];
    }
  
    @AuraEnabled
    public static Map<String, String> setAssociationDetails(
      String associationId
    ) {
      Map<String, String> consentMap = new Map<String, String>();
      Marketing_Association__c mkt = [
        SELECT
          Consent_Script_English__c,
          Consent_Script_French__c,
          Membership_Number_Required__c
        FROM Marketing_Association__c
        WHERE Id = :associationId
      ];
  
      consentMap.put('frenchConsent', mkt.Consent_Script_French__c);
      consentMap.put('englishConsent', mkt.Consent_Script_English__c);
      consentMap.put(
        'membershipNumberRequired',
        String.valueOf(mkt.Membership_Number_Required__c)
      );
      return consentMap;
    }
  
    @AuraEnabled
    public static String validMembership(String fileId, String associationId) {
      for (Membership__c existingMembership : [
        SELECT Id
        FROM Membership__c
        WHERE
          Marketing_Association__c = :associationId
          AND (Lead__c = :fileId
          OR Opportunity__c = :fileId)
      ]) {
        return Label.MEMBERSHIP_EXISTS;
      }
  
      return '';
    }
  }