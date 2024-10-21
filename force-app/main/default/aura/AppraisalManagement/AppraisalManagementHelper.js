({
  loadFileRecord : function(component, helper) {
    console.log("SBT inside loadFileRecord ");
      var action = component.get("c.retrieveAppraisalFile");
      console.log("SBT action "+action);
      var recordId = component.get("v.recordId");
      console.log("SBT recordId "+recordId);

      action.setParams({
          "recordId": recordId
      });
      
      action.setCallback(this, function(response) {
          var state = response.getState();
          console.log("SBT state ="+ state);
          console.log("SBT error ="+ response.getError());

          if (state === "SUCCESS") {
              component.set('v.myFile', response.getReturnValue());
              console.log('myfile = '+JSON.stringify(response.getReturnValue()));
              helper.checkPOAs(component, helper);
              helper.checkAllowOrder(component, helper);
              helper.getProperty(component, helper);
              helper.getPrimaryBorrower(component, helper);
          } else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      
      $A.enqueueAction(action);
      
  },

  checkAllowOrder : function(component, helper) {
      var action = component.get("c.allowOrder");
      action.setParams({
          "recordId": component.get("v.recordId")
      });
      
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
              component.set('v.allowOrder', response.getReturnValue());
              if (!response.getReturnValue()) 
                  helper.getExistingOrders(component, helper);
              else
                  component.set('v.step', 'orderOptions');
          } else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      
      $A.enqueueAction(action);
  },
  
  getExistingOrders : function(component, helper) {
      var action        = component.get("c.retrieveOrders");
      action.setParams({
          "recordId": component.get("v.recordId")
      });
      
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
              console.log('existing orders length');
              console.log(response.getReturnValue());
              component.set('v.existingOrders', response.getReturnValue());
              
              console.log('first item');
              console.log(component.get('v.existingOrders')[0]);
              
              console.log('SBT before setting v.step: ');
              component.set('v.step', 'existingOrders');

          }
          else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      
      $A.enqueueAction(action);
  },
  
  checkPOAs : function(component, helper) {
      var action        = component.get("c.activePOAs");
      action.setParams({
          "recordId": component.get("v.recordId")
      });
      
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
              component.set('v.hasActivePOA', response.getReturnValue());
          }
          else {
              var errors = response.getError();
          }
      });
      
      $A.enqueueAction(action);
  },

  getProperty : function(component, helper) {
      var action        = component.get("c.retrieveProperty");
      var recordId    = component.get("v.myFile.propertyId");
      
      action.setParams({
          "propertyId": recordId,
          "runParseAddress": true
      });
      console.log("PropertyID ="+recordId);
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
              component.set('v.myProperty', response.getReturnValue().p);
              if(response.getReturnValue().error != null) {
                  component.set('v.message', response.getReturnValue().error);
                  component.set('v.messageType', 'warning');
                  component.set('v.messageBackground', 'warning');
              }
          }
          else {
              var errors = response.getError();
              component.set('v.message', errors[0].message);
              component.set('v.messageType', 'error');
              component.set('v.messageBackground', 'error');
          }
      });
      
      $A.enqueueAction(action);
  },
  
  
  doOrderFromMars : function(component, helper) {
      var action        = component.get("c.appraisalOrderFromMars");
      action.setParams({
          "recordId": component.get("v.recordId")
      });

      component.set('v.showSpinner', true);
      action.setCallback(this, function(response) {
          var state = response.getState();
          console.log('state');
          console.log(state);
          if (state === "SUCCESS") {
               console.log('start success');
              component.set('v.orderCompleteMessage', $A.get("$Label.c.Alert_Order_From_Mars_Complete"));
               console.log('orderCompleteMessage set');
              $A.get('e.force:refreshView').fire();
              helper.loadFileRecord(component, helper);
          } else {
              console.log("Failed with state: " + state);
              var errors = response.getError();
              component.set('v.orderCompleteMessage', errors[0].message);
          }
          //component.set('v.step', 'orderComplete');
          component.set('v.showSpinner', false);
      });
      
      $A.enqueueAction(action);
  },
  
  isNullOrEmpty :  function (value) {
      return !value;
  },
        
  validateMinDate : function(component, helper) {

      console.log(component.find("requestedDate").get("v.value"));
      console.log(component.get("v.minDate"));

      if (component.find("requestedDate").get("v.value") < component.get("v.minDate")) {
          component.find("orderFromFCTBtn").set('v.disabled', true);
          component.set('v.odError', true);
          component.set('v.odErrorMessage', $A.get("$Label.c.Warning_Requested_Date_Before_Today"));
      }
      else {
          component.find("orderFromFCTBtn").set('v.disabled', false);
          component.set('v.odError', false);
          component.set('v.odErrorMessage', '');
      }
  },

  setDefaultCostAlert : function(component, helper) {
      var labelString = $A.get("$Label.c.Alert_Default_Cost");
      var field = component.find("costSplitTypeField");
      component.set('v.defaultCostAlert', field.get('v.value') == 'Percent' ? $A.get("$Label.c.Alert_Default_Cost_Percent") : $A.get("$Label.c.Alert_Default_Cost"));

      var hebField = component.find("hebSplitField");
      var partnerField = component.find("partnerSplitField");
      var customerField = component.find("customerSplitField");
      customerField.set('v.value', field.get('v.value') == 'Percent' ? 100 : 350);
      hebField.set('v.value', 0);
      partnerField.set('v.value', 0);
  },
  
  calculateSplitFields : function(component, helper) {
      var costSplitTypeField = component.find("costSplitTypeField");
      var hebField = component.find("hebSplitField");
      var partnerField = component.find("partnerSplitField");

      var defaultTotal = (costSplitTypeField.get('v.value') == 'Percent') ? 100 : 350;
      var customerFieldValue = defaultTotal - hebField.get('v.value') - partnerField.get('v.value');
      component.find("customerSplitField").set('v.value', customerFieldValue);
      helper.checkSplitTotal(component, helper);
  },

  checkSplitTotal : function(component, helper) {
      var costSplitTypeField = component.find("costSplitTypeField");
      var hebField = component.find("hebSplitField");
      var partnerField = component.find("partnerSplitField");
      var customerField = component.find("customerSplitField");

      var defaultTotal = (costSplitTypeField.get('v.value') == 'Percent') ? 100 : 350;

      var currentTotal = parseFloat(customerField.get('v.value')) + parseFloat(hebField.get('v.value')) + parseFloat(partnerField.get('v.value'));
      if (currentTotal != defaultTotal) {
          component.find("orderFromFCTBtn").set('v.disabled', true);
          component.set('v.fctError', true);
          if (costSplitTypeField.get('v.value') == 'Percent')
              component.set('v.fctErrorMessage', $A.get("$Label.c.Warning_Split_Field_Percent_Total"));
          else
               component.set('v.fctErrorMessage', $A.get("$Label.c.Warning_Split_Field_Amount_Total"));
      }
      else if (component.find("paidFromProceeds").get("v.value") == "Yes" && component.find("customerSplitField").get("v.value") == 0) {
          component.find("orderFromFCTBtn").set('v.disabled', true);
          component.set('v.fctError', true);
          component.set('v.fctErrorMessage', $A.get("$Label.c.Warning_Customer_Split_Greater_Than_Zero"));
      }
      else {
          component.find("orderFromFCTBtn").set('v.disabled', false);
          component.set('v.fctError', false);
          component.set('v.fctErrorMessage', '');
      }
  },
  
  processFCTForm : function(component, helper) {
    console.log('SBT inside processFCTForm');  
      var myLead = component.get('v.myFile.app');
      var myProperty = component.get('v.myProperty');

      console.log('SBT myLead: '+myLead);  
      console.log('SBT myProperty: '+myProperty);  

      myProperty.UnitNumberFragment__c = component.find('unitNumberFragment').get('v.value');
      myProperty.AddressNumberFragment__c = component.find('addressNumberFragment').get('v.value');
      myProperty.StreetNameFragment__c = component.find('streetNameFragment').get('v.value');
      myProperty.StreetTypeFragment__c = component.find('streetTypeFragment').get('v.value');
      myProperty.StreetDirectionFragment__c = component.find('streetDirFragment').get('v.value');
      myProperty.CityFragment__c = component.find('cityFragment').get('v.value');
      myProperty.PostalCodeFragment__c = component.find('postalCodeFragment').get('v.value');
      myProperty.ProvinceFragment__c = component.find('provinceFragment').get('v.value');

      console.log('SBT after myProperty'+myProperty); 
      console.log('SBT after myProperty'+component.get('v.recordId'));  

      console.log('SBT after datac: '+ component.find('unitNumberFragment').get('v.value'));
      console.log('SBT after datac: '+component.find('costSplitTypeField').get('v.value')); 
      console.log('SBT after data id233'+component.get('v.myFile.app.Id'));   

      
      var appraisal = {
          'sobjectType':'Appraisal__c', 
          'File__c': component.get('v.myFile.app.OpportunityId'),
          'Application__c':component.get('v.myFile.app.Id'),
          'Application_Property__c':component.get("v.myFile.propertyId"),
          'Cost_Split_Type__c': component.find('costSplitTypeField').get('v.value'),
          'Customer_Split__c': component.find('customerSplitField').get('v.value'),
          'Partner_Split__c': component.find('partnerSplitField').get('v.value'),
          'HEB_Split__c': component.find('hebSplitField').get('v.value'),
          'Paid_From_Proceeds__c': component.find('paidFromProceeds').get('v.value'),
          'Cost_Exception_Approval__c': component.find('costExceptionApproval').get('v.value')
      };
		console.log(appraisal);
      var accData = JSON.stringify(appraisal);
      var finalData = JSON.parse(accData);

      console.log('SBT finalData: '+finalData);

      var appraisalOrder = {
          'sobjectType':'Appraisal_Order__c', 
          'Rush_Order__c': component.find('rushField').get('v.value'),
          'Requested_Date__c': component.find('requestedDate').get('v.value'),
          'Contact_First_Name__c': component.find('firstName').get('v.value'),
          'Contact_Last_Name__c': component.find('lastName').get('v.value'),
          'Contact_Email__c': component.find('emailField').get('v.value'),
          'Primary_Phone__c': component.find('phoneField').get('v.value'),
          'Alternate_Phone__c': component.find('altPhoneField').get('v.value'),
          'Requested_Time_Window__c': component.find('timeField').get('v.value'),
          'Specify_Other_Time__c': component.find('otherTimeField').get('v.value'),
          'Special_Instructions__c': component.find('instructionsField').get('v.value')
      };
      console.log(appraisalOrder);
      console.log('SBT after everything');

      var action        = component.get("c.appraisalOrderFromFCT");
      var recordId    = component.get("v.recordId");
      action.setParams({
          "l": myLead,
          "property": myProperty,
          "appraisal": appraisal,
          "appraisalOrder": appraisalOrder
      });

      component.set('v.showSpinner', true);
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
              component.set('v.orderCompleteMessage', $A.get("$Label.c.Alert_Order_From_FCT_Complete"));
              component.set('v.step', 'orderComplete');
              component.set('v.fctError', false);
              
              component.set('v.orderCompleteMessage', $A.get("$Label.c.Alert_Order_From_FCT_Complete"));
              component.set('v.step', 'orderComplete');
              helper.loadFileRecord(component, helper);
              $A.get('e.force:refreshView').fire();
          } else {
              console.log("Failed with state: " + state);
              var errors = response.getError();
              component.set('v.orderCompleteMessage', errors[0].message);
              component.set('v.step', 'orderFromFCT');

              component.set('v.fctErrorMessage', errors[0].message);
              component.set('v.fctError', true);

              var errors = response.getError();
          }
          component.set('v.showSpinner', false);
      });
      
      $A.enqueueAction(action);
  },
  
  getPrimaryBorrower : function(component, helper) {
      console.log('getPrimaryBorrower!');
      var action        = component.get("c.retrievePrimaryBorrower");
      console.log('SBT getPrimaryBorrower action: '+action);
      var recordId    = component.get("v.recordId");
      console.log('SBT getPrimaryBorrower recordId: '+recordId);
      
      action.setParams({
          "appId": recordId
      });
      console.log('SBT: before callback');
      action.setCallback(this, function(response) {
        console.log('SBT: after callback');
          var state = response.getState();
          console.log('SBT: state'+state);
          if (state === "SUCCESS") {
            console.log('SBT: response'+response);
              console.log('SBT response getReturnValue: '+JSON.stringify(response.getReturnValue()));
              component.set('v.primaryBorrower', response.getReturnValue());
          }
          else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      
      $A.enqueueAction(action);
  },
  getquoteAmountForLead : function(component, helper) {    	
      var action      = component.get("c.retriveLeadQuoteAmount");
      var recordId    = component.get("v.recordId");
      
      action.setParams({ "appId": recordId });
      console.log('gethelper !!! ' + recordId);
      
      action.setCallback(this, function(response) {
          var state = response.getState(); 
          var listpro = response.getReturnValue();
          var rec = listpro[0];
          
          if (state === "SUCCESS") {       
              if(listpro.length > 0){
                  if(rec.Opportunity.SyncedQuoteId != null && rec.Opportunity.SyncedQuote.Quote_Amount__c > 0) {
                      component.set('v.step', 'orderFromFCT');
                      component.set('v.message', '');
                      helper.setDefaultCostAlert(component, helper);
                  }
                  else {
                      component.set('v.message', 'Quote Amount must be greater than zero');
                      component.set('v.messageType', 'error');
                      component.set('v.messageBackground', 'error');
                  }
              }else{
                  component.set('v.message', 'This application doesn\'t have a related opportunity.');
                  component.set('v.messageType', 'error');
                  component.set('v.messageBackground', 'error');
              }
          }
          else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      $A.enqueueAction(action);
  },
  

  refreshViewLead : function(component,event, helper) {    	
      var action      = component.get("c.retriveLeadQuoteAmount");
      var recordId    = component.get("v.recordId");        
      action.setParams({ "leadId": recordId });        
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === "SUCCESS") {
             if(response.getReturnValue() != null && response.getReturnValue().Quote_Amount__c > 0) {
                  component.set("v.leadQuote", response.getReturnValue().Quote_Amount__c);
                  component.set('v.step', 'orderFromFCT');
                  component.set('v.message', '');
                  helper.loadFileRecord(component, helper);       
                  var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                  component.set('v.minDate', today);
              }
              else 
              {
                  helper.loadFileRecord(component, helper);       
                  var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                  component.set('v.minDate', today);
              }
          }
          else {
              var errors = response.getError();
              console.log(errors);
          }
      });
      $A.enqueueAction(action);
  }
})