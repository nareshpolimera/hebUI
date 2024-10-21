import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import hasRestrict_raise_complaint from '@salesforce/customPermission/Restrict_raise_complaint';
import externalCSS from '@salesforce/resourceUrl/externalCSS';
import { checkNull } from "c/cms_jsUtility";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import caseRecMethod from '@salesforce/apex/CMS_Handler.caseRecMethod';
import setBodayandCallGenerateApi from '@salesforce/apex/CMS_Handler.setBodayandCallGenerateApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import COMPLAINANT_OBJECT from '@salesforce/schema/Account';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import HandlingLevel from '@salesforce/schema/User.Handling_Level__c';

import USER_ID from '@salesforce/user/Id';
import Relationship_to_Client__c from '@salesforce/schema/Case.Relationship_to_Client__c';
import Language__c from '@salesforce/schema/Contact.Language__c';
import Preferred_Contact_Method__c from '@salesforce/schema/Contact.FinServ__ContactPreference__c';
export default class Cms_caseComplaintParentComponent extends NavigationMixin(LightningElement) {
    userId = USER_ID;
    userHandlingLevel = '';
    IsCustomerSatisfiedSubject;
    LanguageSubject;
    correspondenceMethodSubject;

    @wire(getRecord, { recordId : "$userId", fields: [HandlingLevel]})
    user ({ error, data }) {
        
        if (data) {
            console.log('xxxxxxxxxxxxxxxxxxxx',JSON.stringify(data.fields.Handling_Level__c.value));
            //userHandlingLevel
           this.userHandlingLevel = data.fields.Handling_Level__c.value;
        } 
    };
    //@wire(IsConsoleNavigation) isConsoleNavigation;
    @api recordId;
    urgentMessageDefault = 'This case is urgent. Please log the Complaint and it will be automatically transferred to a Complaints Specialist.';
    urgentMessageDefault14 = 'This Complaint has passed 14 days. It is urgent and will be escalated to a Designated Employee.';
    urgentMessageDefault50 = 'This Complaint has passed 50 days. It is urgent and will be escalated to a Senior Designated Employee.';
    correspondenceMethod;
    emailReviewContent;
    caseUrgentNavigation = false;
    caseUrgent = false;
    caseUrgentMessageShow = false;
    hasError = false;
    errorMessage = '';
    caseReviewData = {};
    showNewProgressBar = false;
    caseDataDetail = {};
    redressIdList = [];
    saveAndExit = false;
    isApplyRedress = false;
    @track redressList;
    compianantId = '';
    compianantData = {};
    showRedressPage = false;
    showAddNewComplaint = true;
    showCommunicationConsent = false;
    caseIdFromDetail = '';
    showComplaintDetails = false;
    showResolutionDetails = false;
    showResolutionLetter = false;
    showButtons = true;
    consentGiven = false;
    showConfirmButton = true;
    currentStep = 1; // Initialize the current step to 1
    currentStepString = '1';
    showComplainantPopUp = false;
    complainantValid = false;
    showReviewPage = false;


