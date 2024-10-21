import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomMetadata from '@salesforce/apex/CustomMetadataLWCServices.getCustomMetadata';
import getReferalAssociations from '@salesforce/apex/CreateNewAccount.getReferalAssociations';
import init from '@salesforce/apex/CreateNewAccountLWCHandler.init';
import submitRecords from '@salesforce/apex/CreateNewAccount.submitRecords';
import generateQuotes from '@salesforce/apex/CreateNewAccount.generateQuotes';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import Account_OBJECT from "@salesforce/schema/Account";
import Salutation from "@salesforce/schema/Contact.Salutation__c";
import Language from "@salesforce/schema/Contact.Language__c";
import Contact_OBJECT from "@salesforce/schema/Contact";
import GenderType from "@salesforce/schema/LoanApplicant.GenderType";
import LoanApplicant_OBJECT from "@salesforce/schema/LoanApplicant";
import MaritalStatus from "@salesforce/schema/LoanApplicant.MaritalStatus";
import File_OBJECT from "@salesforce/schema/Opportunity";
import LeadSource from "@salesforce/schema/Opportunity.LeadSource";
import FileType from "@salesforce/schema/Opportunity.File_Type__c";
import CASL_Consent from "@salesforce/schema/Account.CASL_Consent__c";
import Channel from "@salesforce/schema/Opportunity.Channel__c";
import LoanApplicationProperty_OBJECT from "@salesforce/schema/LoanApplicationProperty";
import PropertyType from "@salesforce/schema/LoanApplicationProperty.Property_Type__c";
import LoanPurpose from "@salesforce/schema/LoanApplicationProperty.Loan_Purpose__c";
import ReferralChannel from "@salesforce/schema/Opportunity.Referral_Channel__c";
import PropertyMR_OBJECT from "@salesforce/schema/Property_Member_Relationship__c";
import RelationshipCategory from "@salesforce/schema/Property_Member_Relationship__c.Relationship_Category__c";
import RelationshipType from "@salesforce/schema/Property_Member_Relationship__c.Relationship_Type__c";
import Id from "@salesforce/user/Id";
import fetchFSAByParams from '@salesforce/apex/PropertyAddressValidatorController.fetchFSAByParams';

