import { api, LightningElement, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchFSAs from '@salesforce/apex/PropertyAddressValidatorController.fetchFSAs';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import FSA_OBJECT from '@salesforce/schema/FSA__c';
import PROVINCE_FIELD from '@salesforce/schema/FSA__c.Province__c';

const columns = [
    { label: 'FSA', fieldName: 'FSA__c'},
    { label: 'City', fieldName: 'City__c' },
    { label: 'Province', fieldName: 'ProvinceLabel' },
];

const DELAY = 300;


export default class PropertyAddressValidator extends LightningElement {   
    ProvincePicklist;
    ProvincePicklistList;    
    error;
    columns = columns;
    totalRecords;
    pageNo;
    totalPages;
    startRecord;
    endRecord;
    end = false;
    pagelinks = [];
    isLoading = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    ortedBy;
    selectedRecord;  

    @track showTable = true;
    @track records;
    @track recordsperpage = 10;  
    @track recordsToDisplay;
    @track isModalOpen = false;

    @api searchKey;
    @api isModelOpenByDefault;

    @api
    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        const selectedEvent = new CustomEvent('fsaselect', { detail: undefined });
        this.dispatchEvent(selectedEvent);
    }

    @wire(getObjectInfo, { objectApiName: FSA_OBJECT })
    fsaMetadata;
    
    @wire(getPicklistValues, {
                                recordTypeId: '$fsaMetadata.data.defaultRecordTypeId', 
                                fieldApiName: PROVINCE_FIELD
                             }
    ) wiredProvincePicklist({ data }) {
        if (data) {
            this.ProvincePicklist = data.values;
            console.log('this.ProvincePicklist : ', this.ProvincePicklist);
            this.loadFSAData();
        } 
    }
    
    get recordsToDisplayLength() {
        console.log('dd',this.recordsToDisplay);
        return this.recordsToDisplay?.length;
    }

    /**
     * submitDetails : send selected details to others. 
     */
    submitDetails() {      
        if(this.selectedRecord) {
            this.isModalOpen = false;
            const selectedEvent = new CustomEvent('fsaselect', { detail: this.selectedRecord });
            this.dispatchEvent(selectedEvent);
        }  else {
            console.log('Please select a location or Cancel to return to previous screen');
            const evt = new ShowToastEvent({
            message: 'Please select a location or Cancel to return to previous screen',
            variant: "error",
        });
        this.dispatchEvent(evt);
        }
    }

    /**
     * connectedCallback : Method will get called before loading component. It will fetch all required data
     */
    connectedCallback() {
        this.isLoading = true;
        if(this.isModelOpenByDefault) {
            this.isModalOpen = true;
        }        
    }

    /**
     * Load FSA Data
     */
    loadFSAData() {
        this.isLoading = true;
        fetchFSAs({ searchTerm: this.searchKey }).then((result) => {
            this.records = result;
            this.error = undefined;
            this.setPicklistLabelOnFSA();
            this.setRecordsToDisplay();
        }).catch((error) => {
            this.error = error;
            this.records = undefined;
        });
    }

    setPicklistLabelOnFSA() {        
        this.records.forEach(fsaRecord => {
            if (fsaRecord.Province__c) {
                let pickListDetails = this.ProvincePicklist.find(pickList => pickList.value == fsaRecord.Province__c);
                fsaRecord.ProvinceLabel = pickListDetails.label;
            }
        });

        this.records = JSON.parse(JSON.stringify(this.records));
        //this.preparePaginationList();
    }

    /**
     * setRecordsToDisplay : Pagination Method to create list of records to display based on Pageno 
     */
    setRecordsToDisplay() {
        this.totalRecords = this.records.length;
        this.pageNo = 1;
        this.totalPages = Math.ceil(this.totalRecords / this.recordsperpage);
        this.preparePaginationList();

        for (let i = 1; i <= this.totalPages; i++) {
            this.pagelinks.push(i);
        }
        this.isLoading = false;
    }

    /**
     * handleClick : Click method of First, Last, Previous & Last buttons    
     */
    handleClick(event) {
        let label = event.target.title;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleNext() {
        this.pageNo += 1;
        this.preparePaginationList();
    }

    handlePrevious() {
        this.pageNo -= 1;
        this.preparePaginationList();
    }

    handleFirst() {
        this.pageNo = 1;
        this.preparePaginationList();
    }

    handleLast() {
        this.pageNo = this.totalPages;
        this.preparePaginationList();
    }

    /**
     * preparePaginationList : This method will set the pagination page numbers and their bounds
     */
    preparePaginationList() {
        this.isLoading = true;
        let begin = (this.pageNo - 1) * parseInt(this.recordsperpage);
        let end = parseInt(begin) + parseInt(this.recordsperpage);
        this.recordsToDisplay = this.records.slice(begin, end);

        this.startRecord = begin + parseInt(1);
        this.endRecord = end > this.totalRecords ? this.totalRecords : end;
        this.end = end > this.totalRecords ? true : false;

        const event = new CustomEvent('pagination', {
            detail: { 
                records : this.recordsToDisplay
            }
        });
        this.dispatchEvent(event);

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);
        this.isLoading = false;
    }

    /**
     * disableEnableActions : Disbale pagination buttons when user is on that button like Last or First or particular page no
     */
    disableEnableActions() {
        let ltngButtons = this.template.querySelectorAll("lightning-button");
        let htmlButtons = this.template.querySelectorAll("button");
        let allButtons = [...ltngButtons, ...htmlButtons];

        allButtons.forEach(bun => {
            let buttonLabel = (bun.title) ? bun.title : bun.outerText;
            if (buttonLabel == this.pageNo) {
                bun.disabled = true;
            } else {
                bun.disabled = false;
            }

            if (buttonLabel === "First") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (buttonLabel === "Previous") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (buttonLabel === "Next") {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            } else if (buttonLabel === "Last") {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            }
        });
    }

    /**
     * handleRowAction : Handle rowAction event of table
     */
    handleRowAction(event){
        let recordId = event.target.selectedRows[0];
        this.selectedRecord = this.recordsToDisplay.find(record => record.Id == recordId);
        console.log('selectedRecord : ', this.selectedRecord);


    }

    /**
     * handlePage : set the page number when button is clicked
     */
    handlePage(button) {
        this.pageNo = parseInt(button.target.outerText);
        this.preparePaginationList();
    }

    /**
     * renderedCallback : Lifecycle method that will be called every time any change happens on dom 
     */
    renderedCallback() {
       /*if(this.ProvincePicklist.data && !this.ProvincePicklistList) {
           this.ProvincePicklistList = this.ProvincePicklist.data.values;
           console.log('ProvincePicklist.values : ' + this.ProvincePicklistList);

            this.records.forEach(fsaRecord => {
                if(fsaRecord.Province__c) {
                    let pickListDetails = this.ProvincePicklistList.find(pickList => pickList.value == fsaRecord.Province__c);
                    fsaRecord.ProvinceLabel = pickListDetails.label;
                }
            });

            this.records = JSON.parse(JSON.stringify(this.records));
            this.preparePaginationList();
       }*/
    }

}