    leadIdLoaded = false;
    prpertyMembers;
    urlId = '';
    relationShipToClient = '';
    relationShipToClientOptions = '';
    hasLeadId;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo;
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactInfo;
    @wire(getObjectInfo, { objectApiName: COMPLAINANT_OBJECT })
    complainantInfo;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.leadIdLoaded = false;
        if (currentPageReference) {
            this.urlId = currentPageReference.state?.lead__recordId;
            console.log('this.urlId', this.urlId);
            if (!this.urlId) {
                this.leadIdLoaded = true;
                this.setOptionsLoaded();
            } else {
                this.hasLeadId = true;
            }

        }
    }
    @wire(getRelatedListRecords, {
        parentRecordId: '$urlId',
        relatedListId: 'Property_Members__r',
        fields: ['Property_Member__c.Id', 'Property_Member__c.Name', 'Property_Member__c.Last_Name__c', 'Property_Member__c.Name__c',
            'Property_Member__c.First_Name__c', 'Property_Member__c.Preferred_Contact_Method__c', 'Property_Member__c.Preferred_Spoken_Language__c', 'Property_Member__c.Phone__c',
            'Property_Member__c.Email__c', 'Property_Member__c.Primary_Street__c', 'Property_Member__c.Primary_City__c', 'Property_Member__c.Lead__r.Language__c'
            , 'Property_Member__c.Primary_Province__c', 'Property_Member__c.Primary_Postal_Code__c', 'Property_Member__c.Primary_Country__c'],
        where: '{ Role__c : { includes: ["Borrower"] } }'
    })
    listInfo({ error, data }) {
        console.log('12321')
        if (data) {
            console.log('12321')
            this.prpertyMembers = data.records;
            console.log('this.prpertyMembers', this.prpertyMembers);
            this.relationShipToClient = Relationship_to_Client__c;
        } else if (error) {
            this.prpertyMembers = undefined;
            console.log('error', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues,
        {
            recordTypeId: '$caseInfo.data.defaultRecordTypeId',
            fieldApiName: '$relationShipToClient'
        }
    )
    relationShipToClientOptionsData({ error, data }) {
        console.log('1');
        if (data) {
            console.log('data', data)
            this.relationShipToClientOptions = data.values;
            this.leadIdLoaded = true;
            this.setOptionsLoaded();
        } else if (error) {
 
        }
    };
    languageOptions = [];
    preferedContactMetodOptions = [];
    allOptionsLoaded = false;
    y=0
    closeTab = false;
    focusedTabInfoData;
    async setOptionsLoaded() {
        /*if(this.leadIdLoaded){
            console.log(this.complainantInfo);
            this.allOptionsLoaded = true
        }*/
        console.log('hasRestrict_raise_complaint',hasRestrict_raise_complaint);
        if(hasRestrict_raise_complaint){
            this.closeTab = true;
            var focusedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
            if (!focusedTabInfo.tabId && this.y < 2) {
                console.log('000000000000000');
                this.y++
                setTimeout(() => {
                    this.setOptionsLoaded();
                }, 1550);
            }else if(focusedTabInfo.tabId){
                console.log('1111111111111');
                this.focusedTabInfoData = focusedTabInfo.tabId;
                
                this.showToasError('You are not authorized to raise a complaint');
                await this.invokeWorkspaceAPI('closeTab', {
                    tabId: focusedTabInfo.tabId,
                })
               // this.handleCancel();
            }else if(this.focusedTabInfoData){
                console.log('22222222222');
                await this.invokeWorkspaceAPI('closeTab', {
                    tabId: focusedTabInfoData,
                })
            }else{
                console.log('333333333333');
                this.showToasError('You are not authorized to raise a complaint');
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'home'
                    },
                });
            }
        }
        else if (this.leadIdLoaded && !checkNull(this.preferedContactMetodOptions) && !checkNull(this.languageOptions)) {
            this.allOptionsLoaded = true
        }
    }
    renderedCallback() {
        console.log('this.template.querySelector(',!checkNull(this.template.querySelector('[data-id="Green_Button"]')))
        if(this.closeTab && (!checkNull(this.template.querySelector('[data-id="Green_Button"]')))){
            this.template.querySelector('[data-id="Green_Button"]').click();
        }        
    }
    @wire(getPicklistValues,
        {
            recordTypeId: '$contactInfo.data.defaultRecordTypeId',
            fieldApiName: Preferred_Contact_Method__c
        }
    )
    preferedContactMetodOptionsData({ error, data }) {
        console.log('10000000000001');
        //console.log('recordypeinfos '+JSON.stringify(this.complainantInfo.data.defaultRecordTypeId));
        if (data) {
            console.log('data', data)
            this.preferedContactMetodOptions = data.values;
            this.setOptionsLoaded();
        } else if (error) {

        }
    }

    @wire(getPicklistValues,
        {
            recordTypeId: '$contactInfo.data.defaultRecordTypeId',
            fieldApiName: Language__c
        }
    )
    languageOptionsData({ error, data }) {
        console.log('100000001');
        if (data) {
            console.log('data', data)
            this.languageOptions = data.values;
            this.setOptionsLoaded();
        } else if (error) {

        }
    };

    navigateToViewCasePage() {
        this.closeQuickActionOnCaseNavigation();
    }
    passRedressList() {
        console.log('redressList', this.redressList);
        this.template.querySelector('c-cms_redress-parent').setRedressDataListFromParent(this.redressList);
    }
    passRedress() {
        if (this.caseIdFromDetailId) {
            this.template.querySelector('c-cms_redress-parent').getCaseId(this.caseIdFromDetailId);
        } else {
            this.template.querySelector('c-cms_redress-parent').populateRedressDataFromParent(this.redressData);
        }
    }
    navigateFromRedress(event) {
        this.loaded = true;
        this.navigateToViewCasePage();

    }


    fetchRedressList() {
        this.redressList = this.template.querySelector('c-cms_redress-parent').fetchRedressList();
        if (checkNull(this.redressList)) {
            this.hasError = true;
            this.errorMessage = 'Minimum of 1 redress record is required.';
            this.loaded = true;
            return;
        } else if (this.checkCaseValid()) {
            this.hasError = true;
            this.errorMessage = 'Please complete the information in complaint page to review the complaint.';
            this.closeSpiner();

        } else if (!checkNull(this.compianantData.PersonEmail) && !this.consentGiven) {
            this.checkConsentValidity();
            this.closeSpiner();
            return;
        } else {
            this.doCaseReview();
        }
    }
    attemptToSaveRedress() {
        this.fetchRedressList();
    }

    navigateFromProgrssBar(event) {
        console.log('Here at navigateFromProgrssBar 9');
        debugger;
        this.hasError = false;
        this.errorMessage = '';
        this.loaded = false;
        if (this.showRedressPage) {
            this.redressList = this.template.querySelector('c-cms_redress-parent').fetchRedressList();
        }

        if (this.showAddNewComplaint) {
            if (!this.template.querySelector('c-cms_case-add-new-complainiant').checkValidity()) {
                this.complainantValid = false;
                this.compianantData = this.template.querySelector('c-cms_case-add-new-complainiant').passDataToParent();
                this.loaded = true;
            } else {
                this.complainantValid = true;
                this.compianantData = this.template.querySelector('c-cms_case-add-new-complainiant').passDataToParent();
            }

        }

        if (this.showComplaintDetails) {
            let tempCaseDataDetail = this.template.querySelector('c-cms_case-complaint-details').passCaseDataToParent();
            this.assignProperties(tempCaseDataDetail, this.caseDataDetail);
            this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            this.caseDataDetail.E_Consent_Indicator__c = this.consentGiven;
            if (this.caseDataDetail.thisAbout == 'Yes') {
                this.caseUrgent = true;
                this.caseUrgentNavigation = true;
            }
            this.caseDataDetail.Is_this_about_fraud__c = this.caseUrgent;
        }

        if (this.showCommunicationConsent) {
            this.consentGiven = this.template.querySelector('c-cms_case-communication-consent').getConsent();
            this.caseDataDetail.E_Consent_Indicator__c = this.consentGiven;
        }
        if (this.showResolutionDetails) {
            this.caseResolutionData = JSON.parse(JSON.stringify(this.template.querySelector('c-cms_case-resolution-details').passValueToParent()));
            if (this.caseResolutionData) {
                this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            }
        }
        if (this.showReviewPage) {
            this.correspondenceMethod = this.template.querySelector('c-cms_case-review').correspondenceMethod;
        }

        switch (event.currentTarget.dataset.id) {
            case '1':
                if (this.showAddNewComplaint) {
                    this.loaded = true;
                }
                this.caseUrgent = false;
                this.caseUrgentMessageShow = false;
                this.caseUrgentNavigation = false;
                if (!checkNull(this.caseDataDetail) && this.caseDataDetail.thisAbout == 'Yes') {
                    this.caseUrgentNavigation = true;
                }
                this.currentStep = 1;
                this.showAddNewComplaint = true;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showRedressPage = false;
                this.showReviewPage = false;
                break;
            case '2':
                if (this.showCommunicationConsent) {
                    this.loaded = true;
                }
                this.caseUrgent = false;
                this.caseUrgentMessageShow = false;
                this.caseUrgentNavigation = false;
                if (!checkNull(this.caseDataDetail) && this.caseDataDetail.thisAbout == 'Yes') {
                    this.caseUrgentNavigation = true;
                }
                this.currentStep = 2;
                this.showAddNewComplaint = false;
                this.showCommunicationConsent = true;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showRedressPage = false;
                this.showReviewPage = false;
                break;
            case '3':
                if (this.showComplaintDetails) {
                    this.loaded = true;
                }
                this.currentStep = 3;
                this.showAddNewComplaint = false;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = true;
                this.showResolutionDetails = false;
                this.showRedressPage = false;
                this.showReviewPage = false;
                break;
            case '4':
                if (this.showResolutionDetails) {
                    this.loaded = true;
                }
                this.caseUrgent = false;
                this.caseUrgentMessageShow = false;
                this.caseUrgentNavigation = false;
                this.currentStep = 4;
                this.showAddNewComplaint = false;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = true;
                this.showRedressPage = false;
                this.showReviewPage = false;
                break;
            case '5':
                if (this.showRedressPage) {
                    this.loaded = true;
                }
                this.caseUrgent = false;
                this.caseUrgentMessageShow = false;
                this.caseUrgentNavigation = false;
                this.currentStep = 5;
                this.showAddNewComplaint = false;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showRedressPage = true;
                this.showReviewPage = false;
                break;
            case '6':

                this.doCaseReview();
            default:

        }
        this.currentStepString = this.currentStep.toString();
    }




    callShowComplainantPopUp() {
        this.showComplainantPopUp = true;
    }

    callCloseComplainantPopUp() {
        this.showComplainantPopUp = false;
    }

    async closeQuickActionOnCaseNavigation() {
        var focusedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.caseIdFromDetail,
                objectApiName: 'Case',
                actionName: 'view'
            },
        });
        setTimeout(() => {
            this.invokeWorkspaceAPI('closeTab', {
                tabId: focusedTabInfo.tabId,
            })
        }, 1550);
    }
    closeQuickAction() {
        this.closeQuickActionData()
        //  
    }

    async closeQuickActionData() {
        var focusedTabInfo = this.invokeWorkspaceAPI('getFocusedTabInfo');
        await this.invokeWorkspaceAPI('closeTab', {
            tabId: focusedTabInfo.tabId,
        })
    }

    handleCancel() {
        console.log('canceledcalled');
        this.hasError = false;
        this.errorMessage = '';
        this.navigateToRecentListViewPage();
    }

    handleBack() {
        this.hasError = false;
        this.errorMessage = '';
        this.caseUrgent = false;
        this.caseUrgentMessageShow = false;
        this.caseUrgentNavigation = false;
        this.loaded = false;

        if (this.showRedressPage) {
            this.redressList = this.template.querySelector('c-cms_redress-parent').fetchRedressList();
        }

        if (this.showAddNewComplaint) {
            if (!this.template.querySelector('c-cms_case-add-new-complainiant').checkValidity()) {
                this.complainantValid = false;
                this.compianantData = this.template.querySelector('c-cms_case-add-new-complainiant').passDataToParent();
                this.loaded = true;
            } else {
                this.complainantValid = true;
                this.compianantData = this.template.querySelector('c-cms_case-add-new-complainiant').passDataToParent();
            }

        }

        if (this.showComplaintDetails) {
            let tempCaseDataDetail = this.template.querySelector('c-cms_case-complaint-details').passCaseDataToParent();
            this.assignProperties(tempCaseDataDetail, this.caseDataDetail);
            this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            this.caseDataDetail.E_Consent_Indicator__c = this.consentGiven;
            
            if (this.caseDataDetail.thisAbout == 'Yes') {
                this.caseUrgent = true;
                this.caseUrgentNavigation = true;
            }
            this.caseDataDetail.Is_this_about_fraud__c = this.caseUrgent;
        }

        if (this.showCommunicationConsent) {
            this.consentGiven = this.template.querySelector('c-cms_case-communication-consent').getConsent();
            this.caseDataDetail.E_Consent_Indicator__c = this.consentGiven;
        }
        if (this.showResolutionDetails) {
            this.caseResolutionData = JSON.parse(JSON.stringify(this.template.querySelector('c-cms_case-resolution-details').passValueToParent()));
            if (this.caseResolutionData) {
                this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            }
        }



        if (this.showAddNewComplaint) {
            this.navigateToRecentListViewPage();
            

        } else if (this.showCommunicationConsent) {
            this.caseUrgent = false;
            this.caseUrgentMessageShow = false;
            this.currentStep = 1;
            this.showAddNewComplaint = true;
            this.showCommunicationConsent = false;
            this.showComplaintDetails = false;
            this.showResolutionDetails = false;
            this.showResolutionLetter = false;
            this.showButtons = true;
        } else if (this.showComplaintDetails) {
            this.caseUrgent = false;
            this.caseUrgentMessageShow = false;
            if(this.isAnonymous){
                this.currentStep = 1;
                this.showAddNewComplaint = true;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showResolutionLetter = false;
                this.showButtons = true;
            }else if (checkNull(this.compianantData)) {
                this.currentStep = 1;
                this.showAddNewComplaint = true;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showResolutionLetter = false;
                this.showButtons = true;
            } else if (checkNull(this.compianantData.PersonEmail)) {
                this.currentStep = 1;
                this.showAddNewComplaint = true;
                this.showCommunicationConsent = false;
                this.showComplaintDetails = false;
                this.showResolutionDetails = false;
                this.showResolutionLetter = false;
                this.showButtons = true;
            } else {
                this.currentStep = 2;
                this.showComplaintDetails = false;
                this.showCommunicationConsent = true;
            }

        } else if (this.showResolutionDetails) {
            
                this.currentStep = 3;
            this.showResolutionDetails = false;
            this.showComplaintDetails = true;
            
        } else if (this.showRedressPage) {
            this.redressList = this.template.querySelector('c-cms_redress-parent').fetchRedressList();
            this.currentStep = 4;
            this.showRedressPage = false;
            this.showResolutionDetails = true;

            console.log('this.redressList122', this.redressList);

        } else if (this.showReviewPage) {
            this.correspondenceMethod = this.template.querySelector('c-cms_case-review').correspondenceMethod;

            if (this.isApplyRedress && this.caseDataDetail.thisAbout != 'Yes') {
                this.currentStep = 5;
                this.showRedressPage = true;
                this.showReviewPage = false;
            } else if (this.caseDataDetail.thisAbout != 'Yes') {
                this.currentStep = 4;
                this.showReviewPage = false;
                this.showResolutionDetails = true;

            } else if (this.caseDataDetail.thisAbout == 'Yes') {
                this.currentStep = 3;
                this.showReviewPage = false;
                this.showComplaintDetails = true;
            }

        }
        this.currentStepString = this.currentStep.toString();
    }
    showToast(message) {
        const event = new ShowToastEvent({
            title: 'Success!',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }


    showToastWarning(message) {
        const event = new ShowToastEvent({
            title: 'warning!',
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(event);
    }
    showToasError(message) {
        const event = new ShowToastEvent({
            title: 'Error!',
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    handleConfirmAndExit() {
        this.hasError = false;
        this.errorMessage = '';
        this.saveAndExit = true;
        this.handleSaveAndConfirm();
    }
    handleConfirm() {
        this.hasError = false;
        this.errorMessage = '';
        this.saveAndExit = false;
        this.handleSaveAndConfirm();

    }
    handleSaveAndConfirm() {
        this.caseUrgent = false;
        this.caseUrgentMessageShow = false;
        this.caseUrgentNavigation = false;
        this.loaded = false;
        if (this.showAddNewComplaint) {
            this.handleNextButtonClick();

        } else if (this.showCommunicationConsent) {
            this.consentGiven = this.template.querySelector('c-cms_case-communication-consent').getConsent();
            if (!checkNull(this.compianantData.PersonEmail) && !this.consentGiven) {
                this.loaded = true;
                return;
            }

            this.currentStep = 3;
            this.currentStepString = this.currentStep.toString();
            this.showCommunicationConsent = false;
            this.showComplaintDetails = true;
        } else if (this.showComplaintDetails) {
            //saveAndExit
            this.fetchandCreateCaseRecords();

        } else if (this.showResolutionDetails) {

            this.getValueFromReolutionDetaisl();

        } else if (this.showRedressPage) {
            this.attemptToSaveRedress();

            // Show the "Confirm" button on the "Resolution Letter" step
        } else if (this.showResolutionLetter) {
            this.currentStep = this.currentStep + 1;
            this.currentStepString = this.currentStep.toString();
            this.closeQuickAction();
        }
    }
    caseResolutionData = {};
    getValueFromReolutionDetaisl() {
        if (!this.template.querySelector('c-cms_case-resolution-details').checkValidity()) {
            this.loaded = true;
            return;
        }
        this.caseResolutionData = JSON.parse(JSON.stringify(this.template.querySelector('c-cms_case-resolution-details').passValueToParent()));
        console.log('caseResolutionData123'+ JSON.stringify(this.caseResolutionData));
        if (this.caseResolutionData) {
            this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            if (this.caseIdFromDetailId) {
                this.doCaseReview();
            } else {
                if (!this.saveAndExit) {
                    this.resoultionUpdated();
                } else {
                    if (this.checkCaseValid()) {
                        this.hasError = true;
                        this.errorMessage = 'Please complete the information in complaint page to review the complaint.';
                        this.loaded = true;
                    } else if (!checkNull(this.compianantData.PersonEmail) && !this.consentGiven) {
                        this.checkConsentValidity();
                        return;
                    } else {
                        this.doCaseReview();
                    }
                }
            }
        } else {
            this.resoultionUpdated();
        }
    }
    resoultionUpdated() {
        this.currentStep = 5;
        this.currentStepString = this.currentStep.toString();
        this.showResolutionDetails = false;
        this.showRedressPage = true;
    }

    assignProperties(source, target) {
        for (const key in source) {
            if (source.hasOwnProperty(key)) {
                target[key] = source[key];
            }
        }
    }
    fetchResolutionData() {
        try {
            this.template.querySelector('c-cms_case-resolution-details').applyAnonymous(this.isAnonymous);
            this.template.querySelector('c-cms_case-resolution-details').setValueFromParent(this.caseResolutionData);
        } catch (error) {
            console.log('error',JSON.stringify(error))
        }
       

    }


    navigateToRecentListViewPage() {
        this.closeQuickAction();
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Case",
                actionName: "list"
            },
            state: {
                filterName: "Recent"
            },
        });
    }
    hideError() {
        if (this.hasError && this.errorMessage == 'Minimum of 1 redress record is required.') {
            this.hasError = false;
            this.errorMessage = '';
        }

    }


    fetchandCreateCaseRecords() {

        let tempCaseDataDetail = this.template.querySelector('c-cms_case-complaint-details').passCaseDataToParent();
        this.assignProperties(tempCaseDataDetail, this.caseDataDetail);
        this.assignProperties(this.caseResolutionData, this.caseDataDetail);
        this.caseDataDetail.E_Consent_Indicator__c = this.consentGiven;
        if (this.caseDataDetail.thisAbout == 'Yes') {
            this.caseUrgent = true;
            this.caseUrgentNavigation = true;
        }
        this.caseDataDetail.Is_this_about_fraud__c = this.caseUrgent;
        if (this.compianantId) {
            this.caseDataDetail.Complainant__c = this.compianantId;
        }

        if (this.caseIdFromDetail != '') {
            this.caseDataDetail.Id = this.caseIdFromDetail;
        }



        if (this.checkCaseValid()) {
            this.loaded = true;
        } else if (!checkNull(this.compianantData.PersonEmail) && !this.consentGiven) {
            console.log('checkNull(this.compianantData.PersonEmail) ::');
            this.checkConsentValidity();
            this.loaded = true;
            return;
        } else {
            if (this.saveAndExit) {
                this.doCaseReview();
            } else {
                this.caseUrgent = false;
                this.caseUrgentMessageShow = false;
                this.caseUrgentNavigation = false;
                if (!checkNull(this.caseDataDetail) && this.caseDataDetail.thisAbout == 'Yes') {
                    this.caseUrgentNavigation = true;
                }
                this.hasError = false;
                console.log('this.showComplaintDetails ::'+this.showComplaintDetails);
                this.errorMessage = '';
                if (this.showComplaintDetails) {
                    this.showComplaintDetails = false;
                    this.showResolutionDetails = true;
                    this.currentStep = 4;
                    this.currentStepString = this.currentStep.toString();
                    this.closeSpiner();

                }
            }

        }

    }
    checkConsentValidity() {
        if ( !this.isAnonymous && !checkNull(this.compianantData.PersonEmail) && !this.consentGiven) {
            if (!this.showCommunicationConsent) {
                this.hasError = true;
                this.errorMessage = 'Please accept consent in consent page.';
            }
            this.loaded = true;
            return false;
        } else {
            return true;
        }

    }
    checkCaseValid() {
        if (checkNull(this.caseDataDetail.Complaint_Category__c) || checkNull(this.caseDataDetail.Complaint_Subcategory__c)
            || checkNull(this.caseDataDetail.Complaint_Date_Received__c) || checkNull(this.caseDataDetail.Resolution_Sought__c)
            || checkNull(this.caseDataDetail.thisAbout)
            || checkNull(this.caseDataDetail.Detail_of_Complaint__c) || checkNull(this.caseDataDetail.Origin) || checkNull(this.caseDataDetail.Complainant_Type__c)) {
            return true;
        } else if ((this.caseDataDetail.thisAbout == 'No' ) && checkNull(this.caseDataDetail.Can_I_close_or_resolve_this_complaint__c)) {
            return true;
        } else if (this.caseDataDetail.Complaint_Category__c == 'Other' && checkNull(this.caseDataDetail.Category_Description__c)) {
            return true;
        } else if (this.caseDataDetail.Complaint_Subcategory__c == 'Other' && checkNull(this.caseDataDetail.Sub_Category_Description__c)) {
            return true;
        } else {

            return false;
        }
    }
    checkResolutionValid() {
        if (checkNull(this.caseDataDetail)) {
            return true;
        }else if (!checkNull(this.caseDataDetail.Is_Customer_Satisfied__c) && (checkNull(this.caseDataDetail.Complaint_Outcome__c) || checkNull(this.caseDataDetail.Investigation_Details__c) || checkNull(this.caseDataDetail.Statement_of_Fact__c) || (!this.isAnonymous && checkNull(this.caseDataDetail.Apply_Redress__c)))) {
            return true;
        } else {
            return false;
        }
    }
    checkAllPageValid() {

        let redressList = null;
        if (!checkNull(this.redressList) && this.isApplyRedress && !this.caseUrgent) {
            redressList = this.redressList;
        }
        if (!checkNull(this.compianantData)) {
            if (!this.complainantValid) {
                if (!this.showAddNewComplaint) {
                    this.hasError = true;
                    this.errorMessage = 'Please navigate to Complainant Section and enter the valid details.';
                }
                this.loaded = true;
                return false;
            }
        } else {
            if (!this.showAddNewComplaint) {
                this.hasError = true;
                this.errorMessage = 'Please navigate to Complainant Section and enter the valid details.';
            }
            this.loaded = true;
            return false;
        }
        if (!this.checkConsentValidity()) {
            this.loaded = true;
            return false;
        }
        if (this.checkCaseValid()) {
            if (!this.showComplaintDetails) {
                this.hasError = true;
                this.errorMessage = 'Please complete the information in complaint page to review the complaint.';
            }
            this.loaded = true;
            return false;
        }
        if (this.checkResolutionValid()) {
            if (!this.showResolutionDetails) {
                this.hasError = true;
                this.errorMessage = 'please navigate to Resolution Section and complete the details.';
            } else {
                this.template.querySelector('c-cms_case-resolution-details').checkValidity()
            }
            this.loaded = true;
            return false;
        }
        if (this.caseDataDetail.Apply_Redress__c == 'Yes' && checkNull(redressList) && !this.caseUrgent) {
            this.hasError = true;
            this.errorMessage = 'Minimum of 1 redress record is required.';
            this.loaded = true;
            return false;
        }
        return true;
    }

    passDataToReivewPage() {
        console.log(' this.caseReviewData00001k', this.caseReviewData);
        try {
            this.template.querySelector('c-cms_case-review').populateCaseReviewDataFromParent(this.caseReviewData);
        } catch (error) {
            console.log('error', error);
        }

    }

    doCaseReview() {
        console.log('1221312');
        if (this.checkAllPageValid()) {
            this.caseReviewData.preferedContact = this.compianantData.Preferred_Contact_Method__c;
            this.caseReviewData.email = this.compianantData.PersonEmail;
            this.caseReviewData.Country__c = this.compianantData.PersonMailingCountry;
            this.caseReviewData.Street__c = this.compianantData.PersonMailingStreet;
            this.caseReviewData.City__c = this.compianantData.PersonMailingCity;
            this.caseReviewData.correspondenceMethod = this.correspondenceMethod;
            this.caseReviewData.State_Province__c = this.compianantData.PersonMailingState;
            this.caseReviewData.Postal_Code__c = this.compianantData.PersonMailingPostalCode;
            this.caseReviewData.Is_this_about_fraud__c = this.caseDataDetail.Is_this_about_fraud__c;
            this.caseReviewData.RequestBody = this.setRequestData();
            console.log(' this.caseReviewData00001', this.caseReviewData);
            this.currentStep = 6;
            this.caseUrgent = false;
            this.caseUrgentMessageShow = false;
            this.caseUrgentNavigation = false;
            if (!checkNull(this.caseDataDetail) && this.caseDataDetail.thisAbout == 'Yes') {
                this.caseUrgentNavigation = true;
            }

            this.currentStepString = this.currentStep.toString();
            this.showReviewPage = true;
            this.showAddNewComplaint = false;
            this.showCommunicationConsent = false;
            this.showComplaintDetails = false;
            this.showResolutionDetails = false;
            this.showResolutionLetter = false;
            this.showRedressPage = false;
            this.showButtons = true;
            //this.loaded = true;
        } else {
            this.loaded = true;
            return;

        }
    }
    setRequestData() {
        try {
            let request = {};
            request.Language = this.compianantData.Language__pc;
            request.IsCustomerSatisfied = this.caseDataDetail.Is_Customer_Satisfied__c;

            if (checkNull(this.compianantData.Language__pc)) {
                request.Language = 'English';
            }
            request.Source = this.caseDataDetail.Origin;
            request.IsCustomerSatisfied = true;
            if (this.caseDataDetail.Is_Customer_Satisfied__c == 'No') {
                request.IsCustomerSatisfied = false;
            } else if (checkNull(this.caseDataDetail.Is_Customer_Satisfied__c)) {
                request.IsCustomerSatisfied = null;
            }


            request.HandlingLevel  = this.userHandlingLevel;
            request.ReceivedOn = this.caseDataDetail.Complaint_Date_Received__c;
            request.StatementOfFact = this.caseDataDetail.Statement_of_Fact__c;
            request.ResolutionSought = this.caseDataDetail.Resolution_Sought__c;
            request.Category = this.caseDataDetail.Complaint_Category__c;
            request.Subcategory = this.caseDataDetail.Complaint_Subcategory__c;
            
            // Bug: 8758 // Naresh Kumar
            if(request.Category =='Other'){
                request.CategoryDescription = this.caseDataDetail.Category_Description__c;
                request.SubcategoryDescription = this.caseDataDetail.Sub_Category_Description__c;
            }
            
            //  Santhosh Change here the prop Names
            request.ComplainantFirstName  = this.compianantData.FirstName;
            request.ComplainantLastName  = this.compianantData.LastName;

            let redresses = [];
            if (!checkNull(this.redressList)) {
                this.redressList.forEach(element => {
                    let redress = {};
                    // Bug: 8874 Naresh Kumar
                    redress.Type = element.Financial_Redress_Type__c, // element.Type_of_Financial_Redress__c;
                    redress.Method = element.Redress_Method__c;
                    redress.Amount = parseFloat(element.Redress_Amount__c);
                    redress.Rationale = element.Resolution_Rationale__c;
                    redresses.push(redress);
                });
            }


            request.Redresses = redresses;

            return request;
        } catch (error) {
            console.log('error', error);
            this.loaded = true;
        }

    }
    validateAnonymousData(){
        this.hasError = false;
        this.errorMessage = '';
        if (this.showComplaintDetails){
            let tempCaseDataDetail = this.template.querySelector('c-cms_case-complaint-details').passCaseDataToParent();
            this.assignProperties(tempCaseDataDetail, this.caseDataDetail);
            this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            if (this.caseDataDetail.thisAbout == 'Yes') {
                this.caseUrgent = true;
                this.caseUrgentNavigation = true;
            }
            this.caseDataDetail.Is_this_about_fraud__c = this.caseUrgent;
            if (this.checkCaseValid()) {
                return false
            }
        }
        if (this.showResolutionDetails) {
            this.template.querySelector('c-cms_case-resolution-details').checkValidity();
            this.caseResolutionData = JSON.parse(JSON.stringify(this.template.querySelector('c-cms_case-resolution-details').passValueToParent()));
            if (this.caseResolutionData) {
                this.assignProperties(this.caseResolutionData, this.caseDataDetail);
            }
            if (this.checkResolutionValid()) {
                return false
            }
            
        }

        if (this.checkCaseValid()) {
            this.hasError = true;
            this.errorMessage = 'Please complete the information in complaint page to review the complaint.';
            this.loaded = true;
            console.log(this.checkCaseValid());
            return false;
        }

        if (this.checkResolutionValid()) {
            this.hasError = true;
            this.errorMessage = 'please navigate to Resolution Section and complete the details.';
            console.log(this.checkResolutionValid());
            return false;
            
        }
        return true;
    }
    setCreateCaseAnonymous(){
        this.loaded = false;
        console.log('this.validateAnonymousData()',this.validateAnonymousData());
        if(this.validateAnonymousData()){
            this.createCaseByAnonymous();
        }else{
            this.loaded = true;
        }
        //set Apply_Redress__c = ''
    }
    createCaseByAnonymous(){
        let caseDetailDataValue = this.caseDataDetail;
        caseDetailDataValue.Apply_Redress__c = 'No';
        caseDetailDataValue.E_Consent_Indicator__c = false;
        caseDetailDataValue.Complainant_Type__c = 'Anonymous';
        let urlId = null;
        //caseDetailDataValue.Relationship_to_Client__c = compianantData.relationshipValue;
        //caseDetailDataValue.Other_Relationship_to_Client__c = compianantData.otherRelationValue;
        let redressList = null;
        let compianantData = null;
        console.log('1223',JSON.stringify(caseDetailDataValue));
        
        caseRecMethod({ caseRec: caseDetailDataValue, redressList: redressList, complainantData: compianantData, leadId: urlId }).then(result => {

            console.log(result);
                    this.caseIdFromDetailId = result.Id;
                    this.caseIdFromDetail = result.Id;
                    if (!this.caseCreate) {
                        let message = 'Case record with CaseNumber ' + result.CaseNumber + ' has been created';
                        this.showToast(message);
                        this.caseCreate = true;
                    }
            //this.callGenerateApi(result);

            this.navigateToViewCasePage();

        }).catch(error => {
            console.log('error', error)
            this.loaded = true;

        })
    }
    @track caseIdFromDetailId;
    caseCreate = false;
    createCase() {

        if (!this.template.querySelector('c-cms_case-review').checkValidity()) {
            return;
        }
        this.correspondenceMethod = this.template.querySelector('c-cms_case-review').correspondenceMethod;
        let redressList = null;
        let compianantData = null;
        let caseDetailDataValue = null;
        if (this.checkAllPageValid()) {
            caseDetailDataValue = this.caseDataDetail;
            if (this.caseUrgent) {
                caseDetailDataValue.Investigation_Details__c = null;
                caseDetailDataValue.Complaint_Outcome__c = null;
                caseDetailDataValue.Apply_Redress__c = null;
                caseDetailDataValue.Is_Customer_Satisfied__c = null;
                caseDetailDataValue.Statement_of_Fact__c = null;
            }
            if (!checkNull(this.redressList) && this.isApplyRedress && !this.caseUrgent) {
                redressList = this.redressList;
            }

            compianantData = this.compianantData
            console.log('[createCase] this.compianantData: '+JSON.stringify(compianantData));
        } else {
            this.loaded = true;
            return;

        }
        this.openSpiner();
        let urlId = null;
        if (!checkNull(this.urlId)) {
            urlId = this.urlId
        }
        //setBodayandCallGenerateApi
        //obj.removeAttribute('style')
        this.emailReviewContent = this.template.querySelector('c-cms_case-review').emailReviewContent;
        caseDetailDataValue.Correspondence_Method__c = this.correspondenceMethod;
        caseDetailDataValue.Relationship_to_Client__c = compianantData.relationshipValue;
        caseDetailDataValue.Other_Relationship_to_Client__c = compianantData.otherRelationValue;
        caseDetailDataValue.Complainant_Review_Body__c = this.emailReviewContent;
        
        this.LanguageSubject = compianantData.Language__pc;
        this.IsCustomerSatisfiedSubject = caseDetailDataValue.Is_Customer_Satisfied__c;
        this.correspondenceMethodSubject = caseDetailDataValue.Correspondence_Method__c;
        

        if(this.correspondenceMethodSubject === 'Email'){
            if(this.LanguageSubject === 'English'){
                if(this.IsCustomerSatisfiedSubject == null){
                    caseDetailDataValue.Email_Subject__c ='Complaint to HomeEquity Bank Received';
                }else{
                    caseDetailDataValue.Email_Subject__c = 'Complaint to HomeEquity Bank Received';
                }
            }else if(this.LanguageSubject === 'French'){
                if(this.IsCustomerSatisfiedSubject == null){
                    caseDetailDataValue.Email_Subject__c ='Votre plainte à la Banque HomeEquity a été reçue';
                }else{
                    caseDetailDataValue.Email_Subject__c = 'Plainte à la Banque HomeEquity reçue';
                }
            }
        }

        caseRecMethod({ caseRec: caseDetailDataValue, redressList: redressList, complainantData: compianantData, leadId: urlId }).then(result => {

            console.log(result);
            this.callGenerateApi(result);



        }).catch(error => {
            console.log('error', error);            
            this.loaded = true;
            if(error?.body?.message?.includes('DUPLICATES_DETECTED')){
                this.showToasError('The person you are trying to create may already exist. Please utilize an existing record to main data quality standard');
            }
            if(error?.body?.message.includes('Billing State/Province') || error?.body?.message.includes('BillingPostalCode')) {
                this.showToasError('Please enter a valid province or state code');
            }
        })
    }
    callGenerateApi(resultData) {
        // this.correspondenceMethod = 'Mail'
        if (this.correspondenceMethod == 'Mail') {
            setBodayandCallGenerateApi({ Id: resultData.Id }).then(result => {
                try {
                    console.log(resultData);
                    this.caseIdFromDetailId = resultData.Id;
                    this.caseIdFromDetail = resultData.Id;
                    if (!this.caseCreate) {
                        let message = 'Case record with CaseNumber ' + resultData.CaseNumber + ' has been created';
                        this.showToast(message);
                        this.caseCreate = true;
                    }
                    this.currentStep = 6;
                    this.currentStepString = this.currentStep.toString();


                    this.navigateToViewCasePage();

                } catch (error) {
                    console.log('error', error)
                    this.loaded = true;
                }


            }).catch(error => {
                console.log('error', error)
                this.loaded = true;

            })
        } else {
            try {
                console.log(resultData);
                this.caseIdFromDetailId = resultData.Id;
                this.caseIdFromDetail = resultData.Id;
                if (!this.caseCreate) {
                    let message = 'Case record with CaseNumber ' + resultData.CaseNumber + ' has been created';
                    this.showToast(message);
                    this.caseCreate = true;
                }
                this.currentStep = 6;
                this.currentStepString = this.currentStep.toString();


                this.navigateToViewCasePage();

            } catch (error) {
                console.log('error', error)
                this.loaded = true;
            }
        }
    }

    removeErrorMessage() {
        this.hasError = false;
        this.errorMessage = '';
    }
    passDataToComplaintDetails() {
        if ((this.hasLeadId && !checkNull(this.compianantData) && (this.compianantData.ComplainantData != 'Other'))|| this.isAnonymous) {
            this.template.querySelector('c-cms_case-complaint-details').disableType();;
        }

        this.template.querySelector('c-cms_case-complaint-details').setIsAnonymousInfo(this.isAnonymous);
        this.template.querySelector('c-cms_case-complaint-details').setCaseDataFromParent(this.caseDataDetail);
        //this.template.querySelector('c-cms_case-complaint-details').setCaseDataFromParent(this.caseDataDetail);
        //this.template.querySelector('c-cms_case-complaint-details').setCaseDataFromParent(this.caseDataDetail);
        // this.hasLeadId
        //this.compianantData.ComplainantData
        if (this.caseDataDetail.thisAbout == 'Yes') {
            this.caseUrgent = true;
            this.caseUrgentNavigation = true;
            //this.hasError = true;
            //this.errorMessage = 'This case is urgent and needs to be transferred to a Designated Employee (DE) immediately. Please log the complaint and then transfer to a DE.';
        }
    }

    caseUrgentMessageValue ;
    //urgentMessageDefault
    caseUrgentMessage(event) {
        this.caseUrgent = false;
        this.caseUrgentMessageShow = false;
        this.caseUrgentNavigation = false;
        if (!checkNull(this.caseDataDetail) && this.caseDataDetail.thisAbout == 'Yes') {
            this.caseUrgentNavigation = true;
        }
        if (event.detail.message) {
            this.caseUrgent = true;
            this.caseUrgentMessageShow = true;
            this.caseUrgentNavigation = true;
            this.caseUrgentMessageValue = this.urgentMessageDefault;
        }
        console.log('0001',event.detail.message1);
        if(event.detail.message1>14){
            this.caseUrgentMessageShow = true;
            this.caseUrgentMessageValue = this.urgentMessageDefault14;
        }
        if(event.detail.message1>50){
            this.caseUrgentMessageShow = true;
            this.caseUrgentMessageValue = this.urgentMessageDefault50;
        }
        console.log('event.detail.message1',JSON.stringify(event.detail));
    }
    processComplainantNavigation(event) {
        this.compianantId = event.detail.complainantId;
        this.compianantData = event.detail.compianantData;
        console.log('compianantData123 ' + JSON.stringify(this.compianantData));
        this.showAddNewComplaint = false;
        if (checkNull(this.compianantData.PersonEmail)) {
            this.currentStep = 3;
            this.showComplaintDetails = true;
        } else {
            this.currentStep = 2;
            this.showCommunicationConsent = true;
        }
        this.currentStepString = this.currentStep.toString();

    }


    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            console.log('err', err)
                            return reject(err);
                        } else {
                            return resolve(response);
                        }
                    }
                }
            });

            this.dispatchEvent(apiEvent);
        });
    }
    x = 0;
    async setTabInfo() {
        console.log(this.invokeWorkspaceAPI('isConsoleNavigation'));
        var focusedTabInfo = this.invokeWorkspaceAPI('getFocusedTabInfo');
        console.log('focusedTabInfo',JSON.stringify(focusedTabInfo));
        
        if (!focusedTabInfo.tabId && this.x < 6) {
            this.x++
            setTimeout(() => {
                this.setTabInfo();
            }, 1550);
        } else {
            await this.invokeWorkspaceAPI('setTabIcon', {
                tabId: focusedTabInfo.tabId,
                icon: "action:description",
                iconAlt: "description"
            })
            await this.invokeWorkspaceAPI('setTabLabel', {
                tabId: focusedTabInfo.tabId,
                label: "Log Complaint"
            })
        }

    }
    connectedCallback() {
        this.setTabInfo();
        this.openSpiner();
        loadStyle(this, externalCSS);
    }
    cancelchildApplied() {
        this.showButtons = true;
    }
    saveChildApplied() {
        this.showButtons = true;
    }
    hideParentButtonApply() {
        this.showButtons = false;
    }

    handleNextButtonClick() {

        try {

            if (!this.template.querySelector('c-cms_case-add-new-complainiant').checkValidity()) {
                this.complainantValid = false;
                this.loaded = true;
                return;
            }
            this.complainantValid = true;
            this.compianantData = this.template.querySelector('c-cms_case-add-new-complainiant').passDataToParent();

            this.showAddNewComplaint = false;
            if(this.isAnonymous){
                this.currentStep = 3;
                this.showComplaintDetails = true;
            }
            else if (checkNull(this.compianantData.PersonEmail)) {
                this.currentStep = 3;
                this.showComplaintDetails = true;
            } else {
                this.currentStep = 2;
                this.showCommunicationConsent = true;
            }
            this.currentStepString = this.currentStep.toString();
            this.loaded = true;
        } catch (error) {
            console.log('error', error)
        }

    }
    passCompinantId() {

        if (this.hasLeadId) {
            this.template.querySelector('c-cms_case-add-new-complainiant').setRelationshipOptions(this.relationShipToClientOptions);
            this.template.querySelector('c-cms_case-add-new-complainiant').setPropertyMembersOptions(this.prpertyMembers);

        }

        this.template.querySelector('c-cms_case-add-new-complainiant').setpreferedContactMetodOptions(this.preferedContactMetodOptions);
        this.template.querySelector('c-cms_case-add-new-complainiant').setLanguageOptions(this.languageOptions);
        this.template.querySelector('c-cms_case-add-new-complainiant').getCompianantId(this.compianantId);
        this.template.querySelector('c-cms_case-add-new-complainiant').setDataFromParent(this.compianantData);
        this.template.querySelector('c-cms_case-add-new-complainiant').hitCorrespondenceMethodValidation(this.correspondenceMethod);



        //prpertyMembers //relationShipToClientOptions

    }
    fetchConsent() {
        this.template.querySelector('c-cms_case-communication-consent').updateConsentGiven(this.consentGiven, !checkNull(this.compianantData.PersonEmail));
    }
    @track loaded = true;
    closeSpiner() {
        this.loaded = true;
    }

    openSpiner() {
        this.loaded = false;
    }
    setRedress() {
        this.isApplyRedress = this.template.querySelector('c-cms_case-resolution-details').isApplyRedress;
    }
    isAnonymous = false;
    setAnonymousInfo(event){
        console.log(JSON.stringify(event));
        let isAnonymous = this.isAnonymous;
        this.isAnonymous = false;
        if(event.detail.message == 'Yes'){
            this.isAnonymous  = true;
        }
        if(isAnonymous && (isAnonymous != this.isAnonymous) && (!checkNull(this.caseDataDetail)) && (this.caseDataDetail.Complainant_Type__c == 'Anonymous')){
            this.caseDataDetail.Complainant_Type__c = 'Personal (made directly by complainant)';
        }
    }

}