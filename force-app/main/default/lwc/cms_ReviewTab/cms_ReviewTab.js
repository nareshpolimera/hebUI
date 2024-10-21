import { LightningElement, wire, api, track } from "lwc";
import getComplaintDetails from "@salesforce/apex/CMS_Handler.getComplaintDetails";
import getRedressDetailsByCaseId from "@salesforce/apex/CMS_Handler.getRedressDetailsByCaseId";
import setBodayandCallGenerateResolvedApi from "@salesforce/apex/CMS_Handler.setBodayandCallGenerateResolvedApi";
import setResolutionField from "@salesforce/apex/CMS_Handler.setResolutionField";
import changeCorrespondenceMethod from "@salesforce/apex/CMS_Handler.changeCorrespondenceMethod";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { checkNull } from "c/cms_jsUtility";
import { refreshApex } from "@salesforce/apex";
import modalComponent from 'c/modalComponent';

export default class Cms_ReviewTab extends LightningElement {
  @api recordId;
  caseReviewData = {};
  //setFlowToActive = false;

  loaded = false;
  errorFields = "";
  errormsg = "";

  caseDataDetail;
  _caseResults;
  previewBoxCss;
  isDisableSubmit;

  @api
  get previewBoxCss() {
    return this.errormsg === "" ? "" : "display:none";
  }

  //Newly added code on 3rd Sep --> start
  connectedCallback() {
    this.flowInputVariables = [
      {
        name: "recordId",
        type: "String",
        value: this.recordId,
      },
    ];
  }
  //Newly added code on 3rd Sep --> end


  @track redresDetails = [];


  @wire(getComplaintDetails, { caseId: "$recordId" })
  caseRecords(result) {
    this.openSpiner();
    this._caseResults = result;
    const { data, error } = result;
    this.errorFields = "";
    this.errormsg = "";

    if (data) {
      this.caseDataDetail = data;
      if (checkNull(this.caseDataDetail.Is_Customer_Satisfied__c)) {
        this.errorFields += "<li>Customer Satisfied</li>";
      }
      if (checkNull(this.caseDataDetail.Complaint_Outcome__c)) {
        this.errorFields += "<li>Complaint Outcome</li>";
      }
      if (checkNull(this.caseDataDetail.Investigation_Details__c)) {
        this.errorFields += "<li>Investigation Details (for reporting)</li>";
      }
      if (checkNull(this.caseDataDetail.Statement_of_Fact__c)) {
        this.errorFields += "<li>Investigation Result (In communications)</li>";
      }

      if (this.errorFields !== "") {
        console.log(
          "please navigate to Resolution Section and complete the details." +
          this.errorFields
        );
        this.errormsg =
          "Before sending the resolution communication, please complete the following details. <ul>" +
          this.errorFields +
          "</ul>";
        this.closeSpiner();
      }
      else if (this.caseDataDetail.Status !== "Reopened" && (this.caseDataDetail.Resolution_Mail_Status__c === "Pending" || this.caseDataDetail.Resolution_Mail_Status__c === "Sent" ||
        this.caseDataDetail.Status === "Resolved" || this.caseDataDetail.Status === "Closed")) {
        if (this.caseDataDetail.Correspondence_Method__c === "Mail") {
          this.errormsg = "Resolution Letter has been generated";
        } else {
          this.errormsg = "Resolution Letter has been sent";
        }

        this.closeSpiner();
      }
      else {
        getRedressDetailsByCaseId({ caseId: this.caseDataDetail.Id })
          .then(result => {
            this.redresDetails = result;
          }).catch(error => {
            console.log(`Error while fetching Redress Details ${error}`);
          }).then(() => {
            this.setRequestData();
          });
        // this.setRequestData();
      }
    }

    if (error) {
      console.log("Error");
    }
    this.closeSpiner();
  }

