import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import APPLICATION_ID from "@salesforce/schema/LoanApplicant.LoanApplicationId";

export default class CreateApplicantEmployment extends NavigationMixin(LightningElement) {
    
    @api recordId;

    @wire(getRecord, { 
        recordId: "$recordId", 
        fields: [APPLICATION_ID]
    })
    applicant;

    get applicationId() {
        return getFieldValue(this.applicant.data, APPLICATION_ID);
    }

    navigateToNewContactWithDefaults() {
        const defaultValues = encodeDefaultFieldValues({
            LoanApplicationId: this.applicationId,
            LoanApplicantId: this.recordId
        });
    
        console.log(defaultValues);
    
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: "LoanApplicantEmployment",
            actionName: "new",
          },
          state: {
            defaultFieldValues: defaultValues,
          },
        });
      }
}