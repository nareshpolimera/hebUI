import { LightningElement, api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import FileCommunicationChannel from '@salesforce/messageChannel/FileCommunicationChannel__c';
import getDocumentClassificationRecords from '@salesforce/apex/fileUploadController.getDocumentClassificationRecords';
import getRelatedPropertyMemberRecords from '@salesforce/apex/fileUploadController.getRelatedPropertyMemberRecords';
import getRelatedDebtRecords from '@salesforce/apex/fileUploadController.getRelatedDebtRecords';
import getRelatedAppraisalRecords from '@salesforce/apex/fileUploadController.getRelatedAppraisalRecords';
import getRelatedPropertyRecords from '@salesforce/apex/fileUploadController.getRelatedPropertyRecords';
import getRelatedApplicantRecords from '@salesforce/apex/fileUploadController.getRelatedApplicantRecords';
import getLeadRecords from '@salesforce/apex/fileUploadController.getLeadRecords';
import getFileRecords from '@salesforce/apex/fileUploadController.getFileRecords';
import getFileProperties from '@salesforce/apex/fileUploadController.getFileProperties'; 
import {MessageContext,publish} from 'lightning/messageService';
import uploadFile from '@salesforce/apex/fileUploadController.uploadFile';

export default class FileUploader extends LightningElement {
    @api recordId;
    document_types_option_list = [];
    related_entity_option_list = [];
    selected_document_type;
    selected_related_entity;
    related_entity_name;
    document_type_element;
    related_entity_element;
    uploaded_file;
    uploaded_file_size;
    max_file_size;
    DCObject = {};
    value;
    accepted_extensions
    display

    connectedCallback() {
        getDocumentClassificationRecords()
            .then(result => {
                result.forEach(record => {
                    const doc_type = record.Document_Type__c;
                    const doc_related_entity = record.Related_Entity__c;

                    this.document_types_option_list = [...this.document_types_option_list, {
                        label: doc_type,
                        value: doc_type
                    }]

                    this.DCObject[doc_type] = doc_related_entity;
                })
            })
            .catch(error => {
                console.log('error' + error);
            });

        getFileProperties()
            .then(result => {
                console.log('file properties are ', result)
                this.accepted_extensions = result.Accepted_File_Extension__c;
                this.max_file_size = result.File_Upload_Limit__c;
            })
    }

    @wire(MessageContext)
    context 
    handleDocumentSelection(event) {
        this.related_entity_option_list = '';
        this.value = '';
        this.selected_document_type = event.detail.value;
        const related_entity = this.DCObject[event.detail.value];
        console.log('>>>related_entity > '+related_entity); 
        if (related_entity === 'Contact') {
            getRelatedPropertyMemberRecords({ oppId: this.recordId })
                .then(result => {
                    if (result.length > 0) {
                        this.customValidationForEntity(false,'Contact')
                        result.forEach(record => {
                            const pm_name = record.Name__c;
                            const related_entity = 'Contact';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: pm_name,
                                value: record.Id
                            }]
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'Contact')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });
        }

        else if (related_entity === 'Account') {
            getRelatedPropertyMemberRecords({ oppId: this.recordId })
                .then(result => {
                    console.log('result ', result);
                    if (result.length > 0) {
                        this.customValidationForEntity(false,'Account')
                        result.forEach(record => {
                            const pm_name = record.Name;
                            const related_entity = 'Account';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: pm_name,
                                value: record.Id
                            }]
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'Account')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });
        }

        else if (related_entity === 'LoanApplicationLiability') {
            getRelatedDebtRecords({ oppId: this.recordId })
                .then(result => {
                    console.log('result ', result);
                    if (result.length > 0) {
                        this.customValidationForEntity(false,'Application Liabilities')
                        result.forEach(record => {
                            const debt_name = record.Name + ' ' + record.Debt_Identifier__c;
                            const related_entity = 'Application Liabilities';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: debt_name,
                                value: record.Id
                            }]
                        })
                    }
                    else {
                        console.log('There are no related entities Application Liabilities')
                        this.customValidationForEntity(true,'Application Liabilities')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });

        }

        else if (related_entity === 'LoanApplicant') {
            getRelatedApplicantRecords({ oppId: this.recordId })
                .then(result => {
                    console.log('result ', result);
                    if (result.length > 0) {
                        this.customValidationForEntity(false,'Loan Applicant')
                        result.forEach(record => {
                            const apct_name = record.Name;
                            const related_entity = 'Loan Applicant';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: apct_name,
                                value: record.Id
                            }]
                        })
                    }
                    else {
                        console.log('There are no related entities Loan Applicant')
                        this.customValidationForEntity(true,'Loan Applicant')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });

        }

        else if (related_entity === 'Appraisal__c') {
            getRelatedAppraisalRecords({ oppId: this.recordId })
                .then(result => {                    
                    console.log('result ', result);
                    if (result.length > 0){
                        this.customValidationForEntity(false,'Appraisal')
                        result.forEach(record => {
                            const appraisal_name = record.Name;
                            const related_entity = 'Appraisal';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: appraisal_name,
                                value: record.Id
                            }]
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'Appraisal')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });

        }
        else if (related_entity === 'LoanApplicationProperty') {
            getRelatedPropertyRecords({ oppId: this.recordId })
                .then(result => {
                    console.log('result ', result);
                    if (result.length > 0){
                        this.customValidationForEntity(false,'Application Property')
                        result.forEach(record => {
                            const property_name = record.Name;
                            const property_identifier = record.PropertyStreet + ' ' + record.PropertyCity + ' ' + record.PropertyState + ' ' + record.PropertyPostalCode + ' ' + record.PropertyCountry + ' ' + (record.Property_Identifier__c != null ? record.Property_Identifier__c : '');
                            const related_entity = 'Application Property';
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: property_identifier,
                                value: record.Id
                            }]
                            this.value = this.related_entity_option_list[0].value;
                            this.selected_related_entity = this.related_entity_option_list[0].value;
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'Application Property')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });
        }
        else if (related_entity === 'Lead') {
            getLeadRecords({ leadId: this.recordId })
                .then(result => {
                    console.log('result ', result[0]);
                    if (result.length > 0){
                        this.customValidationForEntity(false,'Lead') 
                        result.forEach(record => {
                            const lead_name = record.LastName + ' ' + record.File_Number__c;
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: lead_name,
                                value: record.Id
                            }]
                            this.value = this.related_entity_option_list[0].value;
                            this.selected_related_entity = this.related_entity_option_list[0].value;
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'Lead')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });
        }

        else if (related_entity === 'Opportunity') {
            getFileRecords({ oppId: this.recordId })
                .then(result => {
                    console.log('result ', result[0]);
                    if (result.length > 0){
                        this.customValidationForEntity(false,'File') 
                        result.forEach(record => {
                            const opp_name = record.Name + ' ' + (record.File_Number__c != null ? record.File_Number__c : '');
                            this.related_entity_option_list = [...this.related_entity_option_list, {
                                label: opp_name,
                                value: record.Id
                            }]
                            this.value = this.related_entity_option_list[0].value;
                            this.selected_related_entity = this.related_entity_option_list[0].value;
                        })
                    }
                    else{
                        this.customValidationForEntity(true,'File')
                    }
                })
                .catch(error => {
                    console.log('error' + error);
                });
        }

    }

    handleEntitySelection(event) {
        this.selected_related_entity = event.target.value;
        console.log('selected entity ', this.selected_related_entity)
    }

    fileUploadHandler(event) {
        const file = event.target.files[0]
        this.uploaded_file_size = file.size;
        const file_index = file.name.lastIndexOf('.');
        const file_extension = file.name.substring(file_index).toLowerCase();
        let file_size; 
        let nameCmp = this.template.querySelector("lightning-input");
        if (file.size > this.max_file_size) {
            file_size = this.bytesToSize(this.max_file_size);
            nameCmp.setCustomValidity('File size cannot be more than ' + file_size);
        }
        else {
            nameCmp.setCustomValidity('');
        }
        nameCmp.reportValidity();
        if (!this.accepted_extensions.includes(file_extension)) {
            nameCmp.setCustomValidity('Your selected file type is not permitted!');
        }
        else {
            nameCmp.setCustomValidity('');
        } 
        console.log('file size :: ', file.size)
        let reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.uploaded_file = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.selected_related_entity
            }
            console.log(this.uploaded_file)
        }
        reader.readAsDataURL(file)
    }

    submitHandler(event) {
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true); 
        const update_file = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true); 
        if (All_Compobox_Valid && update_file) {
            const { base64, filename, recordId } = this.uploaded_file;
            console.log('record id ', recordId)
            uploadFile({ base64, filename, recordId, documentType: this.selected_document_type, relatedEntity: this.selected_related_entity }).then(result => {
                this.uploaded_file = null
                let title = `${filename} uploaded successfully!!`
                const toastEvent = new ShowToastEvent({
                    title,
                    variant: "success"
                })
                this.dispatchEvent(toastEvent)
                this.dispatchEvent(new CloseActionScreenEvent()); 
                const message = {
                    lmsData: {
                        value: 'Success'
                    }
                }
                publish(this.context, FileCommunicationChannel, message) 
            }).catch(error => {
                console.log(error);
            });
        } 
    }

    bytesToSize(bytes) {
        console.log('bytesToSize called :: ', bytes)
        var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        if (bytes == 0) return 'n/a';
        var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
        if (i == 0) return bytes + ' ' + sizes[i];
        return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
    }

    customValidationForEntity(value,entity) { 
        if (value === true) {
            console.log('inside method')
            let relatedCmp = this.template.querySelector(".RelatedEntity");
            relatedCmp.setCustomValidity(`There is no ${entity} available`);
            relatedCmp.reportValidity();
        }
        else if (value === false) {
            let relatedCmp = this.template.querySelector(".RelatedEntity");
            relatedCmp.setCustomValidity('');
            relatedCmp.reportValidity();
        } 
    } 
}