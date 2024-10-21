({
    initalizeRecord: function (component, event, helper) {
      // Prepare a new record from template
      component.find("recordCreator").getNewRecord(
        "Membership__c", // sObject type (objectApiName)
        null, // recordTypeId
        false, // skip cache?
        $A.getCallback(function () {
          var rec = component.get("v.newMembership");
          var error = component.get("v.recordError");
          if (error || rec === null) {
            console.log("Error initializing record template: " + error);
            return;
          }
          console.log("Record template initialized: " + rec.apiName);
        })
      );
    },
    populateAssociationNames: function (component, event, helper) {
      var action = component.get("c.setAllAssociations");
  
      action.setParams({});
      action.setCallback(this, function (data) {
        if (data.getReturnValue().length > 0) {
          console.log(data.getReturnValue());
          component.set("v.associationList", data.getReturnValue());
        } else {
          component.set("v.message", $A.get("$Label.NO_MARKETING_ASSOCIATIONS"));
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
          helper.scrollTo(0, 100);
        }
      });
  
      $A.enqueueAction(action);
    },
  
    populateAssociationScript: function (component, event, helper) {
      if (
        component.get("v.selectedAssociationId") == null ||
        component.get("v.selectedAssociationId") == ""
      ) {
        component.set("v.associatonSelected", false);
        return;
      }
      var action = component.get("c.setAssociationDetails");
      action.setParams({
        associationId: component.get("v.selectedAssociationId")
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var obj = response.getReturnValue();
          component.set("v.frenchConsent", obj.frenchConsent);
          component.set("v.englishConsent", obj.englishConsent);
          component.set(
            "v.membershipNumberRequired",
            obj.membershipNumberRequired
          );
          console.log(obj.membershipNumberRequired);
          console.log(component.get("v.membershipNumberRequired"));
        } else {
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
          helper.scrollTo(0, 100);
        }
      });
  
      $A.enqueueAction(action);
    },
  
    validateMembership: function (component, event, helper) {
      if (component.get("v.selectedAssociationId") != null) {
        var action = component.get("c.validMembership");
        action.setParams({
          fileId: component.get("v.recordId"),
          associationId: component.get("v.selectedAssociationId")
        });
        action.setCallback(this, function (response) {
          var state = response.getState();
          if (state === "SUCCESS") {
            if (response.getReturnValue() === "") {
              // Call the save method only when valid
              helper.saveMembership(component, event, helper);
            } else {
              component.set("v.message", response.getReturnValue());
              component.set("v.messageType", "error");
              component.set("v.messageBackground", "error");
              helper.scrollTo(0, 100);
            }
          } else {
            var errors = response.getError();
            component.set("v.message", errors[0].message);
            component.set("v.messageType", "error");
            component.set("v.messageBackground", "error");
            helper.scrollTo(0, 100);
          }
        });
  
        $A.enqueueAction(action);
      }
    },
  
    scrollTo: function (x, y) {
      window.scrollTo(x, y);
    },
  
    saveMembership: function (component, event, helper) {
        console.log('saveMembership');
      var recordId = component.get("v.recordId");
      var sObjectName = component.get("v.sObjectName");
      console.log('saveMembership '+ recordId+' ---' + sObjectName) ;
  
      if (sObjectName === "Lead") {
        component.set("v.simpleMembership.Lead__c", recordId);
      } else {
        component.set("v.simpleMembership.Opportunity__c", recordId);
      }
  
      component.set(
        "v.simpleMembership.Marketing_Association__c",
        component.get("v.selectedAssociationId")
      );
  
      component.set("v.simpleMembership.Id", component.get("v.recordId"));
      component.find("recordCreator").saveRecord(function (saveResult) {
        if (saveResult.state === "SUCCESS") {
          component.set("v.message", "Membership has been added.");
          component.set("v.messageType", "success");
          component.set("v.messageBackground", "success");
          $A.get("e.force:refreshView").fire();
          helper.scrollTo(0, 100);
        } else if (saveResult.state === "ERROR") {
          var errorMsg;
          if (saveResult.error[0].message != null) {
            errorMsg = saveResult.error[0].message;
          } else if (saveResult.getError() != null) {
            var errors = saveResult.getError();
            errorMsg = errors[0].message;
          } else {
            errorMsg = $A.get("$Label.c.Error_Membership_Refresh_Required");
          }
          component.set("v.message", errorMsg);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
          // handle the error state
          console.log(
            "Problem saving Membership record, error: " +
              JSON.stringify(saveResult.error)
          );
          helper.scrollTo(0, 100);
        } else {
          var errors = saveResult.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
          console.log(
            "Unknown problem, state: " +
              saveResult.state +
              ", error: " +
              JSON.stringify(saveResult.error)
          );
          helper.scrollTo(0, 100);
        }
      });
    }
  });