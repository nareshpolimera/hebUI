import { LightningElement, track, api, wire } from 'lwc';
import DataIs_Customer_Satisfied__c from '@salesforce/schema/Case.Is_Customer_Satisfied__c';
import DataComplaint_Outcome__c from '@salesforce/schema/Case.Complaint_Outcome__c';
import DataApply_Redress__c from '@salesforce/schema/Case.Apply_Redress__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
export default class Cms_caseResolutionDetails extends LightningElement {
  @track caseData = {}
  upheld
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  caseInfo;
  partiallyUpheld;
  NotUpheld;
  @api isApplyRedress = false;
  applyRedressYes = false;
  applyRedressNo;
  customerSatisfieddependandRequired = false;
  satisfiedYes;
  satisfiedNo;
  customerSatisfiedOptions;
  applyRedressOptions;
  validityCalled;
  investigationValidityCalled = false;
  redressValidityCalled = false;
  outcomeValidityCalled = false;
  statementnValidityCalled = false;
  Complaint_Outcome_Options;
  complaint_Outcome_OptionsLoaded = false;
  applyRedressOptionsLoaded = false;
  customerSatisfiedOptionsLoaded = false;
  connectedCallbackLoaded = false;
  /*typeOptionsDataValues = [
    { label: 'Yes', value: 'Yes' }, { label: 'No', value: 'No' }
  ]*/
  /* Complaint_Outcome_Options = [
     { label: 'Upheld', value: 'Upheld' }, { label: 'Partially Upheld', value: 'Partially Upheld' }, { label: 'Not Upheld', value: 'Not Upheld' }
   ]*/
  @wire(getPicklistValues, { recordTypeId: '$caseInfo.data.defaultRecordTypeId', fieldApiName: DataComplaint_Outcome__c })
  dataComplaint_Outcome({ error, data }) {
    if (data) {
      this.Complaint_Outcome_Options = [{ label: '--None--', value: '' }];
      this.Complaint_Outcome_Options.push.apply(this.Complaint_Outcome_Options, data.values)
      this.complaint_Outcome_OptionsLoaded = true;
      this.callRedressDataOnAllLoad();

    } else {
      console.log('data2', error);
      // this.error = error;
      //   this.treeModel = undefined;
    }

  }
  @wire(getPicklistValues, { recordTypeId: '$caseInfo.data.defaultRecordTypeId', fieldApiName: DataApply_Redress__c })
  dataApply_Redress({ error, data }) {
    if (data) {
      this.applyRedressOptions = [{ label: '--None--', value: '' }];
      this.applyRedressOptions.push.apply(this.applyRedressOptions, data.values)
      //this.applyRedressOptions = data.values;
      this.applyRedressOptionsLoaded = true;
      this.callRedressDataOnAllLoad();

    } else {
      console.log('data2', error);
      // this.error = error;
      //   this.treeModel = undefined;
    }
  }
  @wire(getPicklistValues, { recordTypeId: '$caseInfo.data.defaultRecordTypeId', fieldApiName: DataIs_Customer_Satisfied__c })
  dataIs_Customer({ error, data }) {
    if (data) {
      this.customerSatisfiedOptions = [{ label: '--None--', value: '' }];

      console.log('data1', data.values);
      this.customerSatisfiedOptions.push.apply(this.customerSatisfiedOptions, data.values)
      //this.customerSatisfiedOptions = data.values;
      console.log('data1', this.typeOptionsDataValues);
      this.customerSatisfiedOptionsLoaded = true;
      this.callRedressDataOnAllLoad();

    } else {
      console.log('data2', error);
      // this.error = error;
      //   this.treeModel = undefined;
    }
  }
  callRedressDataOnAllLoad() {
    if (this.connectedCallbackLoaded && this.customerSatisfiedOptionsLoaded && this.applyRedressOptionsLoaded && this.complaint_Outcome_OptionsLoaded) {
      
      this.connectedCallbackLoaded = false;
      this.customerSatisfiedOptionsLoaded = false;
      this.applyRedressOptionsLoaded = false;
      this.complaint_Outcome_OptionsLoaded = false;
      try {
        this.getCaseDetailsFromParent();
        this.callRedressCheck();
      } catch (error) {
        console.log('error',JSON.stringify(error));
      }
      
    }
  }
  handleChange(event) {
    console.log('caseData', this.caseData);

    switch (event.currentTarget.dataset.id) {
      case 'Investigation Details':
        console.log('event.detail.value', event.detail.value)
        this.caseData.Investigation_Details__c = event.detail.value;
        break;
      case 'Upheld':
        this.caseData.Complaint_Outcome__c = 'Upheld';
        this.partiallyUpheld = 'Neutral';
        this.NotUpheld = 'Neutral';
        this.upheld = 'brand';

        break;
      case 'Partially Upheld':
        this.caseData.Complaint_Outcome__c = 'Partially Upheld';
        this.partiallyUpheld = 'brand';
        this.NotUpheld = 'Neutral';
        this.upheld = 'Neutral';
        break;
      case 'Not Upheld':
        this.caseData.Complaint_Outcome__c = 'Not Upheld';
        this.partiallyUpheld = 'Neutral';
        this.NotUpheld = 'brand';
        this.upheld = 'Neutral';
        break;
      case 'Apply redress Yes':
        this.caseData.Apply_Redress__c = 'Yes';
        this.applyRedressYes = 'brand';
        this.applyRedressNo = 'Neutral';
        break;
      case 'Apply redress No':
        this.caseData.Apply_Redress__c = 'No';
        this.applyRedressYes = 'Neutral';
        this.applyRedressNo = 'brand';
        break;
      case 'satisfied Yes':
        this.caseData.Is_Customer_Satisfied__c = 'Yes';
        this.satisfiedYes = 'brand';
        this.satisfiedNo = 'Neutral';
        break;
      case 'satisfied No':
        this.caseData.Is_Customer_Satisfied__c = 'No';
        this.satisfiedYes = 'Neutral';
        this.satisfiedNo = 'brand';
        break;
      case 'Complaint_Outcome__c':
        this.caseData.Complaint_Outcome__c = event.detail.value;

        break;
      case 'Apply_Redress__c':
        this.caseData.Apply_Redress__c = event.detail.value;
        if (this.caseData.Apply_Redress__c == 'Yes') {
          this.isApplyRedress = true;

        } else {
          this.isApplyRedress = false;
          this.dispatchEvent(new CustomEvent('removeredressmessage', {
            detail: {
              message: 'setredressFromResolution'
            }
          }));
        }
        this.callRedressCheck();
        break;
      case 'Is_Customer_Satisfied__c':
        this.caseData.Is_Customer_Satisfied__c = event.detail.value;
        this.customerSatisfieddependandRequired = true;
        if (!(this.caseData.Is_Customer_Satisfied__c == 'Yes' || this.caseData.Is_Customer_Satisfied__c == 'No')) {

          this.customerSatisfieddependandRequired = false;
        }
        /*if(this.isAnonymous){
          this.customerSatisfieddependandRequired = false;
        }*/
        if (this.investigationValidityCalled || this.validityCalled) {
          this.checkInvestigationValidity();
        }
        if (this.redressValidityCalled || this.validityCalled) {
          this.checkRedressValidity();
        }

        if (this.outcomeValidityCalled || this.validityCalled) {
          this.checkOutcomeValidity();
        }

        if (this.statementnValidityCalled || this.validityCalled) {
          this.checkStatementValidity();
        }
        break;
      case 'Statement_of_Fact__c':
        this.caseData.Statement_of_Fact__c = event.detail.value;

        break;
      default:


    }

  }
  callRedressCheck() {
    this.dispatchEvent(new CustomEvent('setredress', {
      detail: {
        message: 'setredressFromResolution'
      }
    }));
  }
  @api passValueToParent() {
    console.log('this.caseData', this.caseData)
    console.log('this.caseData', JSON.parse(JSON.stringify(this.caseData)))
    return this.caseData;
  }
  isAnonymous = false;

