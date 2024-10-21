import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Complaint_Category from '@salesforce/schema/Case.Complaint_Category__c';
import channelRecieved from '@salesforce/schema/Case.Origin';
import complainantType from '@salesforce/schema/Case.Complainant_Type__c';
import subcategory from '@salesforce/schema/Case.Complaint_Subcategory__c';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { checkNull } from "c/cms_jsUtility";

export default class Cms_caseComplaintDetails extends LightningElement {
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo;
    dependentDisabled = true;
    dateRecieved;
    canIClose_yesVariant = 'Neutral';
    canIClose_NoVariant = 'Neutral';
    thisAbout_yesVariant = 'Neutral';
    thisAbout_NoVariant = 'Neutral';
    closedResolved;
    showWhenReputaionalYes = false;
    closedResolvedGryed = true;
    closedResolvedRequired = false;
    reputationalRisk;
    incidentRecieved;
    thisAbout;
    canIClose;
    resolutionSought;
    detailsOfComplaint;
    value;
    caseRecivedDifference = 0;
    isCategoryValueOther = false;
    @track categoryOptions;
    @track channelOptionsRecieved;
    @track subcategoryOptionsData;
    complainantCategoryValue;
    complainantCategoryValueCheck;
    channelValue;
    subCategoryValue;
    channelOptionsRecieved;
    categoryDescription;
    subCategoryDescription;
    typeDisabled = false;
    @api
    disableType(){
        this.typeDisabled = true;
    }
    typeOptionsDataValues = [
        { label: '--Please select --', value: '' }, { label: 'Yes', value: 'Yes' }, { label: 'No', value: 'No' }
    ]
    typeOptionsData;/*= [
        { label: 'Personal (made directly by client)', value: 'Personal (made directly by client)' },
        { label: 'Personal (third party on behalf of client)', value: 'Client' },
    ];*/
    channelRecievedOptionsCheck = false;
    Complaint_CategoryOptionsCheck = false;
    subcategoryOptionsDataCheck = false;
    connectedCallbackCheck = false;
    complainantTypeOptionsRecieved = false;
    @track controllingPicklist = [];
    @track dependentPicklist;



    @wire(getPicklistValues,
        {
            recordTypeId: '$caseInfo.data.defaultRecordTypeId',
            fieldApiName: Complaint_Category
        }
    )
    Complaint_CategoryOptions({ error, data }) {
        console.log('1');
        if (data) {
            console.log('data', data)
            this.categoryOptions = data.values;
            this.Complaint_CategoryOptionsCheck = true;
            this.fetchCaseDataFromParent();
        } else if (error) {

        }
    };
    hasDependenatValuesLoaded = false;
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$caseInfo.data.defaultRecordTypeId' })
    fetchPicklist({ error, data }) {
        console.log('1234');
        if (data && data.picklistFieldValues) {
            console.log('12346');
            data.picklistFieldValues["Complaint_Category__c"].values.forEach(optionData => {
                this.controllingPicklist.push({ label: optionData.label, value: optionData.value });
            });
            console.log('12344');
            this.dependentPicklist = data.picklistFieldValues["Complaint_Subcategory__c"];
            console.log('12345');
            this.hasDependenatValuesLoaded = true;
            this.fetchCaseDataFromParent()
        }
        
    }
    @wire(getPicklistValues,
        {
            recordTypeId: '$caseInfo.data.defaultRecordTypeId',
            fieldApiName: channelRecieved
        }
    )
    channelRecievedOptions({ error, data }) {
        console.log('1');
        if (data) {
            this.channelOptionsRecieved = data.values;
            this.channelRecievedOptionsCheck = true;
            this.fetchCaseDataFromParent();
        } else if (error) {

        }
    };


    @wire(getPicklistValues,
        {
            recordTypeId: '$caseInfo.data.defaultRecordTypeId',
            fieldApiName: complainantType
            //typeOptionsData
        }
    )
    complainantTypeOptions({ error, data }) {
        console.log('2');
        if (data) {
            this.typeOptionsData = data.values;
            this.complainantTypeOptionsRecieved = true;
            this.fetchCaseDataFromParent();
        } else if (error) {

        }
    };





