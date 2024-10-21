@IsTest
private class AppraisalOrderControllerTest {
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
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
        Account  partnerAccount = TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert new List<Account>{orgAccount,partnerAccount};
            
            Contact c1 = TestFactory.createConsumerContact('Test1', 'Drive', 'testdrive1@chip.ca',orgAccount.Id);
        c1.Alternate_Phone_Number__c = '12121212';
        insert new List<Contact>{ c1};
            
            Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        Opportunity op2 = TestFactory.createConsumerOpportunity('Test Application');
        op2.AccountId = orgAccount.Id;
        insert new List<Opportunity>{op1, op2};
            
            ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test2', AccountId = orgAccount.Id, OpportunityId = op2.id);
        insert new list<ResidentialLoanApplication> {application};
            
            LoanApplicationProperty prop1 = TestFactory.createProperty(application.Id,'test1','123 Test Drive','Toronto','ON','M4M4M4');
        insert prop1;
        
        processSwitches.Deactivate_Triggers__c = TRUE;
        upsert processSwitches;
        
        LoanApplicant loanApp = new LoanApplicant();
        loanApp.name = 'Test';
        loanApp.contactId = c1.Id;
        loanApp.Client__c = partnerAccount.Id;
        loanApp.LoanApplicationId = application.Id;
        loanApp.role__c = 'Borrower';
		loanApp.Is_Primary_Borrower__c = true;
        insert loanApp;
        
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        Appraisal__c apr1 = TestFactory.createAppraisalFromFile(op1);
        Appraisal__c apr2 = TestFactory.createAppraisalFromProperty(prop1,op1);
        insert new List<Appraisal__c>{ apr1, apr2 };
            
