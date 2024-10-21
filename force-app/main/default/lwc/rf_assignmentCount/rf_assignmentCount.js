import { LightningElement, track, api, wire } from 'lwc';
import getAssigmnetCount from'@salesforce/apex/RFAssignmentCountService.getAssigmnetCount';
import getRoleOptions from'@salesforce/apex/RFAssignmentCountService.getRoleOptions';
import getGroupOptions from'@salesforce/apex/RFAssignmentCountService.getGroupOptions';
import getUserOptions from'@salesforce/apex/RFAssignmentCountService.getUserOptions';

const columns = [
    { label: 'User',
        fieldName: 'userUrl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'userName' }, 
        target: '_blank'},
        sortable: true },
    { label: 'Role', fieldName: 'roleName'},
    { label: 'Count', fieldName: 'occupation'},
    { label: 'Max', fieldName: 'maxCapacity'},
    { label: 'Capacity', fieldName: 'capacity'},
    { label: 'Available?', fieldName: 'available', type: 'boolean'},
];

export default class Rf_assignmentCount extends LightningElement {
    @api recordId;
    @api objectApiName;
    roleSelected = '';
    roleOptiones = [{label:"",value:""}];
    groupSelected = '';
    groupOptions = [{label:"",value:""}];
    groupDisabled = true;
    userSelected = '';
    userOptions = [{label:"",value:""}];
    userDisabled = true;
    data = [];
    columns = columns;  
    showDataSpinner = true;

    connectedCallback() {
        console.log('recordId: '+this.recordId);
        console.log('objectApiName: '+this.objectApiName);
    }

    @wire (getRoleOptions)
    wireditems ({ error, data }) {
        if (data) {
            //console.log('options: '+JSON.stringify(data));    
            this.roleOptiones = data;
            this.showDataSpinner = false;
        } else if (error) {
            console.log(error);
            this.errorMessage = error;
            this.showDataSpinner = false;
        }
        else{
            this.resultMessage = 'Filter optiones not found.';
            this.disabled = true;
            this.showDataSpinner = false;
        }
    }

    handleRole(event) {
        this.cleanScreen();
        this.showDataSpinner = true;
        this.roleSelected = event.detail.value;
        this.handleLoadGroups(event);
        this.handleLoadUsers(event);
    }

    cleanScreen(){
        this.groupSelected = '';
        this.groupOptions = [{label:"",value:""}];
        this.userSelected = '';
        this.userOptions = [{label:"",value:""}];
        this.data = [];
    }

    handleLoadGroups(event){
        getGroupOptions({role: this.roleSelected})
        .then((result) => {
            if (result && result.length) {
                //console.log('groupOptions: '+JSON.stringify(result));
                this.groupOptions = result;
                this.groupDisabled = false;
                //this.showDataSpinner = false;
            }
            else{
                this.resultMessage = 'Groups not found';
                //this.disabled = true;
                this.showDataSpinner = false;
            }
        })
        .catch(error => {
            //logic to handle errors
            console.log('error to load items: '+JSON.stringify(error));
            //get error details
            //this.errorMessage = this.reduceErrors(error);
        });
    }

    handleGroup(event) {
        this.groupSelected = event.detail.value;
    }

    handleUser(event) {
        this.userSelected = event.detail.value;
    }

    handleLoadUsers(event){
        getUserOptions({role: this.roleSelected})
        .then((result) => {
            if (result && result.length) {
                //console.log('userOptions: '+JSON.stringify(result));
                this.userOptions = result;
                this.userDisabled = false;
                this.showDataSpinner = false;
            }
            else{
                this.resultMessage = 'Users not found';
                //this.disabled = true;
                this.showDataSpinner = false;
            }
        })
        .catch(error => {
            //logic to handle errors
            console.log('error to loas items: '+JSON.stringify(error));
            //get error details
            //this.errorMessage = this.reduceErrors(error);
        });
    }

    handleShow(event) {
        this.showDataSpinner = true;
        getAssigmnetCount({role: this.roleSelected, userId: this.userSelected,groupId: this.groupSelected})
        .then((result) => {
            if (result) {
                //console.log('assignment count: '+JSON.stringify(result));
                this.data = result;
                this.showDataSpinner = false;
            }
            else{
                this.resultMessage = 'Assignment Count for users not found.';
                //this.disabled = true;
                this.showDataSpinner = false;
            }
        })
        .catch(error => {
            //logic to handle errors
            console.log('error to load items: '+JSON.stringify(error));
            //get error details
            //this.errorMessage = this.reduceErrors(error);
        });
    }

}