public without sharing class UserService {
    public static void updatePersonAccount(List<User> records, Map<Id, User> oldRecords) {
        //Return early if this is a mass update
        if (records.size() > 1) {
            return;
        }

        //Grab the corresponding records
        User updatedUser = records[0];
        User oldUser = oldRecords.get(updatedUser.Id);

        //Update prompotion opt out on associated account (if a change has been made)
        if (updatedUser.Promotion_Opt_Out__c != oldUser.Promotion_Opt_Out__c) {
            Id uid = System.UserInfo.getUserId();
            User currUser = [SELECT Id, AccountId FROM User WHERE Id = :uid][0];
            List<Account> listUserAcc= [SELECT Id, FinServ__MarketingOptOut__pc FROM Account WHERE Id = :currUser.AccountId];
            if(listUserAcc.size()>0) {
                Account currUserAcc = listUserAcc[0];
                currUserAcc.FinServ__MarketingOptOut__pc = updatedUser.Promotion_Opt_Out__c;
                update currUserAcc;
            }            
        }
    }
}