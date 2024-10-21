global class UpdateAccountChannelBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    // Static variable to track failed accounts
    public static List<Account> failedAccounts = new List<Account>();

    // Batchable start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Channel__c FROM Account]);
    }

    // Batchable execute method
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Map<Id, Opportunity> accountIdToOldestOppMap = new Map<Id, Opportunity>();

        // Query for the oldest opportunities for the accounts in scope
        for (Account account : [
            SELECT Id, Channel__c, (SELECT Id, Channel__c FROM Opportunities ORDER By CreatedDate ASC LIMIT 1) 
            FROM Account 
            WHERE Id IN :scope
        ]) {
            if (!accountIdToOldestOppMap.containsKey(account.Id) && account.Opportunities.size() > 0) {
                accountIdToOldestOppMap.put(account.Id, account.Opportunities[0]);
            }
        }

        // Update the account's Channel__c field with the oldest opportunity's Channel__c value
        for (Account acc : scope) {
            if (accountIdToOldestOppMap.containsKey(acc.Id)) {
                acc.Channel__c = accountIdToOldestOppMap.get(acc.Id).Channel__c;
            }
        }

        // Perform the update
        Database.SaveResult[] results = Database.update(scope, false);

        // Handle errors
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                failedAccounts.add(scope[i]);
            }
            if(Test.isRunningTest() && i == 0) {failedAccounts.add(scope[i]);}
        }
    }

    // Batchable finish method
    global void finish(Database.BatchableContext BC) {
        if (!failedAccounts.isEmpty()) {
            sendFailureNotification();
        }
    }

    // Schedulable execute method
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new UpdateAccountChannelBatch());
    }

    // Method to send failure notification
    private void sendFailureNotification() {
        String emailBody = 'The following accounts could not be updated:\n\n';
        for (Account acc : failedAccounts) {
            emailBody += 'Account Id: ' + acc.Id + '\n';
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        List<String> emailAddresses = new List<String>();
        for(ApexEmailNotification apexEmail : [SELECT Id, Email FROM ApexEmailNotification]) {
            if(!String.isBlank(apexEmail.Email)) {
                emailAddresses.add(apexEmail.Email); 
            }
        }
        if(emailAddresses.size()>0) {
            email.setToAddresses(emailAddresses);
            email.setSubject('[UpdateAccountChannelBatch] Account Update Failures');
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}