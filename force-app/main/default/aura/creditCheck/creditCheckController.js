({
  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    if (eventParams.changeType === "LOADED") {
      console.log("record loaded");
      helper.loadDependencies(component, component.get("v.simpleRecord"), helper);
    } else if (eventParams.changeType === "CHANGED") {
      // record is changed
    } else if (eventParams.changeType === "REMOVED") {
      // record is deleted
    } else if (eventParams.changeType === "ERROR") {
      console.log("ERROR on record");
      console.log(component.get("v.recordError"));
      // there’s an error while loading, saving, or deleting the record
    }
  },

  onConsentLoad: function (component, event, helper) {
    console.log("onConsentLoad start");
    var consentValue = component.find("consentField1").get("v.value");
    console.log(consentValue);
    var consentDate = component.find("consentDate1").get("v.value");
    console.log(consentDate);
    component.find("consentField1").set("v.value", false);
    component.find("consentDate1").set("v.value", null);

    if (component.get("v.borrower2") != null) {
      var consentValue = component.find("consentField2").get("v.value");
      var consentDate = component.find("consentDate2").get("v.value");
      component.find("consentField2").set("v.value", false);
      component.find("consentDate2").set("v.value", null);
    }
  },

  onCreditUpdate: function (component, event, helper) {
    console.log("onCreditUpdate start");
    event.preventDefault();
    console.log("onCreditUpdate call doMemberUpdate");

    var taxCurrent = component.find("propTaxesCurrent").get("v.value");
    var taxOwing = component.find("propTaxesOwing").get("v.value");

    var condoFees = component.find("condoFees").get("v.value");
    var feesCurrent = component.find("condoFeesCurrent").get("v.value");
    var feesOwing = component.find("condoFeesOwing").get("v.value");

    if (
      (!taxCurrent && !(taxOwing > 0)) ||
      (condoFees != null && condoFees != "" && !feesCurrent && !(feesOwing > 0))
    ) {
      component.set(
        "v.podMessage",
        "Amounts owing must be provided if not current"
      );
      component.set("v.podMessageType", "error");
      component.set("v.podMessageBackground", "error");
    } else {
      component.set("v.podMessage", "");
      component.set("v.podMessageType", "success");
      component.set("v.podMessageBackground", "success");

      helper.doMemberUpdate(component, event, helper);
    }
  },

  taxOwingRequired: function (component, event, helper) {
    console.log("taxOwingRequired start");
    helper.taxOwingRequired(component, helper);
  },

  feesOwingRequired: function (component, event, helper) {
    console.log("feesOwingRequired start");
    helper.feesOwingRequired(component, helper);
  },

  taxOwingReset: function (component, event, helper) {
    console.log("taxOwingReset start");
    helper.taxOwingReset(component, helper);
  },

  feesOwingReset: function (component, event, helper) {
    console.log("feesOwingReset start");
    helper.feesOwingReset(component, helper);
  }
});