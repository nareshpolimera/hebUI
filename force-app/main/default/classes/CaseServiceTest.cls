@isTest
public class CaseServiceTest {
    
    @testSetup
    static void setupTestData() {
        TestCaseFactory.initTestData();
    }
    
    @isTest
    static void createCaseTest()
    {
        List<Case> newCases = new List<Case>();
         List<Case> updateCases = new List<Case>();
        Account acc = [SELECT ID FROM Account LIMIT 1];
        
        Map<id,Case> oldCaseMap = new Map<id,Case>();
        
        for(integer i=1;i<=10;i++)
        {
            Case newCase = new Case(
                Status = 'Ongoing',
                Origin = 'Email',
                Subject = 'Test Case '+i,
                Complainant_Type__c = 'Personal (made directly by complainant)',
                Complaint_Handling_Level__c = 'Level 1',
                Complaint_Category__c = 'Interest Rate',
                Complaint_Subcategory__c = 'Interest rate change letter',
                Complaint_Date_Received__c = system.today() - i*7,
                Incident_Date__c = System.today() ,
                Language__c = 'English',
                Transfer_to_Role__c = 'SCH',
                Detail_of_Complaint__c = 'Test by Tester - Complaint Case',
                AccountId=acc.Id,
                Complaint_Outcome__c = 'Upheld',
				Investigation_Details__c='Testing' );
            
            newCases.add(newCase);
        }
        
        //
        
        newCases[0].Correspondence_Method__c='Email';
        newCases[0].IsEscalated = TRUE;
        newCases[0].Can_I_close_or_resolve_this_complaint__c=TRUE;
        newCases[0].Is_Customer_Satisfied__c='No';
        
        
        newCases[1].Correspondence_Method__c='Mail';
        newCases[1].IsEscalated = FALSE;
        newCases[1].Can_I_close_or_resolve_this_complaint__c=TRUE;
        newCases[1].Is_Customer_Satisfied__c='Yes';
        
        
        newCases[2].Correspondence_Method__c='Email';
        newCases[2].IsEscalated = FALSE;
        newCases[2].Can_I_close_or_resolve_this_complaint__c=FALSE;
        newCases[2].Is_Customer_Satisfied__c=null;
        
        
        newCases[3].Correspondence_Method__c='Email';
        newCases[3].IsEscalated = TRUE;
        newCases[3].Can_I_close_or_resolve_this_complaint__c=FALSE;
        newCases[3].Is_Customer_Satisfied__c='Yes';
        
        newCases[4].Correspondence_Method__c='Email';
        newCases[4].IsEscalated = FALSE;
        newCases[4].Can_I_close_or_resolve_this_complaint__c=TRUE;
        newCases[4].Is_Customer_Satisfied__c='Yes';
        
        newCases[5].Can_I_close_or_resolve_this_complaint__c = TRUE;
        newCases[5].Is_Customer_Satisfied__c = 'No';
        newCases[5].Correspondence_Method__c='Mail';
        
        newCases[6].Correspondence_Method__c='Email';
        newCases[6].IsEscalated = FALSE;
        newCases[6].Can_I_close_or_resolve_this_complaint__c=TRUE;
        newCases[6].Is_Customer_Satisfied__c='No';
       
        insert newCases;
        
        /*for(Case c:newCases)
        {
            oldCaseMap.put(c.Id,c);
        }
        
        for(Case updateCase:[SELECT Id,Status FROM CASE LIMIT 10])
        {
            updateCase.Status = 'Closed';
            updateCases.add(updateCase);
        }*/
        
        //update updateCases;
        
        for(Case c:newCases)
        {
            oldCaseMap.put(c.Id,c);
        }
        
        CaseService cs = new CaseService();
        
        cs.setCaseStatus(newCases);
        
        updateCases = [SELECT Id,Status,LastModifiedDate,LastModifiedById,OwnerId,Is_this_about_fraud__c FROM CASE LIMIT 10];
        
        cs.createCaseStatusHistoryUpdate(updateCases,oldCaseMap);
        cs.validateEditPermissions(updateCases,oldCaseMap);
    }
    
}