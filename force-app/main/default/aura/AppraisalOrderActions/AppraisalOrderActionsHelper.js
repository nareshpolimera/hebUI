({
    determineActionVisibility: function (component, event, helper) {
      if (
        (component.get("v.order").Cancellation_Reason__c == null ||
          component.get("v.order").Cancellation_Reason__c == "") &&
        component.get("v.order").Appraisal__r.Opportunity__c == null
      ) {
        component.set("v.showActionButtons", true);
      } else {
        component.set("v.showActionButtons", false);
      }
    },
  
    validateCancellation: function (component, event, helper) {
      var action = component.get("c.validateCancellation");
      var recordId = component.get("v.order").Id;
  
      action.setParams({
        recordId: recordId
      });
  
      component.set("v.showSpinner", true);
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          console.log("From server: " + response.getReturnValue());
          var JsonResponse = JSON.parse(response.getReturnValue());
          if (!JsonResponse.valid) {
            component.set("v.message", JsonResponse.errors.toString());
            component.set("v.messageType", "error");
            component.set("v.messageBackground", "error");
            component.set("v.showSpinner", false);
          } else {
            helper.cancelAppraisalOrder(component, event, helper);
          }
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
      });
  
      $A.enqueueAction(action);
    },
  
    cancelAppraisalOrder: function (component, event, helper) {
      var action = component.get("c.cancelAppraisalOrder");
      var recordId = component.get("v.order").Id;
  
      action.setParams({
        recordId: recordId
      });
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var info = response.getReturnValue();
  
          var order = component.get("v.order");
          order.Cancellation_Reason__c = component
            .find("cancellationField")
            .get("v.value");
          component.set("v.order", order);
  
          helper.determineActionVisibility(component, event, helper);
  
          component.set(
            "v.message",
            $A.get("$Label.c.Aura_ConfirmAppraisalCancel")
          );
          component.set("v.messageType", "success");
          component.set("v.messageBackground", "success");
          component.set("v.step", "view");
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
        component.set("v.showSpinner", false);
      });
  
      $A.enqueueAction(action);
    },
  
    setDefaultCostAlert: function (component, helper) {
      var labelString = $A.get("$Label.c.Alert_Default_Cost");
      var field = component.find("costSplitTypeField");
      var defaultTotal =
        field.get("v.value") == "Percent"
          ? 100
          : component.find("actualCostField").get("v.value");
      component
        .find("customerSplitField")
        .set("v.value", field.get("v.value") == "Percent" ? 100 : defaultTotal);
      component
        .find("partnerSplitField")
        .set("v.value", field.get("v.value") == "Percent" ? 0 : 0);
      component
        .find("hebSplitField")
        .set("v.value", field.get("v.value") == "Percent" ? 0 : 0);
    },
  
    checkSplitTotal: function (component, helper) {
      console.log("checkSplitTotal trace");
      var costSplitTypeField = component.find("costSplitTypeField");
      var hebField = component.find("hebSplitField");
      var partnerField = component.find("partnerSplitField");
      var customerField = component.find("customerSplitField");
  
      var defaultTotal =
        costSplitTypeField.get("v.value") == "Percent"
          ? 100
          : component.find("actualCostField").get("v.value");
  
      var currentTotal =
        parseFloat(customerField.get("v.value")) +
        parseFloat(hebField.get("v.value")) +
        parseFloat(partnerField.get("v.value"));
      if (currentTotal != defaultTotal) {
        component.find("updateFeesBtn").set("v.disabled", true);
        component.set("v.messageType", "error");
        if (costSplitTypeField.get("v.value") == "Percent")
          component.set(
            "v.message",
            $A.get("$Label.c.Warning_Split_Field_Percent_Total")
          );
        else
          component.set(
            "v.message",
            $A
              .get("$Label.c.Warning_Split_Field_Amount_Total")
              .replace("350", defaultTotal)
          );
      } else if (
        component.find("paidFromProceeds").get("v.value") == "Yes" &&
        component.find("customerSplitField").get("v.value") == 0
      ) {
        component.find("updateFeesBtn").set("v.disabled", true);
        component.set(
          "v.message",
          $A.get("$Label.c.Warning_Customer_Split_Greater_Than_Zero")
        );
      } else {
        component.find("updateFeesBtn").set("v.disabled", false);
        component.set("v.message", "");
      }
    },
  
    validateUpdateFee: function (component, event, helper) {
      var action = component.get("c.validateUpdateFee");
      var recordId = component.get("v.order").Id;
  
      var appraisal = {
        sobjectType: "Appraisal__c",
        Actual_Cost__c: component.find("actualCostField").get("v.value"),
        Cost_Split_Type__c: component.find("costSplitTypeField").get("v.value"),
        Customer_Split__c: component.find("customerSplitField").get("v.value"),
        Partner_Split__c: component.find("partnerSplitField").get("v.value"),
        HEB_Split__c: component.find("hebSplitField").get("v.value"),
        Paid_From_Proceeds__c: component.find("paidFromProceeds").get("v.value"),
        Cost_Exception_Approval__c: component
          .find("costExceptionApproval")
          .get("v.value"),
        Id: component.get("v.order").Appraisal__c
      };
  
      action.setParams({
        recordId: recordId,
        appraisal: appraisal
      });
      component.set("v.showSpinner", true);
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var JsonResponse = JSON.parse(response.getReturnValue());
          if (!JsonResponse.valid) {
            component.set("v.message", JsonResponse.errors.toString());
            component.set("v.messageType", "error");
            component.set("v.messageBackground", "error");
            component.set("v.showSpinner", false);
          } else {
            helper.doUpdateFee(component, event, helper, appraisal);
          }
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
          component.set("v.showSpinner", false);
        }
      });
  
      $A.enqueueAction(action);
    },
  
    doUpdateFee: function (component, event, helper, appraisal) {
      var action = component.get("c.updateFee");
      var recordId = component.get("v.order").Id;
  
      action.setParams({
        recordId: recordId,
        appraisal: appraisal
      });
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var info = response.getReturnValue();
          helper.retrieveNotes(component, event, helper);
          component.set(
            "v.message",
            $A.get("$Label.c.Aura_UpdateFeeConfirmation")
          );
          component.set("v.messageType", "success");
          component.set("v.messageBackground", "success");
          component.set("v.step", "view");
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
        component.set("v.showSpinner", false);
      });
  
      $A.enqueueAction(action);
    },
  
    retrieveNotes: function (component, event, helper) {
      console.log("retrieveNotes called!");
      var action = component.get("c.getNotes");
      var recordId = component.get("v.order").Id;
  
      action.setParams({
        appraisalOrderId: recordId
      });
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          component.set("v.notes", response.getReturnValue());
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
      });
  
      $A.enqueueAction(action);
    },
  
    retrieveUserPermission: function (component, event, helper) {
      console.log("calling retrieveUserPermission");
      var action = component.get("c.hasSalesPermission");
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            if(response.getReturnValue()==true){
                component.set("v.isCancelDisabled", false);
            }
            this.retrieveStatuses(component, event, helper);
            
        } 
        else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
      });
  
      $A.enqueueAction(action);
  },
  
  retrieveStatuses: function (component, event, helper) {
      console.log("calling retrieveStatuses");
      console.log(component.get("v.order"));
      var action = component.get("c.getStatuses");
      var recordId = component.get("v.order").Id;
  
      console.log(recordId);
      action.setParams({
        appraisalOrderId: recordId
      });
  
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          component.set("v.statuses", response.getReturnValue());
          var statusList = component.get("v.statuses");
          for (var i = 0; i < statusList.length; i++) {
            if (
              statusList[i].Is_Current__c === 'Yes' &&
              (statusList[i].Status__c === "Report Pending" ||
                statusList[i].Status__c === "Completed")
            ) {
              component.set("v.isCancelDisabled", false);
            }
          }
        } else {
          console.log("Failed with state: " + state);
          var errors = response.getError();
          component.set("v.message", errors[0].message);
          component.set("v.messageType", "error");
          component.set("v.messageBackground", "error");
        }
      });
  
      $A.enqueueAction(action);
    }
  });