import { LightningElement, track, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getDynamicTableDataList from '@salesforce/apex/DynamicDataTableComplainantSearch.getWrapperOfSObjectFieldColumnActionValues';
import linkOnlyFile from '@salesforce/apex/DynamicDataTableComplainantSearch.linkOnlyFile';

export default class DynamicComplainantSearchPage extends LightningElement {
    @track strSearchAccName = '';
    @track DataTableResponseWrappper;
    @track finalSObjectDataList;
    @track flattenTransformation;
    @track errorMsg;
    @api recordId;
    emptyValue = '';
    searchEmptyValue = false;
    showErrorMessage = false;
    showSourceObject = false;
    sourceObject = '';
    @track dynamicColumns = [];
    recordsToSave = 'Lead';
    @track complaintObject = {
        'FileNumber': '',
        'LastName': '',
        'FirstName': '',
        'Phone': '',
        'Email': '',
        'ChannelOfComplainant': '',
        'Country': '',
        'Street': '',
        'City': '',
        'State': '',
        'PostalCode': '',
        'fundedDate': '',
        'deathDate': '',
        'properityStreet': '',
        'fileId': '',
        'marsFileId': ''
    };

    displaySpinner = false;
    // handleSearch(event) {
    //     if (event.keyCode === 13) {

    //         this.strSearchAccName = event.currentTarget.value;

    //         if (!this.strSearchAccName) {
    //             this.errorMsg = 'Please enter file number to search.';
    //             this.DataTableResponseWrappper = undefined;
    //         }

    //         getDynamicTableDataList({ searchFileNo: this.strSearchAccName })
    //             .then(result => {

    //                 if (result.sourceObject == 'Lead') {
    //                     this.recordsToSave = 'Lead';

    //                     this.sourceObject = 'The displayed result is from unconverted leads';
    //                     this.showSourceObject = true;
    //                 }
    //                 else if (result.sourceObject == 'HEB') {
    //                     this.recordsToSave = 'HEB';

    //                     this.sourceObject = 'The displayed result is from HEBFileCustomer';
    //                     this.showSourceObject = true;
    //                 }


    //                 this.DataTableResponseWrappper = result;
    //                 let sObjectRelatedFieldListValues = [];

    //                 for (let row of result.lstDataTableData) {
    //                     const finalSobjectRow = {}
    //                     let rowIndexes = Object.keys(row);
    //                     rowIndexes.forEach((rowIndex) => {
    //                         const relatedFieldValue = row[rowIndex];
    //                         if (relatedFieldValue.constructor === Object) {
    //                             this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)
    //                         }
    //                         else {
    //                             finalSobjectRow[rowIndex] = relatedFieldValue;
    //                         }

    //                     });
    //                     sObjectRelatedFieldListValues.push(finalSobjectRow);

    //                 }
    //                 if (!result.lstDataTableData || result.lstDataTableData[0] == null) {
    //                     this.errorMsg = 'File not found';
    //                    this.showSourceObject = false;
    //                 }
    //                 else {
    //                     this.errorMsg = '';
    //                 }

    //                 this.DataTableResponseWrappper = result;
    //                 this.dynamicColumns = this.DataTableResponseWrappper.lstDataTableColumns.filter(col => col.label !== 'Country'
    //                     && col.label !== 'Street' && col.label !== 'City' && col.label !== 'State' && col.label !== 'PostalCode' && col.label !== 'Funded Date' && col.label !== 'Death Date' && col.label !== 'Contact' && col.label !== 'External ID');

    //                 this.finalSObjectDataList = sObjectRelatedFieldListValues;
    //                 this._flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => {
    //                     let rowIndexes = Object.keys(fieldValue);
    //                     rowIndexes.forEach((key) => {
    //                         let finalKey = fieldName + '.' + key;
    //                         finalSobjectRow[finalKey] = fieldValue[key];
    //                     })
    //                 }
    //             })
    //             .catch(error => {

    //                 this.DataTableResponseWrappper = undefined;
    //                 if (error) {
    //                     if (Array.isArray(error.body)) {
    //                         this.errorMsg = error.body.map(e => e.message).join(', ');
    //                     } else if (typeof error.body.message === 'string') {
    //                         this.errorMsg = error.body.message;
    //                     }
    //                 }
    //             })
    //     }

    // }

    connectedCallback() {
        getDynamicTableDataList({ searchFileNo: this.strSearchAccName })
            .then(result => {
                if (result) {
                    this.DataTableResponseWrappper = result;
                    let sObjectRelatedFieldListValues = [];
                    for (let row of result.lstDataTableData) {
                        const finalSobjectRow = {}
                        let rowIndexes = Object.keys(row);
                        rowIndexes.forEach((rowIndex) => {
                            const relatedFieldValue = row[rowIndex];
                            if (relatedFieldValue.constructor === Object) {
                                this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)
                            }
                            else {
                                finalSobjectRow[rowIndex] = relatedFieldValue;
                            }

                        });

                        sObjectRelatedFieldListValues.push(finalSobjectRow);
                    }
                    this.DataTableResponseWrappper = result;
                    this.dynamicColumns = this.DataTableResponseWrappper.lstDataTableColumns.filter(col => col.label !== 'Country' && col.label !== 'Street' && col.label !== 'City' && col.label !== 'State' && col.label !== 'PostalCode' && col.label !== 'Funded Date' && col.label !== 'Death Date' && col.label !== 'Contact' && col.label !== 'External ID');
                    this.finalSObjectDataList = sObjectRelatedFieldListValues;
                    this._flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => {
                        let rowIndexes = Object.keys(fieldValue);
                        rowIndexes.forEach((key) => {
                            let finalKey = fieldName + '.' + key;
                            finalSobjectRow[finalKey] = fieldValue[key];
                        })
                    }
                }
                else {
                    this.DataTableResponseWrappper = undefined;
                    if (error) {
                        if (Array.isArray(error.body)) {
                            this.errorMsg = error.body.map(e => e.message).join(', ');
                        } else if (typeof error.body.message === 'string') {
                            this.errorMsg = error.body.message;
                        }
                    }
                }
            })
    }

    handleSearch(event) {
        if (event.keyCode === 13) {
            this.displaySpinner = true;
            this.strSearchAccName = event.currentTarget.value;

            if (!this.strSearchAccName) {
                this.errorMsg = 'Please enter file number to search.';
                this.DataTableResponseWrappper = undefined;
            }

            getDynamicTableDataList({ searchFileNo: this.strSearchAccName })
                .then(result => {
                    console.log('RetrievedData::result', result);
                    this.displaySpinner = false;
                    if (result.sourceObject == 'Opportunity') {
                        this.recordsToSave = 'Opportunity';

                        this.sourceObject = 'The displayed result is from Files';
                        this.showSourceObject = true;
                    }
                    else if (result.sourceObject == 'HEB') {
                        this.recordsToSave = 'HEB';

                        this.sourceObject = 'The displayed result is from HEBFileCustomer';
                        this.showSourceObject = true;
                    }


                    this.DataTableResponseWrappper = result;
                    let sObjectRelatedFieldListValues = [];
                    this.errorMsg = '';
                    let dataTableData;
                    if (result.lstDataTableData && result.lstDataTableData[0] != null) {
                        console.log('RetrievedData::lstDataTableData', result.lstDataTableData[0]);
                        dataTableData = result.lstDataTableData;
                    }
                    else if (result.lstDataTableDataOpp && result.lstDataTableDataOpp[0] != null) {
                        console.log('RetrievedData::lstDataTableDataOpp', result.lstDataTableDataOpp[0]);
                        dataTableData = result.lstDataTableDataOpp;
                    }
                    else {
                        this.errorMsg = 'File not found';
                        this.showSourceObject = false;
                    }

                    if (dataTableData != null) {
                        for (let row of dataTableData) {
                            console.log('RetrievedData::row', row);
                            const finalSobjectRow = {}
                            let rowIndexes = Object.keys(row);
                            console.log('RetrievedData::rowIndexes', rowIndexes);
                            rowIndexes.forEach((rowIndex) => {
                                const relatedFieldValue = row[rowIndex];
                                console.log('RetrievedData::relatedFieldValue', relatedFieldValue);
                                if (relatedFieldValue.constructor === Object) {
                                    this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)
                                    console.log('RetrievedData::_flattenTransformation', this._flattenTransformation);
                                }
                                else {
                                    finalSobjectRow[rowIndex] = relatedFieldValue;
                                    console.log('RetrievedData::finalSobjectRow', finalSobjectRow[rowIndex]);
                                }

                            });
                            sObjectRelatedFieldListValues.push(finalSobjectRow);
                            console.log('RetrievedData::sObjectRelatedFieldListValues', sObjectRelatedFieldListValues);

                        }

                        this.DataTableResponseWrappper = result;
                        this.dynamicColumns = this.DataTableResponseWrappper.lstDataTableColumns.filter(col => col.label !== 'Country'
                            && col.label !== 'Street' && col.label !== 'City' && col.label !== 'State' && col.label !== 'PostalCode' && col.label !== 'Funded Date' && col.label !== 'Death Date' && col.label !== 'Contact' && col.label !== 'External ID');
                        console.log('RetrievedData::dynamicColumns', this.dynamicColumns);
                        this.finalSObjectDataList = sObjectRelatedFieldListValues;
                        console.log('RetrievedData::finalSObjectDataList', this.finalSObjectDataList);
                        this._flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => {
                            let rowIndexes = Object.keys(fieldValue);
                            rowIndexes.forEach((key) => {
                                let finalKey = fieldName + '.' + key;
                                finalSobjectRow[finalKey] = fieldValue[key];
                            })
                        }
                    }
                })
                .catch(error => {
                    console.log('RetrievedData::error', error);
                    this.displaySpinner = false;
                    this.DataTableResponseWrappper = undefined;
                    if (error) {
                        if (Array.isArray(error.body)) {
                            this.errorMsg = error.body.map(e => e.message).join(', ');
                        } else if (typeof error.body.message === 'string') {
                            this.errorMsg = error.body.message;
                        }
                    }
                })
        }

    }

    // @wire(getDynamicTableDataList, { searchFileNo: '$strSearchAccName' })
    // storeFiles({ data, error }) {
    //     console.log('RetrievedData::InWire')
    //     if (data) {
    //         this.DataTableResponseWrappper = data;
    //         let sObjectRelatedFieldListValues = [];
    //         for (let row of data.lstDataTableData) {
    //             const finalSobjectRow = {}
    //             let rowIndexes = Object.keys(row);
    //             rowIndexes.forEach((rowIndex) => {
    //                 const relatedFieldValue = row[rowIndex];
    //                 if (relatedFieldValue.constructor === Object) {
    //                     this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)
    //                 }
    //                 else {
    //                     finalSobjectRow[rowIndex] = relatedFieldValue;
    //                 }

    //             });

    //             sObjectRelatedFieldListValues.push(finalSobjectRow);
    //         }
    //         this.DataTableResponseWrappper = data;
    //         this.dynamicColumns = this.DataTableResponseWrappper.lstDataTableColumns.filter(col => col.label !== 'Country' && col.label !== 'Street' && col.label !== 'City' && col.label !== 'State' && col.label !== 'PostalCode' && col.label !== 'Funded Date' && col.label !== 'Death Date' && col.label !== 'Contact' && col.label !== 'External ID');
    //         this.finalSObjectDataList = sObjectRelatedFieldListValues;
    //         this._flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => {
    //             let rowIndexes = Object.keys(fieldValue);
    //             rowIndexes.forEach((key) => {
    //                 let finalKey = fieldName + '.' + key;
    //                 finalSobjectRow[finalKey] = fieldValue[key];
    //             })
    //         }
    //     }
    //     else {
    //         this.DataTableResponseWrappper = undefined;
    //         if (error) {
    //             if (Array.isArray(error.body)) {
    //                 this.errorMsg = error.body.map(e => e.message).join(', ');
    //             } else if (typeof error.body.message === 'string') {
    //                 this.errorMsg = error.body.message;
    //             }
    //         }
    //     }
    // }

    saveAndLinkclick() {
        if (this.strSearchAccName == '') {
            this.errorMsg = 'Please enter a file number';
            // Naresh Kumar
            return;
        }
        var el = this.template.querySelector('lightning-datatable').getSelectedRows();
        if (this.recordsToSave == 'Lead') {

            this.complaintObject.FirstName = el[0].FirstName;
            this.complaintObject.FileNumber = el[0].File_Number__c;
            this.complaintObject.LastName = el[0].LastName;
            this.complaintObject.Email = el[0].Email;
            this.complaintObject.ChannelOfComplainant = el[0].Channel__c;
            this.complaintObject.Phone = el[0].Phone;
            this.complaintObject.Country = el[0].Country;
            this.complaintObject.Street = el[0].Street;
            this.complaintObject.State = el[0].State;
            this.complaintObject.City = el[0].City;
            this.complaintObject.PostalCode = el[0].PostalCode;
            this.complaintObject.fundedDate = null;
            this.complaintObject.deathDate = null;
            this.complaintObject.properityStreet = el[0].Property__c;
            this.complaintObject.leadFileId = el[0].Id;
            this.complaintObject.marsFileId = null;


        }
        else if (this.recordsToSave == 'HEB') {
            this.complaintObject.FirstName = el[0].FirstName__c;
            this.complaintObject.FileNumber = el[0].FileNumber__c;
            this.complaintObject.LastName = el[0].LastName__c;
            this.complaintObject.Email = el[0].Email__c;
            this.complaintObject.ChannelOfComplainant = el[0].Channel__c;
            this.complaintObject.Phone = el[0].Phone__c;
            this.complaintObject.Country = el[0].MailingCountry__c;
            this.complaintObject.Street = el[0].MailingStreet__c;
            this.complaintObject.State = el[0].MailingProvince__c;
            this.complaintObject.City = el[0].MailingCity__c;
            this.complaintObject.PostalCode = el[0].MailingPostalCode__c;
            this.complaintObject.fundedDate = el[0].FundedDate__c;
            this.complaintObject.deathDate = el[0].DeathDate__c;
            this.complaintObject.properityStreet = el[0].PropertyStreet__c;
            this.complaintObject.leadFileId = null;
            this.complaintObject.marsFileId = el[0].ExternalID__c;

        }
        saveAndLinkFile({ complainantRecord: JSON.stringify(this.complaintObject), caseId: this.recordId })
            .then(result => {
                this.dispatchEvent(new CloseActionScreenEvent());
                window.location.reload();
            })
            .catch(error => {
                this.errorMsg = JSON.stringify(error);
            })
    }


    linkFileOnly() {

        var el = this.template.querySelector('lightning-datatable').getSelectedRows();
        if (this.strSearchAccName == '') {
            this.errorMsg = 'Please enter a file number';
            // Naresh Kumar
            return;
        }

        // if (this.recordsToSave == 'Lead') {
        //     this.complaintObject.FirstName = el[0].FirstName;
        //     this.complaintObject.FileNumber = el[0].File_Number__c;
        //     this.complaintObject.LastName = el[0].LastName;
        //     this.complaintObject.Email = el[0].Email;
        //     this.complaintObject.ChannelOfComplainant = el[0].Channel__c;
        //     this.complaintObject.Phone = el[0].Phone;
        //     this.complaintObject.Country = el[0].Country;
        //     this.complaintObject.Street = el[0].Street;
        //     this.complaintObject.State = el[0].State;
        //     this.complaintObject.City = el[0].City;
        //     this.complaintObject.PostalCode = el[0].PostalCode;
        //     this.complaintObject.fundedDate=null;
        //     this.complaintObject.deathDate=null;
        //     this.complaintObject.properityStreet=el[0].Property__c;
        //     this.complaintObject.leadFileId=el[0].Id;
        //     this.complaintObject.marsFileId=null;

        // }

        if (el.length == 0) {
            this.errorMsg = 'Please select a file number';
            return;
        }
        else {
            console.log('RetrievedData::', this.recordsToSave);
            if (this.recordsToSave == 'Opportunity') {
                this.complaintObject.FirstName = el[0].FirstName;
                this.complaintObject.FileNumber = el[0].FileNumber;
                this.complaintObject.LastName = el[0].LastName;
                this.complaintObject.Email = el[0].Email;
                this.complaintObject.ChannelOfComplainant = el[0].Channel;
                this.complaintObject.Phone = el[0].Phone;
                this.complaintObject.Country = el[0].Country;
                this.complaintObject.Street = el[0].Street;
                this.complaintObject.State = el[0].State;
                this.complaintObject.City = el[0].City;
                this.complaintObject.PostalCode = el[0].PostalCode;
                this.complaintObject.fundedDate = null;
                this.complaintObject.deathDate = null;
                this.complaintObject.properityStreet = el[0].PropertyStreet;
                this.complaintObject.fileId = el[0].OpportunityId;
                this.complaintObject.marsFileId = null;

            }
            else if (this.recordsToSave == 'HEB') {

                this.complaintObject.FirstName = el[0].FirstName__c;
                this.complaintObject.FileNumber = el[0].FileNumber__c;
                this.complaintObject.LastName = el[0].LastName__c;
                this.complaintObject.Email = el[0].Email__c;
                this.complaintObject.ChannelOfComplainant = el[0].Channel__c;
                this.complaintObject.Phone = el[0].Phone__c;
                this.complaintObject.Country = el[0].MailingCountry__c;
                this.complaintObject.Street = el[0].MailingStreet__c;
                this.complaintObject.State = el[0].MailingProvince__c;
                this.complaintObject.City = el[0].MailingCity__c;
                this.complaintObject.PostalCode = el[0].MailingPostalCode__c;
                this.complaintObject.fundedDate = el[0].FundedDate__c;
                this.complaintObject.deathDate = el[0].DeathDate__c;
                this.complaintObject.properityStreet = el[0].PropertyStreet__c;
                this.complaintObject.fileId = null;
                this.complaintObject.marsFileId = el[0].ExternalID__c;

            }

            linkOnlyFile({ recordToLink: JSON.stringify(this.complaintObject), caseRecordIdToLinkOnly: this.recordId })
                .then(result => {

                    this.dispatchEvent(new CloseActionScreenEvent());
                    window.location.reload();
                }).catch(error => {
                    this.errorMsg = JSON.stringify(error);
                });
        }
    }
    cancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}