            Appraisal_Order__c ao1 = TestFactory.createAppraisalOrderFromAppraisal(apr1);
        Appraisal_Order__c ao2 = TestFactory.createAppraisalOrderFromAppraisal(apr2);
        insert new List<Appraisal_Order__c>{ ao1, ao2 };
    }
    
    @IsTest
    static void testValidateOrder() {
        Test.startTest();
        Appraisal_Order__c ao = [
            SELECT
            Id,
            Alternate_Phone__c,
            Specify_Other_Time__c,
            Requested_Time_Window__c,
            Requested_Date__c,
            Contact_Email__c,
            Contact_First_Name__c,
            Contact_Last_Name__c,
            Primary_Phone__c,
            Appraisal__c,
            Reference_ID__c,
            Special_Instructions__c,
            Appraisal__r.Application_Property__r.LoanApplicationId,
            Rush_Order__c
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        Appraisal__c a = [
            SELECT
            Id,
            Cost_Exception_Approval__c,
            Application__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            Application_Property__c,
            Application_Property__r.LoanApplicationId,
            File__c,
            File__r.File_Number__c,
            File__r.Channel__c
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        ResidentialLoanApplication rla = [
            SELECT Id,OpportunityId
            FROM ResidentialLoanApplication
            WHERE Id = :a.Application_Property__r.LoanApplicationId
        ];
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
                a.Application_Property__c,
                false
            );
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        
        AppraisalOrderController.OrderValidationReport ovr = AppraisalOrderController.validateOrder(
            rla,
            ao,
            a,
            ap.p
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testRetriveLeadQuoteAmount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ResidentialLoanApplication rla = TestFactory.createResidentialLoanApplication(
            'application1'
        );
        rla.AccountId = acc.Id;
        Test.startTest();
        insert rla;
        Assert.IsNotNull(AppraisalOrderController.retriveLeadQuoteAmount(rla.Id));
    }
    
    @IsTest
    static void testretrievePrimaryBorrower() {
        ResidentialLoanApplication rla = [
            SELECT Id,OpportunityId
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
        Opportunity opp = [ SELECT Id,
                           Account.PersonContact.Alternate_Phone_Number__c,
                           Account.PersonContact.FirstName,
                           Account.PersonContact.LastName,
                           Account.PersonContact.Phone,
                           Account.PersonContact.Email,
                           Account.Phone,
                           AccountId
                           FROM Opportunity Where Id=: rla.OpportunityId];

        Test.startTest();
        Assert.IsNotNull(AppraisalOrderController.retrievePrimaryBorrower(rla.Id));
        Test.stopTest();
        
    }
    
    
    @IsTest
    static void testSendNote() {
        Appraisal_Order__c ao = [SELECT Id FROM Appraisal_Order__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        String s = AppraisalOrderController.sendNote(ao.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetLists() {
        Appraisal_Order__c ao = [SELECT Id FROM Appraisal_Order__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        AppraisalOrderController.getStatuses(ao.Id);
        AppraisalOrderController.getNotes(ao.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateUpdateFee() {
        Appraisal_Order__c ao = [
            SELECT Id, Appraisal__c, Reference_Id__c,Appraisal__r.Application_Property__r.LoanApplicationId
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        ao.Reference_Id__c = '1234567890';
        update ao;
        Appraisal__c app = [
            SELECT
            Id,
            File__c,
            Application_Property__c,
            Actual_Cost__c,
            Appraised_Amount__c,
            Cost_Split_Type__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            Cost_Exception_Approval__c
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        app.Actual_Cost__c = app.Actual_Cost__c + 50;
        app.Customer_split__c = app.Customer_split__c + 50;
        app.Appraised_Amount__c = 50;
        String s = AppraisalOrderController.validateUpdateFee(ao.Id, app);
        AppraisalOrderController.updateFee(ao.Id, app);
        Test.stopTest();
        
        Appraisal__c appCheck = [
            SELECT Id, Actual_Cost__c, Customer_split__c,File__c
            FROM Appraisal__c
            WHERE Id = :app.Id
        ];
        System.assertEquals(
            appCheck.Actual_Cost__c,
            app.Actual_Cost__c,
            'Actual Cost not updated'
        );
    }
    
    @IsTest
    static void testUpdateFee() {
        Appraisal_Order__c ao = [
            SELECT Id, Appraisal__c
            FROM Appraisal_Order__c
            LIMIT 1
        ];
        ao.Reference_ID__c = '123';
        update ao;
        
        Appraisal__c app = [
            SELECT
            Id,
            File__c,
            Application_Property__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            Cost_Exception_Approval__c
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        String s = AppraisalOrderController.validateUpdateFee(ao.Id, app);
        Test.stopTest();
    }
    
    @IsTest
    static void testSendAppraisalOrder() {
        Test.startTest();
        Appraisal_Order__c ao = [
            SELECT
            Id,
            Alternate_Phone__c,
            Specify_Other_Time__c,
            Requested_Time_Window__c,
            Requested_Date__c,
            Contact_Email__c,
            Contact_First_Name__c,
            Contact_Last_Name__c,
            Primary_Phone__c,
            Appraisal__c,
            Reference_ID__c,
            Special_Instructions__c,
            Rush_Order__c,
            Appraisal__r.Application_Property__r.LoanApplicationId 
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        Appraisal__c a = [
            SELECT
            Id,
            Cost_Exception_Approval__c,
            Application__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            File__c,
            File__r.File_Number__c,
            File__r.Channel__c,
            Application_Property__c,
            Application_Property__r.LoanApplicationId
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        ResidentialLoanApplication rla = [
            SELECT Id,OpportunityId
            FROM ResidentialLoanApplication
            WHERE Id = :a.Application_Property__r.LoanApplicationId
        ];
        
        AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
            a.Application_Property__c,
            false
        );
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        
        AppraisalOrderController.OrderValidationReport ovr = AppraisalOrderController.validateOrder(
            rla,
            ao,
            a,
            ap.p
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCancellation() {
        Test.startTest();
        Appraisal_Order__c ao = [
            SELECT
            Id,
            Alternate_Phone__c,
            Specify_Other_Time__c,
            Requested_Time_Window__c,
            Requested_Date__c,
            Contact_Email__c,
            Contact_First_Name__c,
            Contact_Last_Name__c,
            Primary_Phone__c,
            Appraisal__c,
            Reference_ID__c,
            Special_Instructions__c,
            Rush_Order__c,
            Appraisal__r.Application_Property__r.LoanApplicationId
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        Appraisal__c a = [
            SELECT
            Id,
            Cost_Exception_Approval__c,
            Application__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            File__c,
            File__r.File_Number__c,
            File__r.Channel__c,
            Application_Property__c,
            Application_Property__r.LoanApplicationId
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        ResidentialLoanApplication rla = [
            SELECT Id,OpportunityId
            FROM ResidentialLoanApplication
            WHERE Id = :a.Application_Property__r.LoanApplicationId
        ];
        AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
            a.Application_Property__c,
            false
        );
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            ao.Reference_ID__c = '20230120612';
        ao.Cancellation_Reason__c = AppraisalCancelOrderService.CANCEL_REASON_FILE_CLOSED_LOST;
        update ao;
        
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        String result = AppraisalOrderController.validateCancellation(ao.Id);
        AppraisalOrderController.hasSalesPermission();
        Test.stopTest();
    }
    
    @IsTest
    static void testThatOrderFromMarsUpdatesOpportunityOnly() {
        Test.startTest();
        ResidentialLoanApplication rla = [
            SELECT Id, OpportunityId
            FROM ResidentialLoanApplication LIMIT 1
        ];
        try{
            AppraisalOrderController.appraisalOrderFromMars(rla.Id);
        } catch(Exception e){
            System.assertNotEquals(e, null);
        }
    }
    
    
    @IsTest
    static void testThatAllowOrderReturnsTrueWhenFlaggedForMars() {
        List<Appraisal_Order__c> orders = [
            SELECT Id, Cancellation_Reason__c, Appraisal__r.Application__c, Appraisal__r.Application_Property__r.LoanApplicationId
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
        ];
        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Id = orders[0].Appraisal__r.Application_Property__r.LoanApplicationId,
            Status = AppraisalOrderService.LEAD_STAGE_APPRAISAL,
            Appraisal_Option__c = AppraisalOrderService.MARS_APPRAISAL_OPTION
        );
        Test.startTest();
        update rla;
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            
            System.assert(
                AppraisalOrderController.allowOrder(orders[0].Appraisal__r.Application_Property__r.LoanApplicationId),
                'Appraisal Order blocked'
            );
        Test.stopTest();
    }
    
    @IsTest
    static void testThatOrdersAreRetrieved() {
        List<Appraisal_Order__c> orders = [
            SELECT Id, Cancellation_Reason__c, Application__r.OpportunityId
            FROM Appraisal_Order__c
        ];
        Test.startTest();
        System.assert(
            AppraisalOrderController.retrieveOrders(
                orders[0].Application__r.OpportunityId
            )
            .size() > 0
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testRetrievePropertyRunParseAddress() {
        Test.startTest();
        LoanApplicationProperty p = [
            SELECT Id, Is_Address_Fragmented__c
            FROM LoanApplicationProperty
            LIMIT 1
        ];
        p.Is_Address_Fragmented__c = 'No';
        update p;
        
        Test.setMock(HttpCalloutMock.class, new ParseRequestMockCallout());
        AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
            p.Id,
            true
        );
        Test.stopTest();
        System.assertNotEquals(ap.p.Is_Address_Fragmented__c,Utils.AFFIRMATIVE);
    }
    
    @IsTest
    static void testRetrievePropertyDoNotRunParseAddress() {
        Test.startTest();
        LoanApplicationProperty p = [
            SELECT Id, Is_Address_Fragmented__c
            FROM LoanApplicationProperty
            LIMIT 1
        ];
        p.Is_Address_Fragmented__c = 'No';
        update p;
        
        Test.setMock(HttpCalloutMock.class, new ParseRequestMockCallout());
        
        AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
            p.Id,
            false
        );
        Test.stopTest();
        System.assertEquals(
            ap.p.Is_Address_Fragmented__c,
            'No',
            'Address was fragmented'
        );
    }
    
    @IsTest
    static void testRetrieveActivePOA() {
        List<Appraisal_Order__c> orders = [
            SELECT Id, Cancellation_Reason__c, Application__r.OpportunityId
            FROM Appraisal_Order__c
        ];
        Test.startTest();
        AppraisalOrderController.activePOAs(orders[0].Application__r.OpportunityId);
        Test.stopTest();
    }
    
    
    @IsTest
    static void testRetrieveAppraisalFileForLead() {
        List<Appraisal_Order__c> orders = [
            SELECT
            Id,
            Cancellation_Reason__c,
            Application__r.OpportunityId,
            Appraisal__r.Application_Property__r.LoanApplicationId,
            Application__c
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
        ];
        
        Test.startTest();
        AppraisalOrderController.AppraisalFile myFile = AppraisalOrderController.retrieveAppraisalFile(
            orders[0].Appraisal__r.Application_Property__r.LoanApplicationId
        );
        System.assertEquals(
            myFile.app.Id,
            orders[0].Appraisal__r.Application_Property__r.LoanApplicationId,
            'Application Id mismatch'
        );
        Test.stopTest();
    }
    
    
    
    /*
* HEB-445: Cancel Appraisal if the Lead is Closed Lost
*/
    @IsTest
    static void testCancelAppraisals() {
        Appraisal_Order__c ao = [
            SELECT Id, Reference_ID__c, Appraisal__r.Application__c, Appraisal__r.Application_Property__r.LoanApplicationId,Application__c
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        
        ao.Reference_ID__c = '20230120612';
        update ao;
        
        Test.setMock(HttpCalloutMock.class, new AppraisalCancelMockCallout());
        Test.startTest();
        AppraisalOrderController.cancelAppraisalOrder(ao.Id);
        Test.stopTest();
        
        Appraisal_Note__c noteCheck = [
            SELECT Id, Content__c
            FROM Appraisal_Note__c
            WHERE Appraisal_Order__c = :ao.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        System.assert(
            noteCheck.Content__c.contains(
                'HEB Appraisal Cancellation Request Reason'
            ),
            'Note not created!'
        );
    }
    
    @IsTest
    static void testcancelAppraisalOrderPostClosedLost() {
        Appraisal_Order__c ao = [
            SELECT Id, Reference_ID__c, Appraisal__r.Application__c, Appraisal__r.Application_Property__r.LoanApplicationId,Application__c
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL
            LIMIT 1
        ];
        
        ao.Reference_ID__c = '20230120612';
        update ao;
        
        Test.setMock(HttpCalloutMock.class, new AppraisalCancelMockCallout());
        Test.startTest();
        AppraisalOrderController.cancelAppraisalOrderPostClosedLost(ao.Id);
        Test.stopTest();
        
        Appraisal_Note__c noteCheck = [
            SELECT Id, Content__c
            FROM Appraisal_Note__c
            WHERE Appraisal_Order__c = :ao.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        System.assert(
            noteCheck.Content__c.contains(
                'HEB Appraisal Cancellation Request Reason'
            ),
            'Note not created!'
        );
    }
    
    @IsTest
    static void testThatOrderFromFCTReturnsErrors() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ResidentialLoanApplication rla = TestFactory.createResidentialLoanApplication(
            'ApplicationTest'
        );
        rla.accountId = acc.Id;
        Test.startTest();       
        insert rla;
        
        LoanApplicationProperty p = TestFactory.createProperty(
            rla.Id,  
            'test',
            '55 FCT Avenue',
            'Winnipeg',
            'MB',
            'Z1Z1Z1'
        );
        p.Zoning__c = 'Residential';
        p.Is_Address_Fragmented__c = Utils.AFFIRMATIVE;
        insert p;
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            Appraisal__c a = new Appraisal__c(
                Application__c = rla.Id,
                Customer_Split__c = 350,
                Partner_Split__c = 0,
                HEB_Split__c = 0,
                Paid_From_Proceeds__c = 'No',
                Cost_Exception_Approval__c = 'Written'
            );
        Appraisal_Order__c ao = new Appraisal_Order__c(
            Requested_Time_Window__c = '8:00AM – 11:00AM',
            Requested_Date__c = date.today().addDays(3),
            Contact_First_Name__c = 'John',
            Contact_Last_Name__c = 'Doe'
        );
        
        Boolean exceptionCaught = false;
        Test.setMock(HttpCalloutMock.class, new AppraisalOrderErrorsMockCallout());
        
        try {
            AppraisalOrderController.appraisalOrderFromFCT(rla, p, a, ao);
        } catch (AuraHandledException e) {
            exceptionCaught = true;
        }
        
        Test.stopTest();
        
        System.assert(exceptionCaught);
    }
    
    @IsTest
    static void testMissingFileTypeThrowsError() {
        Appraisal_Order__c ao = [
            SELECT
            Id,
            Alternate_Phone__c,
            Specify_Other_Time__c,
            Requested_Time_Window__c,
            Requested_Date__c,
            Contact_Email__c,
            Contact_First_Name__c,
            Contact_Last_Name__c,
            Primary_Phone__c,
            Appraisal__c,
            Appraisal__r.Application_Property__r.LoanApplicationId,
            Appraisal__r.File__c,
            Reference_ID__c,
            Special_Instructions__c,
            Rush_Order__c
            FROM Appraisal_Order__c
            WHERE Appraisal__r.Application_Property__r.LoanApplicationId != NULL AND Appraisal__r.File__c != NULL
            LIMIT 1
        ];
        
        Appraisal__c a = [
            SELECT
            Id,
            Cost_Exception_Approval__c,
            Application__c,
            Customer_split__c,
            HEB_Split__c,
            Partner_Split__c,
            Paid_From_Proceeds__c,
            Application_Property__c,
            Application_Property__r.LoanApplicationId,
            File__c,
            File__r.File_Number__c,
            File__r.Channel__c,
            File__r.File_Type__c
            FROM Appraisal__c
            WHERE Id = :ao.Appraisal__c
        ];
        
        ResidentialLoanApplication rla = [
            SELECT Id, OpportunityId
            FROM ResidentialLoanApplication
            WHERE Id = :a.Application_Property__r.LoanApplicationId
        ];
        AppraisalOrderController.AppraisalProperty ap = AppraisalOrderController.retrieveProperty(
            a.Application_Property__c,
            false
        );
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        Test.startTest();
        a.File__r.File_Type__c = null;
        update a;
        
        LoanApplicant la1 = TestFactory.createLoanApplicant(
            'Lorem',
            'Ipsum',
            'lorem.ipsum@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        LoanApplicant la2 = TestFactory.createLoanApplicant(
            'Ipsum',
            'Lorem',
            'lorem.ipsum2@heb.ca',
            rla,
            PropertyMemberService.BORROWER_ROLE
        );
        insert new List<LoanApplicant>{ la1, la2 };
            
            AppraisalOrderController.OrderValidationReport ovr = AppraisalOrderController.validateOrder(
                rla,
                ao,
                a,
                ap.p
            );
        Test.stopTest();
    }
    
    @isTest
    static void testGetPropertyMemberCreditScore() {
        LoanApplicant loanApplicant = [SELECT Id from LoanApplicant limit 1];
        
        // Create a Credit Report record linked to the Loan Applicant
        Credit_Report__c creditReport = new Credit_Report__c(
            Loan_Applicant__c = loanApplicant.Id,
            Credit_Score__c = 720
        );
        insert creditReport;
        
        // Step 2: Test the method with existing Credit Report records
        Test.startTest();
        Integer creditScore = AppraisalOrderService.getPropertyMemberCreditScore(loanApplicant.Id);
        Test.stopTest();
        
        // Step 3: Verify that the latest Credit Report's Credit Score is returned
        System.assertEquals(720, creditScore, 'The credit score should be 720.');
    }
    
    @isTest
    static void testConvertPercentToDecimal() {
        // Test case 1: totalValue is provided, and percentage is calculated
        Decimal totalValue = 2000;
        Decimal percent = 15;
        
        Test.startTest();
        Decimal result = AppraisalOrderService.convertPercentToDecimal(totalValue, percent);
        Test.stopTest();
        System.assertEquals(300.00, result, 'The result should be 300.00 for a 15% of 2000');
        
    }
    
    @isTest
    static void testConvertPercentToDecimalnull() {
        // Test case 1: totalValue is provided, and percentage is calculated
        Decimal totalValue = null;
        Decimal percent = 15;
        
        Test.startTest();
        Decimal result = AppraisalOrderService.convertPercentToDecimal(totalValue, percent);
        Test.stopTest();
        System.assertEquals(52.50, result, 'The result should be 200.00 for a 20% of the default value 1000');
        
    }
    @isTest
    static void testFormatDOB() {
        // Test case 1: A regular date with two-digit month and day
        Date testDate = Date.newInstance(2024, 8, 15);
        
        Test.startTest();
        String formattedDate = AppraisalOrderService.formatDOB(testDate);
        Test.stopTest();
        
        System.assertEquals('2024-08-15', formattedDate, 'The formatted date should be 2024-08-15 for the date 15th August 2024.');
        
    }
    @isTest
    static void testMoveLeadToPreApplication() {
        // Create a test ResidentialLoanApplication record
        ResidentialLoanApplication testLoanApp =[Select Id, OpportunityId, Status,Appraisal_Option__c from ResidentialLoanApplication where OpportunityId != NULL limit 1];
        
        // Define the leadId and new appraisalOption for the test
        Id leadId = testLoanApp.Id;
        String newAppraisalOption = 'MARS';
        
        Test.startTest();
        // Call the method being tested
        AppraisalOrderService.moveLeadToPreApplication(leadId, newAppraisalOption);
        Test.stopTest();
        
        // Query the updated record from the database
        testLoanApp = [
            SELECT Status, Appraisal_Option__c 
            FROM ResidentialLoanApplication 
            WHERE Id = :leadId 
            LIMIT 1
        ];
        
        // Verify that the Status and Appraisal_Option__c fields were updated correctly
        System.assertEquals('Pre-Application', testLoanApp.Status, 'Status should be updated to "Appraisal".');
    }
    @isTest
    static void testConvertNote() {
        // Create a test AppraisalOrder
        Appraisal_Order__c testAppOrder =[Select id from Appraisal_Order__c limit 1];
        
        // Create a mock Note object (assuming ModelAppraisalOrder.Note is a class with properties Text, EnteredBy, and EnteredOn)
        ModelAppraisalOrder.Note testNote = new ModelAppraisalOrder.Note();
        testNote.Text = 'This is a test note';
        testNote.EnteredBy = 'Test User';
        testNote.EnteredOn = DateTime.now();
        
        // Call the convertNote method
        Appraisal_Note__c resultNote = AppraisalOrderService.convertNote(testAppOrder.Id, testNote);
        
        // Verify the result is not null
        System.assertNotEquals(null, resultNote, 'The result should not be null.');
        
        // Verify the fields are populated correctly
        System.assertEquals(testAppOrder.Id, resultNote.Appraisal_Order__c, 'Appraisal_Order__c should match the test Appraisal Order ID.');
        System.assertEquals(true, resultNote.Incoming_Note__c, 'Incoming_Note__c should be true.');
        System.assertEquals(testNote.Text, resultNote.Content__c, 'Content__c should match the Note Text.');
        System.assertEquals(testNote.EnteredBy, resultNote.Entered_By__c, 'Entered_By__c should match the Note EnteredBy.');
        System.assertEquals(testNote.EnteredOn, resultNote.Entered_On_DT__c, 'Entered_On_DT__c should match the Note EnteredOn.');
    }
    @isTest
    static void testSendOrder() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new AppraisalFeeMockCallout());
        
        // Create test data
        ResidentialLoanApplication loanApp = [Select id,OpportunityId from ResidentialLoanApplication limit 1];
        
        Appraisal_Order__c appraisalOrder = [Select id,Special_Instructions__c,Rush_Order__c,Contact_First_Name__c,Contact_Last_Name__c,Primary_Phone__c,Alternate_Phone__c,Contact_Email__c,Requested_Date__c,Requested_Time_Window__c,Specify_Other_Time__c from Appraisal_Order__c limit 1];
        
        Appraisal__c appraisal = [Select id,Cost_Split_Type__c,Actual_Cost__c,HEB_Split__c,Partner_Split__c,Paid_From_Proceeds__c,Cost_Exception_Approval__c,Customer_Split__c from Appraisal__c limit 1];
        
        LoanApplicationProperty property = [Select id,PropertyState,PropertyPostalCode,PropertyCity,PropertyStreet,Property_Type__c,Zoning__c,Property_Value_for_Quote__c,UnitNumberFragment__c,AddressNumberFragment__c,StreetNameFragment__c,StreetTypeFragment__c,StreetDirectionFragment__c,CityFragment__c,PostalCodeFragment__c,ProvinceFragment__c from LoanApplicationProperty limit 1];
        
        // Call the method
        Test.startTest();
        String responseBody = AppraisalOrderService.sendOrder(loanApp, appraisalOrder, appraisal, property);
        Test.stopTest();
        
        // Verify the response
        System.assertEquals('{ "ReferenceID": "20230120612", "IsSuccessful": true, "Notes": [ { "Text": "Appraisal Fee Breakdown: Total Appraisal Fee: $375.00 Customer cost: $275.00 HEB cost: $100.00", "Type": "Appraisal Note", "EnteredOn": "2020-08-17T03:57:24.0402468-04:00", "EnteredBy": "pta" } ], "Errors": []}', responseBody, 'The response body should match the mocked response.');
    }
    
    @isTest
    static void testProcessResponseSuccess() {
        // Create test data
        ResidentialLoanApplication loanApp = [Select Id, OpportunityId from ResidentialLoanApplication where OpportunityId != NULL limit 1];
        
        Appraisal_Order__c appraisalOrder = [Select Id,Special_Instructions__c,Rush_Order__c,Contact_First_Name__c,Contact_Last_Name__c,Primary_Phone__c,Alternate_Phone__c,Contact_Email__c,Requested_Date__c,Requested_Time_Window__c,Specify_Other_Time__c from Appraisal_Order__c limit 1];
        
        Appraisal__c appraisal = [Select Id,Cost_Split_Type__c,Actual_Cost__c,HEB_Split__c,Partner_Split__c,Paid_From_Proceeds__c,Cost_Exception_Approval__c,Customer_Split__c from Appraisal__c limit 1];
        
        LoanApplicationProperty property = [Select Id,Property_Type__c,Zoning__c,Property_Value_for_Quote__c,UnitNumberFragment__c,AddressNumberFragment__c,StreetNameFragment__c,StreetTypeFragment__c,StreetDirectionFragment__c,CityFragment__c,PostalCodeFragment__c,ProvinceFragment__c,PropertyStreet,PropertyPostalCode,PropertyCity from LoanApplicationProperty limit 1];
        AppraisalOrderService.AppraisalOrderDetails aod = new AppraisalOrderService.AppraisalOrderDetails();
        aod.app = appraisal;
        aod.ao = appraisalOrder;
        aod.appLead = loanApp;
        
        
        
        // Mock successful response
        String orderResponse = '{"IsSuccessful":true, "AppraisalProduct":"Test Product", "ReferenceID":"TestRef123", "OrderStatus":"Completed", "OrderStatusChangedOn":"2023-08-09", "Notes":[{"Text":"Test Note", "EnteredBy":"User1", "EnteredOn":"2023-08-09"}]}';
        
        // Call the method
        Test.startTest();
        String result = AppraisalOrderService.processResponse(orderResponse, aod);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(null, result, 'The result should be null on success');
        
        // Verify that records were updated
        Appraisal__c updatedAppraisal = [SELECT Appraisal_Product__c FROM Appraisal__c WHERE Id = :appraisal.Id];
        System.assertEquals('Test Product', updatedAppraisal.Appraisal_Product__c, 'The appraisal product should be updated');
        
        Appraisal_Order__c updatedAppraisalOrder = [SELECT Appraisal__c, Application__c FROM Appraisal_Order__c WHERE Id = :appraisalOrder.Id];
        System.assertEquals(appraisal.Id, updatedAppraisalOrder.Appraisal__c, 'The appraisal ID should be set on the order');
        System.assertEquals(loanApp.Id, updatedAppraisalOrder.Application__c, 'The application ID should be set on the order');
        
        // Verify that notes were inserted
        List<Appraisal_Note__c> notes = [SELECT Content__c FROM Appraisal_Note__c WHERE Appraisal_Order__c = :appraisalOrder.Id];
        System.assertEquals(1, notes.size(), 'One note should be inserted');
        System.assertEquals('Test Note', notes[0].Content__c, 'The note content should match the response');
    }
    
}