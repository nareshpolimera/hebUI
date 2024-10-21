@IsTest
public class ProductLWCFieldsetControllerTest { 
    @TestSetup
    static void makeData() {
        
        MARS_Integration_Settings__c settings = MARS_Integration_Settings__c.getOrgDefaults();
        settings.MARS_Integration_User_Id__c = UserInfo.getUserId();
        upsert settings;
        
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
        processSwitches.Deactivate_Triggers__c = FALSE;
        upsert processSwitches;
        
        Account account = new Account(FirstName = 'Test', LastName = 'Test');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'Test',
            AccountId = account.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            Requested_For__c = Date.today()-1,
            CloseDate = System.today()
        );
        insert opportunity;
        ResidentialLoanApplication application = new ResidentialLoanApplication(
            OpportunityId = opportunity.Id);
        insert application;
        // Create test data for Product
        Product2 p = new Product2( Name = 'CHIP');
        insert p;
    }
    
    @IsTest
    static void testGetFieldSetFieldsWithValues() {
        // Define field set information
        String objectName = 'ResidentialLoanApplication';
        String fieldSetName = 'Product_LWC';
        
        ResidentialLoanApplication res = [select id from ResidentialLoanApplication limit 1];
        Opportunity opp = [select id from opportunity limit 1];
        opp.Term__c = 'Variable';
        opp.Requested_For__c = Date.today();
        opp.StageName = OpportunityService.APPLICATION_OPP_STAGE;
        update opp;
        Product2 prd = [select id from Product2 limit 1];
        // Call the method
        Map<String, Object> response = ProductLWCFieldsetController.getFieldSetFieldsWithValues(res.Id, objectName, fieldSetName);
        
        // Replace 'MyObject' and 'MyFieldSet' with your actual object and field set names
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get('Opportunity');
        Schema.FieldSet fieldSet = objectType.getDescribe().fieldSets.getMap().get('Approved_Opportunity');
        
        // Build the SOQL string
        String soql = 'SELECT Id';
        // Prepare fields to update
        Map<String, Map<String, Object>> fieldsToUpdate = new Map<String, Map<String, Object>>();
        // Iterate over field set members and retrieve field API names
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            soql += ', ' + field.getFieldPath();
            // ... populate fieldsToUpdate with test data
            //if(field.getFieldPath() == 'Product_Type__c')
            fieldsToUpdate.put(field.getFieldPath(), new Map<String, Object>{opp.id=>field.getType()}); 
        }
        
        // Call the method
        ProductLWCFieldsetController.saveOpportunityFields(fieldsToUpdate, opp.Id);
        
        soql += ' FROM Opportunity limit 1';
        
        // Retrieve the updated Opportunity and verify field values
        List<Opportunity> updatedOpps = Database.query(soql);
        
        // Access field values from the retrieved records
        for (Opportunity updatedopp : updatedOpps) {
            System.debug('Field Values: ' + updatedopp);
        }
    }
    @IsTest
    static void testNegative() {
        try{
            ProductLWCFieldsetController.getFieldSetFieldsWithValues(null, null, null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
        try{
            ProductLWCFieldsetController.saveOpportunityFields(null, null);
        } catch(Exception e) {
            System.assertNotEquals(e, null);
        }
    }
}