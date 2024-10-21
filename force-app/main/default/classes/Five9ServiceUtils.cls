public with sharing class Five9ServiceUtils {
    
    public static boolean checkAddtoDialList(Account oppAccount, Opportunity opp){
        if(opp == null){
            return false;
        }

        //Add_to_Dial_List__c          
        if(opp.Channel__c == 'Consumer' &&
            opp.Quote_Status__c == 'Disqualified' &&             
            oppAccount.Local_Date_Time_Numeric__c >= 900 &&
            oppAccount.Local_Date_Time_Numeric__c <= 2000 &&
            (oppAccount.CreatedDate < (System.now() - 180) || 
            oppAccount.Most_Recent_Inquiry_Date__pc < (System.now() - 180)) &&
            oppAccount.In_Nurture_Stream__c == false &&
            opp.Quote_Status__c != 'Closed Lost' &&
            oppAccount.Phone_Verification_Status__c != 'Invalid' &&
            oppAccount.Not_Interested_Yet__c == false){
            return true;
        }

        return false;
    }

    public static boolean checkDialListMain(Account oppAccount, Opportunity opp, Decimal propertyValue){
        if(opp == null){
            return false;
        }

        //Dial_List_Main__c          
        if(opp.Channel__c == 'Consumer' &&
            opp.Quote_Status__c != 'Disqualified' &&     
            (oppAccount.CreatedDate > (System.now() - 180) || 
            oppAccount.Most_Recent_Inquiry_Date__pc > (System.now() - 180)) &&
            oppAccount.In_Nurture_Stream__c == false &&
            opp.File_Queue__c == 'Initial Contact' &&
            propertyValue > 250000 &&
            opp.Quote_Status__c != 'Closed Lost' &&
            oppAccount.Phone_Verification_Status__c != 'Invalid' &&
            oppAccount.Not_Interested_Yet__c == false &&
            opp.Primary_Borrower_Age__c > 54 &&
            oppAccount.Dialer_Dormant__c == false &&
            oppAccount.Dialer_DNC__c == false){
            return true;
        }

        return false;
    }
}