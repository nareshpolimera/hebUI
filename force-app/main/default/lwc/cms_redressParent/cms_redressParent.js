import { LightningElement,track,api } from 'lwc';
import { checkNull } from "c/cms_jsUtility";

export default class Cms_redressParent extends LightningElement {
    @track redressList ;
    @track redressExists = false;
    redressDataEditing = {};
    isValid = false;
    @api caseId = '';
    countI = 0
    redressData;
    closeSpinner(){
        this.dispatchEvent(new CustomEvent('closespiner', {
            detail: {
                message: 'redressPage'
            }
        }));
    }
    @api
    getCaseId(caseId) {
        console.log('caseId', caseId);
        this.caseId = caseId
        this.template.querySelector('c-cms_case-redress').getCaseId(this.caseId);
        //this.closeSpinner();
    }
    @api populateRedressDataFromParent(redressData) {
        if (redressData) {
            this.redressData = redressData;
        }
    }

    passRedress(){
        this.pageLoaded = true;
          this.dispatchEvent(new CustomEvent('fetchredressddetails', {
              detail: {
                  message: 'redresspage'
              }
          }));

    }
    addMoreRedress(){
        if(this.checkValidity()){
            
            this.addRedressDataToList();
            this.template.querySelector('c-cms_case-redress').setNewForm();
        }
        
        
    }
    @api checkValidity(){
        console.log('21321');
        return this.template.querySelector('c-cms_case-redress').checkValidity();
    }
    getRedressDetails(){
        this.redressDataEditing = this.template.querySelector('c-cms_case-redress').fetchRedressDataIfNoCaseId();
        console.log('0001', this.redressDataEditing);

    }
    
    addRedressDataToList(){
        this.getRedressDetails();
        this.countI++;
        console.log('22321');
        if(!this.redressList){
            console.log('2s2321');
            this.redressList = [];
            console.log('22a321');
        }
        console.log('2a2a321',this.redressDataEditing);
        this.redressDataEditing  =JSON.parse(JSON.stringify(this.redressDataEditing));
        console.log('2a2a321',this.redressDataEditing);
        this.redressDataEditing.IdIndex = this.countI;
        this.redressDataEditing.Case__c = this.caseId;
        console.log('22aq321');
        this.redressList.push(this.redressDataEditing);
        console.log('0002',this.redressList);
        this.redressExists = false;
        if(!checkNull(this.redressList)){
            this.redressExists = true;
            if(this.redressList.length == 1){
                this.dispatchEvent(new CustomEvent('closeerror', {
                    detail: {
                        message: 'redressPage'
                    }
                }));
            }
        }
        
    }
    @api
    fetchRedressList(){
        console.log('this.redressList122d',this.redressList);
        return this.redressList;
    }
    connectedCallback(){
        this.passRedressList();
    }
    passRedressList(){
        this.dispatchEvent(new CustomEvent('fetchredressddetailslist', {
            detail: {
                message: 'redresspage'
            }
        }));
    
    }
    @api
    setRedressDataListFromParent(redressList){
        try{
            
            this.redressList = redressList;
            console.log('this.redressList00k',this.redressList)
            if(!checkNull(this.redressList)){
                this.redressExists = true;
            }
        }catch(e){
            console.log('error',e)
        }
        
    }

    Remove(event){

        let dataRecId =  event.currentTarget.dataset.id
        let tempData = [];
        this.redressList.forEach(optionData => {
            if(optionData.IdIndex != dataRecId){
                tempData.push(optionData);
            }
        });
        this.redressList = tempData;
        this.redressExists = false;
        if(!checkNull(this.redressList)){
            this.redressExists = true;
        }
    }
    
}