import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getUsersForHandlingLevel from '@salesforce/apex/CMS_Handler.getUsersForHandlingLevel';
import transferToDesignateEmployeeFromLevelOne from '@salesforce/apex/CMS_Handler.transferToDesignateEmployeeFromLevelOne';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';
import getCaseDetails from "@salesforce/apex/CMS_Handler.getCaseDetails";
import getUserPermissionSets from "@salesforce/apex/CMS_Handler.getUserPermissionSets";

export default class CmsTransferCase extends LightningElement {
    @track currentCaseId;
    @track selectedValue;
    @track selectedUser;
    @track userOptions = []; // Stores all user options
    @track filteredUserOptions = []; // Stores filtered user options based on search
    @track searchTerm = '';
    @track isFpocSelected = false;
    @track dropdownVisible = false; // Controls dropdown visibility
    @track caseOwnerId;

    @wire(CurrentPageReference)
    getStateParamentes(CurrentPageReference) {
        if (CurrentPageReference) {
            this.currentCaseId = CurrentPageReference.state.recordId;
        }
    }

    get radioOptions() {
        return [
            { label: 'FPOC', value: 'FPOC' },
            { label: 'Customer Care Complaint Handler', value: 'CCCH' },
            { label: 'Senior Complaint Handler', value: 'SCH' }
        ];
    }

    handleRadioChange(event) {
        this.selectedValue = event.detail.value;
        this.isFpocSelected = this.selectedValue === 'FPOC';

        if (this.isFpocSelected) {
            this.fetchUserOptions();
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        this.filterUserOptions();
    }

    handleFocus() {
        if (this.searchTerm && this.filteredUserOptions.length > 0) {
            this.dropdownVisible = true;
        }
    }

    handleBlur() {
        setTimeout(() => {
            this.dropdownVisible = false;
        }, 100);
    }

    handleUserSelect(event) {
        const selectedUserId = event.currentTarget.dataset.id;
        const selectedUser = this.userOptions.find(user => user.value === selectedUserId);
        
        if (selectedUser) {
            this.selectedUser = selectedUserId;
            this.searchTerm = selectedUser.label; // Set search term to selected user's name
            this.filteredUserOptions = [];
            this.dropdownVisible = false;
        }
    }

    @track isthisaboutfraud = false;
    connectedCallback() {
        getCaseDetails({ caseId: this.currentCaseId }).then(result => {
            this.caseOwnerId = result.OwnerId;
            this.isthisaboutfraud = result.Is_this_about_fraud__c;

        }).catch(error => {
            console.log(error);
        });

        getUserPermissionSets().then(userPermissionsResult =>{
            console.log('User Permissions');
            this.loggedInUserPermissions = userPermissionsResult;
        }).catch(userPermissionError =>{
            console.log(userPermissionError);
        });
    }

   
    fetchUserOptions() {
        getUsersForHandlingLevel({ caseId: this.currentCaseId })
            .then(result => {
                this.userOptions = result.map(user => ({
                    label: user.Name,
                    value: user.Id
                }));
                this.filterUserOptions(); 
            })
            .catch(error => {
                console.error('Error fetching users:', error);
                this.showToastMessage('No user found with same business unit.', 'error', 'Error');
            });
    }

    filterUserOptions() {
        if (this.searchTerm) {
            this.filteredUserOptions = this.userOptions.filter(user =>
                user.label.toLowerCase().includes(this.searchTerm.toLowerCase())
            );
            this.dropdownVisible = this.filteredUserOptions.length > 0;
        } else {
            this.filteredUserOptions = [];
            this.dropdownVisible = false;
        }
    }

    handleTransfer() {
        // Security Changes
        const permissionSets = JSON.stringify(this.loggedInUserPermissions);
        const isSecondLevelPermission =  (permissionSets.includes('CR_Team_Lead_L1') ||  (permissionSets.includes('Complaints_Specialist_L1')));
        const skipValidation = (permissionSets.includes('DEs_L2') || (permissionSets.includes('SDEs_L3')));
        if (!skipValidation) {
            if(userId != this.caseOwnerId && permissionSets.includes("FPOCs_L1") ) {
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            }
            /* else if(!isSecondLevelPermission){
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            } */
            else if(userId != this.caseOwnerId && this.isthisaboutfraud){
                this.showToastMessage('You are not authorized to transfer this case which you do not own.', 'error', 'Error');
                return;
            }
        }

        if (!this.selectedValue) {
            this.showToastMessage('Please select an option before transferring.', 'error', 'Error');
            return;
        }

        if (this.isFpocSelected && !this.selectedUser) {
            this.showToastMessage('Please select a user for FPOC.', 'error', 'Error');
            return;
        }

        transferToDesignateEmployeeFromLevelOne({ caseId: this.currentCaseId, option: this.selectedValue, userId: this.selectedUser })
            .then(() => {
                this.showToastMessage('Case has been transferred!', 'success', 'Success');
                this.CloseQuickAction();
                this.redirectToCase();
            }).catch(error => {
                console.error('Error during transfer:', error);
                this.showToastMessage('An error occurred during the transfer.', 'error', 'Error');
            });
    }

    handleCancel() {
        this.CloseQuickAction();
    }

    CloseQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    redirectToCase() {
        let baseUrl = `${window.location.origin}/lightning/r/case/${this.currentCaseId}/view`;
        window.open(baseUrl, "_self");
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
}