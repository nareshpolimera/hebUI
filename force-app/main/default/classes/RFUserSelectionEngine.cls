public without sharing class RFUserSelectionEngine {

    private Logger theLogger;
    private string classContext;

    public RFUserSelectionEngine(){
        this.theLogger = new Logger('Routing Framework');
        this.classContext = 'RFUserSelectionEngine';
    }

    public RFUserSelectionEngine(Logger log){
        this.theLogger = log;
        this.classContext = 'RFUserSelectionEngine';
    }

    public List<RFRoutingUser> selectWinningUser(List<RFUserRoleCandidates> userRoleOptions, List<RFUserRoleCapacity> userRoleCapacities) {
        List<RFRoutingUser> userRoleSelectedList = new List<RFRoutingUser>();

        // Check if there are more UserRoleOptions
        if (userRoleOptions == null || userRoleOptions.isEmpty()) {
            //log
            System.debug('[RFUserSelectionEngine] - There are not candidates to find winning user.');
            theLogger.debug(' {0} | There are not candidates to find winning user.', new Object[]{classContext});
            return userRoleSelectedList;
        }

        //log
        theLogger.info(' {0} | START ', new Object[]{classContext});

        // Iterate through each UserRoleOption
        for (RFUserRoleCandidates candidates : userRoleOptions) {
            
            //log
            // theLogger.debug(' {0} | Finding winning user for record: {1}', new Object[]{classContext,RFUtils.getRecordId(candidates.record)});
            
            RFUserRoleCapacity selectedUserRoleCapacity = findUserRoleWithHighestCapacity(candidates.userRoles, userRoleCapacities);
            System.debug('[RFUserSelectionEngine] - selectWinningUser - selectedUserRoleCapacity: ' + selectedUserRoleCapacity);
            if (selectedUserRoleCapacity != null) {
                //log
                theLogger.debug(' {0} | User selected {1}', new Object[]{classContext,selectedUserRoleCapacity.print()});

                // Increment the occupation value for the selected user role
                selectedUserRoleCapacity.occupation += 1;

                // Add to result list
                RFRoutingUser winner = new RFRoutingUser(candidates.record,selectedUserRoleCapacity);
                userRoleSelectedList.add(winner);
                System.debug('[RFUserSelectionEngine] - selectWinningUser - winner: ' + winner);
            }
        }

        //log
        theLogger.info(' {0} | END ', new Object[]{classContext});

        return userRoleSelectedList;
    }

    // Helper method to find the UserRoleCapacity with the highest capacity
    private RFUserRoleCapacity findUserRoleWithHighestCapacity(List<UserRole__c> userRoles, List<RFUserRoleCapacity> userRoleCapacities) {
        
        System.debug('[RFUserSelectionEngine] - userRoles :: '+ userRoles);
        System.debug('[RFUserSelectionEngine] - userRoleCapacities :: '+ userRoleCapacities);
        
        RFUserRoleCapacity highestCapacityRole = null;
        Decimal highestCapacity = -1;
		
        for (UserRole__c role : userRoles) {
            for (RFUserRoleCapacity capacity : userRoleCapacities) {
                if (role.User__c == capacity.userId && role.Role__c == capacity.role) {
                    Decimal currentCapacity = capacity.getCapacity();
                    System.debug('[RFUserSelectionEngine] - currentCapacity :: ' + currentCapacity);
                    if (currentCapacity > 0 && currentCapacity > highestCapacity) {
                        highestCapacityRole = capacity;
                        highestCapacity = currentCapacity;
                    }
                }
            }
        }
		
        return highestCapacityRole;
    }
}