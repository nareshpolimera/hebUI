import { LightningElement,api } from 'lwc';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import FILE_STATUS_FIELD from '@salesforce/schema/Opportunity.StageName';
import FILE_OWNER_FIELD from '@salesforce/schema/Opportunity.OwnerId';
import FILE_NUMBER_FIELD from '@salesforce/schema/Opportunity.File_Number__c';
import FILE_TYPE_FIELD from '@salesforce/schema/Opportunity.File_Type__c';
import SOC_FIELD from '@salesforce/schema/Opportunity.Sales_Ops_Coordinator__c';
import HOMEBRIDGE_MORTGAGE_FIELD from '@salesforce/schema/Opportunity.IsHomebridgeMortgage__c';
import PARTNER_OWNER_FIELD from '@salesforce/schema/Opportunity.BDM__c';
import CHANNEL_FIELD from '@salesforce/schema/Opportunity.Channel__c';
import LANGUAGE_FIELD from '@salesforce/schema/Opportunity.Language__c';
const CHEVRON_UP = "utility:chevronup";
const CHEVRON_DOWN = "utility:chevrondown";

export default class Ds_fileDetailsComponent extends LightningElement {
    @api recordId;
    //Assigning imported object and fields to variables
    objectApiName = OPPORTUNITY_OBJECT;
    fileStatusField = FILE_STATUS_FIELD;
    fileOwnerField = FILE_OWNER_FIELD;
    fileNumberField = FILE_NUMBER_FIELD;
    fileTypeField = FILE_TYPE_FIELD;
    salesOpsCoordinatorField = SOC_FIELD;
    isHomeBridgeMortgageField = HOMEBRIDGE_MORTGAGE_FIELD;
    partnerOwnerField = PARTNER_OWNER_FIELD;
    channelField = CHANNEL_FIELD;
    languageField = LANGUAGE_FIELD;
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