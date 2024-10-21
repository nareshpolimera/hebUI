@isTest
public class RedressTriggerTest {
    //Santhosh -- Commented all DM_ fields as they are no longer needed
    @testSetup
    static void setupTestData() {
        TestFactory.initTestData();
        

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

        Case CurrentCase = [SELECT id
                            FROM Case
                            LIMIT 1];
        
        Redress__c redress = new Redress__C();
        redress.Case__c = c.Id;
        redress.Financial_Redress_Type__c = 'Refund';
        redress.Is_Redress_received__c = 'Yes';
        redress.Redress_Amount__c = 54;
        redress.Redress_Method__c = 'Cheque';
        redress.Resolution_Rationale__c = 'rationale field entry';
        insert redress;
    
        update redress;
        
      
        Case caseAfterUpdate = [ SELECT
                                id,
                                (
                                  SELECT
                                    id,
                                    Redress_Amount__c,
                                    Resolution_Rationale__c
                                  FROM Redresses__r
                                )
                                FROM Case
                                LIMIT 1
                             ];
        
        String expectedEnResult = 'A refund in the amount of $54.00 via cheque. This amount is based on rationale field entry.';
        String expectedFrResult = 'Remboursement de 54.00$ qui sera versé par chèque. Ce montant est basé sur rationale field entry';

        Test.StopTest();
    }

    
   
    
}