import { LightningElement, api, track } from 'lwc';
const CHEVRON_UP = "utility:chevronup";
const CHEVRON_DOWN = "utility:chevrondown";
const PLUS = "utility:add";
const MINUS = "utility:dash";
const BUTTONCHECK = "utility:check";

export default class BorrowersComponent extends LightningElement {
    @api recordId;
    @track chevronToggle = CHEVRON_UP;    
    @track showDetails = true;
    @track showCASLMarketingDetails = false;
    @track hideOrShowEmploymentDetails = false;
    @track hideOrShowEmploymentIncomeDetails = false;

    @track employmentIcon = MINUS;
    @track caslMarketingIcon = MINUS;
    @track employmentIncomeIcon = MINUS;
    @track accordianHeader;
    @api key;
    @api uniqueKey;
    @api borrowerProp;

    @track borrowerItem = {
        isEditModeOn: false,
        mainObject : {},
        caslAndMarketing : {},
        income:{},
        employment: {}
    }

    //#region Connected Call Back
    connectedCallback() {
        console.log(this.uniqueKey);
        this.thisaccordianHeader = this.uniqueKey == 1 ? 'Person ' + this.uniqueKey + ' Primary' : 'Person ' + this.uniqueKey; 
        this.chevronToggle = CHEVRON_UP;
        this.showCASLMarketingDetails = true;
        this.hideOrShowEmploymentDetails = true;
        this.hideOrShowEmploymentIncomeDetails = true;
        this.showDetails = true;

        this.borrowerItem = { isEditModeOn: true, mainObject : {}, caslAndMarketing : {}, income:{}, employment: {} };
    }
    //#endregion
    
    //#region Toggle Logic
    onemploymentIncomeIconClick (event){
        if (event.target.dataset.name === PLUS) {
            this.employmentIncomeIcon = MINUS;
            this.hideOrShowEmploymentIncomeDetails = true;
        }
        else if(event.target.dataset.name === MINUS){
            this.employmentIncomeIcon = PLUS;
            this.hideOrShowEmploymentIncomeDetails = false;
        }
    }

    onemploymentIconClick(event) {
        if (event.target.dataset.name === PLUS) {
            this.employmentIcon = MINUS; 
            this.hideOrShowEmploymentDetails = true;
        }
        else if(event.target.dataset.name === MINUS){
            this.employmentIcon = PLUS;
            this.hideOrShowEmploymentDetails = false;
        }
    }

    onshowCASLMarketingDetailsClick(event) {
        if (event.target.dataset.name === PLUS) {
            this.caslMarketingIcon = MINUS;
            this.showCASLMarketingDetails = true;
        }
        else if(event.target.dataset.name === MINUS){
            this.caslMarketingIcon = PLUS;
            this.showCASLMarketingDetails = false;
        }
    }
    chevronHandler(event) {
        if (event.target.dataset.name === CHEVRON_UP) {
            this.chevronToggle = CHEVRON_DOWN;
            this.showDetails = false;
        }
        else {
            this.chevronToggle = CHEVRON_UP;
            this.showDetails = true;
        }
    }
    //#endregion

    handleOnEditClick(event){
        this.borrowerItem.isEditModeOn = false;
        const selectedEvent = new CustomEvent("borrowervaluechange", { detail: this.borrowerItem });
        this.dispatchEvent(selectedEvent);
    }

    handleOnCancelClick(event){
        this.borrowerItem.isEditModeOn = true;
        const selectedEvent = new CustomEvent("borrowercancel", { detail: this.borrowerItem });
        this.dispatchEvent(selectedEvent);
    }

    @api
    fetchBorrowerData() {
        return this.borrowerItem;
    }
    
    @api
    updateBorrowerData() {
        this.borrowerItem.isEditModeOn = false;
    }

    @api
    onCancelClickBorrower(){
        this.borrowerItem.isEditModeOn = true;
        console.log('on Cancle');
    }
}