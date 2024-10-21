@isTest
public class GenerateEstimateLetterServiceTest
{
    @isTest
    static void testGenerateEstimateLetterPlatformEvent()
    {
        Test.startTest();
 		Map<String, Id> leadRecordTypes = Utils.getRecordTypeIdsBySObjectType(Lead.SObjectType); 
        Opportunity l = new Opportunity (
            Channel__c = Label.Lead_Channel_MrtgBrk, 
            Commitment_Letter_Decision_Date__c = Date.today(), 
            File_Validation_Error__c = TRUE, 
            Missing_MARS_Validation_Message__c = 'Test Value',
            MARS_Validation_Run__c = true ,
            Commitment_Letter_Decision__c = 'Approve',
            Commitment_Letter_Decision_Status__c = Label.Status_Commitment_Letter_Submitted,
            Credit_Assessment_Successful__c = true,
            StageName = 'Test',
            CloseDate = Date.today(),
            Name = 'Test123'     
        );
        insert l;
        
        List<MARS_Ready_Record__c> records = [SELECT Id FROM MARS_Ready_Record__c WHERE SFDC_Id__c = :l.Id];
        GenerateEstimateLetterService.generateEstimateLetterPlatformEvent(l.Id);
        
        Test.stopTest();	
        
        Opportunity lCheck = [
            SELECT Id,
            Commitment_Letter_Validation_Message__c,
            Commitment_Letter_Decision_Status__c,
            Commitment_Letter_Decision_Date__c
            FROM Opportunity
            WHERE Id = :l.Id
        ];
        
        System.assertEquals(null, lCheck.Commitment_Letter_Validation_Message__c);
        System.assertEquals(Date.today(), lCheck.Commitment_Letter_Decision_Date__c);
        System.assert(GenerateEstimateLetterService.generateEstimateLetterEventPublished, 'Platform Event did not fire');
        
        List<MARS_Ready_Record__c> records2 = [SELECT Id FROM MARS_Ready_Record__c WHERE SFDC_Id__c = :l.Id];
        System.assertEquals(records2.size(), records.size() + 1, 'Record not created');
        
    }
}