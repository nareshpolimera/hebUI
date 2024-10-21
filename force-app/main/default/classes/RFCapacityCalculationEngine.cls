/* **************************************************************************
* Trigger: RFCapacityCalculationEngine
* Created by Jordan Ojeda, June 20, 2024
*
* Purpose/Methods: Orchestration class to calculate and return the remaining capacity of a user role
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
public without sharing class RFCapacityCalculationEngine {
    
    private RFUserRoleUtility RFUserRoleUtility;
    private Logger theLogger;
    private string classContext;

    public RFCapacityCalculationEngine(){
        this.theLogger = new Logger('Routing Framework');
        this.classContext = 'RFCapacityCalculationEngine';
        this.RFUserRoleUtility = new RFUserRoleUtility(this.theLogger);
    }

    public RFCapacityCalculationEngine(Logger log){
        this.theLogger = log;
        this.classContext = 'RFCapacityCalculationEngine';
        this.RFUserRoleUtility = new RFUserRoleUtility(log);
    }

    /**
    * Receives list of User roles, performs calculations and returns a list of remaining capacities by user
    * @param List<UserRole__c> User roles to calculate capacity for
    * @return List<RFUserRoleCapacity> List of user ids and their respective remaining capacities
    */
    public List<RFUserRoleCapacity> calculateUserRoleCapacity(List<UserRole__c> userRoles) 
    {
        //log
        theLogger.info(' {0} | START', new Object[]{classContext});

        //obtaining the list of all CapacityDefinitions Ids
        Set<Id> capacityDefinitionIds = RFUserRoleUtility.getCapacityDefinitionRefs(userRoles);

        //getting universe for CapacityDefinition
        List<CapacityDefinition__c> capacityDefinitions = RFUserRoleUtility.getCapacityDefinitions(capacityDefinitionIds);

        // Maps to hold UserRole details
        Map<Id, List<UserRole__c>> roleByCapDefId = RFUserRoleUtility.populateRoleByCapDefIdMap(userRoles);
        Map<Id, List<UserRole__c>> roleByUserId = RFUserRoleUtility.populateRoleByUserIdMap(userRoles);

        // Begin collection of capacity calculations
        List<RFUserRoleCapacity> capacityList = RFUserRoleUtility.collectRemainingCapacities(capacityDefinitions, roleByCapDefId, roleByUserId);
        capacityList = RFUserRoleUtility.getCapacitiesPerRole(capacityList, userRoles);
        
        //log
        theLogger.info(' {0} | END', new Object[]{classContext});

        return capacityList;
    }

}