    @track finalDependentVal;
    @track controllerValue;
    fetchDependentValue(event) {
        this.dependentDisabled = true;
        this.finalDependentVal = [];
        this.showdependent = false;
        const selectedVal = event.target.value;
        //this.controllerValue = selectedVal;
        //this.finalDependentVal.push({label : "--None--", value : ""})
        let controllerValues = this.dependentPicklist.controllerValues;

        this.dependentPicklist.values.forEach(depVal => {
            depVal.validFor.forEach(depKey => {
                if (depKey === controllerValues[selectedVal]) {
                    this.dependentDisabled = false;
                    this.showdependent = true;
                    this.finalDependentVal.push({ label: depVal.label, value: depVal.value });
                }
            });

        });
    }
    fetchDependentValueWithValue(value) {
        this.dependentDisabled = true;
        this.finalDependentVal = [];
        this.showdependent = false;
        const selectedVal = value;
        //this.controllerValue = selectedVal;
        //this.finalDependentVal.push({label : "--None--", value : ""})
        let controllerValues = this.dependentPicklist.controllerValues;

        this.dependentPicklist.values.forEach(depVal => {
            depVal.validFor.forEach(depKey => {
                if (depKey === controllerValues[selectedVal]) {
                    this.dependentDisabled = false;
                    this.showdependent = true;
                    this.finalDependentVal.push({ label: depVal.label, value: depVal.value });
                }
            });

        });
    }

    connectedCallback() {
        console.log('4');
        this.callSpinerOnLoad();
        this.connectedCallbackCheck = true;
        this.fetchCaseDataFromParent();
    }
    fetchCaseDataFromParent() {
        console.log('1connectedCallbackCheck',this.connectedCallbackCheck);
        console.log('1channelRecievedOptionsCheck',this.channelRecievedOptionsCheck);
        console.log('1Complaint_CategoryOptionsCheck',this.Complaint_CategoryOptionsCheck);
        console.log('1subcategoryOptionsDataCheck',this.subcategoryOptionsDataCheck);
        console.log('1complainantTypeOptionsRecieved',this.complainantTypeOptionsRecieved);
        console.log('1hasDependenatValuesLoaded',this.hasDependenatValuesLoaded);
        
        if (this.connectedCallbackCheck && this.channelRecievedOptionsCheck && this.Complaint_CategoryOptionsCheck && this.subcategoryOptionsDataCheck && this.complainantTypeOptionsRecieved && this.hasDependenatValuesLoaded)  {
            console.log('12312312312');
            this.connectedCallbackCheck = false;
            this.channelRecievedOptionsCheck = false;
            this.Complaint_CategoryOptionsCheck = false;
            this.subcategoryOptionsDataCheck = false;
            this.complainantTypeOptionsRecieved = false;
            this.hasDependenatValuesLoaded = false;
            this.dispatchEvent(new CustomEvent('getvaluefromparent', {
                detail: {
                    message: 'caseComplaintDetails'
                }
            }));
            
        }
    }

    @wire(getPicklistValues,
        {
            recordTypeId: '$caseInfo.data.defaultRecordTypeId',
            fieldApiName: subcategory
        }
    )
    subcategoryOptions({ error, data }) {
        if (data) {
            this.subcategoryOptionsData = data.values;
            this.subcategoryOptionsDataCheck = true;
            this.fetchCaseDataFromParent();
        } else if (error) {

        }
    };

