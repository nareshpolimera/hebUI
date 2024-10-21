/********************************************************
@Class      AppraisalService
@brief      Service class for trigger of the Appraisal object.

@revision   2024-05-01 Joel Ojeda
            Porting from legacy SF org.
/******************************************************/
public class AppraisalService {


    //If Appraisal_Amount is changed and the Amount is > 0, we need to set this Appraisal to AppActive and update Parent records accordingly
    public void verifyAppraisedAmount(List<Appraisal__c> records, Map<Id, Appraisal__c> oldRecords) {
        List<Appraisal__c> lsActive = new List<Appraisal__c>();
        Set<String> fieldsToCheck = new Set<String>{'Appraised_Amount__c'};
        List<Appraisal__c> ls = (List<Appraisal__c>) Utils.getChangedObjects(records, oldRecords, fieldsToCheck);
        if (!ls.isEmpty()) {
            for(Appraisal__c rd : ls) {
                If (rd.Active__c == true && rd.Appraised_Amount__c !=null && rd.Appraised_Amount__c > 0 ) {
                    lsActive.add(rd);
                }
            }
            if (!lsActive.isEmpty()) {
                updateAppProperties(lsActive);
            }
        }
    }

    public void setAppraisalToActive(List<Appraisal__c> records) {
        for(Appraisal__c rd : records) {
            rd.Active__c = True;
        }
    }



    public void updateAppProperties(List<Appraisal__c> records) {
        //List to update
        List<LoanApplicationProperty> appProperties = new List<LoanApplicationProperty>();
        List<Opportunity> files = new List<Opportunity>();

        for(Appraisal__c appraisal : records) {

            if (appraisal.Application_Property__c != null){
                LoanApplicationProperty ap = new LoanApplicationProperty();
                ap.Id = appraisal.Application_Property__c;
                ap.PropertyValue = appraisal.Appraised_Amount__c;
                ap.Appraised_Amount__c = appraisal.Appraised_Amount__c;
                appProperties.add(ap);
            }

            if (appraisal.Appraised_Amount__c != null && appraisal.Appraised_Amount__c > 0) {
                if (appraisal.File__c != null)  {
                    Opportunity file = new Opportunity();
                    file.id = appraisal.File__c;
                    file.Quote_Parameters_Updated__c = true;
                    files.add(file);
                }
            }
        }

        if(!appProperties.isEmpty()){
            update appProperties;
        }
        if(!files.isEmpty()){
            update files;
        }
    }

    public void setAppraisalToInactive(List<Appraisal__c> records) {
        Map<Id, Appraisal__c> apprMap = new Map<Id, Appraisal__c>();
        List<Id> lappr = new List<Id>(); // All newly inserted Appraisal 
        Set<Id> fileIds = new Set<Id>();

        for(Appraisal__c rd : records) {
            lappr.add(rd.Id);
            if (rd.File__c != null) {
                fileIds.add(rd.File__c);
            }
        }
        
        for ( Appraisal__c ap : [SELECT Id,File__c, Active__c,Appraised_Amount__c FROM Appraisal__c WHERE File__c IN :fileIds ] )
        {
            if ( ap.active__c == true) {
                apprMap.put(ap.Id,ap);
            }
        }

        If (apprMap.size() > 0) {
            for ( Id i: lappr ) {
                apprMap.remove(i); // Remove mewly created Appraisal
            }
            If (apprMap.size() > 0) {
                List<Appraisal__c> toBeinActiveAppr = apprMap.values();
                
                For ( Appraisal__c appr: toBeinActiveAppr) {
                    appr.Active__c = false;
                }
                update toBeinActiveAppr;

            }
        }

    }

}