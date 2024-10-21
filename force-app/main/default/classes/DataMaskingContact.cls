global class DataMaskingContact implements Database.Batchable<sObject> {
    /*
     * Data Masking for Contact object
     * It is a part of Sandbox refresh process
     * Id batchJobId = Database.executeBatch(new DataMaskingContact(), 1000);
     * AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId ];
     */
    global Database.QueryLocator start(Database.BatchableContext ctx) {
      return Database.getQueryLocator(
        'SELECT Id, IsPersonAccount, FirstName, MiddleName, LastName, Age__c, Birthdate, Email, Phone, Phone_Extension__c, MobilePhone, MailingStreet FROM Contact'
      );
    }
  
    /*
     * Process Contact.
     */
    global void execute(Database.BatchableContext ctx, List<Contact> lst) {
      List<Contact> ctUpd = new List<Contact>();
      System.debug('!!! Number of Contact = ' + lst.size());
      DataMaskingUtils.Name lname = new DataMaskingUtils.name();
      //String mEmail = '';
      for (Contact i : lst) {
        //Name Masking
        lname.firstname = i.firstName;
        lname.middlename = i.MiddleName;
        lname.lastname = i.LastName;
        system.debug('!!!Before masking :' + lname);
        lname = DataMaskingUtils.getNameMasked(lname);
        system.debug('!!!After masking :' + lname);
        i.firstName = lname.firstname;
        i.MiddleName = lname.middlename;
        i.LastName = lname.lastname;
  
        //Email Masking
        //If (String.isNotBlank(i.Email)) mEmail = ld.Email;
        i.Email = DataMaskingUtils.getEmailMasked();
  
        //Address - Street Masking
        i.MailingStreet = DataMaskingUtils.getAddressMasked();
  
        //Phone
        if (String.isNotBlank(i.Phone)) {
          i.Phone = DataMaskingUtils.getPhoneMasked(i.Phone);
        }
        //Mobile Phone
        if (String.isNotBlank(i.MobilePhone)) {
          i.MobilePhone = DataMaskingUtils.getPhoneMasked(i.MobilePhone);
        }
  
        //Phone Extension
        if (String.isNotBlank(i.Phone_Extension__c)) {
          i.Phone_Extension__c = DataMaskingUtils.getPhoneExtensionMasked();
        }
  
        //DOB
        if (i.Birthdate != null) {
          i.Birthdate = DataMaskingUtils.getDOBMasked(i.Birthdate);
          //i.Birthdate = i.Birthdate.addDays(5);
        }
  
        ctUpd.add(i);
      }
  
      update ctUpd;
    }
  
    /*
     * Finish method - close off batch activities.
     */
    global void finish(Database.BatchableContext ctx) {
      system.debug('Contact Masking Job was completed');
      Id batchJobId = Database.executeBatch(new DataMaskingAccount(), 500);

      /**
      Id batchJobId = Database.executeBatch(new DataMaskingComplainant(), 500);
        */
    }
  }