import { LightningElement, api } from 'lwc';

export default class Cms_caseCommunicationConsent extends LightningElement {
    activeSections = ['A', 'B'];
    value = ['option1'];
    activeSectionsMessage = '';
    consentMandatory = false;
    @api consentGiven = false;
    get options() {
        return [
            { label: 'Consent provided by the complainant', value: 'consentRecieved' },
        ];
    }
    @api
    getConsent(){
        this.template.querySelector('.consentclass').classList.remove('consentRequired');
        if(!this.consentGiven && this.consentMandatory){
            this.template.querySelector('.consentclass').classList.add('consentRequired');
            this.template.querySelector('.consentMessage').classList.add('displayerror');
            this.template.querySelector('.consentMessage').classList.remove('hideerror');
        }
        return  this.consentGiven;
    }
    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        this.template.querySelector('.consentclass').classList.remove('consentRequired');
        this.template.querySelector('.consentMessage').classList.add('hideerror');
            this.template.querySelector('.consentMessage').classList.remove('displayerror');
        this.consentGiven = false;
        this.value = e.detail.value;
        if (this.value.length > 0) {
            this.consentGiven = true;
        }
        if(!this.consentGiven && this.consentMandatory){
            this.template.querySelector('.consentclass').classList.add('consentRequired');
            this.template.querySelector('.consentMessage').classList.add('displayerror');
            this.template.querySelector('.consentMessage').classList.remove('hideerror');
        }


    }
    connectedCallback() {
        this.getConsentFromParent();
    }
    getConsentFromParent() {
        this.dispatchEvent(new CustomEvent('fetchconsent', {
            detail: {
                message: 'addConsentPage'
            }
        }));
    }
    @api
    updateConsentGiven(consentGiven,consentMandatory) {
        this.consentGiven = consentGiven;
        this.consentMandatory = consentMandatory; 
        if (this.consentGiven) {
            this.value = ["consentRecieved"];
        }
        this.dispatchEvent(new CustomEvent('closespiner', {
            detail: {
                message: 'AddNewComplainantPage'
            }
        }));

    }
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }
}