({
    avmRequest : function(component, event, helper) {
        console.log('avmRequest');
        helper.doAvmRequest(component, component.get('v.simpleRecord.OpportunityId'), component.get('v.sObjectName'), component.get('v.recordId'));
        
    },
    avmRequestWithRecordSave : function(component, event, helper) {
        console.log('avmRequestWithRecordSave');
        component.set('v.onLoadSwitch',false);
        helper.doAvmRequestWithPropertyFields(component, component.get('v.simpleRecord.OpportunityId'), component.get('v.sObjectName'), component.get('v.recordId'),component.find('cityFragment1').get('v.value'),component.find('streetNameFragment1').get('v.value'),component.find('streetTypeFragment1').get('v.value'),component.find('addressNumberFragment1').get('v.value'),component.find('provinceFragment1').get('v.value'),component.find('postalCodeFragment1').get('v.value'));

    }, 
    handleCreateLoad: function (component, event, helper) {
        if(component.get('v.onLoadSwitch') === true){
            helper.getProperty(component,component.get('v.recordId'));
        }
    
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            helper.doPropertyLookup(component, component.get('v.sObjectName'), component.get('v.recordId'));
        } else if (eventParams.changeType === "CHANGED") {
            // record is changed
        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if (eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    getPropertyAndAppraisalId:function (component, event, helper) {
        if(component.get('v.onLoadSwitch') === true){
            helper.getPropertyId(component,component.get('v.recordId'));
            helper.getAppraisal(component,component.get('v.recordId'),component.get('v.sObjectName'));
        }
    }
})