  @api applyAnonymous(isAnonymous){
    console.log('00000000001',isAnonymous);
    this.isAnonymous = isAnonymous;
  }

  @api setValueFromParent(caseData) {

    this.caseData = caseData
    console.log(this.caseData, 'this.caseData')
    this.customerSatisfieddependandRequired = true;
    if (this.caseData.Is_Customer_Satisfied__c == 'Yes') {
      this.satisfiedYes = 'brand';
    } else if (this.caseData.Is_Customer_Satisfied__c == 'No') {
      this.satisfiedNo = 'brand';
    } else {
      this.customerSatisfieddependandRequired = false;
    }
    if(this.isAnonymous){
      //this.customerSatisfieddependandRequired = false;
      this.caseData.Apply_Redress__c = 'No';
    }
  
    if (this.caseData.Apply_Redress__c == 'Yes') {
      this.isApplyRedress = true;
      this.applyRedressYes = 'brand';
    } else if (this.caseData.Apply_Redress__c == 'No') {
      this.applyRedressNo = 'brand';
      this.isApplyRedress = false;
    }

    if (this.caseData.Complaint_Outcome__c == 'Upheld') {
      this.upheld = 'brand';
    } else if (this.caseData.Complaint_Outcome__c == 'Partially Upheld') {
      this.partiallyUpheld = 'brand';
    } else if (this.caseData.Complaint_Outcome__c == 'Not Upheld') {
      this.NotUpheld = 'brand';
    }
    this.callRedressCheck();
    this.closeSpinerAfterLoad();

  }
  connectedCallback() {
    this.connectedCallbackLoaded = true;
    this.callRedressDataOnAllLoad();
  }

