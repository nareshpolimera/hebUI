({
  loadRecord: function (component, record, helper) {
    console.log("loadRecord");
    component.set("v.showSpinner", true);
    // component.set("v.assessment", {});
    if (record.Opportunity.Credit_bureau_status__c == "Incomplete") {
      helper.showError(component, $A.get("$Label.c.Credit_Check_Incomplete"));
    }
    if (JSON.stringify(component.get("v.property")) === '{}') {
      helper.showError(component, $A.get("$Label.c.Error_File_No_Property"));
      component.set("v.showSpinner", false);
    } else if (component.get("v.assessment").Credit_Assessment_Successful__c) {
      helper.showPrompt(
        component,
        $A.get("$Label.c.Aura_Credit_Check_Complete")
      );
      component.set("v.step", "showAssessment");
      component.set("v.showSpinner", false);
    } else {
      helper.retrieveBorrowers(component, record, helper);
    }
  },

  loadDependencies: function (component, record, helper) {
    Promise.all([
      helper.retrieveProperty(component, record, helper), 
      helper.retrieveAssessment(component, record, helper)
    ]).then(function(results) {
      console.log('Dependencies loaded');
      // record is loaded (render other component which needs record data value)
      helper.loadRecord(component, record, helper);
    }).catch(function (err) {
      console.log('Dependencies not loaded');
      //Handle errors on any promise here
    });
  },

  taxOwingRequired: function (component, helper) {
    console.log("taxOwingRequired start");
    var taxCurrent = component.find("propTaxesCurrent").get("v.value");
    var taxOwing = component.find("propTaxesOwing");
    taxOwing.set("v.required", !taxCurrent);
    if (taxOwing.get("v.value") == "") {
      taxOwing.set("v.value", 0);
    }
  },

  feesOwingRequired: function (component, helper) {
    console.log("feesOwingRequired start");
    var condoFees = component.find("condoFees").get("v.value");
    var feesCurrent = component.find("condoFeesCurrent").get("v.value");
    var feesOwing = component.find("condoFeesOwing");
    feesOwing.set(
      "v.required",
      condoFees != null && condoFees != "" && !feesCurrent
    );
    if (feesOwing.get("v.value") == "") {
      feesOwing.set("v.value", 0);
    }
  },

  taxOwingReset: function (component, helper) {
    var taxesOwing = component.find("propTaxesOwing");

    console.log(taxesOwing.get("v.value"));
    if (taxesOwing.get("v.value") == null || taxesOwing.get("v.value") == "") {
      taxesOwing.set("v.value", 0);
    }
  },

  feesOwingReset: function (component, helper) {
    var feesOwing = component.find("condoFeesOwing");
    console.log(feesOwing.get("v.value"));
    if (feesOwing.get("v.value") == null && feesOwing.get("v.value") == "") {
      feesOwing.set("v.value", 0);
    }
  },

  retrieveBorrowers: function (component, record, helper) {
    console.log("retrieveBorrowers");
    component.set("v.showSpinner", true);
    var action = component.get("c.getBorrowers");
    action.setParams({
      oppId: record.OpportunityId
    });
    action.setCallback(this, function (a) {
      var state = a.getState();
      if (state === "SUCCESS") {
        component.set("v.borrowers", a.getReturnValue().applicants);
        console.log("v.borrowers");
        console.log(component.get("v.borrowers"));
        if (JSON.stringify(component.get("v.borrowers")) === "{}") {
          helper.showError(component, $A.get("$Label.c.Error_No_Borrowers"));
        } else {
          component.set("v.borrower1", component.get("v.borrowers")[0]);
          if(component.get("v.borrowers") != undefined && component.get("v.borrowers")[0] != undefined) {
            component.set("v.pension1", component.get("v.borrowers")[0].Total_Pension_Income__c);
            component.set("v.employment1", component.get("v.borrowers")[0].Total_Employment_Income__c);
            component.set("v.investment1", component.get("v.borrowers")[0].Total_Investment_Income__c);
            component.set("v.rental1", component.get("v.borrowers")[0].Total_Rental_Income__c);
            component.set("v.supportassets1", component.get("v.borrowers")[0].Total_Support_Income__c);
          }

          if (component.get("v.borrowers")[1] != null) {
            component.set("v.borrower2", component.get("v.borrowers")[1]);

            if(component.get("v.borrowers")[1].LoanApplicantIncomes !== undefined) {
              component.set("v.pension1", component.get("v.borrowers")[1].Total_Pension_Income__c);
              component.set("v.employment1", component.get("v.borrowers")[1].Total_Employment_Income__c);
              component.set("v.investment1", component.get("v.borrowers")[1].Total_Investment_Income__c);
              component.set("v.rental1", component.get("v.borrowers")[1].Total_Rental_Income__c);
              component.set("v.supportassets1", component.get("v.borrowers")[1].Total_Support_Income__c);
            }
          }

          component.set("v.step", "creditForm");

          // Check the status of the field and flip states accordingly.
          helper.taxOwingRequired(component, helper);
          helper.feesOwingRequired(component, helper);
        }
      } else {
        var errors = a.getError();
        console.error(errors);
        helper.showError(component, errors[0].message);
      }
      component.set("v.showSpinner", false);
    });
    $A.enqueueAction(action);
  },

  retrieveProperty: function (component, record, helper) {
    console.log("retrieveProperty");
    component.set("v.showSpinner", true);
    var action = component.get("c.getProperty");
    return new Promise(function (resolve, reject) {
      action.setParams({
        application: record
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          component.set("v.property", response.getReturnValue());
          console.log("v.property");
          console.log(component.get("v.property"));
          resolve(response.getReturnValue());
        } else {
          var errors = response.getError();
          console.error(errors);
          helper.showError(component, errors[0].message);
          reject(response.getError()[0])
        }
      });
      $A.enqueueAction(action);
    });
  },

  retrieveAssessment: function (component, record, helper) {
    console.log("retrieveAssessment");
    component.set("v.showSpinner", true);
    var action = component.get("c.getAssessment");
    return new Promise(function (resolve, reject) {
      action.setParams({
        application: record
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          component.set("v.assessment", response.getReturnValue());
          console.log("v.assessment");
          console.log(component.get("v.assessment"));
          resolve(response.getReturnValue());
        } else {
          var errors = response.getError();
          console.error(errors);
          helper.showError(component, errors[0].message);
          reject(response.getError()[0])
        }
      });
      $A.enqueueAction(action);
    });
  },

  showError: function (component, message) {
    component.set("v.message", message);
    component.set("v.messageType", "error");
    component.set("v.messageBackground", "error");
    component.set("v.showSpinner", false);
  },

  showPrompt: function (component, message) {
    component.set("v.message", message);
    component.set("v.messageType", "success");
    component.set("v.messageBackground", "success");
    component.set("v.showSpinner", false);
  },

  doMemberUpdate: function (component, event, helper) {
    var applicationId = component.get("v.simpleRecord").Id;

    console.log("doMemberUpdate start");
    component.set("v.showSpinner", true);
    

    // component.get("v.borrowers")[0].On_Title__c = component
    //   .find("onTitle1")
    //   .get("v.value");
    // component.get("v.borrowers")[0].Income_Documents_Required__c = component
    //   .find("incomeDocuments1")
    //   .get("v.value");

    if(component.get("v.borrowers") != null){
      component.get("v.borrowers")[0].Contact.Credit_Check_Consent_Granted__c = component
      .find("consentField1")
      .get("v.value");
      //contact
      component.get("v.borrowers")[0].Contact.Credit_Check_Consent_Date__c = component
        .find("consentDate1")
        .get("v.value");

      console.log(component.get("v.borrowers")[0]);

      var missingConsent = false;
      if (
        !component.get("v.borrowers")[0].Contact.Credit_Check_Consent_Granted__c ||
        component.get("v.borrowers")[0].Contact.Credit_Check_Consent_Date__c == null
      )
        missingConsent = true;
    }

    if (component.get("v.borrower2") != null) {
      // component.get("v.borrowers")[1].On_Title__c = component
      //   .find("onTitle2")
      //   .get("v.value");
      // component.get("v.borrowers")[1].Income_Documents_Required__c = component
      //   .find("incomeDocuments2")
      //   .get("v.value");
      component.get("v.borrowers")[1].Contact.Credit_Check_Consent_Granted__c =
        component.find("consentField2").get("v.value");
      component.get("v.borrowers")[1].Contact.Credit_Check_Consent_Date__c = component
        .find("consentDate2")
        .get("v.value");

      console.log(component.get("v.borrowers")[1]);
      var missingConsent = false;
      if (
        !component.get("v.borrowers")[1].Contact.Credit_Check_Consent_Granted__c ||
        component.get("v.borrowers")[1].Contact.Credit_Check_Consent_Date__c == null
      )
        missingConsent = true;
    }

    if (missingConsent) {
      helper.showError(
        component,
        $A.get("$Label.c.Error_Credit_ConsentRequired")
      );
    } else {
      console.log(component.get("v.borrowers"));
      var contactsArray = []; 
      component.get("v.borrowers").map(element => {
        contactsArray.push((({ Id, Credit_Check_Consent_Date__c, Credit_Check_Consent_Granted__c }) => ({ Id, Credit_Check_Consent_Date__c, Credit_Check_Consent_Granted__c }))(element.Contact));
      });
      var action = component.get("c.updatePropertyMembers");
      action.setParams({
        contacts: contactsArray
      });
      action.setCallback(this, function (a) {
        var state = a.getState();
        if (state === "SUCCESS") {
          helper.doPropertyUpdate(component, event, helper);
        } else {
          var errors = a.getError();
          console.error(errors);
          helper.showError(component, errors[0].message);
          component.set("v.showSpinner", false);
        }
      });
      $A.enqueueAction(action);
    }
  },

  doPropertyUpdate: function (component, event, helper) {
    console.log("doPropertyUpdate start");
    component.set("v.showSpinner", true);
    var action = component.get("c.updateProperty");

    var property = {
      sobjectType: "LoanApplicationProperty",
      Id: component.get("v.property").Id,
      Annual_Property_Taxes__c: component.find("propTaxes").get("v.value"), // Property
      Property_Tax_Owing__c: component.find("propTaxesOwing").get("v.value"), // Liability
      Property_Taxes_Current__c: component
        .find("propTaxesCurrent")
        .get("v.value"), // Application
      Fire_Insurance_Premium__c: component.find("firePremium").get("v.value"),
      Fire_Insurance_in_place_for_12_Months__c: component
        .find("fireInsurance")
        .get("v.value"), // Application
      Monthly_Condo_Fees__c: component.find("condoFees").get("v.value"), // Liability
      Condo_Fees_Owing__c: component.find("condoFeesOwing").get("v.value"), // Property
      Condo_Fees_Current__c: component.find("condoFeesCurrent").get("v.value") // Property
    };

    console.log("property");
    console.log(property);

    action.setParams({
      property: property
    });
    action.setCallback(this, function (a) {
      var state = a.getState();
      if (state === "SUCCESS") {
        helper.doCreditRequest(component, event, helper, component.get("v.simpleRecord"));
      } else {
        var errors = a.getError();
        console.error(errors);
        helper.showError(component, errors[0].message);
        component.set("v.showSpinner", false);
      }
    });
    $A.enqueueAction(action);
  },

  doCreditRequest: function (component, event, helper, application) {
    console.log("doCreditRequest start");
    component.set("v.showSpinner", true);
    var action = component.get("c.runCreditRequest");

    console.log("application");
    console.log(application);

    action.setParams({
      l: application
    });
    action.setCallback(this, function (a) {
      var state = a.getState();
      var response = state === "SUCCESS" ? a.getReturnValue() : [];
      var isCreditFreeze = false;
      for (let i = 0; i < response.length; i++) {
        if (response[i].Credit_Freeze__c) {
          isCreditFreeze = response[i].Credit_Freeze__c;
        }
      }
      if (state === "SUCCESS") {
        if (isCreditFreeze) {
          helper.showError(
            component,
            $A.get("$Label.c.Credit_Check_Incomplete")
          );
          component.set("v.showSpinner", false);
        } else {
          helper.showPrompt(
            component,
            $A.get("$Label.c.Aura_Credit_Check_Complete")
          );
          console.log('==============doCreditAssessment');
          helper.doCreditAssessment(component, event, helper, component.get("v.simpleRecord"));
          $A.get("e.force:refreshView").fire();
        }
      } else {
        var errors = a.getError();
        console.error(errors);
        helper.showError(component, errors[0].message);
        component.set("v.showSpinner", false);
      }
    });
    $A.enqueueAction(action);
  },

  doCreditAssessment: function (component, event, helper, application) {
    console.log("doCreditAssessment start");
    component.set("v.showSpinner", true);
    var action = component.get("c.runCreditAssessment");

    console.log("application");
    console.log(application);

    action.setParams({
      l: application
    });
    action.setCallback(this, function (a) {
      var state = a.getState();
      var response = a.getReturnValue();
      
      if (state === "SUCCESS") {
        // Set assessment variable as the new Credit_Assessment__c record
        component.set("v.assessment", response);
        helper.doAssessmentUpdate(component, event, helper);
        component.set("v.step", "showAssessment");
        $A.get("e.force:refreshView").fire();
      } else {
        var errors = a.getError();
        console.error(errors);
        helper.showError(component, errors[0].message);
      } 
    });
    $A.enqueueAction(action);
  },

  doAssessmentUpdate: function (component, event, helper) {
    console.log("doAssessmentUpdate start");
    component.set("v.showSpinner", true);
    var action = component.get("c.updateAssessment");
    
    var assessment = {
      sobjectType: "Credit_assessment__c",
      Id: component.get("v.assessment").Id,
      Credit_Assessment_Additional_Information__c: component
        .find("additionalInfo")
        .get("v.value") // Assessment
    };

    console.log("assessment");
    console.log(assessment);

    action.setParams({
      assessment: assessment 
    });
    action.setCallback(this, function (a) {
      var state = a.getState();
      if (state === "SUCCESS") {
        component.set("v.step", "showAssessment");
      } else {
        var errors = a.getError();
        console.error(errors);
        helper.showError(component, errors[0].message);
      }
      component.set("v.showSpinner", false);
    });
    $A.enqueueAction(action);
  }
});