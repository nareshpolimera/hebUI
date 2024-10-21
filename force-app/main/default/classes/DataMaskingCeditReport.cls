global class DataMaskingCeditReport implements Database.Batchable<sObject>, Database.Stateful {
    /*
     * Data Masking for Credit Report Score
     * It is a part of Sandbox refresh process
     * Id batchJobId = Database.executeBatch(new DataMaskingCeditReport(), 2000);
     */
    public Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {

      return Database.getQueryLocator(
        'SELECT Id, Name, Credit_Score__c, Credit_Summary__c FROM Credit_Report__c'
      );
    }
  
    /*
     * Process Credit Report.
     */
    global void execute(
      Database.BatchableContext bc,
      List<Credit_Report__c> lst
    ) {
      List<Credit_Report__c> ptUpd = new List<Credit_Report__c>();
      System.debug('!!! Number of Credit_Report__c = ' + lst.size());
      for (Credit_Report__c i : lst) {
        //Credit Summary
        if (i.Credit_Summary__c != null) {
          i.Credit_Summary__c = 'Credit Summary';
        }
  
        //Credit Score Masking
        if (i.Credit_Score__c != null && i.Credit_Score__c > 0) {
          i.Credit_Score__c = DataMaskingUtils.getCreditScoreMasked();
        }
        recordsProcessed = recordsProcessed + 1;
        ptUpd.add(i);
      }
  
      update ptUpd;
    }
  
    /*
     * Finish method - close off batch activities.
     */
    global void finish(Database.BatchableContext bc) {
      system.debug('Credit Report Masking Job was completed');
      System.debug(recordsProcessed + ' records processed. !!! Credit Report ');
      AsyncApexJob job = [
        SELECT
          Id,
          Status,
          NumberOfErrors,
          JobItemsProcessed,
          ExtendedStatus,
          TotalJobItems,
          CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :bc.getJobId()
      ];
      // call some utility to send email
      DataMaskingUtils.sendMSG('Credit Report', job, recordsProcessed);
      System.debug('!!! job additional info : ' + job);

      /**
      Id batchJobId = Database.executeBatch(
        new DataMaskingPropertyMemeber(),
        2000
      );
       */

       Id batchJobId = Database.executeBatch(new DataMaskingProperty(), 2000);
    }
  }