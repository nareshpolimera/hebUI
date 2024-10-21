({
    handleRecordUpdated: function (component, event, helper) {
      var eventParams = event.getParams();
      if (eventParams.changeType === "LOADED") {
        // record is loaded (render other component which needs record data value)
        console.log("LOADED$$$");
        component.set("v.renderMessage", true);
        var fullMessage = component.get("v.simpleRecord").Warning_Message__c;
        if (!$A.util.isEmpty(fullMessage) && fullMessage.indexOf(";") >= 0) {
          var warningMessage = fullMessage.substring(0, fullMessage.indexOf(";"));
          var creditBureauMessage = fullMessage.substring(
            fullMessage.indexOf(";") + 1,
            fullMessage.length
          );
  
          component.set("v.warningMessage", warningMessage);
          component.set("v.creditBureauMessage", creditBureauMessage);
        } else if (!$A.util.isEmpty(fullMessage)) {
          component.set("v.warningMessage", fullMessage);
        } else {
          component.set("v.warningMessage", null);
          component.set("v.creditBureauMessage", null);
        }
      } else if (eventParams.changeType === "CHANGED") {
        // record is changed
        console.log("CHANGED!!!");
       // component.set("v.hideSpinner", true);
        $A.enqueueAction(component.get("c.refreshFileCheck"));
      } else if (eventParams.changeType === "REMOVED") {
        // record is deleted
        console.log("REMOVED");
      } else if (eventParams.changeType === "ERROR") {
        console.log("ERROR");
        // There’s an error while loading, saving, or deleting the record
      }
    },
  
    toggleBody1: function (component, event, helper) {
      $A.util.toggleClass(component.find("warningBody1"), "slds-hide");
      $A.util.toggleClass(component.find("openicon1"), "slds-hide");
      $A.util.toggleClass(component.find("closeicon1"), "slds-hide");
    },
    toggleBody2: function (component, event, helper) {
      $A.util.toggleClass(component.find("warningBody2"), "slds-hide");
      $A.util.toggleClass(component.find("openicon2"), "slds-hide");
      $A.util.toggleClass(component.find("closeicon2"), "slds-hide");
    },
    toggleBody3: function (component, event, helper) {
      $A.util.toggleClass(component.find("warningBody3"), "slds-hide");
      $A.util.toggleClass(component.find("openicon3"), "slds-hide");
      $A.util.toggleClass(component.find("closeicon3"), "slds-hide");
    },
    onAcknowledge: function (component, event, helper) {
      component.set("v.showSpinner", true);
      var today = new Date();
      component.set("v.simpleRecord.Mismatch_Acknowledgement__c", true);
      component.set(
        "v.simpleRecord.Mismatch_Acknowledgement_Date__c",
        today.toISOString()
      );
      component.set(
        "v.simpleRecord.Mismatch_Acknowledgement_By__c",
        $A.get("$SObjectType.CurrentUser.Id")
      );
      component.set(
        "v.simpleRecord.Warning_Message__c",null
      );
      component.set("v.creditBureauMessage", null); 
      if (
        $A.util.isEmpty(component.get("v.warningMessage")) &&
        $A.util.isEmpty(component.get("v.creditBureauMessage"))
      ) {
        component.set("v.renderMessage", false);
      }
  
      component.find("recordLoader").saveRecord(
        $A.getCallback(function (saveResult) {
          // use the recordUpdated event handler to handle generic logic when record is changed
          if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
            // handle component related logic in event handler
            console.log("updated rec");
            component.set("v.creditBureauMessage", null);
            component.set("v.warningMessage", null);
          } else if (saveResult.state === "INCOMPLETE") {
            console.log("User is offline, device doesn't support drafts.");
          } else if (saveResult.state === "ERROR") {
            console.log(
              "Problem saving record, error: " + JSON.stringify(saveResult.error)
            );
          } else {
            console.log(
              "Unknown problem, state: " +
                saveResult.state +
                ", error: " +
                JSON.stringify(saveResult.error)
            );
          }
          component.set("v.showSpinner", false);
        })
      );
    },
  
    refreshFileCheck: function (component, event, helper) {
      console.log("start refreshFileCheck");
      component.set("v.showSpinner", true);
      component.find("recordLoader").saveRecord(function (saveResult) {
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
          console.log("SUCCESS OR DRAFT!");
          //$A.get("e.force:refreshView").fire();
          component.find("recordLoader").reloadRecord(true);
        } else if (saveResult.state === "INCOMPLETE") {
          // handle the incomplete state
          console.log("User is offline, device doesn't support drafts.");
        } else if (saveResult.state === "ERROR") {
          // handle the error state
          console.log(
            "Problem saving, error: " + JSON.stringify(saveResult.error)
          );
        } else {
          console.log(
            "Unknown problem, state: " +
              saveResult.state +
              ", error: " +
              JSON.stringify(saveResult.error)
          );
        }
        component.set("v.showSpinner", false);
      });
    }
  });