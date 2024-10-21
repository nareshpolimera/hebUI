public class CreateAccountWrapper {
    @AuraEnabled
    public PrimaryAccount primaryAccount;
    @AuraEnabled
    public PropertyMember PropertyMemberOne;
    @AuraEnabled
    public PropertyMember PropertyMemberTwo;
    @AuraEnabled
    public FileDetails fileDetails;
    @AuraEnabled
    public PartnerDetails partnerDetails;
    @AuraEnabled
    public Consent consent;
    @AuraEnabled
    public Property property;
    @AuraEnabled
    public List<String> LoanPurpose; // Updated to handle different formats

    public class PrimaryAccount {
        @AuraEnabled
        public Boolean isPrimaryContact;
        @AuraEnabled
        public Boolean isMailingAddressSameAsProperty;
        @AuraEnabled
        public String salutation;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String dateOfBirth; // Keep as String to handle empty values
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String primaryCity;
        @AuraEnabled
        public String primaryCountry;
        @AuraEnabled
        public String primaryPostalCode;
        @AuraEnabled
        public String primaryProvince;
        @AuraEnabled
        public String primaryStreet;

        public Account toAccount(Property property, String Language){
            Account personAcc = new Account();
            personAcc.Salutation = salutation;
            personAcc.Firstname = firstName;
            personAcc.LastName = lastName;
            personAcc.Phone = phone;
            personAcc.PersonEmail = email;
            personAcc.Language__pc = Language;
            personAcc.PersonMailingCountry = isMailingAddressSameAsProperty ? property.CountryCode : primaryCountry;
            personAcc.PersonMailingStreet = isMailingAddressSameAsProperty ? property.Street : primaryStreet;
            personAcc.PersonMailingCity = isMailingAddressSameAsProperty ? property.City : primaryCity;
            personAcc.PersonMailingState = isMailingAddressSameAsProperty ? property.State : primaryProvince;
            personAcc.PersonMailingPostalCode = isMailingAddressSameAsProperty ? property.Zip : primaryPostalCode;
            return personAcc;
        }
    }

    public class PropertyMember {
        @AuraEnabled
        public Boolean isPrimaryContact;
        @AuraEnabled
        public Boolean isMailingAddressSameAsProperty;
        @AuraEnabled
        public String salutation;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String age;
        @AuraEnabled
        public String gender;
        @AuraEnabled
        public String dateOfBirth; // Keep as String to handle empty values
        @AuraEnabled
        public String maritalStatus;
        @AuraEnabled
        public String primaryCity;
        @AuraEnabled
        public String primaryCountry;
        @AuraEnabled
        public String primaryPostalCode;
        @AuraEnabled
        public String primaryProvince;
        @AuraEnabled
        public String primaryStreet;
        @AuraEnabled
        public Boolean isPrimaryBorrower;
        @AuraEnabled
        public String controlling;
        @AuraEnabled
        public String dependent;
        @AuraEnabled
        public String RelationshipCategory;
        @AuraEnabled
        public String RelationshipType;

        public Account toAccount(Property property){
            Account personAcc = new Account();
            personAcc.Salutation = salutation;
            personAcc.Firstname = firstName;
            personAcc.LastName = lastName;
            personAcc.PersonHomePhone = phone;
            personAcc.PersonEmail = email;
            personAcc.PersonMailingStreet = isMailingAddressSameAsProperty ? property.Street: primaryStreet;
            personAcc.PersonMailingCity = isMailingAddressSameAsProperty ? property.City: primaryCity;
            personAcc.PersonMailingState = isMailingAddressSameAsProperty ? property.State: primaryProvince;
            personAcc.PersonMailingPostalCode = isMailingAddressSameAsProperty ? property.Zip : primaryPostalCode;
            personAcc.PersonMailingCountry = isMailingAddressSameAsProperty ? property.CountryCode : primaryCountry;
            
            if (String.valueOf(dateOfBirth) != '' && dateOfBirth != null) {
                personAcc.PersonBirthdate = Date.valueOf(dateOfBirth);
                personAcc.Date_of_Birth__pc = Date.valueOf(dateOfBirth);
            }
            personAcc.Age__pc = String.IsNotBlank(age) ? Integer.valueOf(age) : null;
            personAcc.Gender__pc = gender;
            personAcc.Marital_Status__pc = maritalStatus;
            return personAcc;
        }
    }

    public class FileDetails {
        @AuraEnabled
        public String Source;
        @AuraEnabled
        public String Type;
        @AuraEnabled
        public String Language;
        @AuraEnabled
        public String Channel;
    }

    public class PartnerDetails {
        @AuraEnabled
        public String ReferralChannel;
        @AuraEnabled
        public String Territory;
        @AuraEnabled
        public String ReferralPartner;
        @AuraEnabled
        public String ReferralOrganization;
        @AuraEnabled
        public String SubmissionAgent;
    }

    public class Consent {
        @AuraEnabled
        public String CASLConsent;
        @AuraEnabled
        public String CASLConsentObtainedBy;
        @AuraEnabled
        public String CASLConsentProvidedOn; // Keep as String to handle empty values
    }

    public class Property {
        @AuraEnabled
        public String PropertyType;
        @AuraEnabled
        public String HomeValue; // Keep as String to handle empty values
        @AuraEnabled
        public String CountryCode;
        @AuraEnabled
        public String Street;
        @AuraEnabled
        public String City;
        @AuraEnabled
        public String State;
        @AuraEnabled
        public String Zip;
    }
}