import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import PARENTFIELD from '@salesforce/schema/Account.PersonContactId';
import GRANTPARENTFIELD from '@salesforce/schema/Contact.IndividualId';

const columns = [
        {
            label: 'Name',
            fieldName: 'Link',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Name' 
                },
                target: '_blank'
            }
        },
        {
            label: 'Party',
            fieldName: 'Party',
            type: 'text'
        },
        {
            label: 'Effective From',
            fieldName: 'EffectiveFrom',
            type: 'date',
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            }
        },
        {
            label: 'Capture Date',
            fieldName: 'CaptureDate',
            type: 'date',
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            }
        }
    ];

export default class ConsentRelatedList extends LightningElement {
    
    @api recordId;
    parentId;
    grandParentId;
    data;
    columns = columns;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: [PARENTFIELD] })
    getParentRecord({ error, data }) {
        console.log({'parent' : data});
        if (data) {
            this.parentId = getFieldValue(data, PARENTFIELD);
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getRecord, { recordId: '$parentId', fields: [GRANTPARENTFIELD] })
    getGrantParentRecords({ error, data }) {
        console.log({'grandParent' : data});
        if (data) {
            this.grandParentId = getFieldValue(data, GRANTPARENTFIELD);
        } else if (error) {
            this.error = error;
        }
    }
    
    @wire(getRelatedListRecords, { parentRecordId: '$grandParentId', relatedListId: 'Individuals', fields: ['ContactPointTypeConsent.Id', 'ContactPointTypeConsent.Name','ContactPointTypeConsent.EffectiveFrom', 'ContactPointTypeConsent.CaptureDate', 'ContactPointTypeConsent.Party.Name'] })
    getRelatedRecords({ data, error }) {
        console.log({'consents' : JSON.stringify(this.data)});
        if (data) {
            this.data = data.records.map(record => {
                return {
                    Id: record.id,
                    Link: `/${record.id}`,
                    Name: record.fields.Name.value,
                    EffectiveFrom: record.fields.EffectiveFrom.value,
                    CaptureDate: record.fields.CaptureDate.value,
                    Party: record.fields.Party.value.fields.Name.value
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }
}