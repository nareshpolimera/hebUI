({
    doInit: function (component, event, helper) {
      helper.populateAssociationNames(component, event, helper);
      helper.initalizeRecord(component, event, helper);
    },
    handleAssociationChange: function (component, event, helper) {
      component.set("v.message", "");
      component.set("v.messageType", "");
      component.set("v.messageBackground", "");
  
      if (component.get("v.selectedAssociationId") != null) {
        component.set("v.associatonSelected", true);
        component.set("v.simpleMembership.Membership_Number__c", "");
  
        helper.populateAssociationScript(component, event, helper);
      }
    },
    handleSaveMembership: function (component, event, helper) {
      helper.validateMembership(component, event, helper);
    },
  
    isRefreshed: function () {
      location.reload();
    }
  });