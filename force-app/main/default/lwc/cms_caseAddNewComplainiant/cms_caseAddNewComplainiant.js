import { api, LightningElement, track } from 'lwc';
import { checkNull } from 'c/cms_jsUtility';
export default class Cms_caseAddNewComplainiant extends LightningElement {
    optionsAnonymous = [{ label: 'Anonymous', value: 'Anonymous' }];
    valueAnonymous = '';
    pageLoaded = false;
    objectApiName = 'Account';
    phone;
    compianantId = '';
    emailRequired = false;
    phoneRequired = false;
    validityCalled = false;
    addressFiedsRequired = true;
    phoneClicked = false;
    emailClicked = false;
    countryClicked = false;
    streetClicked = false;
    cityClicked = false;
    state_ProvinceClicked = false;
    postal_CodeClicked = false;
    @track compianantData = {};
    strStreet;
    strCity;
    strState;
    strCountry;
    strPostalCode;
    searchValue;
    addressValue;
    setaddresslookup = true;
    relationshipOptions;
    contactRoles = [];
    propertyMembersOptions;
    propertyMembersOptionswithFullData;
    relationShipToClientOptionsDisable = true;
    relationShipRequired = false;
    preferedContactMetodOptions = [{ label: '--None--', value: '' }];
    languageOptions = [{ label: '--None--', value: '' }];

    handleSuccessData(event) {
        console.log('sadsad123');
        const updatedRecord = event.detail.id;
        console.log('onsuccess: ', updatedRecord);
        this.dispatchEvent(
            new CustomEvent('navigatenext', {
                detail: {
                    complainantId: event.detail.id,
                    compianantData: this.compianantData,
                },
            })
        );
    }

    handleAnonymousChange(e) {
        this.valueAnonymous = e.detail.value;
        console.log('this.valueAnonymous ', JSON.stringify(this.valueAnonymous));
        if (this.valueAnonymous.length == 1) {
            this.compianantData.Anonymous = true;
            this.passAnonymousInfo('Yes');
        }
        if (this.valueAnonymous.length == 0) {
            this.compianantData.Anonymous = false;
            this.passAnonymousInfo('No');
        }
    }

    passAnonymousInfo(anonymous) {
        this.dispatchEvent(
            new CustomEvent('isanonymous', {
                detail: {
                    message: anonymous,
                },
            })
        );
    }



    @api setpreferedContactMetodOptions(preferedContactMetodOptions) {
        console.log('123123');
        console.log('kkkkk1', preferedContactMetodOptions);
        this.preferedContactMetodOptions = [...this.preferedContactMetodOptions, ...preferedContactMetodOptions];
        console.log('kkkkk', this.preferedContactMetodOptions);

    }
    @api setLanguageOptions(languageOptions) {
        console.log('123333123');
        this.languageOptions = [...this.languageOptions, ...languageOptions];
    }

    @api setRelationships(relationShipToClientOptions) {
        console.log('relationShipToClientOptions', relationShipToClientOptions);
        this.relationshipOptions = [];
        //this.relationshipOptions = relationShipToClientOptions;
        this.relationshipOptions = [...this.relationshipOptions, ...relationShipToClientOptions];
        this.relationshipOptions.unshift({ label: '--None--', value: '' });
    }

    @api setPropertyMembersOptions(options) {
        console.log('[setPropertyMembersOptions] options', options);
        this.propertyMembersOptionswithFullData = options;
        this.propertyMembersOptions = [];
        if (!checkNull(options)) {
            options.forEach(element => {
                let elementOptions = {};
                elementOptions.label = element.fields.Contact.value.fields.Name.value;
                elementOptions.label = element.fields.Contact.value.fields.FirstName.value + ' ' + element.fields.Contact.value.fields.LastName.value;
                elementOptions.value = element.fields.Contact.value.id;
                this.propertyMembersOptions.push(elementOptions);
            });
            this.propertyMembersOptions.unshift({ label: '--None--', value: '' });
            this.propertyMembersOptions.push({ label: 'Other', value: 'Other' });

        } else {
            this.propertyMembersOptions = [];
            this.propertyMembersOptions.unshift({ label: '--None--', value: '' });
            this.propertyMembersOptions.push({ label: 'Other', value: 'Other' });
        }
    }

