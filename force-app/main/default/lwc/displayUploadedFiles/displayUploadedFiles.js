import { LightningElement,wire,track,api } from 'lwc';
import fetchFiles from '@salesforce/apex/displayUploadedFilesController.fetchFiles';
import deleteFiles from '@salesforce/apex/displayUploadedFilesController.deleteFiles';
import LightningConfirm from 'lightning/confirm';
import FileCommunicationChannel from '@salesforce/messageChannel/FileCommunicationChannel__c';
import {MessageContext,subscribe,unsubscribe,APPLICATION_SCOPE} from 'lightning/messageService';
 
export default class DisplayUploadedFiles extends LightningElement {
@api recordId;
rowOffset = 0;
content_version_records;
@track sortBy;
@track sortDirection;

@wire(MessageContext)
context;

subscribeEvent(){   
    subscribe(this.context,FileCommunicationChannel,(message) => {this.handleUploadFileEvent(message)},{scope:APPLICATION_SCOPE})
}

@track columns = [
    {
        type: 'button-icon',
        initialWidth: 34,
        typeAttributes:
        {
            iconName: 'utility:delete',
            name: 'delete',
            iconClass: 'slds-icon-text-default'
        }
    } ,
   {
       label: 'Document',
       sortable: true,
       fieldName: 'Document_Type__c'
   },
   {
       label: 'Related To',
       sortable: true,
       fieldName: 'Related_Entity_Name__c'
   },
   {
    label: 'File Name',
    fieldName: 'nameUrl',
    type: 'url',
    sortable: true,
    typeAttributes: {label: { fieldName: 'Title' }, 
    target: '_self'}
  },
  {
    label: 'Uploaded On',
    fieldName: 'CreatedDate',
    type: 'date', 
    sortable: true,
    typeAttributes: {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true
   }
}  
];

connectedCallback(){

   this.subscribeEvent();

   fetchFiles({ recordId : this.recordId})
   .then( result => {
        let nameUrl;
        console.log('result :: ', result);
//       this.content_version_records = result;

       this.content_version_records = result.map(row => { 
                                                nameUrl = `/${row.ContentDocumentId}`;
                                                return {...row , nameUrl} 
                                            })

       console.log('content version records : ' , this.content_version_records)
   })
   .catch(error => {
       console.log(error)
   })
}

// code using wire property to check if component refreshes automatically

// @wire(fetchFiles , {recordId : '$this.recordId'})
// wiredData({ error, data}){
//     if(data){
//         let nameUrl;
//         console.log('result :: ', data);
//         this.content_version_records = data.map(row => { 
//                                                             nameUrl = `/${row.ContentDocumentId}`;
//                                                             return {...row , nameUrl} 
//                                                         })
            
//         console.log('content version records : ' , this.content_version_records)
//     }
//     else if(error){
//         console.log(error);
//     }
// }


handleRowAction(event) {
   console.log('Delete clicked');
   const row = event.detail.row;
   console.log('row Id is: ', row.Id);
   const actionName = event.detail.action.name;
   switch (actionName) {
       case 'delete':
           this.deleteRow(row);
           break;
       // case 'show_details':
       //     this.showRowDetails(row);
       //     break;
       default:
   }
}

deleteRow(row){
    
    console.log('Delete Row Called : ' , row.Id);

    LightningConfirm.open({
        message: 'Are you sure you want to delete',
        variant: 'headerless'
    })
    .then( result => {
        if(result === true){
            console.log('Confirmation to delete')
            this.deleteDocuments(row);
        }
        
    })
}

deleteDocuments(row){

    deleteFiles({ contentVersionId : row.Id })
    .then( result => {
        console.log('Deleted Successfully')
        const index = this.findRowIndexById(row.Id);
        if (index !== -1) {
            this.content_version_records = this.content_version_records
                .slice(0, index)
                .concat(this.content_version_records.slice(index + 1));
        }
    })
    .catch()

}

 
findRowIndexById(id) {
    console.log('find row index called : ', id);
   let ret = -1;
   this.content_version_records.some((row, index) => {
    console.log('index is ', index)  
    console.log('row id is', row.Id ) 
    if (row.Id === id) {
           ret = index;
           return true;
       }
       return false;
   });
   console.log('return from find row index : ', ret);
   return ret;
}

handleUploadFileEvent(message){
    console.log('message is ', message.lmsData.value)
    console.log('record id is ', this.recordId)

    setTimeout(() => {
        this.refreshDataTable();
    },100)
}

refreshDataTable(){
    fetchFiles({ recordId : this.recordId})
    .then( result => {
         let nameUrl;
         this.content_version_records=null;
         console.log('result from refresh table:: ', result);
        this.content_version_records = result.map(row => { 
                                                 nameUrl = `/${row.ContentDocumentId}`;
                                                 return {...row , nameUrl} 
                                             })
 
        console.log('content version records : ' , this.content_version_records)
    })
    .catch(error => {
        console.log(error)
    })
}

doSorting(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(this.sortBy, this.sortDirection);
}

sortData(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.content_version_records));
    // Return the value stored in the field
    let keyValue = (a) => {
        return a[fieldname];
    };
    // cheking reverse direction
    let isReverse = direction === 'asc' ? 1: -1;
    // sorting data
    parseData.sort((x, y) => {
        x = keyValue(x) ? keyValue(x) : ''; // handling null values
        y = keyValue(y) ? keyValue(y) : '';
        // sorting values based on direction
        return isReverse * ((x > y) - (y > x));
    });
    this.content_version_records = parseData;
}    

}