@IsTest
private class AVMRequestServiceTest {
    
    @testSetup
    static void setupTestData() {
        HEB_Kill_Switch__c hebKillSwitch = HEB_Kill_Switch__c.getOrgDefaults();
        hebKillSwitch.Deactivate_Triggers__c = FALSE;
        upsert hebKillSwitch;
        
        Opportunity op1 = TestFactory.createConsumerOpportunity('Test Drive');
        insert op1;
        
        Account partnerAccount = TestFactory.createPartnerAccount(
            'West Toronto',
            'Bank',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        insert partnerAccount;
        
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'Test', AccountId = partnerAccount.Id);
        insert application;
        
        LoanApplicationProperty prop1 = TestFactory.createProperty(
            application.Id,
            'test1',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        insert prop1;
        
        Appraisal__c apr1 = TestFactory.createAppraisalFromFile(op1);
        Appraisal__c apr2 = TestFactory.createAppraisalFromProperty(prop1,op1);
        
        insert new List<Appraisal__c>{ apr1, apr2 };
            
            Appraisal_Order__c ao1 = TestFactory.createAppraisalOrderFromAppraisal(apr1);
        Appraisal_Order__c ao2 = TestFactory.createAppraisalOrderFromAppraisal(apr2);
        
        insert new List<Appraisal_Order__c>{ ao1, ao2 };
            }
    
    @IsTest
    static void testThatParseRequestReturnsUpdatedProperty() {
        Account partnerAccount = TestFactory.createPartnerAccount(
            'West1 Toronto1',
            'Bank1',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        insert partnerAccount;
        
        Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        objOpportunity.AccountId = partnerAccount.Id;
        update objOpportunity;
        
        ResidentialLoanApplication objResidentialLoanApplication = TestFactory.createResidentialLoanApplication('Test Data');
        objResidentialLoanApplication.OpportunityId = objOpportunity.Id;
        insert objResidentialLoanApplication;
        
        LoanApplicationProperty objLoanApplicationProperty = TestFactory.createProperty(
            objResidentialLoanApplication.Id,
            'testAVM',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        insert objLoanApplicationProperty;
        
        Test.setMock(HttpCalloutMock.class, new ValidationsRequestMockCallout());
        
        Test.startTest();
        AVMRequestService.runAddressParse(objResidentialLoanApplication.Id, 'ResidentialLoanApplication');
        Test.stopTest();
        
        LoanApplicationProperty updatedLoanApplicationProperty = [
            SELECT Id, UnitNumberFragment__c 
            FROM LoanApplicationProperty 
            WHERE LoanApplicationId = :objResidentialLoanApplication.Id 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals(updatedLoanApplicationProperty.UnitNumberFragment__c, '21', 'Unit Number Fragment not updated from mock response');
    }
    
    @IsTest
    static void testThatAVMRequestReturnsUpdatedProperty() {
    	
        Account objPartnerAccount = TestFactory.createPartnerAccount(
            'West2 Toronto2',
            'Bank2',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        insert objPartnerAccount;
        
        Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        objOpportunity.AccountId = objPartnerAccount.Id;
        objOpportunity.File_Number__c = '12345';
        objOpportunity.Channel__c = 'Referred';
        objOpportunity.File_Type__c = 'Reverse Mortgage';
        objOpportunity.LeadSource = 'Client Referral';
        update objOpportunity;
        
        ResidentialLoanApplication objResidentialLoanApplication = TestFactory.createResidentialLoanApplication('Test Data');
        objResidentialLoanApplication.AccountId = objPartnerAccount.Id;
        objResidentialLoanApplication.OpportunityId = objOpportunity.Id;
        insert objResidentialLoanApplication;
        
        Appraisal_Note__c objAppraisalNote = new Appraisal_Note__c();
        objAppraisalNote.Appraisal_Order__c = [SELECT Id FROM Appraisal_Order__c LIMIT 1][0].Id;
        objAppraisalNote.Content__c = 'Test';
        objAppraisalNote.Incoming_Note__c = true;
        //insert objAppraisalNote;
        
        LoanApplicationProperty objLoanApplicationProperty = TestFactory.createProperty(
            objResidentialLoanApplication.Id,
            'testAVM',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        objLoanApplicationProperty.Zoning__c = 'Residential';
        insert objLoanApplicationProperty;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AVMRequestMockCallout());
        
        
        AVMRequestService.runAVMCheck(objResidentialLoanApplication.OpportunityId, 'ResidentialLoanApplication', objResidentialLoanApplication.Id);
        Test.stopTest();
        
        LoanApplicationProperty updatedLoanApplicationProperty = [
            SELECT Id, Use_AVM_Value__c 
            FROM LoanApplicationProperty 
            WHERE LoanApplicationId = :objResidentialLoanApplication.Id 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals(updatedLoanApplicationProperty.Use_AVM_Value__c, true, 'Ordered From not updated from mock response');
    }
    
    @IsTest
    public static void testThatRunAVMCheckCloneReturnsUpdatedProperty() {
        
        Account objPartnerAccount = TestFactory.createPartnerAccount(
            'West3 Toronto3',
            'Bank3',
            'M4M4C4',
            'Toronto',
            '316023456'
        );
        insert objPartnerAccount;
        
        Opportunity objOpportunity = [
            SELECT Id, File_Number__c
            FROM Opportunity
            LIMIT 1
        ];        
        objOpportunity.AccountId = objPartnerAccount.Id;
        objOpportunity.File_Number__c = '12345';
        objOpportunity.Channel__c = 'Referred';
        objOpportunity.File_Type__c = 'Reverse Mortgage';
        objOpportunity.LeadSource = 'Client Referral';
        update objOpportunity;
        
        ResidentialLoanApplication objResidentialLoanApplication = TestFactory.createResidentialLoanApplication('Test Data');
        objResidentialLoanApplication.AccountId = objPartnerAccount.Id;
        objResidentialLoanApplication.OpportunityId = objOpportunity.Id;
        insert objResidentialLoanApplication;
        
        LoanApplicationProperty objLoanApplicationProperty = TestFactory.createProperty(
            objResidentialLoanApplication.Id,
            'testAVM',
            '123 Test Drive',
            'Toronto',
            'ON',
            'M4M4M4'
        );
        insert objLoanApplicationProperty;
        
        Test.startTest();
        
        // Set up mock for the AVM Request
        Test.setMock(HttpCalloutMock.class, new AVMRequestMockCallout());
        
        LoanApplicationProperty updatedProperty = AVMRequestService.runAVMCheckClone(
            objOpportunity.Id,
            'ResidentialLoanApplication',
            objResidentialLoanApplication.Id,
            'Toronto',
            'Test Drive',
            'Drive',
            '123',
            'ON',
            'M4M4M4'
        );
        Test.stopTest();
        
        // Verify that the property was updated correctly
        LoanApplicationProperty result = [
            SELECT AVM_Ordered_From__c, AVM_Reference_Id__c, AVM_Value__c, AVM_Lower_Value_Limit__c,
            AVM_Upper_Value_Limit__c, AVM_Confidence_Rating__c, AVM_Request_Succeeded__c, 
            AVM_Last_Requested__c, Use_AVM_Value__c 
            FROM LoanApplicationProperty 
            WHERE Id = :updatedProperty.Id
            LIMIT 1
        ];
        
        System.assertEquals(result.Use_AVM_Value__c, true, 'Use_AVM_Value__c was not updated correctly.');
        System.assertNotEquals(result.AVM_Reference_Id__c, null, 'AVM_Reference_Id__c should have been updated.');
        System.assertNotEquals(result.AVM_Value__c, null, 'AVM_Value__c should have been updated.');
        System.assertEquals(result.AVM_Request_Succeeded__c, true, 'AVM_Request_Succeeded__c was not updated correctly.');
    }
}