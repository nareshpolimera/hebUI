public class DataTableComplainantSearchObject {
	@AuraEnabled
    public String FileNumber {get;set;}
    @AuraEnabled
    public String FirstName {get;set;}
    @AuraEnabled
    public String LastName {get;set;}
    @AuraEnabled
    public String Channel {get;set;}
    @AuraEnabled
    public String Email {get;set;}
    @AuraEnabled
    public String PropertyStreet {get;set;}
    @AuraEnabled
    public String OpportunityId {get;set;}

    public DataTableComplainantSearchObject(String FileNumber, String Channel, String FirstName, String LastName,String Email,String PropertyStreet,String OpportunityId)
    {
        this.FileNumber = FileNumber;
        this.FirstName = FirstName;
        this.LastName = LastName;
        this.Channel = Channel;
        this.Email = Email;
        this.PropertyStreet = PropertyStreet;
        this.OpportunityId = OpportunityId;
    }
}