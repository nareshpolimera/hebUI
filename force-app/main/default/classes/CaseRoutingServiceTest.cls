@isTest
public class CaseRoutingServiceTest {
    
    private Logger theLogger;
    
    @testSetup
    static void setupTestData() {
        TestCaseFactory.initTestData();
    }
    
    @isTest
    static void createCaseTest()
    {
        List<Case> newCases = new List<Case>();
        
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
                Detail_of_Complaint__c = 'Test by Tester - Complaint Case');
            
            newCases.add(newCase);
        }
        Case newFraudCase = new Case(
            Status = 'Ongoing',
            Origin = 'Email',
            Subject = 'Test Case Fraud Case',
            Complainant_Type__c = 'Personal (made directly by complainant)',
            Complaint_Handling_Level__c = 'Level 1',
            Complaint_Category__c = 'Interest Rate',
            Complaint_Subcategory__c = 'Interest rate change letter',
            Complaint_Date_Received__c = system.today() - 2,
            Incident_Date__c = System.today() ,
            Language__c = 'English',
            Transfer_to_Role__c = 'SCH',
            Is_this_about_fraud__c = TRUE,
            Detail_of_Complaint__c = 'Test by Tester - Complaint Case');
        
        newCases.add(newFraudCase);
        
        
        insert newCases;
        
        
        
        
        newCases[0].Can_I_close_or_resolve_this_complaint__c = FALSE;
        newCases[0].Is_this_about_fraud__c = FALSE;
        
        newCases[1].Is_this_about_fraud__c = TRUE;
        newCases[1].Complaint_Handling_Level__c = 'Level 2';
        
        newCases[3].Is_this_about_fraud__c = TRUE;
        
        
        newCases[4].Transfer_to_Role__c = 'CCCH';
        
        newCases[5].Transfer_to_Role__c = 'DE';
        
        newCases[6].Transfer_to_Role__c = 'SDE';
        
        update newCases;
        
        newCases[1].Complaint_Handling_Level__c = 'Level 3';
        update newCases[1];
        
    }
}