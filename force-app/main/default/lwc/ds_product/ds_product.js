import { LightningElement,api } from 'lwc';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import PRODUCT_TYPE_FIELD from '@salesforce/schema/Opportunity.Product_Type__c';
import TERM_FIELD from '@salesforce/schema/Opportunity.Term__c';
import REQUESTED_AMOUNT_FIELD from '@salesforce/schema/Opportunity.Requested_Amount__c';
import REQUESTED_FOR_FIELD from '@salesforce/schema/Opportunity.Requested_For__c';
import PRODUCT_RATE_SET_FIELD from '@salesforce/schema/Opportunity.Product_Rate_Set__c';
import QUOTE_STATUS_FIELD from '@salesforce/schema/Opportunity.Quote_Status__c';
import QUOTE_AMOUNT_FIELD from '@salesforce/schema/Opportunity.Quote_Amount__c';
import QUOTE_LTV_FIELD from '@salesforce/schema/Opportunity.Quote_LTV__c';
import PRODUCT_QUOTE_SET_FIELD from '@salesforce/schema/Opportunity.Product_Quote_Set__c';
import HOME_VALUE_FOR_QUOTE_FIELD from '@salesforce/schema/Opportunity.Home_Value_for_Quote__c';
const CHEVRON_UP = "utility:chevronup";
const CHEVRON_DOWN = "utility:chevrondown";

export default class Ds_product extends LightningElement {
    @api recordId;
    //Assigning imported object and fields to variables
    objectApiName = OPPORTUNITY_OBJECT;
    productTypeField = PRODUCT_TYPE_FIELD;
    termField = TERM_FIELD;
    requestedAmountField = REQUESTED_AMOUNT_FIELD;
    requestedForField = REQUESTED_FOR_FIELD;
    productRateSetField = PRODUCT_RATE_SET_FIELD;
    quoteStatusField = QUOTE_STATUS_FIELD;
    quoteAmountField = QUOTE_AMOUNT_FIELD;
    quoteLTVField = QUOTE_LTV_FIELD;
    productQuoteSetField = PRODUCT_QUOTE_SET_FIELD;
    homeValueForQuoteField = HOME_VALUE_FOR_QUOTE_FIELD;

    //member variables
    chevronToggle = CHEVRON_UP;
    showDetails = true;
    showEditButton = true;

    //Handles events on chevron icon. It changes icon everytime user clicks on the icon to change chevron direction.Also sets the visibility of component body
    chevronHandler(event){
        console.log(JSON.stringify(event.target.dataset.name));
        if(event.target.dataset.name === CHEVRON_UP){
            this.chevronToggle = CHEVRON_DOWN;
            this.showDetails = false;
        }
        else{
            this.chevronToggle = CHEVRON_UP;
            this.showDetails = true;
        }
    }

    //Handles click event on edit button. Toggles between view form and edit form. Defines visibility of Save and Cancel buttons
    editButtonHandler(event){
        this.showEditButton = false;
    }

    //Handles click event on cancel button. Toggles between edit form and view form. Resets the edited field values and switches to record view form
    cancelButtonHandler(event){
        this.showEditButton = true;
    }
}