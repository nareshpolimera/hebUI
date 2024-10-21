/* **************************************************************************
* Wrapper: RFUserRoleCapacity
* Created by Jordan Ojeda, June 20, 2024
*
* Purpose/Methods: This wrapper class holds a User's remaining capacity
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFUserRoleCapacity {
    
    public Id userRoleId { get; set; }
    public Decimal occupation { get; set; }
    public Decimal maxCapacity { get; set; }
    public String role { get; set; }
    public Id userId { get; set; }
    public String userName { get; set; }
    public boolean available { get; set; }

    /**
    * Constructor for RFUserRoleCapacity
    * @param UserRole__c userRole role
    * @param Decimal occupation current workload
    */
    public RFUserRoleCapacity(UserRole__c userRole, Decimal occupation ) {
        this.userRoleId = userRole.Id;
        this.occupation = occupation;
        this.maxCapacity = userRole.MaxCapacity__c;
        this.role = userRole.Role__c;
        this.userId = userRole.User__c;
        this.available = userRole.Available__c;
        this.userName = userRole.User_name__c;
    }

    // Capacity method to calculate available capacity
    public Decimal getCapacity() {
        if(maxCapacity != null && occupation != null){
            return (maxCapacity - occupation);
        }
        else if(maxCapacity == null){
            return 0;
        }
        else{
            return 0;
        }
    }

    public String print(){
        String message = 'User: {0} | Role: {1} | Available: {2} | Max Capacity: {3} | Occupation: {4} | Capacity: {5}';
        List<Object> args = new List<Object>{this.userName,this.role,this.available,this.maxCapacity,this.occupation,getCapacity()};
        return String.format(message, args);
    }
}