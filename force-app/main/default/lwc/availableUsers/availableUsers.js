import { LightningElement, wire, track } from 'lwc';
import {fireEvent} from 'c/pubsub';
import{CurrentPageReference} from 'lightning/navigation';
import getSortedSpecialst from '@salesforce/apex/EventAssignmentService.getSortedSpecialistList';


export default class AvailableUsers extends LightningElement {

    @track assignedLeads;

    @wire(CurrentPageReference) pageRef;

    colorsOn = false;

    // Map of colors to specialsits
    colorUIDMap = [];
    
    // Static list of 20 colors
    colorList =  [  '#726673', '#F00EE9', '#FF6600', '#00FF00', '#6600FF', 
                    '#0E63F0', '#800000', '#e6194B', '#f58231', '#666633',
                    '#00FF99', '#00CC99', '#00FFFF', '#996633', '#99CCFF',
                    '#6600FF', '#9900FF', '#996699', '#808000', '#660033',
                ];

    // Retrieve the list of specialists from EventAssignmentService
    @wire(getSortedSpecialst)
    wiredGetSortedSpecialst(result) {

        // Data has been retrieved
        if(result.data) {
            console.log('success');
            console.log(result.data)
            // Add specialists to tracked list
            this.assignedLeads = result.data;
            var arrId = [];
            // Map colors to specialists
            for (var i = 0; i < result.data.length; i++) {
                arrId.push(result.data[i].User__c);
            }

            for (var i = 0; i < arrId.length; i++) {
                this.colorUIDMap[arrId[i]] = this.colorList[i];
            }
        } else {
            // There has been an issue retrieving the data
            console.log('error');
            console.log(result.error);
        }
    }

    // Handle selecting a specific specialist user
    toggleCalendar(event) {
        console.log('toggling calendar');
        var trElements = this.template.querySelectorAll('tr')
        for (var i = 0; i < trElements.length; i++) {
            if(trElements[i].className = 'slds-hint-parent dataRow') {
                    if(trElements[i].dataset.id != event.target.dataset.id) {
                        trElements[i].className = 'slds-hint-parent dataRow';
                        console.log(trElements[i].dataset.id + ' does not equal ' + event.target.dataset.id);
                    } else {
                        trElements[i].className = 'slds-hint-parent dataRow slds-theme_shade';
                    }
            }
        }
        console.log('queryselectorend')
        console.log(event.target.dataset.id);
        var data = [];
        data['id'] = event.target.dataset.id;
        data['color'] = this.colorUIDMap[event.target.dataset.id];
        console.log(event.target);
        fireEvent(this.pageRef, 'handleToggleCalendar', data);
        console.log('after fire event');
    }

    // After re-rendering elements, add colors and refresh
    renderedCallback() {
        console.log('rendered callback');
        console.log(this.template.querySelectorAll('tr'));
        var trElements = this.template.querySelectorAll('tr')
        for (var i = 0; i < trElements.length; i++) {
            //var color = this.colorList[i];
            console.log('setting color for rows');
            console.log(this.colorUIDMap);
            console.log(trElements[i].dataset.id);
            console.log('ending setting color');
        }
        console.log(this.colorUIDMap);
        console.log('rendered callback');
        this.refresh();
    }

    // Select top specialist and refresh data / UI
    refresh() {
        console.log('refreshing child');
        // Refresh wired data
        getSortedSpecialst().then( result =>{
            console.log('fetching assigned');
            console.log(result.data);
            if(result.data) {
                this.assignedLeads = result.data;
            }

            // Refresh calendar 
            var data = [];
            data['id'] = this.assignedLeads[0].User__c;
            data['color'] = this.colorUIDMap[this.assignedLeads[0].User__c];
            this.addColor();
            // Select the top specialist
            var trElements = this.template.querySelectorAll('tr')
            //trElements[0].class
            for (var i = 0; i < trElements.length; i++) {
                if((trElements[i].className = 'slds-hint-parent dataRow') && (i == 1)) {
                        trElements[i].className = 'slds-hint-parent dataRow slds-theme_shade';
                        console.log(trElements[i].className);
                }
            }
            fireEvent(this.pageRef, 'handleToggleCalendar', data);
        })
        .catch( error =>{
            console.log('error refreshing');
            console.log(error);
        });
    }

    // Select all specialists and show all events on calendar
    viewAll() {
        var trElements = this.template.querySelectorAll('tr')
        for (var i = 0; i < trElements.length; i++) {
            if(trElements[i].className = 'slds-hint-parent dataRow') {
                    trElements[i].className = 'slds-hint-parent dataRow slds-theme_shade';
                    console.log(trElements[i].className);
            }
        }
        fireEvent(this.pageRef, 'handleRefresh', this.colorUIDMap);
    }

    // Refresh colors
    addColor() {
        var trElements = this.template.querySelectorAll('tr')
        for (var i = 0; i < trElements.length; i++) {
            if(trElements[i].className = 'slds-hint-parent dataRow') {
                    trElements[i].style.color = this.colorUIDMap[trElements[i].dataset.id];
                    console.log(trElements[i].className);
            }
        }
        this.colorsOn = true;
    }

}