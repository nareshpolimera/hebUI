({
    doInit : function(component, event, helper) {
        console.log('retrieve user perm');
        helper.retrieveUserPermission(component,event,helper);
        component.set('v.notesColumns', [
            {label: 'Entered By', fieldName: 'Entered_By__c', type: 'text', wrapText: true},
            {label: 'Entered On', fieldName: 'Entered_On_DT__c', type: 'datetime',typeAttributes: {  
                                                                            day: 'numeric',  
                                                                            month: 'short',  
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true}},
            {label: 'Content', fieldName: 'Content__c', type: 'text', wrapText: true}
        ]);

        component.set('v.statusColumns', [
            {label: 'Current?', fieldName: 'Is_Current__c', type: 'text',wrapText: true},
            {label: 'Status', fieldName: 'Status__c', type: 'text', wrapText: true},
            {label: 'Status Date', fieldName: 'Status_Date__c', type: 'datetime',typeAttributes: {  
                                                                            day: 'numeric',  
                                                                            month: 'short',  
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true}}
        ]);

        helper.determineActionVisibility(component, event, helper);  
        helper.retrieveNotes(component, event, helper);
    },

    goBack : function(component, event, helper) {
        component.set('v.message', '');
        component.set('v.step', 'view');
    },
    
    startUpdateFee : function(component, event, helper) {
        component.set('v.step', 'updateFee');
    },

    sendNote : function(component, event, helper) {
        component.set('v.step', 'sendNote');
    },
    
    confirmNote : function(component, event, helper) {
        helper.retrieveStatuses(component, event, helper);
        helper.retrieveNotes(component, event, helper);
        component.set('v.step', 'view');
        component.set('v.message', $A.get("$Label.c.Aura_AppraisalNoteConfirm"));
        component.set('v.messageType', 'success');
        component.set('v.messageBackground', 'success');
    },
    
    cancelOrder : function(component, event, helper) {
        component.set('v.step', 'confirmCancel');
    },

    finishCancel : function(component, event, helper) {
      event.preventDefault(); // stop form submission
      helper.validateCancellation(component, event, helper);
    },
    
    runUpdateFees: function(component, event, helper) {
      event.preventDefault(); // stop form submission
      helper.validateUpdateFee(component, event, helper);
    },
    
    toggleCostSplitType : function(component, event, helper) {
        helper.setDefaultCostAlert(component, helper);
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

    handleCreateLoad: function (component, event, helper) {       
        component.find("customerSplitField").set("v.required", component.find("paidFromProceeds").get("v.value") == "Yes");
     }
      
})