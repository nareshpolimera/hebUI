import { LightningElement,api } from 'lwc';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import TERRITORY_FIELD from '@salesforce/schema/Opportunity.Territory2Id';
import REFERRAL_PARTNER_FIELD from '@salesforce/schema/Opportunity.Referral_Partner__c';
import SUBMISSION_PARTNER_FIELD from '@salesforce/schema/Opportunity.Submission_Partner__c';
import REFERRAL_CHANNEL_FIELD from '@salesforce/schema/Opportunity.Referral_Channel__c';
import REFERRAL_ORGANIZATION_FIELD from '@salesforce/schema/Opportunity.Referral_Organization__c';
const CHEVRON_UP = "utility:chevronup";
const CHEVRON_DOWN = "utility:chevrondown";

export default class Ds_partnerDetails extends LightningElement {
    @api recordId;
    //Assigning imported object and fields to variables
    objectApiName = OPPORTUNITY_OBJECT;
    territoryField = TERRITORY_FIELD;
    referralPartnerField = REFERRAL_PARTNER_FIELD;
    submissionPartnerField = SUBMISSION_PARTNER_FIELD;
    referralChannelField = REFERRAL_CHANNEL_FIELD;
    referralOrganizationField = REFERRAL_ORGANIZATION_FIELD;
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