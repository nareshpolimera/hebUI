@isTest
public class PartnerEstimateLetterServiceTest {
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
    static void testGenerateCommitmentLetterPlatformEvent() {
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
           // l1.CurrentOrganization__c = [select id from account where RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId() limit 1].Id;
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
            Role__C = 'Borrower'
        );
        insert la;
        Credit_Assessment__c ca = new Credit_Assessment__c (
            Credit_Assessment_Required__c = false,
            Application__c = rla.id
        );
        insert ca;
        List<MARS_Ready_Record__c> records = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ];
        
       // l.Commitment_Letter_Decision__c =  'Decline';
        //l.Commitment_Letter_Decision_Reason__c = 'Other';
        l.Credit_Assessment_Successful__c = true;
        l.Intake_Reference_Type__c = 'Velocity';
         //update l;
        
        PartnerEstimateLetterService.setMode = null; // Reset the mode for actual test.
        PartnerEstimateLetterService.generateCommitmentLetterPlatformEvent(l.Id);
        Test.stopTest();
        
        Opportunity lCheck = [
            SELECT
            Id,
            Commitment_Letter_Validation_Message__c,
            Commitment_Letter_Decision_Status__c,
            Commitment_Letter_Decision_Date__c
            FROM Opportunity
            WHERE Id = :l.Id
        ];
        System.assertNotEquals(null, lCheck.Commitment_Letter_Validation_Message__c);
        System.assertEquals(
            Label.Status_Commitment_Letter_Submitted,
            lCheck.Commitment_Letter_Decision_Status__c
        );
        System.assertEquals(
            Date.today(),
            lCheck.Commitment_Letter_Decision_Date__c
        );
        PartnerEstimateLetterService.generateCommitmentLetterPlatformEvent(l.Id);
        
        List<MARS_Ready_Record__c> records2 = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ];
        System.assertEquals(
            records2.size(),
            records.size(),
            'Record not created'
        );
    }
    
    @isTest
    static void testGenerateCommitmentLetterPlatformEvent1() {
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
           // l1.CurrentOrganization__c = [select id from account where RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId() limit 1].Id;
            insert l1;
        }
        Opportunity l = new Opportunity (
            
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
            Role__C = 'Borrower'
        );
        insert la;
        Credit_Assessment__c ca = new Credit_Assessment__c (
            Credit_Assessment_Required__c = false,
            Application__c = rla.id
        );
        insert ca;
        List<MARS_Ready_Record__c> records = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ]; 
        PartnerEstimateLetterService.setMode = PartnerEstimateLetterService.Mode.Record_State; // Reset the mode for actual test.
        PartnerEstimateLetterService.generateCommitmentLetterPlatformEvent(l.Id); 
        
        List<MARS_Ready_Record__c> records2 = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ];
        System.assertEquals(
            records2.size(),
            records.size(),
            'Record not created'
        );
        Test.stopTest();
    }
    
    
    @isTest
    static void testGenerateCommitmentLetterPlatformEvent2() {
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
           // l1.CurrentOrganization__c = [select id from account where RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId() limit 1].Id;
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
            Role__C = 'Borrower'
        );
        insert la;
        Credit_Assessment__c ca = new Credit_Assessment__c (
            Credit_Assessment_Required__c = false,
            Application__c = rla.id
        );
        insert ca;
        List<MARS_Ready_Record__c> records = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ]; 
        l.Credit_Assessment_Successful__c = true;
        l.Intake_Reference_Type__c = 'Velocity';
  
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(l); 
        PartnerEstimateLetterService.setMode = PartnerEstimateLetterService.Mode.Record_State; // Reset the mode for actual test. 
        PartnerEstimateLetterService.validateForCommitmentLetter(oppList,PartnerEstimateLetterService.Mode.Record_State); 
       
        List<MARS_Ready_Record__c> records2 = [
            SELECT Id
            FROM MARS_Ready_Record__c
            WHERE SFDC_Id__c = :l.Id
        ];
        System.assertEquals(
            records2.size(),
            records.size(),
            'Record not created'
        );
        Test.stopTest();
    }
}