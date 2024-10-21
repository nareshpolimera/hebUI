public without sharing class CreateNewAccountLWCHandler {
   

  public class TestWrapper {
    @auraEnabled public Map<String,Object> primaryAccount{get; set;}
  }

  @AuraEnabled
  public static string sampleMethod(TestWrapper wrapper){
    try {
      return 'test';
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

    /*-----------------------------------------------------------------------------------
      @description       : Method is responsible for returning inital defaults required
      @last modified on  : 07-14-2021
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   04-21-2021   Majente Dev                          Initial Version
      -----------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static InitReturnWrapper init(){
      InitReturnWrapper wrapper = new InitReturnWrapper();
      wrapper.accountRecordTypeId = getRecordTypeID();
      wrapper.recordTypeOptions = getAssignedRecordTypes();
       
       return wrapper;
    }

    @AuraEnabled
    public static Id insertRecord(  PropertyRecord pr,Lead leadRecord,
                                    String recordtypeId,
                                    String propertyId,
                                    String primaryContactPropertyMember,
                                    String borrowerOne,
                                    String borrowerTwo,
                                    Boolean isDuplicateErrorSkip)
                                    { return '12345677';   }


    /*-----------------------------------------------------------------------------------
      @description       : Wrapper class
      @last modified on  : 07-14-2021
      Modifications Log
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   04-21-2021   Majente Dev                          Initial Version
      -----------------------------------------------------------------------------------
    */ 
    public class InitReturnWrapper {
        @auraEnabled public Id accountRecordTypeId{get; set;}
        @auraEnabled public List<Options> recordTypeOptions{get; set;}
        @auraEnabled public List<Options> propertyProvinceOptions{get; set;}


    }



    /*-----------------------------------------------------------------------------------
      @description       : Method is responsible for returning the default record type Id
      @last modified on  : 07-14-2021
      @param             : NA
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   04-21-2021   Majente Dev                          Initial Version
      -----------------------------------------------------------------------------------
    */
    public static Id getRecordTypeID(){
        Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
            }
        }
        return defaultRecordType.getRecordTypeId();
    }


    /*-----------------------------------------------------------------------------------
      @description       : Method is responsible for returning the assigned record types to the current user
      @last modified on  : 07-14-2021
      @param             : NA
      Modifications Log 
      -----------------------------------------------------------------------------------
      Ver   Date         Author                               Modification
      1.0   04-21-2021   Majente Dev                          Initial Version
      -----------------------------------------------------------------------------------
    */
    public static List<Options> getAssignedRecordTypes(){
        List<Options> recordTypeOptions = new List<Options>();
        Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
        for( Schema.RecordTypeInfo recordType : dsr.getRecordTypeInfos()){
            if(recordType.isAvailable()){
                if(recordType.Name!='Master') {
                    recordTypeOptions.add(new Options(recordType.Name, recordType.getRecordTypeId()));
                }
            }
        }
        return recordTypeOptions;
    }
  /*-----------------------------------------------------------------------------------
    @description       : Method is responsible for returning the assigned record types to the current user
    @last modified on  : 07-14-2021
    @param             : NA
    Modifications Log 
    -----------------------------------------------------------------------------------
    Ver   Date         Author                               Modification
    1.0   04-21-2021   Majente Dev                          Initial Version
    -----------------------------------------------------------------------------------
  */
  private Class Options{
    @AuraEnabled public string label;
    @AuraEnabled public string value;
    public Options(string label, string value){
        this.label = label;
        this.value = value;
    } 
  }
  
  public Class PropertyRecord{
    @AuraEnabled public string selectedCountry {get; set;}
    @AuraEnabled public string selectedCity {get; set;}
    @AuraEnabled public string selectedPostalCode {get; set;}
    @AuraEnabled public string selectedProvince {get; set;}
    @AuraEnabled public string street {get; set;}
    @AuraEnabled public string propertyType {get; set;}
  }
  
  public class MyPickListInfo{
    public String validFor;
  }
  
  public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField){
    Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
    
    Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
    
    Schema.DescribeSObjectResult describeResult = objType.getDescribe();
    Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
    Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
    
    List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
    List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
    
    for(Schema.PicklistEntry currControllingValue : controllingValues)
    {
        controllingInfo.put(currControllingValue.getLabel(), new List<String>());
    }
    
    for(Schema.PicklistEntry currDependentValue : dependentValues)
    {
        String jsonString = JSON.serialize(currDependentValue);
        
        MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
        
        String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
        
        Integer baseCount = 0;
        
        for(Integer curr : hexString.getChars())
        {
            Integer val = 0;
            
            if(curr >= 65)
            {
                val = curr - 65 + 10;
            }
            else
            {
                val = curr - 48;
            }
            
            if((val & 8) == 8)
            {
                controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
            }
            if((val & 4) == 4)
            {
                controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());                    
            }
            if((val & 2) == 2)
            {
                controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());                    
            }
            if((val & 1) == 1)
            {
                controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());                    
            }
            
            baseCount += 4;
        }            
    } 
    
    return controllingInfo;
  }

}