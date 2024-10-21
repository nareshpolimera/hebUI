import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import esclateToDesignateEmployeeFromLevelOne from "@salesforce/apex/CMS_Handler.esclateToDesignateEmployeeFromLevelOne";
import getUserPermissionSets from "@salesforce/apex/CMS_Handler.getUserPermissionSets";
import getCaseDetails from "@salesforce/apex/CMS_Handler.getCaseDetails";
import userId from '@salesforce/user/Id';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
// import ProfileName from '@salesforce/schema/User.Profile.Name';

export default class Cms_EscalateCase extends NavigationMixin(LightningElement) {

    @track currentCaseId;
    @track deValue = '';
    @track deRationale;
    @track sdeRationale;
    @track areDetailsVisible = false;
    @track sdeVisible;
    @track deVisible;
    @track caseRec;
    @track requiredDE = false;
    @track requiredSDE = false;

    @track isLoadingIndicator = false;
    // @track userProfileName = '';

    get optionsA() {
        return [
            { label: '   Designated Employee', value: 'DE' },
            { label: '   Senior Designated Employee', value: 'SDE' }
        ];
    }


    get optionsB() {
        return [
            { label: '   Senior Designated Employee', value: 'SDE' }
        ];
    }


    @track radioList;

    /*@wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
        }
    }*/

    @wire(CurrentPageReference)
    getStateParamentes(CurrentPageReference) {
        if (CurrentPageReference) {
            this.currentCaseId = CurrentPageReference.state.recordId;
        }
    }

    @track caseOwnerId;
    @track loggedInUserPermissions;
    @track isthisaboutfraud = false;
    connectedCallback() {
        getCaseDetails({ caseId: this.currentCaseId }).then(result => {
            this.caseOwnerId = result.OwnerId;
            this.isthisaboutfraud = result.Is_this_about_fraud__c;
            if (result != undefined && result.Complaint_Handling_Level__c == 'Level 2') {
                this.radioList = this.optionsB;
                this.areDetailsVisible = true;
                this.deVisible = false;
                this.sdeVisible = true;
                this.deValue = 'SDE';
                this.requiredSDE = true;
            }
            else {
                this.radioList = this.optionsA;
            }

            getUserPermissionSets().then(userPermissionsResult => {
                console.log('User Permissions');
                this.loggedInUserPermissions = userPermissionsResult;
            }).catch(userPermissionError => {
                console.log(userPermissionError);
            });


        }).catch(error => {
            console.log(error);
        });
    }

    handleOnDEChange(event) {
        console.log(event.target.value);
        this.areDetailsVisible = true;
        if (event.target.value == 'DE') {
            this.sdeVisible = false;
            this.deVisible = true;
            this.requiredDE = true;
            this.requiredSDE = false;
        }
        else {
            this.deVisible = false;
            this.sdeVisible = true;
            this.requiredSDE = true;
            this.requiredDE = false;
        }
        this.deValue = event.target.value;
    }

    redirectToOpportunity() {
        let baseUrl = `${window.location.origin}/lightning/r/case/${this.currentCaseId}/view`;
        window.open(baseUrl, "_self");
    }

    CloseQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToastMessage(message, variant, title) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }

    handleDERationale(event) {
        this.deRationale = event.target.value;
    }

    handleSDERationale(event) {
        this.sdeRationale = event.target.value;
    }


    isValidRadio() {
        let isValid = true;
        const fields = this.template.querySelectorAll('lightning-radio-group');
        if (fields) {
            fields.forEach(field => {
                if (field.name == 'radioGroup') {
                    if (!field.checkValidity()) {
                        field.reportValidity();
                        isValid = false;
                    }
                }
            });
        }
        return isValid;
    }

    isValidInput() {
        let isValid = true;
        const fields = this.template.querySelectorAll('lightning-textarea');
        if (fields) {
            fields.forEach(field => {
                if (this.requiredDE && field.name == 'escalationtoDERationale') {
                    if (!field.checkValidity()) {
                        field.setCustomValidity("Please provide Escalation to DE Rationale");
                        field.reportValidity();
                        isValid = false;
                    }
                } else if (this.requiredSDE && field.name == 'escalationtoSDERationale') {
                    if (!field.checkValidity()) {
                        field.setCustomValidity("Please provide Escalation to SDE Rationale");
                        field.reportValidity();
                        isValid = false;
                    }
                }
            });
        }
        return isValid;
    }

    handleOnEscalate(event) {
        // Security Changes
        const permissionSets = JSON.stringify(this.loggedInUserPermissions);
        const isSecondLevelPermission = (permissionSets.includes('CR_Team_Lead_L1') || (permissionSets.includes('Complaints_Specialist_L1')));
        const skipValidation = (permissionSets.includes('DEs_L2') || (permissionSets.includes('SDEs_L3')));
        if (!skipValidation) {
            if (userId != this.caseOwnerId && permissionSets.includes("FPOCs_L1")) {
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            }
            /* else if (!isSecondLevelPermission) {
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            } */
            else if (userId != this.caseOwnerId && this.isthisaboutfraud) {
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            }
        }

        this.isLoadingIndicator = true;
        if (this.deValue != undefined && this.deValue != '') {
            let rationaleValue = this.deValue == 'DE' ? this.deRationale : this.sdeRationale;
            if (rationaleValue == undefined || rationaleValue == '') {
                this.isValidInput();
            }
            else {
                esclateToDesignateEmployeeFromLevelOne({ caseId: this.currentCaseId, role: this.deValue, rationale: rationaleValue })
                    .then(result => {
                        this.isLoadingIndicator = false;
                        console.log(result);
                        this.CloseQuickAction();
                        this.showToastMessage(`Case has been Escalated!`, 'Success', 'Success');
                        // setTimeout(() => {
                        this.redirectToOpportunity();
                        // }, 3000);

                    }).catch(error => {
                        this.isLoadingIndicator = true;
                        console.log(error);
                    });
            }


        }
        else {
            this.isValidRadio();
            this.showToastMessage('Please select Escalate Level', 'warning', 'warning');
        }
    }

}