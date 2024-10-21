@isTest
public with sharing class displayUploadedFilesControllerTest {
    @testSetup
    static void setupTestData()
    {
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
        
        Lead l = new Lead (
            
            LastName = 'Test123',
            FirstName = 'Test123',
            Email = 'testdrive@chip.ca',
            CASL_Consent__c = 'Implied'
        );
        insert l;
        
        Lead leadRecord = [SELECT Id,Name,Email FROM Lead WHERE Email = 'testdrive@chip.ca'];
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title          = 'a picture';
        contentVersion.PathOnClient   = 'Pic.jpg';
        contentVersion.VersionData    = Blob.valueOf('Test Content');
        contentVersion.IsMajorVersion = true;
        insert contentVersion; 
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink cdl2 = New ContentDocumentLink();
        cdl2.LinkedEntityId = leadRecord.id;
        cdl2.ContentDocumentId = documents[0].Id;
        cdl2.shareType = 'V';
        cdl2.visibility = 'AllUsers';
        insert cdl2;
        
    }

    @isTest
    public static void displayFilesTest(){

        Lead leadRecord = [SELECT Id,Name,Email FROM Lead WHERE Email = 'testdrive@chip.ca'];
        
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        list<ContentVersion> contentVersionRecords = displayUploadedFilesController.fetchFiles(leadRecord.id);
        
        displayUploadedFilesController.deleteFiles(cv.id);
    }
     @isTest
    public static void displayFilesTest1(){
		Test.startTest();
        Account l1 = new Account();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            l1 = TestFactory.createPartnerAccount(
                'Test',
                'Acc',
                '50004',
                'Toronto',
                null            
            );
            insert l1;
        }
        Opportunity l = new Opportunity (
            Channel__c = Label.Lead_Channel_MrtgBrk, 
            Commitment_Letter_Decision_Date__c = Date.today(), 
            File_Validation_Error__c = TRUE, 
            Missing_MARS_Validation_Message__c = 'Test Value',
            MARS_Validation_Run__c = true ,
            Commitment_Letter_Decision__c = 'Approve',
            Commitment_Letter_Decision_Status__c = Label.Status_Commitment_Letter_Submitted,
            Credit_Assessment_Successful__c = true,
            Intake_Reference_Type__c = 'Velocity',
            StageName = 'Test',
            CloseDate = Date.today(),
            Name = 'Test123',
            AccountId = l1.Id
        );
        insert l;
        ResidentialLoanApplication rla = new ResidentialLoanApplication (
            OpportunityId = l.id,
            name = 'test'
        );
        insert rla;
        LoanApplicant la = new LoanApplicant (
            LoanApplicationId = rla.id,
            name = 'test',
            Role__c = 'Borrower'
        );
        insert la;
        
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        list<ContentVersion> contentVersionRecords = displayUploadedFilesController.fetchFiles(l.id);
        
        displayUploadedFilesController.deleteFiles(cv.id);
        Test.stopTest();
    }
}