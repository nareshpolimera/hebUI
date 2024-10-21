import { LightningElement,api, track } from 'lwc';
const CHEVRON_UP = "utility:chevronup";
const CHEVRON_DOWN = "utility:chevrondown";

export default class BorrowersComponent extends LightningElement {
    @api recordId;
    @track chevronToggle = CHEVRON_UP;
    chevronHandler(event){
        console.log(JSON.stringify(event.target.dataset.name));
        if(event.target.dataset.name === CHEVRON_UP){
            this.chevronToggle = CHEVRON_DOWN;
        }
        else{
            this.chevronToggle = CHEVRON_UP;
        }
    }
    
}