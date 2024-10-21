({
    
    validateQuote:function(component, event, helper) {
        
        var action	    = component.get("c.validateQuote");
        var recordId    = component.get("v.recordId");
        var sObjectName = component.get("v.sObjectName");
        
        action.setParams({
            "recordId": recordId
        });
    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                console.log("From server: " + response.getReturnValue());
                var JsonResponse = JSON.parse(response.getReturnValue());
                if (! JsonResponse.validQuote)
                {
                    component.set('v.message',  JsonResponse.errorMessage);
                    component.set('v.messageType', 'error');
                    component.set('v.messageBackground', 'error');
                    
                } else
                {
                    helper.getQuote(component, event, helper);
                    component.set('v.message', 'Quote request has been submitted. Please close this window.');
                    component.set('v.messageType', 'success');
                    component.set('v.messageBackground', 'success');
                }
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
	},
    
    getQuote:function(component, event, helper) {
        
        var action	    = component.get("c.getQuote");
        var recordId    = component.get("v.recordId");
        var sObjectName = component.get("v.sObjectName");

        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var info = response.getReturnValue();
				$A.get('e.force:refreshView').fire();
            }
            else {
                console.log("Failed with state: " + state);
                var errors = response.getError();
                component.set('v.message', errors[0].message );
                component.set('v.messageType', 'error');
                component.set('v.messageBackground', 'error');
            }
        });
        
        $A.enqueueAction(action);
    },
})