    handleChange(event) {
        console.log('changeApplied');
        switch (event.currentTarget.dataset.id) {
            case 'Complainant_Category':

                //this.complainantCategoryValue = 
                if(this.complainantCategoryValueCheck != event.detail.value){
                    this.subCategoryValue = undefined;
                }
                this.complainantCategoryValue = event.detail.value;
                this.complainantCategoryValueCheck = this.complainantCategoryValue;
                if (this.complainantCategoryValue) {
                    this.dependentDisabled = false;
                }
                this.fetchDependentValue(event);
               
                this.isCategoryValueOther = false;

                if(this.complainantCategoryValue == 'Other'){
                    this.isCategoryValueOther = true;
                    this.subCategoryValue = 'Other'
                }else{
                    this.categoryDescription = '';
                    this.subCategoryDescription = '';
                }
                break;
            case 'Channel_Category':
                // code block
                this.channelValue = event.detail.value;
                
                break;
            case 'Sub_Category':
                // code block
                this.subCategoryValue = event.detail.value;
                break;
            case 'dateRecieved':
                this.dateRecieved = event.detail.value;
                let mydate = new Date(this.dateRecieved);
                
                const date = new Date();
    
                let day = date.getDate();
                let month = date.getMonth() + 1;
                let monthData = '';
                let dayData = '';
                if (month < 10) {
                    monthData = '0';
                }
                if (day < 10) {
                    dayData = '0';
                }
                let year = date.getFullYear();
                // This arrangement can be altered based on how we want the date's format to appear.
                let currentDate = new Date(`${year}-${monthData}${month}-${dayData}${day}`);
                console.log('mydate',mydate);
                console.log('currentDate',currentDate);
                console.log('mydate - currentDate',(mydate - currentDate)/86400000);
                this.caseRecivedDifference = ((currentDate - mydate)/86400000)+1;
                this.closedResolvedRequired = false;
                this.closedResolvedGryed = true;
                if (this.reputationalRisk == 'No' ) {
                    this.closedResolvedRequired = true;
                    this.closedResolvedGryed = false;
                    
                }else{
                    this.closedResolved = '';
                }
                this.showCaseUrgentMessage(this.showWhenReputaionalYes,this.caseRecivedDifference);
                break;
            case 'incidentRecieved':
                // code block
                this.incidentRecieved = event.detail.value;
                break;
            case 'reputational-risk':
                this.closedResolvedRequired = false;
                this.closedResolvedGryed = true;
                this.showWhenReputaionalYes = false
                this.reputationalRisk = event.detail.value;
                this.thisAbout = event.detail.value;
                if (this.reputationalRisk == 'Yes') {
                    this.showWhenReputaionalYes = true;
                } if (this.reputationalRisk == 'No' ) {
                    this.closedResolvedRequired = true;
                    this.closedResolvedGryed = false;
                    
                }else{
                    this.closedResolved = '';
                }
                this.showCaseUrgentMessage(this.showWhenReputaionalYes,this.caseRecivedDifference);
                break;
            case 'closed-resolved':
                // code block
                this.closedResolved = event.detail.value;
                this.canIClose = event.detail.value;
                break;
            case 'thisAbout_yes':

                this.thisAbout = 'yes';
                this.thisAbout_yesVariant = 'brand';
                this.thisAbout_NoVariant = 'Neutral';
                if (this.thisAbout) {
                    this.errorThisAbout = false;
                }


                break;
            case 'thisAbout_No':
                this.thisAbout = 'No';
                this.thisAbout_NoVariant = 'brand';
                this.thisAbout_yesVariant = 'Neutral';
                if (this.thisAbout) {
                    this.errorThisAbout = false;
                }
                break;
            case 'canIClose_No':
                this.canIClose = 'No';
                this.canIClose_NoVariant = 'brand';
                this.canIClose_yesVariant = 'Neutral';
                if (this.canIClose) {
                    this.errorCanIResolve = false;
                }
                break;
            case 'canIClose_yes':
                this.canIClose = 'yes';
                this.canIClose_yesVariant = 'brand';
                this.canIClose_NoVariant = 'Neutral';
                if (this.canIClose) {
                    this.errorCanIResolve = false;
                }
                break;
            case 'detailsOfComplaint':
                this.detailsOfComplaint = event.detail.value;
                break;
            case 'resolutionSought':
                this.resolutionSought = event.detail.value;
                break;
            case 'complainantTypeValue':

                this.complainantTypeValue = event.detail.value;
                break;
            case 'Category_Description':

                this.categoryDescription = event.detail.value;
                break;
            case 'Sub_Category_Description':

                this.subCategoryDescription = event.detail.value;
                break;
            default:
            // code block
        }
    }
    errorThisAbout = false;
    errorCanIResolve = false;
    @api
    passCaseDataToParent() {
        
        let caseData = {};
        
        caseData.Complaint_Category__c = this.complainantCategoryValue;
        caseData.Complaint_Subcategory__c = this.subCategoryValue;
        caseData.Complaint_Date_Received__c = this.dateRecieved;
        caseData.Sub_Category_Description__c = this.subCategoryDescription;
        caseData.Category_Description__c = this.categoryDescription;
        
        caseData.Incident_Date__c = this.incidentRecieved;
        caseData.thisAbout = this.thisAbout;
        caseData.Can_I_close_or_resolve_this_complaint__c = false;
        caseData.closedResolved = this.closedResolved;
        if(this.closedResolved == 'Yes'){
            caseData.Can_I_close_or_resolve_this_complaint__c = true;
        }
        
        caseData.Resolution_Sought__c = this.resolutionSought;
        caseData.Detail_of_Complaint__c = this.detailsOfComplaint;
        caseData.Origin = this.channelValue;
        caseData.Complainant_Type__c = this.complainantTypeValue;
        caseData.dateRecievedDifference = this.caseRecivedDifference;

        if (!caseData.thisAbout) {
            this.errorThisAbout = true;
        }
        if (!caseData.Can_I_close_or_resolve_this_complaint__c) {
            this.errorCanIResolve = true;
        }

        this.template.querySelectorAll('.reportValidityClass').forEach(element => {
            let checkValidtyData = false;
            checkValidtyData = element.reportValidity();
            if (checkValidtyData) {
                element.reportValidity();
            }

        });

        return caseData
    }
    isAnonymous ;
    @api
    setIsAnonymousInfo(isAnonymous){
        this.isAnonymous = isAnonymous;
    }
    @api
    setCaseDataFromParent(caseData) {
        console.log('loadApplied');
        try {
            if (!checkNull(caseData)) {
                this.complainantCategoryValue = caseData.Complaint_Category__c;
                this.complainantCategoryValueCheck = this.complainantCategoryValue;
                if(!checkNull(this.complainantCategoryValue)){
                    this.fetchDependentValueWithValue(this.complainantCategoryValue);
                }
                
                this.subCategoryValue = caseData.Complaint_Subcategory__c;
                this.dateRecieved = caseData.Complaint_Date_Received__c
                this.incidentRecieved = caseData.Incident_Date__c;
                this.thisAbout = caseData.thisAbout;
                
                this.categoryDescription = caseData.Category_Description__c;
                this.subCategoryDescription = caseData.Sub_Category_Description__c;
                this.reputationalRisk = caseData.thisAbout;
                this.closedResolved = 'No';
                if(caseData.Can_I_close_or_resolve_this_complaint__c){
                    this.closedResolved = 'Yes';
                }
                this.canIClose = 'No';
                if(caseData.Can_I_close_or_resolve_this_complaint__c){
                    this.canIClose = 'Yes';
                }
                this.closedResolved = caseData.closedResolved;
                this.resolutionSought = caseData.Resolution_Sought__c;
                this.detailsOfComplaint = caseData.Detail_of_Complaint__c;
                this.channelValue = caseData.Origin;
                this.complainantTypeValue = caseData.Complainant_Type__c;
                this.closedResolvedRequired = false;
                this.closedResolvedGryed = true;
                this.caseRecivedDifference = caseData.dateRecievedDifference;
                if (this.reputationalRisk == 'No' ) {
                    this.closedResolvedRequired = true;
                    this.closedResolvedGryed = false;
                }
                if (this.thisAbout == 'yes') {
                    this.thisAbout_yesVariant = 'brand';
                } else if (this.thisAbout == 'No') {
                    this.thisAbout_NoVariant = 'brand'
                }
    
                if (this.canIClose == 'yes') {
                    this.canIClose_yesVariant = 'brand';
                } else if (this.canIClose == 'No') {
                    this.canIClose_NoVariant = 'brand'
                }
                if (this.complainantCategoryValue) {
                    this.dependentDisabled = false;
                }
                
            }
            if(checkNull(this.complainantTypeValue)){
                this.complainantTypeValue = 'Personal (made directly by complainant)'
            }
            if(this.isAnonymous){
                this.complainantTypeValue = 'Anonymous';
            }
            this.isCategoryValueOther = false;
            if(this.complainantCategoryValue == 'Other'){
                this.isCategoryValueOther = true;
                this.subCategoryValue = 'Other';
            }else{
                this.categoryDescription = '';
                this.subCategoryDescription = '';
            }
            
            
            if (checkNull(this.dateRecieved)) {
                const date = new Date();
    
                let day = date.getDate();
                let month = date.getMonth() + 1;
                let monthData = '';
                let dayData = '';
                if (month < 10) {
                    monthData = '0';
                }
                if (day < 10) {
                    dayData = '0';
                }
                let year = date.getFullYear();
                // This arrangement can be altered based on how we want the date's format to appear.
                let currentDate = `${year}-${monthData}${month}-${dayData}${day}`;
                this.dateRecieved = currentDate;
                this.caseRecivedDifference = 0;
            }
            this.showWhenReputaionalYes = false
            if (this.reputationalRisk == 'Yes') {
                this.showWhenReputaionalYes = true;
            }
            if (this.showWhenReputaionalYes || this.caseRecivedDifference>14) {
                this.showCaseUrgentMessage(this.showWhenReputaionalYes,this.caseRecivedDifference);
    
            }
            this.closeSpinerAfterLoad();
        } catch (error) {
            console.log('error',error);
        }
        
    }
    closeSpinerAfterLoad() {
        this.dispatchEvent(new CustomEvent('closespiner', {
            detail: {
                message: 'CloseSpiner'
            }
        }));
    }
    callSpinerOnLoad() {
        this.dispatchEvent(new CustomEvent('openspiner', {
            detail: {
                message: 'openSpiner'
            }
        }));
    }
    showCaseUrgentMessage(caseurgent,days) {
        this.dispatchEvent(new CustomEvent('caseurgent', {
            detail: {
                message: caseurgent,
                message1:days
            }
        }));
    }

}