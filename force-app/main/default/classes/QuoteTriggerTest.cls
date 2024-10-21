@IsTest
public class QuoteTriggerTest {

    @testSetup static void setupTestData() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        Account partnerAccount =TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert partnerAccount;
        Opportunity opp1 = TestFactory.createConsumerOpportunity('Test AVM');
        opp1.File_Number__c='123456';
        opp1.AccountId=partnerAccount.Id;
        insert opp1;
    }
    
	/*
	 * HEB-273: Check that when opportunity product is changed the right quote is synced
	 */
    @IsTest
    static void testInsertAndUpdateQuote() {
        Opportunity o = [select Id,Product_Type__c,syncedQuoteId from Opportunity limit 1];
        Test.startTest();
        Quote quote1 				= TestFactory.createEligibleQuoteFromOpportunity(o);
        quote1.product_Type__c = 'CHIP';
        Quote quote2 				=  TestFactory.createEligibleQuoteFromOpportunity(o);
        quote2.product_Type__c = 'CHIP MAX';
        insert new List<Quote> { quote1, quote2 };
        quote1.Active_Quote__c = true;
        quote2.Rate__c = 23; 
        update new List<Quote> { quote1, quote2 };        
        Test.stopTest();
    }
   
}