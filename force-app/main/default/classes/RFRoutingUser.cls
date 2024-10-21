/* **************************************************************************
* Wrapper: RFRoutingUser
* Created by Jordan Ojeda, June 20, 2024
*
* Purpose/Methods: This wrapper class holds a User's remaining capacity
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFRoutingUser {
    
    public RFUserRoleCapacity userRole { get; set; }
    public String recordId { get; set; }
    public sObject record { get; set; }

    /**
    * Constructor for RFUserRoleCapacity
    * @param UserRole__c userRole role
    * @param Decimal ocupation current workload
    */
    public RFRoutingUser(String recordId, RFUserRoleCapacity userRole ) {
        this.userRole = userRole;
        this.recordId = recordId;
    }

    /**
    * Constructor for RFUserRoleCapacity
    * @param UserRole__c userRole role
    * @param Decimal ocupation current workload
    */
    public RFRoutingUser(sObject record, RFUserRoleCapacity userRole ) {
        this.userRole = userRole;
        this.record = record;
        if(record != null){
            this.recordId = record.id;
        }
    }
}