export default class CreateNewAccountLWC  extends NavigationMixin(LightningElement) {


_selected=[];
@track recordId;
userId = Id;
@api selectedRecordType;
@api selectedContactId;
@track isLoaded = false;
@track openmodel = false;
@track recordTypeOptions;
@track isReferredLeadType = false;
@track isMailingAddressSameAsProperty = true;
@track defaultChannel;
@track showSpinner = false;
@track isReferralChannelRequired = false;
@track submitDisabled = false;
@track isFileSourceRequired = false;
@track isLanguageRequired = false;
@track isFileTypeRequired = false;
@track isLastNameRequired = true;
@track isFileChannelRequired = true;
defaultFileType = 'Reverse Mortgage';
defaultLanguage = 'English';
duplicateRecords;
referralPartnerId = '';
@track contactId;
@track contactTerritoryType;
@track todaysDate;
accountRecordTypeId;
@track salutationOptions;
contactRecordTypeId;
loanApplicantRecordTypeId;
@track maritalStatusOptions;
@track genderOptions;
opportunityRecordTypeId;
lapRecordTypeId;
propertyMRRecordTypeId;
@track fileTypeOptions;
@track fileSourceOptions;
allfileSourceOptions;
optionsDependent;
@track consentCASLConsentOptions;
@track fileLanguageOptions;
@track fileChannelOptions;
@track propertyTypeOptions;
@track loanOptions;
@track partnerReferralChannelOptions;
@track relationshipCategoryOptions;
@track relationshipTypeOptions;
@track relationshipTypeOptionsAll;
@track propertyAddress = {
    street: '',
    city: '',
    province: '',
    postalCode: '',
    country: 'Canada'
};

@track PersonMailingAddress = {
    street: '',
    city: '',
    province: '',
    postalCode: '',
    country: 'Canada'
};

@track Property ={
    selectedCountry : 'Canada',
    selectedCity : '',
    selectedPostalCode : '',
    selectedProvince: '',
    street :'',
    propertyType : ''
};

@track PrimaryContact = {
    isPrimaryContact : false,
    isMailingAddressSameAsProperty : true,
    salutation : '',
    firstName : '',
    lastName : '',
    dateOfBirth:'',
    phone : '',
    email : '',
    primaryCity : '',
    primaryCountry : 'Canada',
    primaryPostalCode : '',
    primaryProvince : '',
    primaryStreet : '',

};

get PropertyMember1(){
    return this.fileData.PropertyMemberOne;
} 
get PropertyMember2() {
    return this.fileData.PropertyMemberTwo;
}

@track isAddressValidatorDisplayed = false;

@track fileData = {
    primaryAccount : {
        FirstName : '',
        LastName : '',
        Salutation : '',
        Phone : '',
        Email : '',
        isMailingAddressSameAsProperty : true,
        CountryCode: 'Canada',
        Street : '',
        City : '',
        State : '',
        Zip : ''
    },
    PropertyMemberOne : {
        isPrimaryContact : false,
        salutation : '',
        firstName : '',
        lastName : '',
        phone : '',
        email : '',
        age : '',
        gender : '',
        dateOfBirth : '',
        maritalStatus : '',
        primaryCity : '',
        primaryCountry : 'Canada',
        primaryPostalCode : '',
        primaryProvince : '',
        primaryStreet : '',
        isMailingAddressSameAsProperty : true,
        isPrimaryBorrower : true,
        controlling   : '',
        dependent : ''
    },
    PropertyMemberTwo : {
        isPrimaryContact : false,
        salutation : '',
        firstName : '',
        lastName : '',
        phone : '',
        email : '',
        age : '',
        gender : '',
        dateOfBirth : '',
        maritalStatus : '',
        primaryCity : '',
        primaryCountry : 'Canada',
        primaryPostalCode : '',
        primaryProvince : '',
        primaryStreet : '',
        isMailingAddressSameAsProperty : true,
        isPrimaryBorrower : false,
        controlling   : '',
        dependent : ''
    },

    fileDetails : {
        Source : '',
        Type : 'Reverse Mortgage',
        Language : 'English',
        Channel : ''
    },
    
    partnerDetails : {
        ReferralChannel : '',
        Territory : '',
        ReferralPartner : '',
        ReferralOrganization : ''
    },

    consent : {
        CASLConsent : '',
        CASLConsentObtainedBy : this.userId,
        CASLConsentProvidedOn :''
    },

    property : {
        PropertyType : '',
        HomeValue : '',
        CountryCode: 'Canada',
        Street : '',
        City : '',
        State : '',
        Zip : ''
    },
    LoanPurpose : [],
};

filterReferralPartner = {
    criteria:[
        {
        fieldPath: 'RecordType.Name',
        operator: 'eq',
        value: 'Partner'
        }
    ]
}; 
filterSubmissionPartner = {
    criteria:[
        {
        fieldPath: 'Account.RecordType.Name',
        operator: 'eq',
        value: 'Partner'
        }
    ]
};

/** *
 * In the connected callback we:
 * 1. Set this.todaysDate
 * 2. Call init() from apex controller to load parameters from backend.
 *    TODO: Improve this to reduce hardcoded values i.e picklists
*/
connectedCallback() {  

    const queryString = window.location.search;
    const urlParams = new URLSearchParams(queryString);
    const params = urlParams.get('ws')
    this.fullDate = new Date();
    this.fullMonth = this.fullDate.getMonth() + 1;
    this.todaysDate = this.fullDate.getFullYear().toString() +'-'+this.fullMonth.toString() +'-'+this.fullDate.getDate().toString();
    console.log('fulldate::'+this.todaysDate);
        
    this.isLoaded = false;
    
    init()
        .then((result) => {
            if(!this.selectedRecordType){
                this.selectedRecordType = result.accountRecordTypeId;
            }
            this.recordTypeOptions = result.recordTypeOptions;
            if(this.recordTypeOptions.length > 0){
                for(let i = 0; i < this.recordTypeOptions.length; i++){
                    if(this.recordTypeOptions[i].label === 'Client' && this.recordTypeOptions[i].value === this.selectedRecordType){
                        this.isReferredLeadType = true;
                        }
                }
            }
            this.isLoaded = true;
        })
        .catch((error) => {
            console.log('error.body.message ', error.body.message); 
            this.isLoaded = true;
            this.showToast('Error', error.body.message, 'Error');
        })
}
isRendered = false;
renderedCallback(){
    if(!this.isRendered){
        this.isRendered = true;
        console.log('selectedRecordType: ', this.selectedRecordType);
    }
    
}

@wire(getCustomMetadata , { metadataName: 'Dependent_Picklist_Settings__mdt', 
    fields:['Controller_value__c', 'Object__c','Picklist__c','Values__c','Dependent_Picklist__c'],
    filters: 'Object__c = \'Opportunity\''
})
wiredMetadata({ error, data }) {
    //console.log('get Dependent_Picklist_Settings__mdt: '+JSON.stringify(data));
    if (data) {
        this.optionsDependent = data;
        console.log('optionsDependent: '+JSON.stringify(this.optionsDependent));
    }
}

@wire(getObjectInfo, { objectApiName: Contact_OBJECT })
results({ error, data }) {
if (data) {
    this.contactRecordTypeId = data.defaultRecordTypeId;
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.contactRecordTypeId = undefined;
}
}

@wire(getPicklistValues, { recordTypeId: "$contactRecordTypeId", fieldApiName: Salutation })
picklistResults({ error, data }) {
if (data) {
    //this.salutationOptions = data.values;
    this.salutationOptions = Object.assign([], data.values);
    this.salutationOptions.unshift({
        value: undefined,
        label: '--None--',
    });
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.salutationOptions = undefined;
}
}
@wire(getObjectInfo, { objectApiName: LoanApplicant_OBJECT })
results1({ error, data }) {
if (data) {
    this.loanApplicantRecordTypeId = data.defaultRecordTypeId;
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.loanApplicantRecordTypeId = undefined;
}
}
@wire(getObjectInfo, { objectApiName: File_OBJECT })
results2({ error, data }) {
if (data) {
    this.opportunityRecordTypeId = data.defaultRecordTypeId;
    console.log('opportunityRecordTypeId----'+this.opportunityRecordTypeId);
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.opportunityRecordTypeId = undefined;
}
}
@wire(getObjectInfo, { objectApiName: Account_OBJECT })
results3({ error, data }) {
if (data) {
    this.accountRecordTypeId = data.defaultRecordTypeId;
    console.log('accountRecordTypeId----'+this.accountRecordTypeId);
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.accountRecordTypeId = undefined;
}
}

@wire(getObjectInfo, { objectApiName: LoanApplicationProperty_OBJECT })
results4({ error, data }) {
if (data) {
    this.lapRecordTypeId = data.defaultRecordTypeId;
    console.log('lapRecordTypeId----'+this.lapRecordTypeId);
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.lapRecordTypeId = undefined;
}
}

@wire(getObjectInfo, { objectApiName: PropertyMR_OBJECT })
results5({ error, data }) {
if (data) {
    this.propertyMRRecordTypeId = data.defaultRecordTypeId;
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.propertyMRRecordTypeId = undefined;
}
}

@wire(getPicklistValues, { recordTypeId: "$loanApplicantRecordTypeId", fieldApiName: MaritalStatus })
picklistResults1({ error, data }) {
if (data) {
    this.maritalStatusOptions = data.values;
    this.error = undefined;
} else if (error) {
    this.error = error;
    this.maritalStatusOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$loanApplicantRecordTypeId", fieldApiName: GenderType })
picklistResults2({ error, data }) {
if (data) {
    this.genderOptions = data.values;
    this.error = undefined;
} else if (error) {    
    this.error = error;
    this.genderOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$opportunityRecordTypeId", fieldApiName: LeadSource })
picklistResults3({ error, data }) {
if (data) {
    this.allfileSourceOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.allfileSourceOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$opportunityRecordTypeId", fieldApiName: FileType })
picklistResults4({ error, data }) {
if (data) {
    this.fileTypeOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.fileTypeOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$accountRecordTypeId", fieldApiName: CASL_Consent })
picklistResults5({ error, data }) {
if (data) {
    this.consentCASLConsentOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.consentCASLConsentOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$contactRecordTypeId", fieldApiName: Language })
picklistResults6({ error, data }) {
if (data) {
    this.fileLanguageOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.fileLanguageOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$opportunityRecordTypeId", fieldApiName: Channel })
picklistResults7({ error, data }) {
if (data) {
    this.fileChannelOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.fileChannelOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$lapRecordTypeId", fieldApiName: PropertyType })
picklistResults8({ error, data }) {
if (data) {
    this.propertyTypeOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.propertyTypeOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$lapRecordTypeId", fieldApiName: LoanPurpose })
picklistResults9({ error, data }) {
if (data) {
    this.loanOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.loanOptions = undefined;
}
}
@wire(getPicklistValues, { recordTypeId: "$opportunityRecordTypeId", fieldApiName: ReferralChannel })
picklistResults10({ error, data }) {
if (data) {
    this.partnerReferralChannelOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.partnerReferralChannelOptions = undefined;
}
}

@wire(getPicklistValues, { recordTypeId: "$propertyMRRecordTypeId", fieldApiName: RelationshipCategory })
picklistResults11({ error, data }) {
if (data) {
    this.relationshipCategoryOptions = data.values;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.relationshipCategoryOptions = undefined;
}
}

@wire(getPicklistValues, { recordTypeId: "$propertyMRRecordTypeId", fieldApiName: RelationshipType })
picklistResults12({ error, data }) {
if (data) {
    this.relationshipTypeOptionsAll = data;
    this.error = undefined;

} else if (error) {    
    this.error = error;
    this.relationshipTypeOptionsAll = undefined;
}
}

// onSubmitHandler(event) {
//     console.log('test submit');

//     this.fileData.primaryAccount = this.PrimaryContact;
//     this.fileData.property.City = this.Property.selectedCity;
//     this.fileData.property.CountryCode = this.Property.selectedCountry;
//     this.fileData.property.Zip = this.Property.selectedPostalCode;
//     this.fileData.property.State = this.Property.selectedProvince;
//     this.fileData.property.Street = this.Property.street;

//     console.log('final fileData: ');
//     console.log(JSON.stringify(this.fileData));

    /**  
     *  1. Validate fileData.PrimaryAccount
     *  1.1 (if applicable) Validate primary accounts address
     *  2. Validate Property Address 
     *  3. Validate Borrower 1
     *  4. Validate Borrower 2
     *  5. Submit to backend for processessing
     * 
     * 
     * 
     * **/

    /** THIS IS HOW THEY USE TO VALIDATE THE LEAD:
    // let createLeadFlag = false;     
    // console.log('onsubmit event recordEditForm' + event.detail.fields);

    // event.preventDefault();

    // this.leadData = event.detail.fields;
    // this.leadData.Segment__c = 'Standard';
    // this.leadData.Sales_Process__c = 'Remote';
    // this.leadData.Channel__c = this.defaultChannel;
    // this.leadData.Loan_Purpose__c = this._selected;
    
    // if(this.isMailingAddressSameAsProperty){
    //     this.leadData.City = this.Property.selectedCity;
    //     this.leadData.CountryCode = this.Property.selectedCountry;
    //     this.leadData.StateCode = this.Property.selectedProvince;
    //     this.leadData.Street = this.Property.street;
    //     this.leadData.PostalCode = this.Property.selectedPostalCode;
    // }else{
    //     this.leadData.City = this.leadAddress.city;
    //     this.leadData.CountryCode = this.leadAddress.country;
    //     this.leadData.StateCode = this.leadAddress.province;
    //     this.leadData.Street = this.leadAddress.street;
    //     this.leadData.PostalCode = this.leadAddress.postalCode;
    // }
    // if (this.PropertyMember1.isPrimaryContact) {
    //     this.PropertyMember1.salutation = this.leadData.Salutation;
    //     this.PropertyMember1.firstName = this.leadData.FirstName;
    //     this.PropertyMember1.lastName = this.leadData.LastName;
    //     this.PropertyMember1.primaryCity = this.leadData.City;
    //     this.PropertyMember1.primaryCountry = this.leadData.CountryCode;
    //     this.PropertyMember1.primaryProvince = this.leadData.StateCode;
    //     this.PropertyMember1.primaryStreet = this.leadData.Street;
    //     this.PropertyMember1.primaryPostalCode = this.leadData.PostalCode;
    //     this.PropertyMember1.isMailingAddressSameAsProperty=false;
    // }

    // if(this.checkIsPropertyMember1Avail() && this.checkIsPropertyMember2Avail()){            
    //     //this.insertLead();
    //     createLeadFlag = true;
    // }
    // else if((this.PropertyMember1.lastName == '') && !this.checkIsPropertyMember2Avail()){
    //     this.showToast('Error Creating Lead', 'Borrower1 should be given before Borrower2', 'Error');
    // } else if(!this.checkIsPropertyMember1Avail() && this.checkIsPropertyMember2Avail()){
    //     this.setBorrowerLastNameRequired();

    //     if(this.isPropertyMemberOneLastNameRequired==false){                
    //         //this.insertLead();
    //         createLeadFlag = true;
    //     }
    // } else if(!this.checkIsPropertyMember1Avail() && !this.checkIsPropertyMember2Avail()){
    //     this.setBorrowerLastNameRequired();
        
    //     if(this.isPropertyMemberOneLastNameRequired == false && this.isPropertyMemberTwoLastNameRequired == false){                
    //         //this.insertLead();
    //         createLeadFlag = true;
    //     }
    // } **/

    // // insertLead method will be invoked only if the address is selected correctly 
    // //let thisTemplate = this.template.querySelector("c-property-address-validator");
    // if(createLeadFlag) {
    //     if(this.Property.selectedPostalCode ) {
    //         let params = {
    //             city : this.Property.selectedCity, 
    //             province : this.Property.selectedProvince, 
    //             zip : this.Property.selectedPostalCode
    //         }
    //         console.log('Params sent to Popup : ', params);
    //         fetchFSAByParams(params).then((result) => {
    //             if(result.length == 0) {
    //                 this.isAddressValidatorDisplayed = true;
    //                 //thisTemplate.openModal();
    //             } else {
    //                 this.insertLead();
    //                 this.isAddressValidatorDisplayed = false;
    //             }
    //         }).catch((error) => {
    //             console.log('Exception/ Error : ', error);
    //             this.isAddressValidatorDisplayed = false;
    //         });

    //         //If postal Code is not provided then directly perform Lead operations in "insertLead"
    //         /*if(!this.Property.selectedPostalCode) {
    //             this.insertLead();
    //         }*/
    //     } else {
    //            this.createApplication();
    //     }
    // } */
    
//}

checkIsPropertyMember2Avail(){
    if((this.PropertyMember2.salutation == '' && this.PropertyMember2.firstName == '' && 
                this.PropertyMember2.age == '' &&  this.PropertyMember2.dateOfBirth == '' &&
                this.PropertyMember2.maritalStatus == '' &&  this.PropertyMember2.gender == ''  &&  
                this.PropertyMember2.lastName == ''))
    {
        return true;
    }
    else {
        return false;
    }
}
checkIsPropertyMember1Avail(){
    if((this.PropertyMember1.salutation == '' && this.PropertyMember1.firstName == '' && 
    this.PropertyMember1.age == '' &&  this.PropertyMember1.dateOfBirth == '' &&
    this.PropertyMember1.maritalStatus == '' &&  this.PropertyMember1.gender == ''  &&  
    this.PropertyMember1.lastName == ''))
    {
    return true;
    }
    else {
    return false;
    }
}

setBorrowerLastNameRequired(){

    let isProp2Avail = this.checkIsPropertyMember2Avail();

    if((this.PropertyMember1.salutation !== '' || this.PropertyMember1.firstName !== '' || 
                this.PropertyMember1.age !== '' || this.PropertyMember1.dateOfBirth !== '' || 
                this.PropertyMember1.maritalStatus !== ''||  this.PropertyMember1.gender !== '') 
                &&  this.PropertyMember1.lastName == '')
    {
        this.isPropertyMemberOneLastNameRequired = true;
    }
    else{
        this.isPropertyMemberOneLastNameRequired = false;
    }
    
    if(!isProp2Avail) {
            if((this.PropertyMember2.salutation !== '' || this.PropertyMember2.firstName !== '' || 
            this.PropertyMember2.age !== '' ||  this.PropertyMember2.dateOfBirth !== ''|| this.PropertyMember2.maritalStatus !== ''|| 
            this.PropertyMember2.gender !== '') && this.PropertyMember2.lastName == '')
            {
                this.isPropertyMemberTwoLastNameRequired = true;
            }
            else
            {
                this.isPropertyMemberTwoLastNameRequired = false;
            }
        }      
}


@track PropertyMemberOnePropertyMemberInfo;
@track PropertyMemberTwoPropertyMemberInfo;

onSubmitHandler(event) {
    this.fileData.primaryAccount = this.PrimaryContact;
    this.fileData.property.City = this.Property.selectedCity;
    this.fileData.property.CountryCode = this.Property.selectedCountry;
    this.fileData.property.Zip = this.Property.selectedPostalCode;
    this.fileData.property.State = this.Property.selectedProvince;
    this.fileData.property.Street = this.Property.street;

    //console.log('final fileData: ');
    //console.log(JSON.stringify(this.fileData));

    // Perform client-side validation first
    const validationErrors = this.validateRequiredFields();
    if (validationErrors.length > 0) {
        this.showToast('Error', 'The following mandatory fields are missing:\n' + validationErrors.join(', '), 'error');
        return; 
        // Exit the method if there are validation errors
    }

    //show spinner
    this.showSpinner = true;
    //validate address postal code
    console.log('validateAddress : ', JSON.stringify(this.Property));
    if(this.Property.selectedPostalCode) {
        let params = {
            city : this.Property.selectedCity, 
            province : this.Property.selectedProvince, 
            zip : this.Property.selectedPostalCode
        }
        console.log('Params sent to Popup : ', params);
        fetchFSAByParams(params).then((result) => {
            if(result.length == 0) {
                this.isAddressValidatorDisplayed = true;
                this.showSpinner = false;
            } else {
                this.isAddressValidatorDisplayed = false;
                this.createApplication();                              
            }
        }).catch((error) => {
            console.log('Exception/ Error : ', error);
            this.isAddressValidatorDisplayed = false;
            this.showSpinner = false;
        });
    }   
    else{
        this.createApplication();   
    } 
}

createApplication() {

    console.log('calling submitRecords:');
    let fileDataString = JSON.stringify(this.fileData);

    submitRecords({ wrapperString: fileDataString })
        .then((result) => {
            console.log('result account==', result);
            this.recordId = result;
            this.showSpinner = false;
            this.isLoaded = false;
            this.isLoaded = true;
            this.duplicateRecords = undefined;
            this.showToast('Success', 'Account Created Successfully', 'success');  
            if(this.recordId){
                generateQuotes({ accountId: this.recordId })
                .then((result) => {
                    console.log('Quotes Generated Successfully');
                })
                .catch((error) => {
                    console.log('Generating Quote Error: ', error);
                });
            }
            this.navigateToAccount(this.recordId);
        })
        .catch((error) => {
            console.log('Insert Account error ', error);
            this.showSpinner = false;
            var message = error.body.message;

            if (message && message.includes('Duplicates Found')) {
                this.duplicateRecords = JSON.parse(message.substring(41));
                this.showToast('Error Creating Account', 'Duplicates Found!', 'warning', 'dismissable');
            } else {
                this.showToast('Error Creating Account', message, 'error');
            }
        });
}

showToast(title, message, variant, mode = 'dismissable') {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant,
            mode
        })
    );
}



validateRequiredFields() {
    const errors = [];
    
    if (this.isFileChannelRequired && !this.fileData.fileDetails.Channel) {
        errors.push('File Channel');
    }
    if (this.isLastNameRequired && !this.PrimaryContact.lastName) {
        errors.push('Last Name');
    }
    if (this.isReferralChannelRequired && !this.fileData.partnerDetails.ReferralChannel) {
        errors.push('Referral Channel');
    }
    if (this.isFileSourceRequired && !this.fileData.fileDetails.Source) {
        errors.push('File Source');
    }
    if (this.isLanguageRequired && !this.fileData.fileDetails.Language) {
        errors.push('Language');
    }
    if (this.isFileTypeRequired && !this.fileData.fileDetails.Type) {
        errors.push('File Type');
    }
    if(this.isContactInfoRequired){
        errors.push('Primary Phone or Email');
    }
    if(this.isContactInfoRequiredforPropOne){
        errors.push('Borrower 1 Phone or Email');
    }
    if(this.isContactInfoRequiredforPropTwo){
        errors.push('Borrower 2 Phone or Email');
    }

    //show mesasges on field
    const allRequireInputs = [...this.template.querySelectorAll('.input-required')];
    const allVald = false;
    if(allRequireInputs){
        allVald = allRequireInputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    }

    return errors;
}

get isContactInfoRequired(){
    if( this.isLastNameRequired &&
        this.PrimaryContact != null &&  
        this.PrimaryContact.phone == '' && 
        this.PrimaryContact.email == ''){
        //this.isValidOne = true;
        return true;
    }
    else {
        //.isValidOne = false;
        return false;
    }
}

closeCurrentTab(){
    const closeTab = new CustomEvent('closeTab', { detail: { status : 'handleSave'  }}) ;
    this.dispatchEvent(closeTab);
}

setPropertyMember1Info(){
    let propertyMember1Wrapper=[];
    if(this.PropertyMember1.firstName !== '' && this.PropertyMember1.lastName !== '')
    {
        if(this.PropertyMember1.isMailingAddressSameAsProperty) {
            this.fileData.PropertyMemberOne.primaryCity = this.Property.selectedCity;
            this.fileData.PropertyMemberOne.primaryCountry = this.Property.selectedCountry;
            this.fileData.PropertyMemberOne.primaryProvince = this.Property.selectedProvince;
            this.fileData.PropertyMemberOne.primaryStreet = this.Property.street;
            this.fileData.PropertyMemberOne.primaryPostalCode = this.Property.selectedPostalCode;
        }
        propertyMember1Wrapper.push(this.PropertyMember1);
    }
    this.PropertyMemberOnePropertyMemberInfo = JSON.stringify(this.PropertyMember1);

    return JSON.stringify(propertyMember1Wrapper);
}
setPropertyMember2Info(){
    let propertyMember2Wrapper=[];

    if(this.PropertyMember2.firstName !== '' && this.PropertyMember2.lastName !== ''){
        if(this.PropertyMember2.isMailingAddressSameAsProperty) {
            this.fileData.PropertyMemberTwo.primaryCity = this.Property.selectedCity;
            this.fileData.PropertyMemberTwo.primaryCountry = this.Property.selectedCountry;
            this.fileData.PropertyMemberTwo.primaryProvince = this.Property.selectedProvince;
            this.fileData.PropertyMemberTwo.primaryStreet = this.Property.street;
            this.fileData.PropertyMemberTwo.primaryPostalCode = this.Property.selectedPostalCode;
        }
        propertyMember2Wrapper.push(this.PropertyMember2);
    }
    else {
        //If no field value entered on Property member 2 setion, then  No property member relationship record created in this case.
        //    this.PropertyMember1.propertyMemberRelationship.relationshipCategory = '';
        //    this.PropertyMember1.propertyMemberRelationship.relationshipType = '';
    }

    this.PropertyMemberTwoPropertyMemberInfo = JSON.stringify(this.PropertyMember2);

    var strreq2 = JSON.stringify(propertyMember2Wrapper);
    return strreq2;
}

//@track isValidOne = false;
//@track isValidTwo = false;

get isLastNameRequiredforPropOne(){
    if( this.PropertyMember1 != null &&  
        (this.PropertyMember1.salutation != '' || 
        this.PropertyMember1.firstName != '' || 
        this.PropertyMember1.age !== '' || 
        this.PropertyMember1.dateOfBirth !== '' || 
        this.PropertyMember1.maritalStatus !== ''||  
        this.PropertyMember1.gender !== '')
        && this.PropertyMember1.lastName == '')
    {
        //this.isValidOne = true;
        return true;
    }
    else {
        //.isValidOne = false;
        return false;
    }
}

get isContactInfoRequiredforPropOne(){
    if( this.PropertyMember1 != null &&  
        this.PropertyMember1.lastName != '' &&
        this.PropertyMember1.phone == '' && 
        this.PropertyMember1.email == ''){
        //this.isValidOne = true;
        return true;
    }
    else {
        //.isValidOne = false;
        return false;
    }
}

get isLastNameRequiredforPropTwo(){
    if( this.PropertyMember2 != null &&  
        (this.PropertyMember2.salutation != '' || 
        this.PropertyMember2.firstName != '' || 
        this.PropertyMember2.age !== '' ||
        this.PropertyMember2.dateOfBirth !== '' || 
        this.PropertyMember2.maritalStatus !== ''||  
        this.PropertyMember2.gender !== '')
        && this.PropertyMember2.lastName == '')
    {
        //this.isValidTwo = true;
        return true;
    }
    else {
        
        //this.isValidTwo = false;
        return false;
    }

}

get isContactInfoRequiredforPropTwo(){
    if( this.PropertyMember2 != null &&  
        this.PropertyMember2.lastName != '' &&
        this.PropertyMember2.phone == '' && 
        this.PropertyMember2.email == ''){
        //this.isValidOne = true;
        return true;
    }
    else {
        //.isValidOne = false;
        return false;
    }
}

get propertyMember2Entered(){

    if(this.PropertyMember2.firstName !== '' && this.PropertyMember2.lastName !== ''){
        return true;
    }
    return false;
}

handlePropertyMemberInputFields(event) {
    //all valid records
    var elementname = event.target.name;
    var elementvalue = event.target.value;

    if(elementname === 'dobpm1' || elementname === 'dobpm2'){
        elementvalue = event.target.value == null ? '' : event.target.value;        
    }

    if (elementname === 'firstNamepm1') {
        this.fileData.PropertyMemberOne.firstName = elementvalue;
    } else if (elementname === 'firstNamepm2') {
        this.fileData.PropertyMemberTwo.firstName = elementvalue;
    } else if (elementname === 'lastNamepm1') {
        this.fileData.PropertyMemberOne.lastName = elementvalue;
    } else if (elementname === 'lastNamepm2') {
        this.fileData.PropertyMemberTwo.lastName = elementvalue;
    } else if (elementname === 'phonepm1') {
        this.fileData.PropertyMemberOne.phone = elementvalue;
    } else if (elementname === 'phonepm2') {
        this.fileData.PropertyMemberTwo.phone = elementvalue;
    } else if (elementname === 'emailpm1') {
        this.fileData.PropertyMemberOne.email = elementvalue;
    } else if (elementname === 'emailpm2') {
        this.fileData.PropertyMemberTwo.email = elementvalue;
    } else if (elementname === 'agepm1') {
        this.fileData.PropertyMemberOne.age = elementvalue;
    } else if (elementname === 'agepm2') {
        this.fileData.PropertyMemberTwo.age = elementvalue;
    } 
    else if(elementname === 'dobpm1'){
        this.fileData.PropertyMemberOne.dateOfBirth = elementvalue;
        //calculate age
        this.fileData.PropertyMemberOne.age = this.getAge(elementvalue);
    }
    else if(elementname === 'dobpm2'){
        this.fileData.PropertyMemberTwo.dateOfBirth = elementvalue;
        //calculate age
        this.fileData.PropertyMemberTwo.age = this.getAge(elementvalue);
    }
}

getAge(dateString) {
    if(!dateString){
        return;
    }
    var today = new Date();
    var birthDate = new Date(dateString);
    var age = today.getFullYear() - birthDate.getFullYear();
    var m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    console.log('[getAge] age: '+age);
    return age.toString();
}

handleCancel() {
    this.closeCurrentTab();
    this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
            objectApiName: 'Account',
            actionName: 'list'
        },
        state: {       
            filterName: 'Recent' 
        }
    });
}

handleRecordTypeChange(event) {
    console.log(event.detail.value);
    this.selectedRecordType = event.detail.value;
}

handleSaveModal(){
    this.isLoaded=false;
    if(!this.selectedRecordType){
        this.showToast('Error', 'Please Select RecordType!', 'Error');
    }else{
        for(let i = 0; i < this.recordTypeOptions.length; i++){
            if(this.recordTypeOptions[i].label === 'Referred Lead' && this.recordTypeOptions[i].value === this.selectedRecordType){
                this.isReferredLeadType = true;
                break;
            }
        }
        this.openmodel = false;
    }
    this.isLoaded=true;
}
@track isModalOpen = true;
closeModal() {
    this.openmodel = false;
}
closeErrorModal(){
    //event.preventDefault();
    
    this.isModalOpen = false;
    this.duplicateRecords = undefined;
}

showToast(title, message, variant,mode) {
    this.dispatchEvent(new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    })
    );
}

navigateToAccount(account) {
    this.isLoaded=false;
    this.isLoaded=true;
    this.closeCurrentTab();
    window.open(window.location.origin + '/lightning/r/Account/' +account+ '/view','_top');
}

navigateToAccountURL(account){
    this.isLoaded=false;
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            //https://homeequitybank--devm3.lightning.force.com/lightning/r/Lead/00Q2F000008lo7FUAQ/view 
            url: window.location.origin + '/lightning/r/Account/' +lead+ '/view' 
        }
    },true);
    this.isLoaded=true;
}

fsaSelectionHandler(event) {
    console.log('Data from popup ', event.detail);
    if(event.detail) { 
        this.Property.selectedCity = event.detail.City__c;
        this.Property.selectedProvince = event.detail.Province__c ;
        this.Property.selectedPostalCode = 
        (this.Property.selectedPostalCode.length<=3) ?
            event.detail.FSA__c : this.Property.selectedPostalCode;
        console.log('propertypostalcode'+this.Property.selectedPostalCode);
        this.propertyAddress.city = event.detail.City__c;
        this.propertyAddress.province = (event.detail.Province__c) ? event.detail.Province__c : "";
        this.propertyAddress.postalCode = (this.Property.selectedPostalCode.length<=3) ?
            event.detail.FSA__c : this.Property.selectedPostalCode;
        console.log('propertyaddresspostalcode'+this.propertyAddress.postalCode);
        this.Property = JSON.parse(JSON.stringify(this.Property));
        this.propertyAddress = JSON.parse(JSON.stringify(this.propertyAddress));
    }
    this.isAddressValidatorDisplayed = false;
}

handleAccountRecordClick(event) {
    let recordId = event.currentTarget.dataset.id;
    window.open(window.location.origin + '/lightning/r/Account/' + recordId + '/view', '_top');
}


// FORM DATA CHANGE HANDLERS
handleFileSourceChange(event) {
    this.fileData.fileDetails.Source = event.detail.value;
}
handleFileTypeChange(event) {
    this.fileData.fileDetails.Type = event.detail.value;
}
handleFileLanguageChange(event) {
    this.fileData.fileDetails.Language = event.detail.value;
}
handleFileChannelChange(event) {
    this.fileData.fileDetails.Channel = event.detail.value;
    if(event.target.value === 'Referred' ||
        event.target.value === 'Wealth Management' ||
        event.target.value === 'Mortgage Broker Direct'){
        this.isReferralChannelRequired = true;
        this.isFileSourceRequired = true;
        this.isLanguageRequired = true;
        this.isFileTypeRequired = true;
        this.isLastNameRequired = true;
    }
    else if(event.target.value === 'Consumer'){
        this.isLastNameRequired = true;
        this.isFileSourceRequired = true;
        this.isLanguageRequired = true;
        this.isFileTypeRequired = true;
        this.isReferralChannelRequired = false;
    }
    else {
        this.isLastNameRequired = true;
        this.isFileSourceRequired = false;
        this.isLanguageRequired = false;
        this.isFileTypeRequired = false;
        this.isReferralChannelRequired = false;
    }
    
    //filter File Source picklist based on channel
    this.fileSourceOptions = this.handleFilterPicklist('Channel__c',event.target.value,'LeadSource',this.allfileSourceOptions);
    //clear selected file source
    this.fileData.fileDetails.Source = '';
}
handleFilterPicklist(controllerField,controllerValue,dependentField,tofilter){
    let results = [];
    if(this.optionsDependent && tofilter){
        //console.log('[handleFilterPicklist] star: '+JSON.stringify(tofilter));
        this.optionsDependent.forEach(function(settings){
            //console.log('[handleFilterPicklist] settings: '+JSON.stringify(settings));
            if(settings.Picklist__c ==  controllerField &&
                settings.Dependent_Picklist__c == dependentField &&
                settings.Controller_value__c == controllerValue){
                results = tofilter.filter((opt) => settings.Values__c.toLowerCase().includes(opt.value.toLowerCase()));
            }
        });
    }
    //console.log('[handleFilterPicklist] results: '+JSON.stringify(results));
    return results;
}
handlePartnerReferralChannelChange(event) {
    this.fileData.partnerDetails.ReferralChannel = event.detail.value    
}
handlePartnerSubmissionAgentChange(event) {
    this.fileData.partnerDetails.SubmissionAgent = event.detail.recordId;
}
handlePartnerTerritoryChange(event) {
    this.fileData.partnerDetails.Territory = event.detail.recordId;
}
handlePartnerReferralPartnerChange(event) {
    this.fileData.partnerDetails.ReferralPartner = event.detail.recordId;
    this.referralPartnerId = event.detail.recordId;
    //get partner referal related lookups
    this.handleGetPartnerAssociations();
}
handlePartnerReferralOrganizationChange(event) {
    this.fileData.partnerDetails.ReferralOrganization = event.detail.recordId;
}
handleConsentCASLConsentChange(event) {
    this.fileData.consent.CASLConsent = event.detail.value;
}
handleConsentCASLConsentObtainedByChange(event) {
    this.fileData.consent.CASLConsentObtainedBy = event.detail.recordId;
}
handleConsentCASLConsentProvidedOnChange(event) {
    this.fileData.consent.CASLConsentProvidedOn = event.detail.value;
}
handlePropertyTypeChange(event){
    this.fileData.property.PropertyType = event.detail.value;
    this.Property.propertyType = event.detail.value;
}
handlePropertyHomeValueChange(event) {
    this.fileData.property.HomeValue = event.detail.value;
}
handleRelationshipCategoryChange(event) {
    this.fileData.PropertyMemberTwo.RelationshipCategory = event.detail.value;
    let key = this.relationshipTypeOptionsAll.controllerValues[event.target.value];
    this.relationshipTypeOptions = this.relationshipTypeOptionsAll.values.filter(opt => opt.validFor.includes(key));
}
handleRelationshipTypeChange(event) {
    this.fileData.PropertyMemberTwo.RelationshipType = event.detail.value;
}
handlePrimaryContactSalutationChange(event){
    this.PrimaryContact.salutation = event.detail.value;
}
handlePrimaryContactFirstNameChange(event){
    this.PrimaryContact.firstName = event.detail.value;
}
handlePrimaryContactLastNameChange(event){
    this.PrimaryContact.lastName = event.detail.value;
}
handlePrimaryContactDateOfBirthChange(event){
    this.PrimaryContact.dateOfBirth = event.detail.value;
}
handlePrimaryContactPhoneChange(event){
    this.PrimaryContact.phone = event.detail.value;
}
handlePrimaryContactEmailChange(event){
    this.PrimaryContact.email = event.detail.value;
}
handleOnChangeAddressSameCheckbox(event){
    if(!event.target.checked){
        this.PrimaryContact.isMailingAddressSameAsProperty = false;
    }else{
        this.PrimaryContact.isMailingAddressSameAsProperty = true;
    }
}
handlePropertyAddressChange(event){
    this.Property.selectedCity = event.detail.city;
    this.Property.street= event.detail.street;
    this.Property.selectedProvince = event.detail.province;
    this.Property.selectedPostalCode = event.detail.postalCode;
    this.Property.selectedCountry = event.detail.country;
    this.validatePostalCode('PropertyAddressChange');
}

validatePostalCode(classname){
    const address = this.template.querySelector("."+classname);
    //Country Field Validation
    const regex = "[A-Z]\\d[A-Z]\\d[A-Z]\\d";
    var postalCode = address.postalCode;
    if (!postalCode.match(regex)) {
        address.setCustomValidityForField("Postal Code must match A1A1A1 format.", "postalCode");
        this.submitDisabled = true;
    } else {
        address.setCustomValidityForField("", "postalCode");
          //Reset previously set message
    }
    address.reportValidity();
    this.template.querySelectorAll('lightning-input-address').forEach(element => {
        element.reportValidity();
        if(element.reportValidity()){this.submitDisabled = false;}
        else{this.submitDisabled = true;}
        });
}
handlePersonMailingAddressChange(event){
    this.PersonMailingAddress.city = event.detail.city;
    this.PersonMailingAddress.street= event.detail.street;
    this.PersonMailingAddress.province = event.detail.province;
    this.PersonMailingAddress.postalCode = event.detail.postalCode;
    this.PersonMailingAddress.country = event.detail.country;
}
handleLoanPurposeChange(event){
    console.log('[handleLoanPurposeChange] '+event.detail.value)    
    if(event.detail.value){    
        this.fileData.LoanPurpose = event.detail.value;
    }
    //this._selected = event.detail.value;
}
handleOnChangeAddressSamePM1Checkbox(event){
    if(!event.target.checked){
        this.fileData.PropertyMemberOne.isMailingAddressSameAsProperty = false;
    }else{
        this.fileData.PropertyMemberOne.isMailingAddressSameAsProperty = true;
        this.fileData.PropertyMemberOne.primaryCity = '';
        this.fileData.PropertyMemberOne.primaryStreet = '';
        this.fileData.PropertyMemberOne.primaryProvince = '';
        this.fileData.PropertyMemberOne.primaryPostalCode = '';
        this.fileData.PropertyMemberOne.primaryCountry = 'Canada';
    }
}
handleOnChangeAddressSamePM2Checkbox(event){
    if(!event.target.checked){
        this.fileData.PropertyMemberTwo.isMailingAddressSameAsProperty = false;
    }else{
        this.fileData.PropertyMemberTwo.isMailingAddressSameAsProperty = true;
        this.fileData.PropertyMemberTwo.primaryCity = '';
        this.fileData.PropertyMemberTwo.primaryStreet = '';
        this.fileData.PropertyMemberTwo.primaryProvince = '';
        this.fileData.PropertyMemberTwo.primaryPostalCode ='';
        this.fileData.PropertyMemberTwo.primaryCountry = 'Canada';
    }
}

handlePropertyMember1PrimaryContact(event){
    this.fileData.PropertyMemberOne.isPrimaryContact = event.detail.checked;
    if (event.detail.checked) {
        let firstName = this.template.querySelector('.firstName').value;
        this.fileData.PropertyMemberOne.firstName = firstName;
        let lastName = this.template.querySelector('.lastName').value;
        this.fileData.PropertyMemberOne.lastName = lastName;
        let salutation = this.template.querySelector('.salutation').value;
        this.fileData.PropertyMemberOne.salutation = salutation;
        let phone = this.template.querySelector('.phone').value;
        this.fileData.PropertyMemberOne.phone = phone;
        let email = this.template.querySelector('.email').value;
        this.fileData.PropertyMemberOne.email = email;
        let dob = this.template.querySelector('.dateOfBirth').value;
        //console.log('[handlePropertyMember1PrimaryContact] -  dob '+dob);
        this.fileData.PropertyMemberOne.dateOfBirth = dob;
        //calculate age
        this.fileData.PropertyMemberOne.age = this.getAge(dob);
    }

}
handlePropertyMember1SalutationChange(event){
    this.fileData.PropertyMemberOne.salutation = event.detail.value;
}
handlePropertyMember2SalutationChange(event){
    this.fileData.PropertyMemberTwo.salutation = event.detail.value;
}

handlePropertyMember1GenderChange(event){
    this.fileData.PropertyMemberOne.gender = event.detail.value;
}
handlePropertyMember2GenderChange(event){
    this.fileData.PropertyMemberTwo.gender = event.detail.value;
}

handlePropertyMember1MaritalStatusChange(event){
    this.fileData.PropertyMemberOne.maritalStatus = event.detail.value;
}
handlePropertyMember2MaritalStatusChange(event){
    this.fileData.PropertyMemberTwo.maritalStatus = event.detail.value;
}

handlePrimaryContactAddressChange(event){
    this.PrimaryContact.primaryCity = event.detail.city;
    this.PrimaryContact.primaryStreet= event.detail.street;
    this.PrimaryContact.primaryProvince = event.detail.province;
    this.PrimaryContact.primaryPostalCode = event.detail.postalCode;
    this.PrimaryContact.primaryCountry = event.detail.country;
    this.validatePostalCode('PrimaryContactAddress');
}

handlePropertyMemberAddress1Change(event){
    this.fileData.PropertyMemberOne.primaryCity = event.detail.city;
    this.fileData.PropertyMemberOne.primaryStreet= event.detail.street;
    this.fileData.PropertyMemberOne.primaryProvince = event.detail.province;
    this.fileData.PropertyMemberOne.primaryPostalCode = event.detail.postalCode;
    this.fileData.PropertyMemberOne.primaryCountry = event.detail.country;
    this.validatePostalCode('PropertyMemberAddress1');
}

handlePropertyMemberAddress2Change(event){
    this.fileData.PropertyMemberTwo.primaryCity = event.detail.city;
    this.fileData.PropertyMemberTwo.primaryStreet= event.detail.street;
    this.fileData.PropertyMemberTwo.primaryProvince = event.detail.province;
    this.fileData.PropertyMemberTwo.primaryPostalCode = event.detail.postalCode;
    this.fileData.PropertyMemberTwo.primaryCountry = event.detail.country;
    this.validatePostalCode('PropertyMemberAddress2');
}

handlePropertyMemberRelationship(event) {
    let selected = event.detail.pickListValue;
    var selectedValues = JSON.parse(JSON.stringify(selected));
    console.log('selectedValues', selectedValues);
    if (selectedValues) 
    {
        if(selectedValues.controlling != null )
        {
            this.fileData.PropertyMemberTwo.controlling = selectedValues.controlling;
            if(this.PropertyMember1 != null ){
                this.fileData.PropertyMemberOne.controlling = selectedValues.controlling;
            }
        }

        if(selectedValues.dependent != null )
        {
            this.fileData.PropertyMemberTwo.dependent = selectedValues.dependent;
            if(this.PropertyMember1 != null ){
                this.fileData.PropertyMemberOne.dependent = this.relationShipTypeMap[selectedValues.dependent];
            }
        }
    }
    else 
    {
        this.fileData.PropertyMemberTwo.controlling = '';
        this.fileData.PropertyMemberTwo.dependent = '';
        this.fileData.PropertyMemberOne.controlling = '';
        this.fileData.PropertyMemberOne.dependent = '';
    }
}
handleGetPartnerAssociations(){
    getReferalAssociations({ accountId: this.referralPartnerId })
        .then((result) => {
            if(result){
                for (let obj of result) {
                    let { Territory2Id, CurrentOrganization__c } = obj;
                    if (Territory2Id) {
                        this.fileData.partnerDetails.Territory = Territory2Id;
                    }
                    if (CurrentOrganization__c) {
                        this.fileData.partnerDetails.ReferralOrganization = CurrentOrganization__c;
                    }
                }
            }
        })
        .catch((error) => {
            console.log('getReferalAssociations error ', error);
            this.showSpinner = false;
            var message = error.body.message;
            this.showToast('Error Pre-filling informations according to Referral Partner', message, 'error');
        }
    );
}
/*OPTIONS FOR COMBO BOXES */
propertyCountryOptions = [ 
    {   
        label: 'Canada', 
        value: 'Canada' 
    } 
];

provinceOptions = [
    {
        value: 'AB',
        label: 'Alberta',
    },
    {
        value: 'BC',
        label: 'British Columbia',
    },
    {
        value: 'MB',
        label: 'Manitoba',
    },
    {
        value: 'NB',
        label: 'New Brunswick',
    },
    {
        value: 'NL',
        label: 'Newfoundland And Labrador',
    },
    {
        value: 'NS',
        label: 'Nova Scotia',
    },
    {
        value: 'NT',
        label: 'Northwest Territories',
    },
    {
        value: 'NU',
        label: 'Nunavut',
    },
    {
        value: 'ON',
        label: 'Ontario',
    },
    {
        value: 'PE',
        label: 'Prince Edward Island',
    },        
    {
        value: 'QC',
        label: 'Quebec',
    },
    {
        value: 'SK',
        label: 'Saskatchewan',
    },
    {
        value: 'YT',
        label: 'Yukon',
    }
];
}