  handleClick() {
    refreshApex(this._caseResults);
    getRedressDetailsByCaseId({ caseId: this.caseDataDetail.Id })
      .then(result => {
        this.redresDetails = result;
      }).catch(error => {
        console.log(`Error while fetching Redress Details ${error}`);
      }).then(() => {
        this.setRequestData();
      });
    // return refreshApex(this._caseResults);
  }

  async sendLetter() {

    if (this.caseDataDetail.Correspondence_Method__c == "Email") {
      this.template.querySelector("c-cms_case-review").populateEmailReviewContentFromParent(this.caseReviewData);
      // this.template.querySelector("c-cms_case-review").setFlowToActive = true;
      
      // setTimeout(() => {
      //   console.log("Delayed for 1 second.");
      // }, 5000);
      
      // console.log('modalComponent::', this.flowInputVariables);
      // const result = await modalComponent.open({
      //   size: 'small',
      //   description: 'Accessible description of modal\'s purpose',
      //   content: this.flowInputVariables,
      // });
      // console.log(result);

    } else if (this.caseDataDetail.Correspondence_Method__c == "Mail") {
      this.sendLetterAndUpdate();
    }
  }

  openCloseCaseFlow(event) {
    console.log('modalComponent::', this.flowInputVariables);
      const result = modalComponent.open({
        size: 'small',
        description: 'Accessible description of modal\'s purpose',
        content: this.flowInputVariables,
      });
      console.log(result);
  }


  async sendLetterAndUpdate() {
    let correspondenceMethod =
      this.template.querySelector("c-cms_case-review").correspondenceMethod;
    if (
      correspondenceMethod == "Email" &&
      (checkNull(this.caseDataDetail.Account.PersonEmail) ||
        this.caseDataDetail.E_Consent_Indicator__c == false)
    ) {
      this.showErrorToast(
        "Complainant does not have an email associated and/or E-Consent Provided"
      );
      return;
    }


    if (
      correspondenceMethod == "Mail" &&
      (checkNull(this.caseDataDetail.Account.PersonMailingStreet) ||
        checkNull(this.caseDataDetail.Account.PersonMailingCountry) ||
        checkNull(this.caseDataDetail.Account.PersonMailingCity) ||
        checkNull(this.caseDataDetail.Account.PersonMailingState) ||
        checkNull(this.caseDataDetail.Account.PersonMailingPostalCode))
    ) {
      this.showErrorToast(
        "Complaintant does not have all mandatory Mail fields : Street, Country, Province, City or Postal Code"
      );
      return;
    }

    if (
      correspondenceMethod != "Mail" &&
      this.caseDataDetail.Confirmation_Provided__c != "Yes"
    ) {
      this.showErrorToast("Acknowledgement letter has not been sent");
      return;
    }

    if (correspondenceMethod !== this.caseDataDetail.Correspondence_Method__c) {
      await this.updateMethod(correspondenceMethod);
    }
    this.callGenerateApi(this.caseDataDetail, correspondenceMethod);
  }

  async updateMethod(method) {
    // add email validation

    await changeCorrespondenceMethod({ caseId: this.recordId, method: method })
      .then((result) => {
        console.log("Method Updated");
      })
      .catch((error) => {
        console.log("error", error);
        this.loaded = true;
      });
  }

  callGenerateApi(resultData, correspondenceMethod) {
    this.loaded = false;
    this.isDisableSubmit = true;
    this.openSpiner();
    if (correspondenceMethod == "Mail") {
      setBodayandCallGenerateResolvedApi({ Id: this.recordId })
        .then((result) => {
          try {
            this.showToast("Resolution document has been generated");
            this.loaded = true;

            // this.navigateToViewCasePage();
          } catch (error) {
            console.log("error", error);
            this.loaded = true;
          }
        })
        .catch((error) => {
          console.log("error", error);
          this.loaded = true;
        });
      this.closeSpiner();
    } else {
      try {
        setResolutionField({ caseId: this.recordId })
          .then((result) => {
            try {
              console.log(result);
              this.showToast("Resolution document has been sent");
              this.closeSpiner();

              // this.navigateToViewCasePage();
            } catch (error) {
              console.log("error", error);
              this.loaded = true;
            }
          })
          .catch((error) => {
            console.log("error", error);
            this.loaded = true;
          });
      } catch (error) {
        console.log("error", error);
        this.loaded = true;
      }
      this.closeSpiner();
    }
  }

