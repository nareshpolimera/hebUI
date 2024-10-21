import { LightningElement, api, track } from "lwc";
import { checkNull } from "c/cms_jsUtility";
import getPreview from "@salesforce/apex/CMS_Handler.getPreview";
import getEmailContent from "@salesforce/apex/CMS_Handler.getEmailContent";
import { updateRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Case.Id";
import Email_Review_Content_Body from "@salesforce/schema/Case.Complainant_Review_Body__c";
import LightningModal from 'lightning/modal';


export default class Cms_caseReview extends LightningElement {
  @api correspondenceMethod;
  @track caseReviewData;
  @api emailReviewContent;
  @api caseId;
  @api setFlowToActive
  @track emailReviewData;

  //requestData = {};
  hasError = false;
  errorMessage = "";
  correspondenceMethodOptions = [
    { label: "--None--", value: "" },
    { label: "Mail", value: "Mail" },
    { label: "Email", value: "Email" }
  ];
  handleChange(event) {
    switch (event.currentTarget.dataset.id) {
      case "correspondence_Method":
        this.hasError = false;
        this.errorMessage = "";
        this.correspondenceMethod = event.detail.value;
        console.log("this.caseReviewData22", JSON.stringify(this.caseReviewData));
        this.setEmailContentData(this.caseReviewData);
        break;
    }
  }

  //Santhosh
  setEmailContentData(caseReviewData) {
    //this.caseReviewData = caseReviewData;
    caseReviewData.RequestBody.correspondenceMethod = this.correspondenceMethod;

    let VarCustomerSatisfied = caseReviewData.RequestBody.IsCustomerSatisfied;
    let IsFraudCase = caseReviewData.Is_this_about_fraud__c;
    let dateRecieved = caseReviewData.RequestBody.ReceivedOn;
    let mydate = new Date(dateRecieved);
    const date = new Date();
    let day = date.getDate();
    let month = date.getMonth() + 1;
    let monthData = '';
    let dayData = '';
    if (month < 10) {
      monthData = '0';
    }
    if (day < 10) {
      dayData = '0';
    }
    let year = date.getFullYear();

    var currentDate = new Date(`${year}-${monthData}${month}-${dayData}${day}`);
    console.log('mydate', mydate);
    console.log('currentDate', currentDate);
    console.log('mydate - currentDate', (mydate - currentDate) / 86400000);
    let numberDaysDue = ((currentDate - mydate) / 86400000) + 1;
    let Escalated;

    if ((numberDaysDue != undefined && numberDaysDue > 14) || IsFraudCase == true) {
      Escalated = true;
    }

    if (VarCustomerSatisfied == null) {
      caseReviewData.RequestBody.ComplaintLetterType = 'Acknowledgement of complaint';
    } else if (VarCustomerSatisfied != null && Escalated == true) {
      caseReviewData.RequestBody.ComplaintLetterType = 'Acknowledgement of complaint';
    } else if (VarCustomerSatisfied != null && Escalated == false) {
      caseReviewData.RequestBody.ComplaintLetterType = 'Combined Acknowledgment & Resolution Letter';
    }
    this.emailReviewData = caseReviewData;
    let requestData = JSON.stringify(caseReviewData.RequestBody);
    console.log('Email Content requestData' + requestData);

    this.getContent(requestData);

  }

  @track isEmailContentloaded = false;
  emailContentText = "";
  getContent(requestData) {
    this.isEmailContentloaded = true;
    console.log("requestData", requestData);
    getEmailContent({ reqBody: requestData })
      .then((result) => {
        this.isEmailContentloaded = false;
        console.log("result", JSON.parse(result));
        //container.innerHTML = JSON.parse(result).previewText;
        this.emailContentText = JSON.parse(result).content;
        this.emailReviewContent = this.emailContentText;
        console.log("emailReviewContent New ::", this.emailReviewContent);
        if (this.isCaseUpdate) {
          if (this.caseId) {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.caseId;
            fields[Email_Review_Content_Body.fieldApiName] = this.emailReviewContent;
            const recordinput = { fields: fields };
            updateRecord(recordinput).then((record) => {
              console.log("Email Updated Content ", record);

              // Naresh Kumar
              this.dispatchEvent(
                new CustomEvent('openclosecaseflowpage', {
                  detail: {
                    case: record,
                  },
                })
              );
            });
          }
        }
      })
      .catch((error) => {
        this.isEmailContentloaded = false;
        //this.richtext = "Error while processing your request.";
        console.log("error at new email content", error);
      });
  }

  @track isCaseUpdate = false;

  @api
  populateEmailReviewContentFromParent(tempCaseReviewData) {
    this.isCaseUpdate = true;
    this.emailReviewData = tempCaseReviewData;
    this.emailReviewData.RequestBody.ComplaintLetterType = 'Resolution letter';
    this.emailReviewData.RequestBody.ComplainantFirstName = this.emailReviewData.FirstName;
    this.emailReviewData.RequestBody.ComplainantLastName = this.emailReviewData.LastName;
    let requestData = JSON.stringify(this.emailReviewData.RequestBody);
    this.getContent(requestData);

  }

  @api
  checkValidity() {
    this.validityCalled = true;
    let isValid = true;
    this.template
      .querySelectorAll(".reportValidityClass")
      .forEach((element) => {
        let checkValidtyData = false;
        checkValidtyData = element.reportValidity();
        if (!checkValidtyData) {
          element.reportValidity();
          isValid = false;
        }
      });

    if (isValid) {
      if (
        this.correspondenceMethod == "Email" &&
        (checkNull(this.caseReviewData) || checkNull(this.caseReviewData.email))
      ) {
        this.hasError = true;
        this.errorMessage =
          "Email address field on the Complainant screen is required for Email selection.";
      }

      if (
        this.correspondenceMethod == "Mail" &&
        (checkNull(this.caseReviewData) ||
          checkNull(this.caseReviewData.Country__c) ||
          checkNull(this.caseReviewData.Street__c) ||
          checkNull(this.caseReviewData.City__c) ||
          checkNull(this.caseReviewData.State_Province__c) ||
          checkNull(this.caseReviewData.Postal_Code__c))
      ) {
        this.hasError = true;
        this.errorMessage =
          "Mail address field  on the Complainant screen is required for Mail selection.";
      }
      if (this.hasError) {
        return false;
      }
    }
    return isValid;
  }

  connectedCallback() {
    this.getDatafromParent();
    this.flowInputVariables = [
      {
        name: "recordId",
        type: "String",
        value: this.caseId,
      },
    ];

    if (this.correspondenceMethod != undefined && this.caseReviewData != undefined) {
      this.setEmailContentData(this.caseReviewData);
    }
  }
  /* this.dispatchEvent(new CustomEvent('closespiner', {
        detail: {
            message: 'AddNewComplainantPage'
        }
    }));*/
  getDatafromParent() {
    this.dispatchEvent(
      new CustomEvent("getdataforreviewpage", {
        detail: {
          message: "ReviewPage"
        }
      })
    );
  }

  @api
  populateCaseReviewDataFromParent(caseReviewData) {
    console.log("this.caseReviewData11", JSON.stringify(caseReviewData));
    console.log(JSON.stringify(caseReviewData));
    this.caseReviewData = caseReviewData;
    console.log("this.caseReviewData11", caseReviewData);
    this.correspondenceMethod = caseReviewData.correspondenceMethod;
    if (this.caseReviewData.RequestBody.IsComplainantSatisfied != null) {
      this.caseReviewData.RequestBody.ComplaintLetterType = 'Resolution letter';
      console.log("this.ComplaintLetterType", this.caseReviewData.RequestBody.ComplaintLetterType);
    } else {
      this.caseReviewData.RequestBody.ComplaintLetterType = null;
    }
    //this.ComplaintLetterType = 'Resolution letter';
    // 'Resolution letter';
    //caseReviewData.RequestBody.Language ='French';
    let requestData = JSON.stringify(caseReviewData.RequestBody);
    this.setPreview(requestData);
  }
  @track richtext = "";
  setPreview(requestData) {
    console.log("requestData", requestData);
    getPreview({ reqBody: requestData })
      .then((result) => {
        //const container = this.template.querySelector('.container');
        console.log("result", JSON.parse(result));
        //container.innerHTML = JSON.parse(result).previewText;
        this.richtext = JSON.parse(result).previewText;
        //this.emailReviewContent = this.richtext;
        //console.log("emailReviewContent", this.emailReviewContent);
        this.closeSpinner();

      })
      .catch((error) => {
        //const container = this.template.querySelector('.container');
        this.richtext = "Error while processing your request.";
        console.log("error", error);
        this.closeSpinner();
      });
  }
  closeSpinner() {
    this.dispatchEvent(new CustomEvent("closespiner"));
  }
  renderedCallback() { }
}