import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getRelatedRecords } from 'lightning/uiRelatedListApi';

export default class Consent extends LightningElement {
    @api recordId;
    childRecords;

    @wire(getRecord, { recordId: '$recordId', fields: ['Individual.Id', 'Individual.OwnerId'] }) 
    individual;

    @wire(getRelatedRecords, { parentRecordId: '$recordId', relationshipField: 'Individuals', fields: ['ContactPointTypeConsent.Name']})
    wiredRelatedRecs({ data, error }) {
        if(data) {
            this.childRecords = data.records;
        }
        else if(error) {
            console.error(error);
        }
    }

    get consentOwnerId() {
        return this.individual.data ? this.individual.data.OwnerId : '';
    }
}