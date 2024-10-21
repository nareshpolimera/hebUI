global class DynamicDataTableComplainantSearch {
    // @AuraEnabled(cacheable=true)
    // public static DataTableResponse getWrapperOfSObjectFieldColumnActionValues(String searchFileNo)
    // {
    //     List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
    //     List<SObject> lstDataTableData = new List<SObject>();
    //     List<string> columnList = new List<string>();
    //     List<string> fieldAPINameList = new List<string>();
    //     DataTableResponse finalWrapper   = new DataTableResponse();
    //     DynamicTableForComplainantSearch__mdt tableComponentMetadata = new DynamicTableForComplainantSearch__mdt();
    //     String filenumber=searchFileNo;
    //     String sourceObject;
    //     tableComponentMetadata = [SELECT DeveloperName, FieldValue__c,Header__c, Query__c, Title__c FROM  DynamicTableForComplainantSearch__mdt  
    //                               WHERE DeveloperName =: 'Lead'];
        
    //     // String queryForLead= tableComponentMetadata.Query__c +' WHERE File_Number__c = \''+ filenumber + '\''+ 'AND IsConverted = false';    
    //     String queryForLead= tableComponentMetadata.Query__c +' WHERE File_Number__c = \''+ filenumber + '\''+ 'AND IsConverted = false';        
    
        
    //     if (String.isBlank(filenumber)) {
    //         lstDataTableData.add(null);
    //         sourceObject ='HEB';
    //     }
    //     else {
            
    //         // Seaching in Lead , If not found going to HEB External Objects and getting the data.
            
    //         for(SObject sObjectItem : Database.query(queryForLead)) {
    //             lstDataTableData.add(sObjectItem);
    //         }
    //         sourceObject ='Lead';
            
    //         if(lstDataTableData.isempty()) {
    //             tableComponentMetadata = [SELECT DeveloperName, FieldValue__c, Header__c, Query__c, Title__c FROM  DynamicTableForComplainantSearch__mdt 
    //                                       WHERE DeveloperName =: 'HEBFileCustomer'];
    //             String queryForExternalFile= tableComponentMetadata.Query__c +' WHERE FileNumber__c LIKE \'%'+ filenumber + '%\'';
    //             for(SObject sObjectItem : Database.query(queryForExternalFile)) {
    //                 lstDataTableData.add(sObjectItem);
    //             }
    //             if(lstDataTableData.isempty()) {
    //                 if(filenumber!=' ')
    //                 {
    //                     lstDataTableData.add(null);
    //                 }
    //             }
    //             sourceObject ='HEB';
    //         }
    //     }
    //     if(tableComponentMetadata.Header__c != null) {
    //         columnList = tableComponentMetadata.Header__c.split(',');
    //     }
    //     if(tableComponentMetadata.FieldValue__c != null) {
    //         fieldAPINameList = tableComponentMetadata.FieldValue__c.split(',');
    //     }
    //     for(integer i = 0; i < columnList.size(); i++)
    //     {
    //         DataTableColumns datacolumns = new DataTableColumns(columnList[i].trim() , 
    //                                                             fieldAPINameList[i].substringBefore(':').trim(),
    //                                                             fieldAPINameList[i].substringAfter(':').trim());
    //         lstDataColumns.add(datacolumns);
    //     }
    //     finalWrapper.lstDataTableColumns = lstDataColumns;
    //     finalWrapper.lstDataTableData    = lstDataTableData;
    //     finalWrapper.sourceObject = sourceObject;
    //     return finalWrapper;
    // }

    //Commented above method,copied it and made changes to the copy
    @AuraEnabled(cacheable=true)
    public static DataTableResponse getWrapperOfSObjectFieldColumnActionValues(String searchFileNo)
    {
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        List<SObject> lstDataTableData = new List<SObject>();
        List<DataTableComplainantSearchObject> lstDataTableDataOpp = new List<DataTableComplainantSearchObject>();
        List<string> columnList = new List<string>();
        List<string> fieldAPINameList = new List<string>();
        DataTableResponse finalWrapper   = new DataTableResponse();
        DynamicTableForComplainantSearch__mdt tableComponentMetadata = new DynamicTableForComplainantSearch__mdt();
        String filenumber=searchFileNo;
        String sourceObject;
        
        tableComponentMetadata = [SELECT DeveloperName, FieldValue__c, Header__c, Query__c, Title__c 
                                   FROM  DynamicTableForComplainantSearch__mdt 
                                   WHERE DeveloperName =: 'HEBFileCustomer'];
        
        System.debug('RetrievedData::');
        if(String.isBlank(filenumber)){
            lstDataTableData.add(null);
            lstDataTableDataOpp.add(null);
        }
        else{
        	String queryForExternalFile= tableComponentMetadata.Query__c +' WHERE FileNumber__c LIKE \'%'+ filenumber + '%\'';
            System.debug('RetrievedData::HEB' + Database.query(queryForExternalFile));
            for(SObject sObjectItem : Database.query(queryForExternalFile)) {
                System.debug('RetrievedData::In Loop');
            	lstDataTableData.add(sObjectItem);
         	}
            sourceObject ='HEB';
            if(lstDataTableData.isempty()) {
            	lstDataTableData.add(null);
                tableComponentMetadata = [SELECT DeveloperName, FieldValue__c,Header__c, Query__c, Title__c 
                                          FROM  DynamicTableForComplainantSearch__mdt  
                                  		  WHERE DeveloperName =: 'Opportunity'];
                String queryForOpportunity= tableComponentMetadata.Query__c +' WHERE File_Number__c = \''+ filenumber + '\'' ;
                System.debug('RetrievedData::' + Database.query(queryForOpportunity));
                List<Opportunity> opportunityList = Database.query(queryForOpportunity);
                if(opportunityList != null && opportunityList.size() > 0){
                    List<ResidentialLoanApplication> loanApplicationList = [Select id,(select contact.firstname,contact.lastname,contact.email  from LoanApplicants WHERE Is_Primary_Borrower__c = true),(select id,PropertyStreet from LoanApplicationProperties) 
                                                                        FROM ResidentialLoanApplication
                                                                        WHERE OpportunityId=: opportunityList[0].id];
                
                    /* System.debug('RetrievedData::loanApplicationList' + loanApplicationList);
                    System.debug('RetrievedData::loanApplicationList[0]' + loanApplicationList[0]);
                    System.debug('RetrievedData::LoanApplicants' + loanApplicationList[0].LoanApplicants);
                    System.debug('RetrievedData::LoanApplicationProperties' + loanApplicationList[0].LoanApplicationProperties); */
                    String firstName='';
                    String lastName='';
                    String email='';
                    String PropertyStreet='';
                    if(loanApplicationList != null && loanApplicationList.size() > 0  && loanApplicationList[0].LoanApplicants.size()>0 && loanApplicationList[0].LoanApplicants[0] != null){
                        firstName = loanApplicationList[0].LoanApplicants[0].contact.firstname;
						lastName = loanApplicationList[0].LoanApplicants[0].contact.lastname;
                        email = loanApplicationList[0].LoanApplicants[0].contact.email;
                    }
                    if(loanApplicationList != null && loanApplicationList.size() > 0 && loanApplicationList[0].LoanApplicationProperties.size()>0 && loanApplicationList[0].LoanApplicationProperties[0] != null){
                        PropertyStreet = loanApplicationList[0].LoanApplicationProperties[0].PropertyStreet;
                    }
                    DataTableComplainantSearchObject dataTableItem = new DataTableComplainantSearchObject(opportunityList[0].File_Number__c,
                                                                                                          opportunityList[0].Channel__c,
                                                                                                          firstName,
                                                                                                          lastName,
                                                                                                          email,
                                                                                                          PropertyStreet,
                                                                                                          opportunityList[0].Id);
                    
                    lstDataTableDataOpp.add(dataTableItem);
                    sourceObject ='Opportunity';
                    System.debug('RetrievedData::lstDataTableData' + lstDataTableDataOpp);
                }
             }
        }
               
/*        
        tableComponentMetadata = [SELECT DeveloperName, FieldValue__c,Header__c, Query__c, Title__c FROM  DynamicTableForComplainantSearch__mdt  
                                  WHERE DeveloperName =: 'Opportunity'];
        
        // String queryForLead= tableComponentMetadata.Query__c +' WHERE File_Number__c = \''+ filenumber + '\''+ 'AND IsConverted = false';    
        String queryForOpportunity= tableComponentMetadata.Query__c +' WHERE File_Number__c = \''+ filenumber + '\'' ;        
    
        
        if (String.isBlank(filenumber)) {
            lstDataTableData.add(null);
            sourceObject ='HEB';
        }
        else {
            
            // Seaching in Opportunity , If not found going to HEB External Objects and getting the data.
            
            System.debug('RetrievedData::' + Database.query(queryForOpportunity));
            //Map<Id,SObject> opportunityList = new Map<Id,SObject>(Database.query(queryForLead));
            List<Opportunity> opportunityList = Database.query(queryForOpportunity);
            List<ResidentialLoanApplication> loanApplicationList = [Select id,(select contact.firstname,contact.lastname,contact.email from LoanApplicants WHERE Is_Primary_Borrower__c = true),(select id,PropertyStreet from LoanApplicationProperties) 
                                                                    FROM ResidentialLoanApplication
                                                                   	WHERE OpportunityId=: opportunityList[0].id];
            
            System.debug('RetrievedData::loanApplicationList' + loanApplicationList);
            System.debug('RetrievedData::loanApplicationList[0]' + loanApplicationList[0]);
            System.debug('RetrievedData::LoanApplicants' + loanApplicationList[0].LoanApplicants);
            System.debug('RetrievedData::LoanApplicationProperties' + loanApplicationList[0].LoanApplicationProperties);
            
            DataTableComplainantSearchObject dataTableItem = new DataTableComplainantSearchObject(opportunityList[0].File_Number__c,
                                                                                                  opportunityList[0].Channel__c,
                                                                                                  loanApplicationList[0].LoanApplicants[0].contact.firstname,
                                                                                                  loanApplicationList[0].LoanApplicants[0].contact.lastname,
                                                                                                  loanApplicationList[0].LoanApplicants[0].contact.email,
                                                                                                  loanApplicationList[0].LoanApplicationProperties[0].PropertyStreet);
            
            lstDataTableDataOpp.add(dataTableItem);
            sourceObject ='Opportunity';
            System.debug('RetrievedData::lstDataTableData' + lstDataTableDataOpp);

            if(lstDataTableDataOpp.isempty()) {
                tableComponentMetadata = [SELECT DeveloperName, FieldValue__c, Header__c, Query__c, Title__c FROM  DynamicTableForComplainantSearch__mdt 
                                          WHERE DeveloperName =: 'HEBFileCustomer'];
                String queryForExternalFile= tableComponentMetadata.Query__c +' WHERE FileNumber__c LIKE \'%'+ filenumber + '%\'';
                for(SObject sObjectItem : Database.query(queryForExternalFile)) {
                    lstDataTableData.add(sObjectItem);
                }
                if(lstDataTableData.isempty()) {
                    if(filenumber!=' ')
                    {
                        lstDataTableData.add(null);
                    }
                }
                sourceObject ='HEB';
            }
        }
*/
        if(tableComponentMetadata.Header__c != null) {
            columnList = tableComponentMetadata.Header__c.split(',');
        }
        if(tableComponentMetadata.FieldValue__c != null) {
            fieldAPINameList = tableComponentMetadata.FieldValue__c.split(',');
        }
        System.debug('RetrievedData::columnList' + columnList);
        System.debug('RetrievedData::fieldAPINameList' + fieldAPINameList);

        for(integer i = 0; i < columnList.size(); i++)
        {
            DataTableColumns datacolumns = new DataTableColumns(columnList[i].trim() , 
                                                                fieldAPINameList[i].substringBefore(':').trim(),
                                                                fieldAPINameList[i].substringAfter(':').trim());
            lstDataColumns.add(datacolumns);
        }
        System.debug('RetrievedData::lstDataColumns' + lstDataColumns);
		System.debug('RetrievedData::sourceObject' + sourceObject);
        finalWrapper.lstDataTableColumns = lstDataColumns;
        finalWrapper.lstDataTableData    = lstDataTableData;
        finalWrapper.lstDataTableDataOpp    = lstDataTableDataOpp;
        finalWrapper.sourceObject = sourceObject;
        return finalWrapper;
    }
    //Test code ends here
    
    /*
@AuraEnabled
public static Complainant__c saveAndLinkFile(String complainantRecord,String caseId)
{
Id caseComplaintRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
String fileNumberToMap;
List<Case> currentCaseRecordTOSaveAndLink = new  List<Case>();
List<Complainant__c> compllist = new  List<Complainant__c>();
RecordWrapper recordWrapper = (RecordWrapper)System.JSON.deserializeStrict(complainantRecord, RecordWrapper.class);
fileNumberToMap = recordWrapper.FileNumber;
String query='SELECT Id,First_Name__c,Last_Name__c,Email__c,Phone__c FROM Complainant__c WHERE File_Number__c=:'+ fileNumberToMap+';';
Case caseToUpdate =[SELECT ID, FILE_NUMBER__C, ORIGIN FROM CASE WHERE RECORDTYPEID =:caseComplaintRecordTypeId and ID=:caseId];
List<Complainant__c> complainanttoUpsert= [SELECT ID,FIRST_NAME__C,LAST_NAME__C,EMAIL__C,PHONE__C FROM COMPLAINANT__C WHERE FILE_NUMBER__C=:fileNumberToMap];
Complainant__c complainant = new Complainant__c();
if(recordWrapper != null) {
if(recordWrapper.FileNumber != null && !String.isBlank(recordWrapper.FileNumber)) {
complainant.File_Number__c = recordWrapper.FileNumber;
}
if(recordWrapper.FirstName != null && !String.isBlank(recordWrapper.FirstName)) {
complainant.First_Name__c = recordWrapper.FirstName;
}
if(recordWrapper.LastName != null && !String.isBlank(recordWrapper.LastName)){
complainant.Last_Name__c = recordWrapper.LastName;
}
if(recordWrapper.Email != null && !String.isBlank(recordWrapper.Email)){
complainant.Email__c = recordWrapper.Email;
}
if(recordWrapper.Phone != null && !String.isBlank(recordWrapper.Phone)){
complainant.Phone__c = recordWrapper.Phone;
}
if(recordWrapper.Country != null && !String.isBlank(recordWrapper.Country)){
complainant.Country__c = recordWrapper.Country;
}
if(recordWrapper.Street != null && !String.isBlank(recordWrapper.Street)){
complainant.Street__c = recordWrapper.Street;
}
if(recordWrapper.State != null && !String.isBlank(recordWrapper.State)){
complainant.State_Province__c = recordWrapper.State;
}
if(recordWrapper.City != null && !String.isBlank(recordWrapper.City)){
complainant.City__c = recordWrapper.City;
}
if(recordWrapper.PostalCode != null && !String.isBlank(recordWrapper.PostalCode)){
complainant.Postal_Code__c = recordWrapper.PostalCode;
}
complainanttoUpsert.add(complainant);
caseToUpdate.File_Number__c = recordWrapper.FileNumber;
caseToUpdate.Sales_Channel__c = recordWrapper.ChannelOfComplainant;
caseToUpdate.Mortgage_Funded_Date__c = recordWrapper.fundedDate;
caseToUpdate.Date_of_Death__c = recordWrapper.deathDate;
if(recordWrapper.leadFileId != null && !String.isBlank(recordWrapper.leadFileId)){
caseToUpdate.Lead_File__c = recordWrapper.leadFileId;
caseToUpdate.MARS_File__c =null;
}
if(recordWrapper.marsFileId != null && !String.isBlank(recordWrapper.marsFileId)){
caseToUpdate.MARS_File__c = recordWrapper.marsFileId;
caseToUpdate.Lead_File__c = null;
}
caseToUpdate.Property_Street__c=recordWrapper.properityStreet;
currentCaseRecordTOSaveAndLink.add(caseToUpdate);
}
try {
Schema.SObjectField fileNumber = Complainant__c.Fields.File_Number__c;
Database.UpsertResult [] cr = Database.upsert(complainanttoUpsert , fileNumber, false);
for(Complainant__c c:complainanttoUpsert)
{
for(Case caserecord :currentCaseRecordTOSaveAndLink)
{
caserecord.Complainant__c=c.Id;
}
}
update(currentCaseRecordTOSaveAndLink);
}
catch(DmlException e) {
}
return complainant;
} */
    
    @AuraEnabled
    public  static Case linkOnlyFile(String recordToLink,String caseRecordIdToLinkOnly)
    {
        List<Case> currentCaseRecord = new  List<Case>();
        Id caseComplaintRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        RecordWrapper recordWrapper = (RecordWrapper)System.JSON.deserializeStrict(recordToLink, RecordWrapper.class);
        Case c =[SELECT ID, FILE_NUMBER__C, ORIGIN FROM CASE WHERE RECORDTYPEID =: caseComplaintRecordTypeId and id=:caseRecordIdToLinkOnly];
        c.File_Number__c=recordWrapper.FileNumber;
        c.Sales_Channel__c = recordWrapper.ChannelOfComplainant;
        c.Mortgage_Funded_Date__c = recordWrapper.fundedDate;
        c.Date_of_Death__c = recordWrapper.deathDate;
        c.Property_Street__c=recordWrapper.properityStreet;
        if(recordWrapper.fileId != null && !String.isBlank(recordWrapper.fileId)){
            c.Opportunity_File__c = recordWrapper.fileId;
            c.MARS_File__c =null;
        }
        if(recordWrapper.marsFileId != null && !String.isBlank(recordWrapper.marsFileId)){
            c.MARS_File__c = recordWrapper.marsFileId;
            c.Opportunity_File__c = null;
        }
        currentCaseRecord.add(c);
        try {
            update currentCaseRecord;
        } catch(DmlException e) {
        }
        return c;
    }
    
    public class RecordList
    {     @AuraEnabled
        public List<RecordWrapper> RecordList;
    }
    
    public class RecordWrapper
    {
        @AuraEnabled
        public string FirstName { get; set; }
        @AuraEnabled
        public string LastName { get; set; }
        @AuraEnabled
        public string Email { get; set; }
        @AuraEnabled
        public string Phone { get; set; }
        @AuraEnabled
        public string FileNumber { get; set; }
        @AuraEnabled
        public string ChannelOfComplainant { get; set; }
        @AuraEnabled
        public string Country { get; set; }
        @AuraEnabled
        public string Street { get; set; }
        @AuraEnabled
        public string City { get; set; }
        @AuraEnabled
        public string State { get; set; }
        @AuraEnabled
        public string PostalCode { get; set; }
        @AuraEnabled
        public DateTime fundedDate { get; set; }
        @AuraEnabled
        public DateTime deathDate { get; set; }
        @AuraEnabled
        public string properityStreet { get; set; }
        @AuraEnabled
        public string id { get; set; }
        @AuraEnabled
        public string fileId { get; set; }
        @AuraEnabled
        public string marsFileId { get; set; }
    }
}