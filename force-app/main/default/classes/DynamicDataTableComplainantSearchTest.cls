@isTest
public class DynamicDataTableComplainantSearchTest {
    
    @testSetup
    static void setupTestData() {
        Date xDate = Date.valueOf('2021-03-01');
        Product_Quote_Set__c pqs = new Product_Quote_Set__c(
            Name = '2021 Mar Quote Set 123XYZ',
            External_ID__c = '4321987',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate
        );
        insert pqs;
        Product_Rate_Set__c prs = new Product_Rate_Set__c(
            Name = '2021 Mar Rate Set 5678abc',
            External_ID__c = '9876543',
            Available__c = true,
            Current__c = true,
            Effective_Date__c = xDate 
        );
        insert prs;
        Document_Classification__c dc = new Document_Classification__c();
        dc.Document_Type__c = 'T4';
        dc.Related_Entity__c = 'Opportunity';
        dc.External_ID__c = 12345;
        dc.Expired__c = false;
        insert dc;
    }
    @isTest
    static void testGetWrapperOfSObjectFieldColumnActionValuesWithFileNumber() {
 
        // Call the method
        Test.startTest();
        //Create Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account a = new Account();
        a.FirstName = 'Test';
        a.LastName = 'Person Account';
        a.RecordTypeId = accRecordTypeId;
        insert a;
        
        //Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Last',
            Email = 'abc@test.com'
        );
        insert con;
        
        Opportunity testOpp  = new Opportunity(
            
            name = 'test',
            StageName = 'New',
            CloseDate = Date.today() ,
            AccountId = a.id,
            File_Number__c = '12345' 
            
        );
        insert testOpp ;
 
        //Create LoanApplication
        ResidentialLoanApplication loanApplication = new ResidentialLoanApplication(
            OpportunityId = testOpp.Id
        );
        insert loanApplication;
        
        //Create Applicant
        LoanApplicant applicant = new LoanApplicant(
            ContactId = con.Id,
            LoanApplicationId = loanApplication.Id,
            Is_Primary_Borrower__c = true,
            Name = 'Tets12',
            Role__C = 'Borrower'
        );
        insert applicant;
        
        //Create Property
        LoanApplicationProperty prop = new LoanApplicationProperty(
            PropertyStreet = 'Test Property',
            LoanApplicationId = loanApplication.Id
        );
        insert prop;
        
        DynamicDataTableComplainantSearch.RecordWrapper wrapper= new DynamicDataTableComplainantSearch.RecordWrapper();
        wrapper.FileNumber = testOpp.File_Number__c;
        wrapper.ChannelOfComplainant = testOpp.Channel__c;
        wrapper.properityStreet = prop.PropertyStreet;
        String wrapper1 = JSON.serialize(wrapper);
        DataTableResponse response = DynamicDataTableComplainantSearch.getWrapperOfSObjectFieldColumnActionValues('12345');
		wrapper.id = 'Test';        
        Test.stopTest();
 		// Assertions
		System.assertNotEquals(null, response, 'Response should not be null');
  		 
    }
    
    @isTest
    static void testLinkOnlyFile() {
        // Setup test data
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        Case testCase = new Case(
            RecordTypeId = caseRecordTypeId,
            File_Number__c = '12345',
            Sales_Channel__c = 'Consumer',
            Property_Street__c = '123 Main St',
            Complaint_Date_Received__c = Date.today()
        );
        insert testCase;
        
        // Call the method
        Test.startTest();
        //Create Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account a = new Account();
        a.FirstName = 'Test';
        a.LastName = 'Person Account';
        a.RecordTypeId = accRecordTypeId;
        insert a;
        
        //Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Last',
            Email = 'abc@test.com'
        );
        insert con;
        
        Opportunity testOpp  = new Opportunity(
            
            name = 'test',
            StageName = 'New',
            CloseDate = Date.today() ,
            AccountId = a.id,
            File_Number__c = '12345' 
            
        );
        insert testOpp ;
 
        //Create LoanApplication
        ResidentialLoanApplication loanApplication = new ResidentialLoanApplication(
            OpportunityId = testOpp.Id
        );
        insert loanApplication;
        
        //Create Applicant
        LoanApplicant applicant = new LoanApplicant(
            ContactId = con.Id,
            LoanApplicationId = loanApplication.Id,
            Is_Primary_Borrower__c = true,
            Name = 'Tets12',
            Role__C = 'Borrower'
        );
        insert applicant;
        
        //Create Property
        LoanApplicationProperty prop = new LoanApplicationProperty(
            PropertyStreet = 'Test Property',
            LoanApplicationId = loanApplication.Id
        );
        insert prop;
        
        DynamicDataTableComplainantSearch.RecordWrapper wrapper= new DynamicDataTableComplainantSearch.RecordWrapper();
        wrapper.FileNumber = testOpp.File_Number__c;
        wrapper.ChannelOfComplainant = testOpp.Channel__c;
        wrapper.properityStreet = prop.PropertyStreet;
        String wrapper1 = JSON.serialize(wrapper);
        Case updatedCase = DynamicDataTableComplainantSearch.linkOnlyFile(JSON.serialize(wrapper), testCase.Id);
        wrapper.FirstName = 'Test';
        wrapper.LastName = 'Test';
        wrapper.Email = 'Test@ddw.test';
        wrapper.Country = 'Test';
        wrapper.City = 'Test';
        wrapper.Phone = '123';
        Test.stopTest();
         
		// Assertions
 		Assert.isNotNull(updatedCase);
 
    }
}