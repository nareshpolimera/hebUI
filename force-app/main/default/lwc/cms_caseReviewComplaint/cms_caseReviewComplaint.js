import { LightningElement, api, track, wire } from 'lwc';


export default class Cms_caseReviewComplaint extends LightningElement {
  caseLoaded = false;
  @track firstName;
  modeEdit;
  @track caseDetails = {
    'First_Name__c': '',
    'Last_Name__c': '',
    'Email__c': '',
    'Postal_Code__c': '',
    'CaseNumber': '',
    'Complaint_Category__c': '',
    'Complaint_Date_Received__c': '',
    'Resolution_Sought__c': '',
    'Incident_Date__c': '',
    'Total_Redress__c': '',
    'Type': '',
    'Complaint_Outcome__c': '',
  };
  connectedCallback(){
    this.dispatchEvent(new CustomEvent('fetchcasedetails'));
  }
  
  handleEdit() {
    this.modeEdit = true;
    this.hideParentButton();

  }
  handleFirstNameChange(event) {
    this.firstName = event.target.value;
  }
  @api updateCaseDataFromParent(caseDetails) {
    console.log('123213213');
    this.caseDetails = caseDetails;
    console.log('this.caseDetails00000000000000', JSON.stringify(this.caseDetails));
    this.caseLoaded = true;

  }
  
  handleSave(){
    this.dispatchEvent(new CustomEvent('handlesave'));
    this.modeEdit = false;
  }
  handleCancel(){
    this.dispatchEvent(new CustomEvent('handlecancel'));
    this.modeEdit = false;
  }
  hideParentButton(){
    this.dispatchEvent(new CustomEvent('hideparentbutton'));
  }
  //childButtonShown
}