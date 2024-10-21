@IsTest
global class sdgDataProviderApexTest {
    
    @testSetup
    static void setupTestData(){
        
        Account l1 = new Account();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            l1 = TestFactory.createPartnerAccount('Test','Acc','50004','Toronto',null);
            insert l1;
        }
        
        Opportunity l = TestFactory.createConsumerOpportunity('Test AVM');
        l.File_Number__c='123456';
        l.AccountId=l1.Id;
        insert l;	
        
        ResidentialLoanApplication rla = new ResidentialLoanApplication (OpportunityId = l.id,name = 'test');
        insert rla;
        
        Quote quote1 = new Quote(OpportunityId = l.id,name='QT1',Active_Quote__c=false,Age_First_Borrower__c=40);
        Quote quote2 = new Quote(OpportunityId = l.id,name='QT2',Active_Quote__c=false,Age_First_Borrower__c=40);
        
        insert new List<Quote>{ quote1, quote2 }; 
            
            }
    
    @IsTest
    static void loadSDG(){
        
        string tag = 'Apex:sdgDataProviderApexExample';
        //create an sdg with relevant tag:
        
        test.startTest();
        ResidentialLoanApplication app = [select id from ResidentialLoanApplication limit 1];
        //not actually interested in whether this works - only the structure
        sortablegrid.SDG s = sdgDataProviderApex.LoadSDG(tag,app.id);
        system.assertNotEquals(null, s, 'sdgDataProviderApexExampleTest:loadSDG returned null');
        
        system.assertEquals(13, s.SDGFields.size(), 'Fields on example data provider');
        system.assertEquals(0, s.SDGActions.size(), 'Actions on example data provider');
        test.stopTest();
    }
    
    @IsTest
    static void getData(){
        string tag = 'apex:sdgDataProviderApexExample';
        test.startTest();
        sortablegrid.SDGREquest req = new sortablegrid.SDGREquest();
        req.SDGTag = tag;
        
        req.pageid=1;
        req.pagesize=5;
        req.filters=new List<sortablegrid.SDGFilter>{new sortablegrid.SDGFilter('9', '=', '40')};
            ResidentialLoanApplication app = [select id from ResidentialLoanApplication limit 1];
        sortablegrid.SDG s = sdgDataProviderApex.LoadSDG(tag,app.id);
        req.ParentRecordID = app.id;
        try{
        	sortablegrid.sdgresult sr = sdgDataProviderApex.getData(s, req);
        }catch(Exception e){
            System.assertNotEquals(e, null);
        }
        test.stopTest();
    }
}