  setRequestData() {
    try {
      let request = {};
      request.Language = this.caseDataDetail.Language__c;
      request.IsComplainantSatisfied =
        this.caseDataDetail.Is_Customer_Satisfied__c;

      if (checkNull(this.caseDataDetail.Language__c)) {
        request.Language = "English";
      }
      request.Source = this.caseDataDetail.Origin;
      request.IsCustomerSatisfied = true;
      if (this.caseDataDetail.Is_Customer_Satisfied__c == "No") {
        request.IsCustomerSatisfied = false;
      } else if (checkNull(this.caseDataDetail.Is_Customer_Satisfied__c)) {
        request.IsCustomerSatisfied = null;
      }

      request.ReceivedOn = this.caseDataDetail.Complaint_Date_Received__c;
      request.StatementOfFact = this.caseDataDetail.Statement_of_Fact__c;
      request.ResolutionSought = this.caseDataDetail.Resolution_Sought__c;
      request.Category = this.caseDataDetail.Complaint_Category__c;
      request.Subcategory = this.caseDataDetail.Complaint_Subcategory__c;
      request.CategoryDescription = this.caseDataDetail.Category_Description__c;
      request.SubcategoryDescription = this.caseDataDetail.Sub_Category_Description__c;
      let redresses = [];
      if (!checkNull(this.caseDataDetail.Redresses__r)) {
        this.caseDataDetail.Redresses__r.forEach((element) => {
          let redress = {};
          redress.Type = element.Financial_Redress_Type__c;
          redress.Method = element.Redress_Method__c;
          redress.Amount = parseFloat(element.Redress_Amount__c);
          redress.Rationale = element.Resolution_Rationale__c;
          redresses.push(redress);
        });
      }
      // Naresh Kumar
      if (redresses.length <= 0) {
        if (!checkNull(this.redresDetails)) {
          this.redresDetails.forEach((element) => {
            let redress = {};
            redress.Type = element.Financial_Redress_Type__c;
            redress.Method = element.Redress_Method__c;
            redress.Amount = parseFloat(element.Redress_Amount__c);
            redress.Rationale = element.Resolution_Rationale__c;
            redresses.push(redress);
          });
        }
      }

      request.Redresses = redresses;
      request.HandlingLevel = this.caseDataDetail.Complaint_Handling_Level__c;
      request.ComplaintLetterType = "Resolution letter";
      this.caseReviewData.correspondenceMethod =
        this.caseDataDetail.Correspondence_Method__c;
      this.caseReviewData.RequestBody = request;
      this.caseReviewData.IsThisFraudCase = this.caseDataDetail.Is_this_about_fraud__c;
      this.caseReviewData.FirstName = this.caseDataDetail.Account.FirstName;
      this.caseReviewData.LastName = this.caseDataDetail.Account.LastName;
      this.callReviewPage();
    } catch (error) {
      console.log("error", error);
    }
  }

  callReviewPage() {
    try {
      console.log('this.caseReviewData.IsThisFraudCase' + this.caseReviewData.IsThisFraudCase);
      this.template
        .querySelector("c-cms_case-review")
        .populateCaseReviewDataFromParent(this.caseReviewData);
    } catch (error) {
      console.log("error", error);
    }
  }

  closeSpiner() {
    this.loaded = true;
  }

  openSpiner() {
    this.loaded = false;
  }

  showToast(message) {
    const event = new ShowToastEvent({
      title: "Success!",
      message: message,
      variant: "success"
    });
    this.dispatchEvent(event);
  }

  showErrorToast(message) {
    const event = new ShowToastEvent({
      title: "Error!",
      message: message,
      variant: "error"
    });
    this.dispatchEvent(event);
  }
}