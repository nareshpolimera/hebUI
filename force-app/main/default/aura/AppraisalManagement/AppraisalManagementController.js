({
    doInit : function(component, event, helper) {
        helper.loadFileRecord(component, helper);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.minDate', today);
    },
    
    
    refreshView: function(component, event, helper) {
        helper.refreshViewLead(component, event, helper);
    },

    loadOrders : function(component, event, helper) {
        helper.checkAllowOrder(component, helper);
    },
    
    orderFromFCT : function(component, event, helper) {                        
        helper.getquoteAmountForLead (component, helper);       
    },    
    orderFromMars : function(component, event, helper) {
        component.set('v.step', 'orderFromMars');
        helper.doOrderFromMars(component, helper);
    },
    
    updateRushOrder : function(component, event, helper) {
        var rushField = component.find("rushField");
        component.set('v.showRushWarning', rushField.get('v.value') == 'Yes');
    },

    validateMinDate : function(component, event, helper) {
        helper.validateMinDate(component, helper);
    },

    requireOtherTime : function(component, event, helper) {
        var window = component.find("timeField").get("v.value");
        component.find("otherTimeField").set("v.required", window == "Other Time");
    },
    
    toggleCostSplitType : function(component, event, helper) {
        helper.setDefaultCostAlert(component, helper);
    },
    
    updateSplitFields : function(component, event, helper) {
        console.log('updateSplitFields called');
        helper.calculateSplitFields(component, helper);
    },

    updateSplitTotalCheck : function(component, event, helper) {
        console.log('updateSplitFields called');
        helper.checkSplitTotal(component, helper);
    },

    toggleCustomerRequired : function(component, event, helper) {
        console.log('toggleCustomerRequired called');
        component.find("customerSplitField").set("v.required", component.find("paidFromProceeds").get("v.value") == "Yes");
        helper.checkSplitTotal(component, helper);
    },
    
    onFCTSubmit: function(component, event, helper) {
        event.preventDefault(); // stop form submission
        var eventFields = event.getParam("fields");
        // Check for required fields.
        if (helper.isNullOrEmpty(component.find("addressNumberFragment").get("v.value")) ||
            helper.isNullOrEmpty(component.find("streetNameFragment").get("v.value"))    ||
            helper.isNullOrEmpty(component.find("cityFragment").get("v.value"))          ||
            helper.isNullOrEmpty(component.find("provinceFragment").get("v.value"))      ||
            helper.isNullOrEmpty(component.find("postalCodeFragment").get("v.value")))   {
                component.set('v.acError', true);
                component.set('v.acErrorMessage', $A.get("$Label.c.Warning_Address_Details_Missing_Required"));
        } else {
            component.set('v.acError', false);
            component.set('v.acErrorMessage', '');
        }

        if (component.find("firstName").get("v.value")     == null ||
            component.find("lastName").get("v.value")      == null ||
            component.find("phoneField").get("v.value")    == null ||
            component.find("altPhoneField").get("v.value") == null ||
            (
                component.find("timeField").get("v.value") == 'Other Time' && 
                component.find("otherTimeField").get("v.value") == null
            )) {
                component.set('v.odError', true);
                component.set('v.odErrorMessage', $A.get("$Label.c.Warning_Order_Details_Missing_Required"));
        }
        else {
            component.set('v.odError', false);
            component.set('v.odErrorMessage', '');
        }
        console.log('v.acError = ' + component.get("v.acError"));
        console.log('v.odError = ' + component.get("v.odError"));
        if (component.get("v.acError") == false &&
            component.get("v.odError") == false ) { 
            helper.processFCTForm(component,helper);
        }

        console.log('debugging over');
    }
    
})