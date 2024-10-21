@isTest
public class LoanApplicationAssetServiceTest {
    
  @testSetup
  static void setupTestData() {
    HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getOrgDefaults();
    processSwitches.Deactivate_Triggers__c = false;
    upsert processSwitches;
        Account partnerAccount =TestFactory.createPartnerAccount('West Toronto','Bank','M4M4C4','Toronto','316023456');
        insert partnerAccount;
        Opportunity opp1 = TestFactory.createConsumerOpportunity('Test AVM');
        opp1.File_Number__c='123456';
        opp1.AccountId=partnerAccount.Id;
        insert opp1;
        ResidentialLoanApplication application = new ResidentialLoanApplication(Name = 'TestApp', AccountId = partnerAccount.Id);
        insert application;
        LoanApplicationProperty loanProperty = new LoanApplicationProperty(
            Name = 'Test Property',
            LoanApplicationId = application.Id,
            Property_Type__c = 'Single Family Dwelling',
            PropertyPostalCode = 'L5C2B8',
            PropertyCity = 'Mississauga',
            PropertyStateCode = 'AB',
            PropertyCountryCode = 'CA'
        );
        insert loanProperty;
        List<Profile> profileList = [
            SELECT Id, Name
            FROM Profile
            WHERE
            Name IN (
                :Label.ConsumerSales_Profile_Name,
                :Label.Call_Centre_Profile_Name,
                :Label.BDM_Profile_Name,
                :Label.SystemAdmin_Profile_Name,
                :Label.HEBStandard_Profile_Name,
                :Label.Integration_Profile_Name,
                'Relationship Manager'
            )
        ];
        Profile adminProfile;
        Profile standardUserProfile;
        Profile relManagerProfile;
         for (Profile p : profileList) {
            if (p.Name == Label.SystemAdmin_Profile_Name)
                adminProfile = p;
            if (p.Name == Label.HEBStandard_Profile_Name)
                standardUserProfile = p;  
            if (p.Name == 'Relationship Manager')
                relManagerProfile = p;  
        }
            User relUser = new User(
            ProfileId = relManagerProfile.Id,
            Username = 'rel@chip.ca',
            Email = 'rel@chip.ca',
            FirstName = 'rel',
            LastName = 'user',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            Alias = 'relUser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert relUser;
  }
    
 	@isTest
    static void testLoanApplicationAssetHandler() {
        // Retrieve setup data
        Account account = [SELECT Id,PersonContactId FROM Account where IsPersonAccount=true LIMIT 1];
        Contact contact = [Select Id,RecordTypeId, RecordType.Name from Contact where id=:account.PersonContactId limit 1];
        System.debug('Inside Test' + contact);
        
        ResidentialLoanApplication loanApp = [SELECT Id FROM ResidentialLoanApplication WHERE AccountId = :account.Id LIMIT 1];

        // Create LoanApplicationAsset records
        LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = loanApp.Id,Name='text');

        // Instantiate handler and call lifecycle methods
        LoanApplicationAssetHandler handler = new LoanApplicationAssetHandler(new List<LoanApplicationAsset>{asset});
        handler.beforeInsert(new List<LoanApplicationAsset>{asset});
        insert asset;
        
        handler.afterInsert(new List<LoanApplicationAsset>{asset}, new Map<Id, LoanApplicationAsset>{asset.Id => asset});
        
        // Update the record
        handler.beforeUpdate(new List<LoanApplicationAsset>{asset}, new Map<Id, LoanApplicationAsset>{asset.Id => asset});
        update asset;
    }

    @isTest
    static void testLoanApplicationAssetServiceSetOwner() {
        // Retrieve setup data
        Account account = [SELECT Id,PersonContactId FROM Account where IsPersonAccount=true LIMIT 1];
        Contact contact = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        ResidentialLoanApplication loanApp = [SELECT Id, AccountId,OpportunityId FROM ResidentialLoanApplication WHERE AccountId = :account.Id LIMIT 1];
        

        // Create LoanApplicationAsset records
        LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = loanApp.Id,Name='text');
        insert asset;
		system.debug('loanlenaopp'+asset.LoanApplication?.OpportunityId);
        system.debug('loanlenaAccount'+asset.LoanApplication?.AccountId);
        // Invoke setOwner method from service
        LoanApplicationAssetService service = new LoanApplicationAssetService();
        service.setOwner(new List<LoanApplicationAsset>{asset});

        // Assert that the OwnerId was set correctly
        LoanApplicationAsset updatedAsset = [SELECT Id, OwnerId FROM LoanApplicationAsset WHERE Id = :asset.Id LIMIT 1];
        System.assertNotEquals(null, updatedAsset.OwnerId, 'OwnerId should have been set.');
    }

    @isTest
    static void testLoanApplicationAssetServiceUpdateFileRecordType() {
        // Retrieve setup data
       Account account = [SELECT Id,PersonContactId FROM Account where IsPersonAccount=true LIMIT 1];
        Contact contact = [SELECT Id, OwnerId,RecordTypeId FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        ResidentialLoanApplication loanApp = [SELECT Id, AccountId,OpportunityId FROM ResidentialLoanApplication WHERE AccountId = :account.Id LIMIT 1];

        // Create LoanApplicationAsset records
 		LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = loanApp.Id,Name='text');
        insert asset;

    }

    @isTest
    static void testLoanApplicationAssetDomainBeforeInsert() {
        // Retrieve setup data
        Account account = [SELECT Id,PersonContactId FROM Account where IsPersonAccount=true LIMIT 1];
        ResidentialLoanApplication loanApp = [SELECT Id FROM ResidentialLoanApplication WHERE AccountId = :account.Id LIMIT 1];

        // Create LoanApplicationAsset records
        LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = loanApp.Id,Name='text');

        // Invoke beforeInsert method from domain
        LoanApplicationAssetDomain domain = new LoanApplicationAssetDomain();
        domain.beforeInsert(new List<LoanApplicationAsset>{asset});

        // Insert asset and verify
        insert asset;
        LoanApplicationAsset insertedAsset = [SELECT Id, OwnerId  FROM LoanApplicationAsset WHERE Id = :asset.Id LIMIT 1];
        System.assertNotEquals(null, insertedAsset.OwnerId, 'OwnerId should have been set.');
    }

    @isTest
    static void testLoanApplicationAssetDomainBeforeUpdate() {
        // Retrieve setup data
         Account account = [SELECT Id,PersonContactId FROM Account where IsPersonAccount=true LIMIT 1];
        ResidentialLoanApplication loanApp = [SELECT Id FROM ResidentialLoanApplication WHERE AccountId = :account.Id LIMIT 1];

        // Create and insert LoanApplicationAsset record
        LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = loanApp.Id,Name='text');
        insert asset;

        // Simulate an update
        LoanApplicationAsset updatedAsset = [SELECT Id, LoanApplication.Account.PersonContactId FROM LoanApplicationAsset WHERE Id = :asset.Id LIMIT 1];

        // Invoke beforeUpdate method from domain
        LoanApplicationAssetDomain domain = new LoanApplicationAssetDomain();
        domain.beforeUpdate(new List<LoanApplicationAsset>{updatedAsset}, new Map<Id, LoanApplicationAsset>{asset.Id => asset});

        // Update the record
        update updatedAsset;

    }

}