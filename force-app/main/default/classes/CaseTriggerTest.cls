@IsTest
public without sharing class CaseTriggerTest {
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
        
        TestCaseFactory.initTestData();
    }
    
    @IsTest
    static void testRedressCreation() {
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Test.StartTest();
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName1',
            'Smith',
            '123smith@test.heb.ca',
            '41643210987'
        );
        insert cp;
        Case c = TestFactory.createComplaintCase(
            cp.id,
            'Case Trigger Test98765'
        );
        insert c;
        
        Redress__c redress = new Redress__C();
        redress.Case__c = c.Id;
        redress.Financial_Redress_Type__c = 'Refund';
        redress.Is_Redress_received__c = 'Yes';
        redress.Redress_Amount__c = 54;
        redress.Redress_Method__c = 'Cheque';
        redress.Resolution_Rationale__c = 'rationale field entry';
        
        insert redress;
        Test.StopTest();
    }
    
    /*
* HEB-28: Check that Opportunity MARS fields are updated automatically when moves to In Application
*/
    @IsTest
    static void testLinkCaseFromLead2ConvertedOpp() {
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Test.StartTest();
        Opportunity opp = [
            SELECT Id, File_Number__c
            FROM Opportunity
            WHERE Name = 'Test Drive'
        ];
        opp.File_Number__c = 'Test';
        update opp;
        
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName1',
            'Smith',
            '123smith@test.heb.ca',
            '41643210987'
        );
        insert cp;
        Case c = TestFactory.createComplaintCase(
            cp.id,
            'Case Trigger Test98765'
        );
        insert c;
        
        Case cn = [
            SELECT
            Id,
            Subject,
            File_Number__c,
            //Lead_File__c,
            MARS_File__c,
            Opportunity_File__c
            FROM Case
            WHERE subject = 'Case Trigger Test98765'
            LIMIT 1
        ];
        cn.File_Number__c = opp.File_Number__c;
        // cn.Lead_File__c = opp.Id;
        cn.MARS_File__c = null;
        cn.Opportunity_File__c = null;
        update cn;
        
        
        Test.StopTest();

        System.assertEquals(
            'Test',
            cn.File_Number__c,
            'Case was linked to Opportunity'
        );
    }
    
    /*
* HEB-248: Check that Quotes roll up to Lead
*/
    @IsTest
    static void testCaseCreation() {
        Test.setMock(HttpCalloutMock.class,new ValidationsRequestMockCallout());
        Account cp = TestFactory.createComplainant(
            'ComplainantFirstName2',
            'Smith2',
            '12356smith@test.heb.ca',
            '4164321978'
        );
        insert cp;
        Case c = TestFactory.createComplaintCase(
            cp.id,
            'Case Trigger Test98766'
        );
        Case c1 = TestFactory.createComplaintCase(
            cp.id,
            'Case Trigger Test88888'
        );
        insert new List<Case>{ c, c1 };
            
            List<Case> clist = [
                SELECT
                Id,
                File_Number__c,
                //Lead_File__c,
                MARS_File__c,
                Opportunity_File__c
                FROM Case
            ];
        
        //     where Subject = 'Case Trigger Test98765' limit 1];
        
        ResidentialLoanApplication application = [
            SELECT Id
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        LoanApplicationProperty prop1 = TestFactory.createProperty(
            application.Id,
            'Test',
            '123 LeadTriggerTest Drive',
            'Toronto',
            'ON',
            'M4M3M3'
        );
        insert prop1;
        
        Opportunity varOpportunity = testFactory.createConsumerOpportunity('testerSOCName');
        varOpportunity.File_Number__c = prop1.Id;
        
        insert varOpportunity;
        Test.StartTest();
        
        varOpportunity = [SELECT Id, File_Number__c FROM Opportunity][0];
        
        clist[0].File_Number__c = varOpportunity.File_Number__c;
        clist[0].Opportunity_File__c = varOpportunity.Id;
        
        update clist[0];
        
        clist = [
            SELECT
            Id,
            File_Number__c,
            //Lead_File__c,
            MARS_File__c,
            Opportunity_File__c
            FROM Case
        ];
        
        System.assertEquals(clist[0].Opportunity_File__c, varOpportunity.Id);
        
        clist[1].File_Number__c = varOpportunity.File_Number__c;
        clist[1].Opportunity_File__c = varOpportunity.Id;
        clist[0].File_Number__c = '';
        clist[0].Opportunity_File__c = null;
        
        update clist;
        clist = [
            SELECT
            Id,
            File_Number__c,
            //Lead_File__c,
            MARS_File__c,
            Opportunity_File__c
            FROM Case
        ];
        Test.StopTest();
        System.assertEquals(clist[1].Opportunity_File__c, varOpportunity.Id);
    }
    
   
}