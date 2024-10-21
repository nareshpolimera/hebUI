({
    retrieveProperty : function(component, helper) {
        var action = component.get('c.getFileProperty');
        console.log(component.get('v.simpleRecord').Id);
        //console.log(component.get('v.simpleRecord').Property__c);
        action.setParams({
            "propertyId" : component.get('v.simpleRecord').Id
        });
        console.log(component.get('v.simpleRecord'));
        action.setCallback(this, function(a) {
            var state = a.getState();
            console.log('state = ' + state);
            if (state === "SUCCESS") {
                console.log('a.getReturnValue()');
                console.log(a.getReturnValue());
                helper.placeMarker(component, a.getReturnValue());                
            } else {
                var errors = a.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },

    placeMarker : function(component, property) {
        console.log('placeMarker start ');
        if (
            property != null && 
            property.PropertyStreet != null && 
            property.PropertyCity != null && 
            property.PropertyState != null 
        ) {
            let markers = [];
            markers.push({
                'location': {
                    Street: property.PropertyStreet,
                    City: property.PropertyCity,
                    State: property.PropertyState
                },
                title: property.PropertyStreet + ' ' + property.PropertyCity + ' ' + property.PropertyState,
            });
            component.set('v.mapMarkers', markers);
            component.set('v.addressFound', true);
        }
        
    }
})