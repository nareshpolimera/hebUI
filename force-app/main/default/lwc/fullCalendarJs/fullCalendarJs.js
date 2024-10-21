import { LightningElement, wire, track, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS';
import fetchAllEvents from '@salesforce/apex/FullCalendarService.fetchAllEvents';
import fetchAllEventsByUser from '@salesforce/apex/FullCalendarService.fetchAllEventsByUser';
import getUsernameById from '@salesforce/apex/AvailableUsersService.getUsernameById';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import{CurrentPageReference} from 'lightning/navigation';
import EVENT_OBJECT from '@salesforce/schema/Event';
import OWNER_ID_FIELD from '@salesforce/schema/Event.OwnerId';
import START_FIELD from '@salesforce/schema/Event.StartDateTime';
import END_FIELD from '@salesforce/schema/Event.EndDateTime';
import SUBJECT_FIELD from '@salesforce/schema/Event.Subject';
import { createRecord } from 'lightning/uiRecordApi';
import createNewEvent from '@salesforce/apex/FullCalendarService.createNewEvent';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import { updateRecord } from 'lightning/uiRecordApi';
import getSortedSpecialst from '@salesforce/apex/EventAssignmentService.getSortedSpecialistList';


/**
 * FullCalendarJs
 * @description Full Calendar JS - Lightning Web Components
 */
export default class FullCalendarJs extends LightningElement {

  fullCalendarJsInitialised = false;
  wiredEvents = [];
  _eventResponse;
  _eventUserResponse;
  selectedUser = null;
  selectedColor = null;
  colorUIDMap = [];
  @api recordId;

  @wire(CurrentPageReference) pageRef;
  // Controls save modal display
  @track bShowModal = false;
  // Map of colors to specialists / events
  colorList =  [  '#726673', '#F00EE9', '#FF6600', '#00FF00', '#6600FF', 
                  '#0E63F0', '#800000', '#e6194B', '#f58231', '#666633',
                  '#00FF99', '#00CC99', '#00FFFF', '#996633', '#99CCFF',
                  '#6600FF', '#9900FF', '#996699', '#808000', '#660033',
              ];  

  
  // Opens event save modal 
  openModal() {
      this.bShowModal = true;
  }

  // Closes event save modal
  closeModal() {
      const el = this.template.querySelector('div.createNewEvent');
      $(el).attr('class', 'slds-hide createNewEvent');
      this.bShowModal = false;
  }

  // Get most recent hundred events for specialists 
  @wire(fetchAllEvents)
  fetchAllEventsWired(result) {
    if(result) {
      this._eventResponse = result;
    } else {
      this._eventResponse = result.error;
    }

      this.wiredEvents = [];
      
      if((this.selectedUser == null) || (this.selectedUser == '')) {
        if(result.data) {
          var idArr = []
          for (var i = 0; i < result.data.length; i++) {
            if(!idArr.includes(result.data[i].OwnerId)){
              idArr.push(result.data[i].OwnerId);
            }
          }
          for (var i = 0; i < result.data.length; i++) {
            this.colorUIDMap[idArr[i]] = this.colorList[i];
          }

          for (var i = 0; i < result.data.length; i++) {
              var item = result.data[i];
              var startDateConvertedObject = new Date(item.StartDateTime);
              var endDateConvertedObject = new Date(item.EndDateTime);
              var modifiedItem = {
                  id : item.Id,
              editable : false,
              title : item.Subject,
              start : startDateConvertedObject.toLocaleString(),
              end : endDateConvertedObject.toLocaleString(),
              description : item.Description,
              allDay : false,
              extendedProps : {
                whoId : item.WhoId,
                whatId : item.WhatId
              }
              }
              this.wiredEvents.push(modifiedItem);
          }
        }
        else if(result.error) {
            console.log(result.error);
        } else {
            console.log('Untraceable error');
        }
      } else {
        var detailArr = []
        detailArr['id'] = this.selectedUser;
        detailArr['color'] = this.selectedColor;
        this.renderNewEventsByUser(detailArr);
      }
  }

  /**
   * @description Standard lifecyle method 'renderedCallback'
   *              Ensures that the page loads and renders the 
   *              container before doing anything else
   */
  renderedCallback() {

    // Performs this operation only on first render
    if (this.fullCalendarJsInitialised) {
      return;
    }
    this.fullCalendarJsInitialised = true;
    
    // Executes all loadScript and loadStyle promises
    // and only resolves them once all promises are done
    Promise.all([
      loadScript(this, FullCalendarJS + '/jquery.min.js'),
      loadScript(this, FullCalendarJS + '/moment.min.js'),
      loadScript(this, FullCalendarJS + '/fullcalendar.min.js'),
      loadStyle(this, FullCalendarJS + '/fullcalendar.min.css'),
    ])
    .then(() => {
      // Initialise the calendar configuration
      this.initialiseFullCalendarJs2();
      getSortedSpecialst()
      .then( result => {
        var arrId = [];
        for (var i = 0; i < result.length; i++) {
            arrId.push(result[i].User__c);
        }
        for (var i = 0; i < arrId.length; i++) {
            this.colorUIDMap[arrId[i]] = this.colorList[i];
        }
        var detail = [];
        detail['id'] = result[0].User__c;
        detail['color'] = this.colorUIDMap[result[0].User__c];
        this.toggleCalendar(detail);
      }).catch(error => {
        console.log('fc error');
        console.log(error);
      });
    })
    .catch(error => {
      console.error({
        message: 'Error occured on FullCalendarJS',
        error
      });
    })
  }

   /**
   * @description Initialise the calendar configuration
   *              This is where we configure the available options for the calendar.
   *              This is also where we load the Events data.
   */
  initialiseFullCalendarJs2() {

    const ele = this.template.querySelector('div.fullcalendarjs');

    // eslint-disable-next-line no-undef
    $(ele).fullCalendar({
      header: {
          left: 'prev,next today',
          center: 'title',
          right: 'month,agendaWeek,agendaDay'
      },
      timeZone: 'America/Seattle',
      // defaultDate: new Date(), // default day is today
      navLinks: true, // can click day/week names to navigate views
      editable: false,
      eventLimit: true, // allow "more" link when too many events
      events: this.wiredEvents,
      businessHours: {
        dow: [1, 2, 3, 4, 5],
        start: '08:00',
        end: '18:00',
      },
      scrollTime: '08:00',
      defaultView: 'agendaWeek',

      eventClick: function(info) {
        console.log('replacing');
        console.log(info.id);
        var itemId = info.id;
        window.location.replace("/lightning/r/Event/" + itemId + "/view");
      },

      dayClick: function(date, jsEvent, view) {
        
        var all = $(this).parents();
        var allInputs = all.find('input');
        for (var i = 0; i < allInputs.length; i++) {
            console.log('inputs')
            console.log(allInputs[i].className + ' ' + allInputs[i].tagName);
            if(allInputs[i].className == '') {

            }
        }
        var assignedTo = all.find('.assignedTo').first();

        if((assignedTo.val() == null) || (assignedTo.val() == '')) {
          alert('Please select a user before adding an event');
          console.log('dispatched event');
          return;
        }

        var hider = all.find('.slds-hide.createNewEvent');
        $(hider).attr('class', 'createNewEvent')
        var startDate = all.find('.startDate').first();
        var endDate = all.find('.endDate').first();
        
        startDate.val(moment(date).format('YYYY-MM-DD'));
        endDate.val(moment(date).format('YYYY-MM-DD'));
        if(view.viewSpec['type'] != 'month') {
          var startTime =   all.find('.startTime').first();
          var endTime =   all.find('.endTime').first();
          startTime.val(moment(date).format('HH:mm'));
          date = moment(date).add('30', 'm');
          endTime.val(date.format('HH:mm'));
        }
      }
    });
  }

  // Allow communication between user list and calendar
  connectedCallback() {
      registerListener('handleToggleCalendar', this.toggleCalendar, this);
      registerListener('handleRefresh', this.refresh, this);
  }

  // Allow communication between user list and calendar
  disconnectedCallback() {
      unregisterAllListeners(this);
  }

  // Refresh calendar with new details
  refresh(detail) {
      this.selectedUser = null;
      var el = this.template.querySelector('input.assignedTo');
      $(el).val(null);
      fetchAllEvents()
      .then(result => {
          const ele = this.template.querySelector('div.fullcalendarjs');
          $(ele).fullCalendar('removeEvents');
          this.wiredEvents = result;
          var newEvents = [];
          for (var i = 0; i < result.length; i++) {
              var item = result[i];
              var eventColor = detail[item.OwnerId];
              var startDateConvertedObject = new Date(item.StartDateTime);
              var endDateConvertedObject = new Date(item.EndDateTime);

              var modifiedItem = {
                  id : item.Id,
              editable : false,
              title : item.Subject,
              start : startDateConvertedObject.toLocaleString(),
              end : endDateConvertedObject.toLocaleString(),
              description : item.Description,
              allDay : false,
              color: eventColor,
              extendedProps : {
                whoId : item.WhoId,
                whatId : item.WhatId
              }
              }
              newEvents.push(modifiedItem);
          }

          $(ele).fullCalendar( 'addEventSource', newEvents);
          $(ele).fullCalendar('refetchEvents');
      })
      .catch(error => {
          console.log('Refresh error:');
          console.log(error);
      });
  }

  // Switch associated calendar events 
  toggleCalendar(detail) {
      const detailFinal = {detail};
      this.selectedUser = detail['id'];

      getUsernameById({ userId : detail['id']})
        .then(result => {
          var el = this.template.querySelector('input.assignedTo');
          $(el).val(result);
          el.dataset.id = detail['id'];
        })
        .catch(error => {
          console.log('Selecting user fail: ');
          console.log(error);
        });
        
        this.renderNewEventsByUser(detail);
  }

  // Render new events based on user provided
  renderNewEventsByUser(detail) {
    var eventArr = this._eventResponse.data;
    var newEvents = [];
    const ele = this.template.querySelector('div.fullcalendarjs');
 
    if( $ != null && $(ele).fullCalendar('removeEvents') != undefined) {$(ele).fullCalendar('removeEvents');}
   // $(ele).fullCalendar('removeEvents');
    for (var i = 0; i < eventArr.length; i++) {
        var item = eventArr[i];
        if(item.OwnerId != detail['id']) {
          console.log('no match for ' + detail['id'] + ' ' + item.OwnerId);
          continue;
        } else {
          console.log('match for '  + detail['id'] + ' ' + item.OwnerId)
        }
        var startDateConvertedObject = new Date(item.StartDateTime);
        var endDateConvertedObject = new Date(item.EndDateTime);
        var eventColor = detail['color'];
        this.selectedColor = detail['color'];
        var modifiedItem = {
            id : item.Id,
            editable : false,
            title : item.Subject,
            start : startDateConvertedObject.toLocaleString(),
            end : endDateConvertedObject.toLocaleString(),
            description : item.Description,
            allDay : false,
            color: eventColor,
            extendedProps : {
              whoId : item.WhoId,
              whatId : item.WhatId
            }
        }

        newEvents.push(modifiedItem);
    }
    try{  
    $(ele).fullCalendar( 'addEventSource', newEvents);
    if($ != null && $(ele).fullCalendar('refetchEvents') != undefined) {$(ele).fullCalendar('refetchEvents');}
    }
    catch(e){

    }
   // $(ele).fullCalendar('refetchEvents');
  }

  // Attempt to save an event 
  saveEvent(event) {

    this.disableSave();
    var oppId = this.pageRef['attributes']['recordId'];
    console.log('>>>>recordId '+this.recordId);    
    //Validate subject 
    var subject = this.template.querySelector('.slds-input.subject').value;
    if((subject == null) || (subject == '')) {
      var subjectFormEl = this.template.querySelector('.slds-form-element.slds-form-element_horizontal.subject');
      subjectFormEl.className = 'slds-form-element slds-form-element_horizontal subject slds-has-error';
      var subjectErrorEl = this.template.querySelector('.slds-form-element__help.slds-hide.subject');
      subjectErrorEl.className = 'slds-form-element__help subject'
      return;
    } else {
      console.log(subject);
    }

      //Validate startTime 
      var startDate = this.template.querySelector('.slds-input.startDate').value;
      var startTime = this.template.querySelector('.slds-input.startTime').value;

      //var zone = new Date().toLocaleTimeString('en-us',{timeZoneName:'short'}).split(' ')[2]
      console.log('!!! startDate= '+startDate);
      console.log('!!! startTime= '+startTime);
      //var d = new Date(startDate + ' ' + zone);
      var d = new Date(startDate + ' ' + 'PST');
      console.log('!!! d = '+ d);
      var hourStringSplit = startTime.split(':');
      d.setHours(hourStringSplit[0]);
      d.setMinutes(hourStringSplit[1]);
      var startDateTime = d;
      console.log('!!! plus Hour&Minute startDateTime '+ startDateTime);
      //Get description
      var description = this.template.querySelector('.slds-input.description').value;
      console.log('description ' + description);

      //Validate End Time
      var endDate = this.template.querySelector('.slds-input.endDate').value;
      var endTime = this.template.querySelector('.slds-input.endTime').value;
      
      //var zone = new Date().toLocaleTimeString('en-us',{timeZoneName:'short'}).split(' ')[2]
      console.log('!!! endDate= '+endDate);
      console.log('!!! endTime= '+endTime);
      //var ed = new Date(endDate + ' ' + zone);
      var ed = new Date(endDate + ' ' + 'PST');
      console.log('!!! ed = '+ed);
      var hourStringSplit = endTime.split(':');
      ed.setHours(hourStringSplit[0]);
      ed.setMinutes(hourStringSplit[1]);
      var endDateTime = ed;
      console.log('!!! after setting Hours+Minutes ed = '+ed);
      // Gather remaining fields from form
      var isLiveTransfer = this.template.querySelector('.slds-checkbox.is-live-transfer').checked;
      var assignedTo = this.template.querySelector('.slds-input.assignedTo').dataset.id;
      const fields = {};
      fields[OWNER_ID_FIELD.fieldApiName] = assignedTo;
      console.log('assigned to '+assignedTo);
      fields[START_FIELD.fieldApiName] = startDateTime;
      console.log('start field '+startDateTime);
      fields[END_FIELD.fieldApiName] = endDateTime;
      console.log('end field');
      fields[SUBJECT_FIELD.fieldApiName] = subject;
      fields['WhoId'] = assignedTo;
      fields['RecordId'] = this.recordId;
      fields['Description'] = description;
      fields['IsLiveTransfer'] = isLiveTransfer;
      fields['TypeOfMeeting'] = 'Initial Contact';

      console.log(fields);

      // Attempt to create a new event with gathered fields
      createNewEvent(fields) 
        .then(result => {
          console.log('success');
          console.log(result);
          this.closeModal();
          const event = new ShowToastEvent({
              title: 'Event Created',
              message: 'Your event has been successfully created',
              variant: 'success',
              mode: 'dismissable'
            });
            this.dispatchEvent(event);
            console.log('about to refresh apex');
            console.log('selected user before save ' + this.selectedUser);
            const ele = this.template.querySelector('div.fullcalendarjs');;
            updateRecord({fields: {Id: this.recordId}});
            this.enableSave();
            refreshApex(this._eventResponse);
        })
        .catch(error => {
          console.log('Save Event error ');
          console.log(error);
          var errorMsg;
          
          try {
            if(error.body.pageErrors[0]!= null && error.body.pageErrors[0].message != null) {
              errorMsg = error.body.pageErrors[0].message;
            } else {
              errorMsg = 'Check that selected specialist and lead are both in the initial contact queue.';
            }  
            if(error.body.fieldErrors[0]!= null && error.body.fieldErrors[0].message != null) {
              errorMsg = error.body.pageErrors[0].message;
            }          
          } catch (error) {
            errorMsg = 'Unknow error, please contact your Administrator.'
          }                   

          const event = new ShowToastEvent({
            title: 'Event Could Not Be Created',
            message: errorMsg,
            variant: 'error',
            mode: 'dismissable'
          });
          this.dispatchEvent(event);
          this.enableSave();
        });
        
  }

  // Disable save btn for modal
  disableSave() {
    var saveBtnEl = this.template.querySelector('.slds-button.slds-button_success.saveEvent');
    $(saveBtnEl).prop('disabled', true);
  }

  // Enable save btn for modal
  enableSave() {
    var saveBtnEl = this.template.querySelector('.slds-button.slds-button_success.saveEvent');
    $(saveBtnEl).prop('disabled', false);
  }
}