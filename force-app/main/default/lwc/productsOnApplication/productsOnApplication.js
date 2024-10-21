import { LightningElement, api, wire, track } from 'lwc';
import getFieldSetFieldsWithValues from '@salesforce/apex/ProductLWCFieldsetController.getFieldSetFieldsWithValues';
import saveOpportunityFields from '@salesforce/apex/ProductLWCFieldsetController.saveOpportunityFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex'; // Import refreshApex to refresh the wired data

export default class ProductsOnApplication extends LightningElement {
    @api objectApiName = 'ResidentialLoanApplication'; 
    @api fieldSetName = 'Product_LWC'; 
    @api recordId; // This is the ResidentialLoanApplication record ID

    @track fieldsWithValues = [];
    @track residentialLoanAppFields = [];  // Stores fields from the ResidentialLoanApplication object
    @track error;
    @track opportunityId; // To store the retrieved OpportunityId
    @track isLoading = true; // Spinner control

    wiredFieldsWithValuesResult; // Step 1: Store the wired result to use for refresh

    @api Mode;

    viewForm = false;

    connectedCallback(){
        if(this.Mode == 'Read Only'){
            this.viewForm = true;
        }
    }

    @wire(getFieldSetFieldsWithValues, { recordId: '$recordId', objectName: '$objectApiName', fieldSetName: '$fieldSetName' })
    wiredFieldsWithValues(result) {
        this.wiredFieldsWithValuesResult = result; // Step 2: Store the result so we can refresh it later
        const { data, error } = result;

        if (data) {
            this.fieldsWithValues = data.fields;
            this.error = undefined;

            // Store fields related to the ResidentialLoanApplication object
            this.residentialLoanAppFields = this.fieldsWithValues.filter(field => !field.fieldPath.startsWith('Opportunity.'));

            this.opportunityId = data.OpportunityId;
            this.isLoading = false; // Hide spinner after data is loaded
        } else if (error) {
            this.error = error.body.message;
            this.isLoading = false; // Hide spinner if there is an error
        }
    }

    handleChange(event) {
        const fieldPath = event.target.dataset.fieldPath;
        const value = event.target.value;

        const fieldIndex = this.residentialLoanAppFields.findIndex(field => field.fieldPath === fieldPath);

        if (fieldIndex !== -1) {
            const updatedField = { ...this.residentialLoanAppFields[fieldIndex] };
            updatedField.value = value; // Set the new value
            this.residentialLoanAppFields = [
                ...this.residentialLoanAppFields.slice(0, fieldIndex),
                updatedField,
                ...this.residentialLoanAppFields.slice(fieldIndex + 1)
            ];
        }
    }

    handleSave() {
        this.isLoading = true; // Show spinner while saving

        // Prepare the fields to update based on the already updated residentialLoanAppFields
        const fieldsToUpdate = {};
        this.residentialLoanAppFields.forEach(field => {
            fieldsToUpdate[field.fieldPath] = { value: field.value, type: field.type }; // Keep the updated values
        });

        if (this.opportunityId) {
            saveOpportunityFields({ fieldsToUpdate: fieldsToUpdate, opportunityId: this.opportunityId })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity updated successfully',
                        variant: 'success'
                    }));

                    // Step 3: Refresh the data after saving
                    return refreshApex(this.wiredFieldsWithValuesResult); // Refresh the Apex data
                })
                .then(() => {
                    this.isLoading = false; // Hide spinner after refresh is complete
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error updating Opportunity',
                        message: error.body.message,
                        variant: 'error'
                    }));
                    this.isLoading = false; // Hide spinner if there is an error
                });
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'OpportunityId not found. Cannot update Opportunity.',
                variant: 'error'
            }));
            this.isLoading = false; // Hide spinner if there is an error
        }
    }
}