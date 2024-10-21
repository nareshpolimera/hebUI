public without sharing class RFUserRoleCandidates {
    public sObject record { get; set; }
    public List<UserRole__c> userRoles { get; set; }

    public RFUserRoleCandidates(sObject record){
        this.userRoles = new List<UserRole__c>();
        this.record = record;
    }

    public void addCandicates(List<UserRole__c> candidates){
        if(candidates != null && !candidates.isEmpty()){
            this.userRoles.addAll(candidates);
        }
    }
}