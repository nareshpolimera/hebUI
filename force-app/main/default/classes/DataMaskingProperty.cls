global class DataMaskingProperty implements Database.Batchable<sObject> {
    /*
     * Data Masking for Property object
     * It is a part of Sandbox refresh process
     * !!! User 500 batch size
     * Id batchJobId = Database.executeBatch(new DataMaskingProperty(), 500);
     */
    global Database.QueryLocator start(Database.BatchableContext ctx) {
      return Database.getQueryLocator(
        'SELECT Id, Name, StreetNameFragment__c, PropertyStreet FROM LoanApplicationProperty'
      );
    }
  
    /*
     * Process Property.
     */
    global void execute(Database.BatchableContext ctx, List<LoanApplicationProperty> lst) {
      List<LoanApplicationProperty> ptUpd = new List<LoanApplicationProperty>();
      System.debug('!!! Number of Property = ' + lst.size());
      for (LoanApplicationProperty i : lst) {
        //Address - Street Masking
        if(String.isNotBlank(i.PropertyStreet)){
            i.PropertyStreet = DataMaskingUtils.getAddressMasked();
            ptUpd.add(i);
        }
      }
      
      if(ptUpd != null && !ptUpd.isEmpty()){
        update ptUpd;
      }
    }
  
    /*
     * Finish method - close off batch activities.
     */
    global void finish(Database.BatchableContext ctx) {
      system.debug('Property Masking Job was completed');
      /**
      Id batchJobId = Database.executeBatch(new DataMaskingLead(), 500);
       */
      Id batchJobId = Database.executeBatch(new DataMaskingContact(), 1000);
    }
  }