    connectedCallback() {
        this.pageLoaded = true;
        this.dispatchEvent(
            new CustomEvent('fetchcompinantiddetails', {
                detail: {
                    message: 'addComplainantPage',
                },
            })
        );
    }
    @api getCompianantId(compianantId) {
        this.compianantId = compianantId;
    }

    handleFormSubmit(event) {
        const fields = event.detail.fields;
    }
    handleOkay() {
        //this.close('okay');
        this.closeOkayaddNewCompainant();
    }
    closeOkayaddNewCompainant() {
        this.dispatchEvent(
            new CustomEvent('closeaddnewcompianiantpopup', {
                detail: {
                    message: 'AddNewComplainantPage ',
                },
            })
        );
    }
    openSpinner() {
        this.dispatchEvent(new CustomEvent('openspiner'));
    }
    closeSpinner() {
        this.dispatchEvent(new CustomEvent('closespiner'));
    }
    @api handleSubmitButtonClick() {
        try {
            this.template.querySelector('lightning-record-edit-form').submit();
            this.dispatchEvent(
                new CustomEvent('closespiner', {
                    detail: {
                        message: 'AddNewComplainantPage',
                    },
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new CustomEvent('closespiner', {
                    detail: {
                        message: 'AddNewComplainantPage',
                    },
                })
            );
            console.log('error', error);
        }
    }

    handleLoad() {
        this.dispatchEvent(
            new CustomEvent('closespiner', {
                detail: {
                    message: 'AddNewComplainantPage',
                },
            })
        );
    }
    setValuesToAllFields(idValue) {
        try {
            this.propertyMembersOptionswithFullData.forEach(element => {
                console.log('[setValuesToAllFields] element: ', element);
                if (element.fields.Contact.value.id == idValue) {
                    //console.log('this.compianantData.Phone', element.fields.Contact.value.fields.Phone.value);
                    this.compianantData.Id = element.fields.Contact.value.fields.AccountId.value;
                    this.compianantData.LastName = element.fields.Contact.value.fields.LastName.value;
                    this.compianantData.FirstName = element.fields.Contact.value.fields.FirstName.value;
                    this.compianantData.Phone = element.fields.Contact.value.fields.Phone.value;
                    this.compianantData.PersonEmail = element.fields.Contact.value.fields.Email.value;
                    // this.compianantData.FinServ__ContactPreference__pc = element.fields.Contact.value.fields.FinServ__ContactPreference__c.value;
                    this.compianantData.Contact_Preference__c = element.fields.Contact.value.fields.Contact_Preference__c.value;
                    this.compianantData.PersonMailingCountry = element.fields.Contact.value.fields.MailingCountry.value;
                    this.compianantData.PersonMailingStreet = element.fields.Contact.value.fields.MailingStreet.value;
                    this.compianantData.PersonMailingCity = element.fields.Contact.value.fields.MailingCity.value;
                    this.compianantData.PersonMailingState = element.fields.Contact.value.fields.MailingState.value;
                    this.compianantData.PersonMailingPostalCode = element.fields.Contact.value.fields.MailingPostalCode.value;
                    this.compianantData.Language__pc = element.fields.Contact.value.fields.Language__c.value;
                    if (
                        !checkNull(element.fields.Contact.value.fields.Phone.value)
                    ) {
                        const x = element.fields.Contact.value.fields.Phone.value
                            .replace(/\D+/g, '')
                            .match(/(\d{0,3})(\d{0,3})(\d{0,4})/);

                        this.phone = !x[2]
                            ? x[1]
                            : `(${x[1]}) ${x[2]}` + (x[3] ? `-${x[3]}` : ``);
                        console.log('this.compianantData.Phone__c', this.phone);
                    } else {
                        this.phone = '';
                    }
                }
            });
        } catch (error) {
            console.log('error', error);
        }
    }
    ComplainantDataprev = '';
    showOtherSpecifyOption = false;
    handleChange(event) {
        debugger;
        console.log('[handleChange] event.currentTarget.dataset.id', event.currentTarget.dataset.id);
        switch (event.currentTarget.dataset.id) {
            case 'ComplainantData':

                // this.template.querySelector('form').reset();
                console.log('0000000000000000000000001');
                this.compianantData.ComplainantData = event.detail.value;
                console.log('1231223s');
                if (this.ComplainantDataprev != event.detail.value) {
                    console.log('123122d3');
                    this.compianantData.relationshipValue = '';
                    if (this.compianantData.ComplainantData == 'Other') {
                        console.log('1232d123');
                        this.compianantData.LastName = '';
                        this.compianantData.FirstName = '';
                        this.compianantData.Phone = '';
                        this.compianantData.PersonEmail = '';
                        // this.compianantData.FinServ__ContactPreference__pc = '';
                        this.compianantData.Contact_Preference__c = '';
                        this.compianantData.PersonMailingCountry = '';
                        this.compianantData.PersonMailingStreet = '';
                        this.compianantData.PersonMailingCity = '';
                        this.compianantData.PersonMailingState = '';
                        this.compianantData.PersonMailingPostalCode = '';
                        this.compianantData.Language__pc = '';
                        this.phone = '';

                    }
                    //this.checkValidity();
                }

                this.ComplainantDataprev = event.detail.value;
                this.relationShipToClientOptionsDisable = true;
                this.relationShipRequired = false;
                console.log('1[handleChange] - compianantData.ComplainantData ',this.compianantData.ComplainantData);
                if (this.compianantData.ComplainantData == 'Other') {
                    this.relationShipToClientOptionsDisable = false;
                    this.relationShipRequired = true;
                }
                if (this.compianantData.ComplainantData != 'Other' && !checkNull(this.compianantData.ComplainantData)) {
                    console.log('this.compianantData.ComplainantData 000k', this.compianantData.ComplainantData);
                    this.setValuesToAllFields(this.compianantData.ComplainantData);
                }
                this.resetValidity();
                break;
            case 'Other_Relationship_to_Client__c':
                this.compianantData.otherRelationValue = event.detail.value;

                break;
            case 'Relationship_to_Client':
                console.log('0000000000000000000000002');
                this.compianantData.relationshipValue = event.detail.value;


                break;
            case 'Name':
                console.log('0000000000000000000000003');
                this.compianantData.Name = event.detail.value;
                break;
            case 'Phone__c':
                console.log('0000000000000000000000004');
                const x = event.target.value
                    .replace(/\D+/g, '')
                    .match(/(\d{0,3})(\d{0,3})(\d{0,4})/);

                event.target.value = !x[2]
                    ? x[1]
                    : `(${x[1]}) ${x[2]}` + (x[3] ? `-${x[3]}` : ``);
                this.phone = event.target.value;
                this.compianantData.Phone = event.detail.value.replaceAll(
                    /\D/g,
                    ''
                );
                if (this.compianantData.Phone.length > 10) {
                    this.compianantData.Phone = this.compianantData.Phone.slice(
                        0,
                        -1
                    );
                }
                if (this.validityCalled || this.phoneClicked) {
                    this.checkPhoneValidity();
                }
                break;
            case 'First_Name__c':
                console.log('0000000000000000000000005');
                this.compianantData.FirstName = event.detail.value;
                break;
            case 'Alternative_Phone__c':
                console.log('0000000000000000000000006');
                this.compianantData.Alternative_Phone__c = event.detail.value;
                break;
            case 'Last_Name__c':
                console.log('0000000000000000000000007');
                this.compianantData.LastName = event.detail.value;

                break;
            case 'Email__c':
                console.log('0000000000000000000000008');
                this.compianantData.PersonEmail = event.detail.value;
                if (this.validityCalled || this.emailClicked) {
                    this.checkEmailValidity();
                }
                break;
            case 'File_Number__c':
                console.log('0000000000000000000000009');
                this.compianantData.File_Number__c = event.detail.value;
                break;
            case 'Contact_Preference__c':
                console.log('0000000000000000000000010 Contact_Preference__c');
                this.compianantData.Contact_Preference__c = event.detail.value;
                this.addressFiedsRequired = true;
                if (
                    this.compianantData.Contact_Preference__c == 'Email' ||
                    this.compianantData.Contact_Preference__c == 'Phone'
                ) {
                    this.addressFiedsRequired = false;
                }
                if (this.validityCalled || this.emailClicked) {
                    this.checkEmailValidity();
                }
                if (this.validityCalled || this.phoneClicked) {
                    this.checkPhoneValidity();
                }
                if (this.validityCalled || this.streetClicked) {
                    this.checkAddressValidity1();
                }
                if (this.validityCalled || this.cityClicked) {
                    this.checkAddressValidity2();
                }
                if (this.validityCalled || this.state_ProvinceClicked) {
                    this.checkAddressValidity3();
                }
                if (this.validityCalled || this.postal_CodeClicked) {
                    this.checkAddressValidity4();
                }
                if (this.validityCalled || this.countryClicked) {
                    this.checkAddressValidity5();
                }

                break;
            case 'Country__c':
                console.log('0000000000000000000000011');
                this.compianantData.PersonMailingCountry = event.detail.value;
                break;
            case 'Street__c':
                console.log('0000000000000000000000012');
                this.compianantData.PersonMailingStreet = event.detail.value;
                break;
            case 'City__c':
                console.log('0000000000000000000000013');
                this.compianantData.PersonMailingCity = event.detail.value;
                break;
            case 'State_Province__c':
                console.log('0000000000000000000000014');
                this.compianantData.PersonMailingState = event.detail.value;
                break;
            case 'Postal_Code__c':
                this.compianantData.PersonMailingPostalCode = event.detail.value;
                break;
            case 'Language__pc':
                console.log('0000000000000000000000015');
                this.compianantData.Language__pc = event.detail.value;
                console.log('Language',this.compianantData.Language__pc);
                break;
            default:
        }

        this.emailRequired = false;
        this.phoneRequired = false;
        if (this.compianantData.Contact_Preference__c == 'Email') {
            this.emailRequired = true;
            let addressfields1 = this.template.querySelector('.addressfields1');
            let addressfields2 = this.template.querySelector('.addressfields2');
            let addressfields3 = this.template.querySelector('.addressfields3');
            let addressfields4 = this.template.querySelector('.addressfields4');
            let addressfields5 = this.template.querySelector('.addressfields5');
            addressfields1.required = false;
            addressfields2.required = false;
            addressfields3.required = false;
            addressfields4.required = false;
            addressfields5.required = false;
        }
        if (this.compianantData.Contact_Preference__c == 'Phone') {
            this.phoneRequired = true;
            let addressfields1 = this.template.querySelector('.addressfields1');
            let addressfields2 = this.template.querySelector('.addressfields2');
            let addressfields3 = this.template.querySelector('.addressfields3');
            let addressfields4 = this.template.querySelector('.addressfields4');
            let addressfields5 = this.template.querySelector('.addressfields5');
            addressfields1.required = false;
            addressfields2.required = false;
            addressfields3.required = false;
            addressfields4.required = false;
            addressfields5.required = false;
        }
        if (checkNull(this.compianantData.Contact_Preference__c)) {
            this.phoneRequired = true;
            this.emailRequired = true;
            let addressfields1 = this.template.querySelector('.addressfields1');
            let addressfields2 = this.template.querySelector('.addressfields2');
            let addressfields3 = this.template.querySelector('.addressfields3');
            let addressfields4 = this.template.querySelector('.addressfields4');
            let addressfields5 = this.template.querySelector('.addressfields5');
            addressfields1.required = true;
            addressfields2.required = true;
            addressfields3.required = true;
            addressfields4.required = true;
            addressfields5.required = true;
        }
        if (this.compianantData.Contact_Preference__c == 'Mail') {
            let addressfields1 = this.template.querySelector('.addressfields1');
            let addressfields2 = this.template.querySelector('.addressfields2');
            let addressfields3 = this.template.querySelector('.addressfields3');
            let addressfields4 = this.template.querySelector('.addressfields4');
            let addressfields5 = this.template.querySelector('.addressfields5');
            addressfields1.required = true;
            addressfields2.required = true;
            addressfields3.required = true;
            addressfields4.required = true;
            addressfields5.required = true;

        }
        if (this.compianantData.relationshipValue == 'Other (Please specify)') {
            this.showOtherSpecifyOption = true;
        } else {
            this.showOtherSpecifyOption = false;
            this.compianantData.otherRelationValue = '';
        }
        // 
    }

    addressInputChange(event) {
        this.openSpinner();
        this.setaddresslookup = false;
        this.strStreet = event.target.street;
        this.strCity = event.target.city;
        this.strState = event.target.province;
        this.strCountry = event.target.country;
        this.strPostalCode = event.target.postalCode;
        this.compianantData.PersonMailingCountry = this.strCountry;
        this.compianantData.PersonMailingStreet = this.strStreet;
        this.compianantData.PersonMailingCity = this.strCity;
        this.compianantData.PersonMailingState = event.target.province;
        this.compianantData.PersonMailingPostalCode = event.target.postalCode;

        setTimeout(() => {
            this.setaddresslookup = true;
            this.checkValidity();
        }, 1);
        setTimeout(() => {
            this.closeSpinner();
        }, 550);
    }
    checkAddressValidity2() {
        try {
            let addressfields2 = this.template.querySelector('.addressfields2');
            if (
                !addressfields2.value &&
                (this.compianantData.Contact_Preference__c != 'Email' &&
                    this.compianantData.Contact_Preference__c != 'Phone')
            ) {
                addressfields2.required = true;
            } else {
                addressfields2.required = false;
            }
            addressfields2.reportValidity();
        } catch (error) {
            console.log(error);
        }
    }
    checkAddressValidity3() {
        try {
            let addressfields3 = this.template.querySelector('.addressfields3');
            if (
                !addressfields3.value &&
                (this.compianantData.Contact_Preference__c != 'Email' &&
                    this.compianantData.Contact_Preference__c != 'Phone')
            ) {
                addressfields3.required = true;
            } else {
                addressfields3.required = false;
            }
            addressfields3.reportValidity();
        } catch (error) {
            console.log(error);
        }
    }
    checkAddressValidity4() {
        try {
            let addressfields4 = this.template.querySelector('.addressfields4');
            if (
                !addressfields4.value &&
                (this.compianantData.Contact_Preference__c != 'Email' &&
                    this.compianantData.Contact_Preference__c != 'Phone')
            ) {
                addressfields4.required = true;
            } else {
                addressfields4.required = false;
            }
            addressfields4.reportValidity();
        } catch (error) {
            console.log(error);
        }
    }
    checkAddressValidity5() {
        try {
            let addressfields5 = this.template.querySelector('.addressfields5');
            if (
                !addressfields5.value &&
                (this.compianantData.Contact_Preference__c != 'Email' &&
                    this.compianantData.Contact_Preference__c != 'Phone')
            ) {
                addressfields5.required = true;
            } else {
                addressfields5.required = false;
            }
            addressfields5.reportValidity();
        } catch (error) {
            console.log(error);
        }
    }

    checkAddressValidity1() {
        try {
            let addressfields1 = this.template.querySelector('.addressfields1');
            if (
                !addressfields1.value &&
                (this.compianantData.Contact_Preference__c != 'Email' &&
                    this.compianantData.Contact_Preference__c != 'Phone')
            ) {
                addressfields1.required = true;
            } else {
                addressfields1.required = false;
            }
            addressfields1.reportValidity();
        } catch (error) {
            console.log(error);
        }
    }

    @api passDataToParent() {
        this.checkValidity();
        console.log('this.compianantDataopx', JSON.stringify(this.compianantData));
        return this.compianantData;
    }
    checkEmailValidity() {
        let emailCmp = this.template.querySelector('.emailValidity');
        if (
            !emailCmp.value &&
            (this.compianantData.Contact_Preference__c == 'Email' ||
                checkNull(this.compianantData.Contact_Preference__c))
        ) {
            emailCmp.required = true;
            emailCmp.setCustomValidity('Complete this field');
        } else {
            emailCmp.required = false;
            emailCmp.setCustomValidity(''); // clear previous value
        }
        emailCmp.reportValidity();
    }
    checkPhoneValidity() {
        let phoneCmp = this.template.querySelector('.phoneValidity');
        if (
            !phoneCmp.value &&
            (this.compianantData.Contact_Preference__c == 'Phone' ||
                checkNull(this.compianantData.Contact_Preference__c))
        ) {
            phoneCmp.required = true;
            phoneCmp.setCustomValidity('Complete this field');
        } else {
            phoneCmp.required = false;
            phoneCmp.setCustomValidity(''); // clear previous value
        }
        phoneCmp.reportValidity();
    }

    @api checkValidity() {
        this.validityCalled = true;
        let isValid = true;
        this.template
            .querySelectorAll('.reportValidityClass')
            .forEach(element => {
                let checkValidtyData = false;
                checkValidtyData = element.reportValidity();
                if (!checkValidtyData) {
                    element.reportValidity();
                    isValid = false;
                }
            });
        return isValid;
    }
    resetValidity() {
        try {
            this.template
                .querySelectorAll('.reportValidityClass')
                .forEach(element => {
                    let req = element.required;
                    console.log('element.dataset.id', element.dataset.id);
                    console.log('element.dataset.id', req);
                    if (req) {
                        element.required = false;
                        element.setCustomValidity('');
                        element.reportValidity();


                        element.required = req;
                        //element.reset();
                    }
                });
        } catch (error) {
            console.log('error', error);
        }

    }
    correspondenceMethod;
    onceCalled = false;
    renderedCallback() {
        let emailCmp = this.template.querySelector('.emailValidity');
        let addressfields1 = this.template.querySelector('.addressfields1');
        let addressfields2 = this.template.querySelector('.addressfields2');
        let addressfields3 = this.template.querySelector('.addressfields3');
        let addressfields4 = this.template.querySelector('.addressfields4');
        let addressfields5 = this.template.querySelector('.addressfields5');
        if (
            emailCmp &&
            addressfields1 &&
            addressfields2 &&
            addressfields3 &&
            addressfields4 &&
            addressfields5 &&
            !this.onceCalled
        ) {
            this.onceCalled = true;
            if (this.correspondenceMethod) {
                this.hitCorrespondenceMethodValidationAfterAllFieldLoaded();
            }
        }
    }

    hitCorrespondenceMethodValidationAfterAllFieldLoaded() {
        let correspondenceMethod = this.correspondenceMethod;

        try {
            if (correspondenceMethod == 'Email') {
                let emailCmp = this.template.querySelector('.emailValidity');
                if (!emailCmp.value) {
                    emailCmp.required = true;
                    //emailCmp.setCustomValidity("Complete this field");
                    emailCmp.reportValidity();
                }
                if (!this.emailRequired) {
                    emailCmp.required = false;
                }
                // this.compianantData.Email__c = event.detail.value;
                // this.compianantData
            } else if (correspondenceMethod == 'Mail') {
                let addressfields1 = this.template.querySelector('.addressfields1');
                let addressfields2 = this.template.querySelector('.addressfields2');
                let addressfields3 = this.template.querySelector('.addressfields3');
                let addressfields4 = this.template.querySelector('.addressfields4');
                let addressfields5 = this.template.querySelector('.addressfields5');

                if (!addressfields1.value) {
                    addressfields1.required = true;
                    //addressfields1.setCustomValidity("Complete this field");
                    addressfields1.reportValidity();
                }
                if (!addressfields2.value) {
                    addressfields2.required = true;
                    //addressfields2.setCustomValidity("Complete this field");
                    addressfields2.reportValidity();
                }
                if (!addressfields3.value) {
                    addressfields3.required = true;
                    //addressfields3.setCustomValidity("Complete this field");
                    addressfields3.reportValidity();
                }
                if (!addressfields4.value) {
                    addressfields4.required = true;
                    //addressfields4.setCustomValidity("Complete this field");
                    addressfields4.reportValidity();
                }
                if (!addressfields5.value) {
                    addressfields5.required = true;
                    //addressfields5.setCustomValidity("Complete this field");
                    addressfields5.reportValidity();
                }
                if (!this.addressFiedsRequired) {
                    addressfields1.required = false;
                    addressfields2.required = false;
                    addressfields3.required = false;
                    addressfields4.required = false;
                    addressfields5.required = false;
                }
            }
        } catch (error) {
            console.log('error', error);
        }
    }

    @api hitCorrespondenceMethodValidation(correspondenceMethod) {
        this.correspondenceMethod = correspondenceMethod;
        if (this.onceCalled) {
            this.hitCorrespondenceMethodValidationAfterAllFieldLoaded();
        }
    }
    @api setDataFromParent(compianantData) {
        this.compianantData = compianantData;
        if (
            !checkNull(this.compianantData) &&
            !checkNull(this.compianantData.Phone)
        ) {
            const x = this.compianantData.Phone
                .replace(/\D+/g, '')
                .match(/(\d{0,3})(\d{0,3})(\d{0,4})/);

            this.phone = !x[2]
                ? x[1]
                : `(${x[1]}) ${x[2]}` + (x[3] ? `-${x[3]}` : ``);
        }
        this.emailRequired = false;
        this.phoneRequired = false;
        if (this.compianantData.Contact_Preference__c == 'Email') {
            this.emailRequired = true;
        }
        if (this.compianantData.Contact_Preference__c == 'Phone') {
            this.phoneRequired = true;
        }
        if (checkNull(this.compianantData.Contact_Preference__c)) {
            this.phoneRequired = true;
            this.emailRequired = true;
        }
        this.addressFiedsRequired = true;
        if (
            this.compianantData.Contact_Preference__c == 'Email' ||
            this.compianantData.Contact_Preference__c == 'Phone'
        ) {
            this.addressFiedsRequired = false;
        }
        if (this.compianantData.ComplainantData == 'Other') {
            this.relationShipToClientOptionsDisable = false;
            this.relationShipRequired = true;
        }
        this.showOtherSpecifyOption = false;
        if (this.compianantData.relationshipValue == 'Other (Please specify)') {
            this.showOtherSpecifyOption = true;
        }
        console.log('compianantData.otherRelationValue', this.compianantData.otherRelationValue);
        this.valueAnonymous = [];
        if (this.compianantData.Anonymous) {
            this.valueAnonymous = ["Anonymous"];
        }

        this.handleLoad();
    }

    inputClicked(event) {
        switch (event.currentTarget.dataset.id) {
            case 'Phone__c':
                this.phoneClicked = true;
                break;
            case 'Email__c':
                this.emailClicked = true;
                break;
            case 'Country__c':
                this.countryClicked = true;
                break;
            case 'Street__c':
                this.streetClicked = true;
                break;
            case 'City__c':
                this.cityClicked = true;
                break;
            case 'State_Province__c':
                this.state_ProvinceClicked = true;
                break;
            case 'Postal_Code__c':
                this.postal_CodeClicked = true;
                break;
        }
    }
}