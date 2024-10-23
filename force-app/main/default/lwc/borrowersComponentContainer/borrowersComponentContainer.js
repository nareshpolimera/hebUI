import { LightningElement,api, track } from 'lwc';

export default class BorrowersComponentContainer extends LightningElement {
    @api recordId;

    @track borrowers = [];
    @track currentIndex;
    connectedCallback() {
        for (let index = 1; index < 3; index++) {
            this.borrowers.push( {  Index : index, currentIndex :  index });
            this.currentIndex = index;
        }
    }
    handleAddNewBrrower(event){        
        this.currentIndex = this.currentIndex + 1;
        this.borrowers.push( {  Index : this.currentIndex, currentIndex :  this.currentIndex });
    }

    handleBorrowerChange(event) {
        console.log('Hey I am here');
        const totalComponents = this.template.querySelectorAll("c-borrowers-component");
        for (let i = 0 ; i < totalComponents.length; i++) {
            const element = totalComponents[i];
            console.log(element);
            element.updateBorrowerData();
        }
    }

    handleBorrowerCancel(event){
        const totalComponents = this.template.querySelectorAll("c-borrowers-component");
        for (let i = 0 ; i < totalComponents.length; i++) {
            const element = totalComponents[i];
            console.log(element);
            element.onCancelClickBorrower();
        }
    }
}