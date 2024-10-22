import { LightningElement,api, track } from 'lwc';

export default class BorrowersComponentContainer extends LightningElement {
    @api recordId;

    connectedCallback(){
        for (let index = 0; index < 2; index++) {
            const element = index;
        }
    }
}