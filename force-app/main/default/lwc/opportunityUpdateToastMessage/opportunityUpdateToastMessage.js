import { LightningElement , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createMarsRecord from '@salesforce/apex/OpportunitySendEmailController.createMarsRecord';
import {
    FlowNavigationFinishEvent,FlowNavigationBackEvent 
} from 'lightning/flowSupport';
export default class OpportunityUpdateToastMessage extends LightningElement {
    @api recordId;
    @api oppName;
    @api type;
    @api availableActions = [];

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: '',
            message: 'Lead "'+this.oppName+'" was saved.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
        this.closeFlow();
    }

    connectedCallback() {
        alert(this.recordId,this.type);
        createMarsRecord({ recordId: this.recordId, type: this.type })
        .then(result => {
            alert(JSON.stringify(result));
            if(result){this.showErrorToast();}
            else{this.showSuccessToast();}
        })
        .catch(error => {;
            alert(JSON.stringify(error))
            this.showErrorToast();
        });   
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Please try again later.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
        this.closeFlow();
    }

    closeFlow(){
            var navigateNextEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateNextEvent);      
    }
}