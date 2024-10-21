import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ModalComponent extends LightningModal {
    @api content;

    connectedCallback(){
        console.log('Loading....');
    }
    handleStatusChange(event){
        if(event.detail.status === 'FINISHED') {
            console.log('flow finished');
            this.close('done');
            location.reload();
        }
    }
}