/* **************************************************************************
* Test: OpportunityOwnershipServiceTest
* Created by Joel Ojeda, August 13, 2024
*
* Purpose/Methods: Test class to manage ownership of opportunity and its child records
*
* Unit Test: OpportunityOwnershipServiceTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
@isTest
public with sharing class OpportunityOwnershipServiceTest {
    
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
        
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name IN (:Label.SystemAdmin_Profile_Name)];
        
         User sysAdmin2 = new User(
            ProfileId = profileList[0].Id,
            Username = 'anotherAdmin@chip.ca',
            Email = 'anotherAdmin@chip.ca',
            FirstName = 'admin',
            LastName = 'Support',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'admin2',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sysAdmin2;
        
        Account orgAccount = TestFactory.createPartnerOrgAccount( 'TestAccount','32244','Quebec', '41643210987');
        orgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Organization').getRecordTypeId();
        insert new List<Account>{orgAccount};
            
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op2.id);
        insert new list<ResidentialLoanApplication> {application};
            
            LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M4M4M4');
        
        Appraisal__c apr1 = TestFactory.createAppraisalFromFile(op1);
        Appraisal__c apr2 = TestFactory.createAppraisalFromProperty(prop1,op1);
        insert new List<Appraisal__c>{ apr1, apr2 };
            
            Appraisal_Order__c ao1 = TestFactory.createAppraisalOrderFromAppraisal(apr1);
        Appraisal_Order__c ao2 = TestFactory.createAppraisalOrderFromAppraisal(apr2);
        insert new List<Appraisal_Order__c>{ ao1, ao2 };
    }
    
    @isTest
    static void test_changeOwnership_Application() {
        
        List<Opportunity> opps = [Select Id from Opportunity where Account.Name = 'TestAccount'];
        System.assert(!opps.isEmpty());
        
        List<User> users = [Select Id from User where LastName = 'Support' limit 1];
        System.assert(!users.isEmpty());
        
        Test.StartTest();
        
        opps[0].ownerId = users[0].Id;
        update opps;
        
        Test.StopTest();
        
        opps = [SELECT Id, OwnerId,
                (SELECT Id, OwnerId FROM Lending_Applications),
                (SELECT Id, OwnerId FROM Appraisals__r where Application__c != null)
                FROM Opportunity
                WHERE Id = :opps[0].Id];
        System.assert(!opps.isEmpty());
        
        if(opps[0].Lending_Applications != null && !opps[0].Lending_Applications.isEmpty()){
            for(ResidentialLoanApplication application : opps[0].Lending_Applications){
                System.assertEquals(users[0].Id,application.OwnerId);
            }
        }
        
        if(opps[0].Appraisals__r != null && !opps[0].Appraisals__r.isEmpty()){
            for(Appraisal__c appraisal : opps[0].Appraisals__r){
                System.assertEquals(users[0].Id,appraisal.OwnerId);
            }
        }
        // Credit Report
        for (Credit_Report__c creditReport : [SELECT Id,
                                              OwnerId
                                              FROM Credit_Report__c
                                              WHERE Loan_Applicant__c != null AND
                                              Loan_Applicant__r.LoanApplicationId != null AND 
                                              Loan_Applicant__r.LoanApplication.OpportunityId != null AND
                                              Loan_Applicant__r.LoanApplication.OpportunityId = :opps[0].Id]) {
                                                  System.assertEquals(users[0].Id,creditReport.OwnerId);
                                              }
        
        for (Appraisal_Order__c apprOrder : [SELECT Id,
                                             OwnerId
                                             FROM Appraisal_Order__c
                                             WHERE Appraisal__c != null AND
                                             Appraisal__r.Application__c != null AND
                                             Appraisal__r.Application__r.OpportunityId != null AND
                                             Appraisal__r.Application__r.OpportunityId = :opps[0].Id]){
                                                 System.assertEquals(users[0].Id,apprOrder.OwnerId);
                                             }
    }
    
    @isTest
    static void test_changeOwnership_Error() {
        
        List<Opportunity> opps = [Select Id from Opportunity where Account.Name = 'TestAccount'];
        System.assert(!opps.isEmpty());
        
        List<User> users = [Select Id from User where LastName = 'Support' limit 1];
        System.assert(!users.isEmpty());
        
        Test.StartTest();
        //enable error
        OpportunityOwnershipService.throwError = true;
        opps[0].ownerId = users[0].Id;
        update opps;
        Test.StopTest();
        
        opps = [SELECT Id, OwnerId,
                (SELECT Id, OwnerId FROM Lending_Applications),
                (SELECT Id, OwnerId FROM Appraisals__r where Application__c != null)
                FROM Opportunity
                WHERE Id = :opps[0].Id];
        System.assert(!opps.isEmpty());
        
        if(opps[0].Lending_Applications != null && !opps[0].Lending_Applications.isEmpty()){
            for(ResidentialLoanApplication application : opps[0].Lending_Applications){
                System.assertNotEquals(users[0].Id,application.OwnerId);
            }
        }
        
        if(opps[0].Appraisals__r != null && !opps[0].Appraisals__r.isEmpty()){
            for(Appraisal__c appraisal : opps[0].Appraisals__r){
                System.assertNotEquals(users[0].Id,appraisal.OwnerId);
            }
        }
        
        // Credit Report
        for (Credit_Report__c creditReport : [SELECT Id,
                                              OwnerId
                                              FROM Credit_Report__c
                                              WHERE Loan_Applicant__c != null AND
                                              Loan_Applicant__r.LoanApplicationId != null AND 
                                              Loan_Applicant__r.LoanApplication.OpportunityId != null AND
                                              Loan_Applicant__r.LoanApplication.OpportunityId = :opps[0].Id]) {
                                                  System.assertNotEquals(users[0].Id,creditReport.OwnerId);
                                              }
        
        for (Appraisal_Order__c apprOrder : [SELECT Id,
                                             OwnerId
                                             FROM Appraisal_Order__c
                                             WHERE Appraisal__c != null AND
                                             Appraisal__r.Application__c != null AND
                                             Appraisal__r.Application__r.OpportunityId != null AND
                                             Appraisal__r.Application__r.OpportunityId = :opps[0].Id]){
                                                 System.assertNotEquals(users[0].Id,apprOrder.OwnerId);
                                             }
        
        //check log creation
        List<Process_Log__c> logs = [Select Id from Process_Log__c where Context__c = 'OpportunityOwnershipService'];
        System.assert(!logs.isEmpty());
    }
}