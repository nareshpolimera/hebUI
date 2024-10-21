import { api, LightningElement, track } from 'lwc';
import { checkNull } from "c/cms_jsUtility";

export default class Cms_caseRedress extends LightningElement {
    pageLoaded = false;
    objectApiName = 'Redress__c';
    @track redressId = '';
    @api caseId = '';
    @track redressData = {'Redress_Amount__c':'0'};
    

    handleSuccessData(event) {
        const updatedRecord = event.detail.id;
        this.dispatchEvent(new CustomEvent('navigatenextfromredress', {
            detail: {
                redressId: updatedRecord
            }
        }));

    }

    connectedCallback() {
        this.pageLoaded = true;
          this.dispatchEvent(new CustomEvent('fetchredressddetails', {
              detail: {
                  message: 'redresspage'
              }
          }));

    }
    @api
    getRedressId(redressId) {
        this.redressId = redressId
    }
    @api
    getCaseId(caseId) {
        this.caseId = caseId
        
        //this.closeSpinner();
    }
    @api
    async handleSubmitButtonClick() {
        try {
            await this.template.querySelector('lightning-record-edit-form').submit();
        } catch (error) {
            console.log('error', error);
        }

    }
    handleSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Street = '32 Prince Street';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    
    handleChange(event) {
        switch (event.currentTarget.dataset.id) {
            case 'Financial_Redress_Type__c':
                this.redressData.Financial_Redress_Type__c = event.detail.value;
                break;
            case 'Redress_Method__c':
                this.redressData.Redress_Method__c = event.detail.value;
                break;
            case 'Redress_Amount__c':
                this.redressData.Redress_Amount__c = event.detail.value;
                this.checkAmountValidity();
                break;
            case 'Is_Redress_received__c':
                this.redressData.Is_Redress_received__c = event.detail.value;
                break;
            case 'Resolution_Rationale__c':
                this.redressData.Resolution_Rationale__c = event.detail.value;
                break;
            default:

        }
    }
    @api
    fetchRedressDataIfNoCaseId() {
        return this.redressData;
    }
    handleError(event) {
        let message = event.detail.detail;
        this.closeSpinner();

    }
    closeSpinner() {
        this.dispatchEvent(new CustomEvent('closespiner', {
            detail: {
                message: 'redressPage'
            }
        }));
    }
    @api populateRedressDataFromParent(redressData) {
        if (redressData) {
            this.redressData = redressData;
        }
    }
    handleLoad() {
        this.closeSpinner();
    }

    @api
    checkValidity() {
        return this.reportValidity();
    }
    checkAmountValidity() {
        try {
            let amountElement = this.template.querySelector(".currency-class");
            if(!(this.redressData.Redress_Amount__c > 0)){
                amountElement.setCustomValidity("Amount should be greater than 0.");
            }else{
                amountElement.setCustomValidity("");
            }
            amountElement.reportValidity();
        } catch (error) {
        }
        
        
    }

    reportValidity() {
        let isValid = true;
        this.template.querySelectorAll('.reportValidityClass').forEach(element => {
             if(!(this.redressData.Redress_Amount__c > 0)){
                try {
               if(element.classList.contains("currency-class")){
                    element.setCustomValidity("Amount should be greater than 0.");
                    isValid = false;
                }
                } catch (error) {
                    console.log(error);
                }
                
            }
            let checkValidtyData = false;
            checkValidtyData = element.reportValidity();
            if (!checkValidtyData) {
                element.reportValidity();
                isValid = false;
            }

        });
        return isValid;
    }
    @api
    setNewForm(){
        this.clearData();
    }
    clearData(){
        this.redressData={'Financial_Redress_Type__c': '', 'Redress_Method__c': '', 'Redress_Amount__c': '0', 'Is_Redress_received__c': '','Resolution_Rationale__c':''};
    }
}