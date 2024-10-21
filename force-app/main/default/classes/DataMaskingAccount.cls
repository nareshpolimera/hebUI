global class DataMaskingAccount implements Database.Batchable<sObject> {
    /*
     * Data Masking for Account object
     * It is a part of Sandbox refresh process
     * Id batchJobId = Database.executeBatch(new DataMaskingAccount(), 500);
     */
    global Database.QueryLocator start(Database.BatchableContext ctx) {
      return Database.getQueryLocator(
        'SELECT Id,IsPersonAccount, FirstName, MiddleName, LastName,Phone,Phone_Extension__c, BillingStreet ' +
        'FROM Account'
      );
    }
  
    /*
     * Process Account.
     */
    global void execute(Database.BatchableContext ctx, List<Account> lst) {
      List<Account> acUpd = new List<Account>();
      //DataMaskingUtils.Name lname = new DataMaskingUtils.name();
      //String mEmail = '';
      for (Account i : lst) {
        //Name Masking
        /*
              if (i != null) {
                  lname.firstname  = i.firstName;            
                  lname.middlename = i.MiddleName;
                  lname.lastname   = i.LastName;
                  system.debug('!!!Before masking :'+lname);
                  lname = DataMaskingUtils.getNameMasked(lname);
                  system.debug('!!!After masking :'+lname);
                  i.firstName  = lname.firstname;
                  i.MiddleName = lname.middlename;
                  i.LastName   = lname.lastname;
              }
              */
  
        //Address - Street Masking
        i.BillingStreet = DataMaskingUtils.getAddressMasked();
  
        //Phone
        if (String.isNotBlank(i.Phone)) {
          i.Phone = DataMaskingUtils.getPhoneMasked(i.Phone);
        }
  
        //Phone Extension
        if (String.isNotBlank(i.Phone_Extension__c)) {
          i.Phone_Extension__c = DataMaskingUtils.getPhoneExtensionMasked();
        }
  
        acUpd.add(i);
      }
  
      update acUpd;
    }
  
    /*
     * Finish method - close off batch activities.
     */
    global void finish(Database.BatchableContext ctx) {
      system.debug('Account Masking Job was completed');
    }
  }