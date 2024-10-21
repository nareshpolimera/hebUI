/**
 * @purpose : Controller class for lwc "PropertyAddressValidator"
 */
public with sharing class PropertyAddressValidatorController {
    /**
     * @description fetchFSAs description : This method will fetch FSA records based on provided search String
     * @return   return description
     */ 
    @AuraEnabled(cacheable=false)
    public static List<FSA__c> fetchFSAs(String searchTerm) {
        String input;

        if(String.isNotBlank(searchTerm)) {
            if(searchTerm.length() < 3) {
                input = searchTerm + '%';
            } else if(searchTerm.length() == 3) {
                input = searchTerm;
            } else {
                input = searchTerm.substring(0, 3);
            }
        } /*else {
            input = '%';
        }*/

        input = input.toUpperCase();
        System.debug('input : '  + input);
        return [SELECT Id, Name, City__c, FSA__c, Province__c 
                FROM FSA__c
                WHERE Is_Active__c = true 
                AND FSA__c LIKE :input
                Order By City__c Limit 150];
    }
    /**
     * @description fetchFSAByParams description : Fetch all FSA records based on parameters
     * @param  city     city description
     * @param  province province description
     * @param  zip      zip description
     * @return          return description
     */ 
    @AuraEnabled(cacheable=false)
    public static List<FSA__c> fetchFSAByParams(String city, String province, String zip) {   
        String zipSearch = (zip.length() < 3) ? zip + '%' : zip.substring(0, 3);
        System.debug('Params : city' + city + ', province ' + province + ', zip ' + zipSearch);
        return [SELECT Id, Name, City__c, FSA__c, Province__c 
                FROM FSA__c
                WHERE Is_Active__c = true 
                AND FSA__c LIKE :zipSearch
                AND City__c = :city
                AND Province__c = :province
                Order By City__c];
    }

}