  getCaseDetailsFromParent() {
    this.dispatchEvent(new CustomEvent('getcasedetailsforresolution', {
      detail: {
        message: 'getcasedetailsforresolution'
      }
    }));
  }
  closeSpinerAfterLoad() {
    this.dispatchEvent(new CustomEvent('closespiner', {
      detail: {
        message: 'CloseSpiner'
      }
    }));
  }
  showTooltipSection = false;
  showTooltip() {
    this.showTooltipSection = true;
  }
  hideTooltip() {
    this.showTooltipSection = false;
  }


  @api
  checkValidity() {
    this.validityCalled = true;
    let isValid = true;
    this.template.querySelectorAll('.reportValidityClass').forEach(element => {
      let checkValidtyData = false;
      checkValidtyData = element.reportValidity();
      console.log('checkValidtyData', checkValidtyData);
      if (!checkValidtyData) {
        console.log(element);
        element.reportValidity();
        isValid = false;
      }

    });
    console.log('isValid', isValid)
    return isValid;
  }

  setFocusInitiated(event) {
    switch (event.currentTarget.dataset.id) {
      case 'Investigation Details':
        this.investigationValidityCalled = true;
        break;
      case 'Apply_Redress__c':
        this.redressValidityCalled = true;
        break;
      case 'Complaint_Outcome__c':
        this.outcomeValidityCalled = true;
        break;
      case 'Statement_of_Fact__c':
        this.statementnValidityCalled = true;

        break;
    }
  }
  checkOutcomeValidity() {
    try {
      let outcomefields = this.template.querySelector(".Outcome");
      if (this.caseData.Is_Customer_Satisfied__c == 'Yes' || this.caseData.Is_Customer_Satisfied__c == 'No') {
        outcomefields.required = true;
      } else {
        outcomefields.required = false;
      }
      outcomefields.reportValidity();
    } catch (error) {
      console.log(error)
    }
  }
  checkInvestigationValidity() {
    try {
      let investigationfields = this.template.querySelector(".Investigation");
      if (this.caseData.Is_Customer_Satisfied__c == 'Yes' || this.caseData.Is_Customer_Satisfied__c == 'No') {
        investigationfields.required = true;
      } else {
        investigationfields.required = false;
      }
      investigationfields.reportValidity();
    } catch (error) {
      console.log(error)
    }
  }
  checkStatementValidity() {
    try {
      let statementfields = this.template.querySelector(".Statement");
      if (this.caseData.Is_Customer_Satisfied__c == 'Yes' || this.caseData.Is_Customer_Satisfied__c == 'No') {
        statementfields.required = true;
      } else {
        statementfields.required = false;
      }
      statementfields.reportValidity();
    } catch (error) {
      console.log(error)
    }
  }

  checkRedressValidity() {
    try {
      let applyRedressfields = this.template.querySelector(".applyRedress");
      if (this.caseData.Is_Customer_Satisfied__c == 'Yes' || this.caseData.Is_Customer_Satisfied__c == 'No') {
        applyRedressfields.required = true;
      } else {
        applyRedressfields.required = false;
      }
      applyRedressfields.reportValidity();
    } catch (error) {
      console.log(error)
    }
  }




}