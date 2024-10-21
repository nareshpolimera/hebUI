({
    doInit: function(component, event, helper) {
        // Fetch the Person Account record type ID
        var action = component.get("c.getPersonAccountRecordTypeId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var clientRecordTypeId = response.getReturnValue();
                var recordTypeId = component.get("v.pageReference").state.recordTypeId;
                component.set("v.recordtypeId", recordTypeId);

                var navService = component.find("navService");
                var baseUrl = window.location.origin;

                // Set the isClientRecordType attribute
                component.set("v.isClientRecordType", recordTypeId === clientRecordTypeId);

                if (recordTypeId !== clientRecordTypeId) {
                    if (navService) {
                        console.log('Navigation service is available.');
                        window.location.href = baseUrl + '/lightning/o/Account/new?count=3&nooverride=1&useRecordTypeCheck=1&navigationLocation=LIST_VIEW&recordTypeId=' + recordTypeId;
                    } else {
                        console.error('Navigation service is not available.');
                        // Fallback to direct window location change if navService is not available
                        window.location.href = baseUrl + '/lightning/o/Account/new?count=3&nooverride=1&useRecordTypeCheck=1&navigationLocation=LIST_VIEW&recordTypeId=' + recordTypeId;
                    }
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error('Error retrieving Person Account record type ID:', errors);
            }
        });
        $A.enqueueAction(action);
    },

    handleClose: function(component, event, helper) {
        var homeEvent = $A.get("e.force:navigateToObjectHome");
        homeEvent.setParams({
            "scope": "Account"
        });
        homeEvent.fire();

        //console.log('calling closeTab');
        helper.closeTab(component);

        $A.get("e.force:closeQuickAction").fire();        
    },

    closeTab: function(component, event, helper) {
        helper.closeTab(component);
    }

})