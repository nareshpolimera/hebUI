/******************************************************//**
@Class      AppraisalNoteService
@brief      Service class for trigger of the AppraisalNote object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalNoteService
{
    public static final String APPRAISAL_ORDER_NOT_SUBMITTED = Label.Error_APPRAISAL_ORDER_NOT_SUBMITTED;
    public static final String APPRAISAL_SEND_STATUS_SENDING = Label.Aura_APPRAISAL_SEND_STATUS_SENDING;
    public static final String APPRAISAL_SEND_STATUS_SEND_ERROR = Label.Error_Prefix;
    public static final String APPRAISAL_SEND_STATUS_FAILED = Label.Error_APPRAISAL_SEND_STATUS_FAILED;
    public static final String APPRAISAL_SEND_STATUS_SENT = Label.Aura_APPRAISAL_SEND_STATUS_SENT;
    
    public void validateOrder(List<Appraisal_Note__c> records)
    {
        Set<Id> appoIDs = new Set<Id>();
        for (Appraisal_Note__c an : records) {
            appoIds.add(an.Appraisal_Order__c);
        }
        
        Map<Id, String> referenceIDs = new Map<Id, String>();
        for (Appraisal_Order__c ao : [
            SELECT Id, Reference_Id__c
            FROM Appraisal_Order__c
            WHERE Id IN :appoIDs
        ])
        {
            referenceIDs.put(ao.Id, ao.Reference_Id__c);
        }
        
        for (Appraisal_Note__c an : records)
        {
            if (referenceIDs.get(an.Appraisal_Order__c) == null)
            {
                an.addError(APPRAISAL_ORDER_NOT_SUBMITTED);
            }
        }
    }
    
    public void designateOrigin(List<Appraisal_Note__c> records)
    {
        for (Appraisal_Note__c an : records)
        {
            system.debug(UserInfo.getUserId());
            if (Utils.isIntegrationUser())
            {
                an.Incoming_Note__c = true;
            }
            else
            {
                an.Send_Note_Status__c = APPRAISAL_SEND_STATUS_SENDING;
            }
        }
    }
    
    public void sendNote(List<Appraisal_Note__c> records)
    {
        List<Id> incomingIds = new List<Id>();
        
        for (Appraisal_Note__c an : records)
        {
            if (!an.Incoming_Note__c)
            {
                incomingIds.add(an.Id);
            }
        }
        
        sendNote(incomingIds);
    }
    
    public static void sendNote(List<Id> recordIDs)
    {
        for (Id i : recordIDs)
        {
            AppraisalSendNoteService.sendNote(i);
        }
    }

    public void setEnteredOnDate(List<Appraisal_Note__c> records)
    {
        Datetime currDT = System.now();
        for (Appraisal_Note__c anc : records)
        {
            if (anc.Entered_On_DT__c == null)
            {
                anc.Entered_On_DT__c = currDt;
            }
        }
    }
}