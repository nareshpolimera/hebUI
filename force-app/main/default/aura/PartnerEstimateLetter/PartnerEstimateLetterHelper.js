({
	openActionWindow : function(component, event, helper) {
		var action	    = component.get("c.generateCommitmentLetterPlatformEvent");
        var recordId    = component.get("v.recordId");
        
        action.setParams({
            "leadId": recordId,
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                console.log("From server: " + response.getReturnValue());
                var JsonResponse = JSON.parse(response.getReturnValue());
                if (JsonResponse.submitted) {
                    component.set('v.message', $A.get("$Label.c.Status_Commitment_Letter_Submitted"));
                    component.set('v.messageType', 'success');
                    component.set('v.messageBackground', 'success');
                }
                else {
                    component.set('v.message', JsonResponse.errorMessage);
                    component.set('v.messageType', 'error');
                    component.set('v.messageBackground', 'error');
                }

                /*setTimeout(function() {
                    $A.get("e.force:closeQuickAction").fire();
                    location.reload();
                    // $A.get("e.force:refreshView").fire();
                }, 1000);*/
            }
            else {
                console.log("Failed with state: " + state);
                var errors = response.getError();
                component.set('v.message', errors[0].message);
                component.set('v.messageType', 'error');
                component.set('v.messageBackground', 'error');
            }
        });
        
        $A.enqueueAction(action);
	}
})