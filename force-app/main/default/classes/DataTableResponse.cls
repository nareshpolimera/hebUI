public class DataTableResponse {
    @AuraEnabled
    public List<DataTableColumns> lstDataTableColumns {get;set;}
    @AuraEnabled
    public List<sObject> lstDataTableDataOriginal {get;set;}
    @AuraEnabled
    public List<sObject> lstDataTableData {get;set;}
    @AuraEnabled
    public List<DataTableComplainantSearchObject> lstDataTableDataOpp {get;set;}
    @AuraEnabled
    public String sourceObject {get;set;}
}