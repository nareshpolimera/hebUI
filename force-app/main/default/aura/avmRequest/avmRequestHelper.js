({
    doPropertyLookup : function(component,  sObjectName, recordId) {
        component.set('v.showSpinner', true);
        var action = component.get('c.runAddressParse');
        action.setParams({
            "sObjectName": sObjectName,
            "recordId"   : recordId
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            console.log('doPropertyLookup===');
            console.log(recordId);
            if (state === "SUCCESS") {
                if (a.getReturnValue()) {
                    component.set('v.avmAlreadyDone', true);
                } else {
                    component.set('v.parseAddressDone', true);
                    component.set('v.message', 'The Property address has been parsed and fragments saved; please review, correct and request AVM');
                    component.set('v.messageType', 'success');
                    component.set('v.messageBackground', 'success');
                }
            } else {
                var errors = a.getError();
                console.error(errors);
                component.set('v.message', errors[0].message);
                component.set('v.messageType', 'error');
                component.set('v.messageBackground', 'error');
                component.set('v.parseAddressFailed', true);
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
        
    },

    doAvmRequest : function(component, opportunityId, sObjectName , recordId) {
        console.log('avmRequest===');
        component.set('v.showSpinner', true);
        var action = component.get('c.runAVMCheck');
        action.setParams({
            "opportunityId":opportunityId,
            "sObjectName": sObjectName,
            "recordId"   : recordId
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                component.set('v.avmRequestDone', true);
                component.set('v.parseAddressDone', false);
                component.set('v.parseAddressFailed', false);
                component.set('v.message', 'The AVM Request is Complete');
                component.set('v.messageType', 'success');
                component.set('v.messageBackground', 'success');
                component.set("v.propertyId",a.getReturnValue().Id)
                $A.get('e.force:refreshView').fire();
            } else {
                var errors = a.getError();
                console.error(errors);
                component.set('v.message', errors[0].message);
                component.set('v.messageType', 'error');
                component.set('v.messageBackground', 'error');
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
        
    },
    doAvmRequestWithPropertyFields : function(component, opportunityId, sObjectName , recordId, City, StreetName, StreetType,AddressNumber,Province, PostalCode) {
        console.log('doAvmRequestWithPropertyFields===runAVMCheckClone');
        component.set('v.showSpinner', true);
        var action = component.get('c.runAVMCheckClone');
        action.setParams({
            "opportunityId" : opportunityId,
            "sObjectName": sObjectName,
            "recordId"   : recordId,
            "City"       : City,
            "StreetName" : StreetName,
            "StreetType" : StreetType,
            "AddressNumber" : AddressNumber,
            "Province"   : Province,
            "PostalCode" : PostalCode
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                component.set("v.propertyId", a.getReturnValue().Id);
                component.set('v.avmRequestDone', true);
                component.set('v.parseAddressDone', false);
                component.set('v.parseAddressFailed', false);
                component.set('v.message', 'The AVM Request is Complete');
                component.set('v.messageType', 'success');
                component.set('v.messageBackground', 'success');
                $A.get('e.force:refreshView').fire();
            } else {
                var errors = a.getError();
                component.set('v.message', errors[0].message);
                component.set('v.messageType', 'error');
                component.set('v.messageBackground', 'error');
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
    },
    getProperty : function(component,recordId) {
        component.set('v.showSpinner', true);
        var act = component.get('c.queryProperty');
        act.setParams({
            "recordId" : recordId
        });
        act.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if (a.getReturnValue()) {
                    component.find("cityFragment1").set("v.value", a.getReturnValue().PropertyCity);
                    component.find("streetNameFragment1").set("v.value", a.getReturnValue().PropertyStreet);
                    component.find("provinceFragment1").set("v.value", a.getReturnValue().PropertyState);
                    component.find("postalCodeFragment1").set("v.value", a.getReturnValue().PropertyPostalCode);
                    console.log('Address fields set');
                }
            } else {
                var errors = a.getError();
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(act);
        
    },
    getPropertyId : function(component,recordId) {
        component.set('v.showSpinner', true);
        var act = component.get('c.queryProperty');
        act.setParams({
            "recordId" : recordId
        });
        act.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if (a.getReturnValue()) {
                    component.set("v.propertyId", a.getReturnValue().Id);
                    
                }
            } else {
                var errors = a.getError();
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(act);
        
    },
    getAppraisal : function(component,recordId,sObjectName) {
       
        component.set('v.showSpinner', true);
        var act = component.get('c.getRecordsInContext');
        act.setParams({
            "recordId" : recordId,
            "sObjectName": sObjectName
        });
        act.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if (a.getReturnValue()) {
                   
                    component.set("v.appraisalId", a.getReturnValue().Id);
                   // component.set("v.propertyId",a.getReturnValue().Application_Property__c)
                }
            } else {
                var errors = a.getError();
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(act);
        
    }
})