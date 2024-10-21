@isTest
public with sharing class OpportunityRoutingServiceTest {

    @testSetup
    public static void initializeData(){

        //create pooling group
        Pooling_Group__c pgorup1 = (Pooling_Group__c)GeneralTestFactory.createSObject(new Pooling_Group__c());
        pgorup1.Name = 'SOC1';

        Pooling_Group__c pgorup2 = (Pooling_Group__c)GeneralTestFactory.createSObject(new Pooling_Group__c());
        pgorup2.Name = 'BU1';

        insert new list<Pooling_Group__c>{pgorup1,pgorup2};

        // Creating assignment rule
        Assignment_Rule__c assignmentRule1 = (Assignment_Rule__c)GeneralTestFactory.createSObject(new Assignment_Rule__c());
        assignmentRule1.Role__c = 'SOC';
        assignmentRule1.Pooling_Group__c = pgorup1.Id;

        Assignment_Rule__c assignmentRule2 = (Assignment_Rule__c)GeneralTestFactory.createSObject(new Assignment_Rule__c());
        assignmentRule2.Role__c = 'BU';
        assignmentRule2.Rule_Logic__c = '1';
        assignmentRule2.Pooling_Group__c = pgorup2.Id;

        insert new list<Assignment_Rule__c>{assignmentRule1,assignmentRule2};

        // Creating assignment rule details
        Assignment_Rule_Detail__c ard1 = (Assignment_Rule_Detail__c)GeneralTestFactory.createSObject(new Assignment_Rule_Detail__c());
        ard1.Assignment_Rule__c = assignmentRule1.Id;
        ard1.Rule_Id__c = '1';
        ard1.Field__c = 'Name';
        ard1.Operator__c = 'contains';
        ard1.Value__c = 'Test SOC';
        
        Assignment_Rule_Detail__c ard2 = (Assignment_Rule_Detail__c)GeneralTestFactory.createSObject(new Assignment_Rule_Detail__c());
        ard2.Assignment_Rule__c = assignmentRule1.Id;
        ard2.Rule_Id__c = '2';
        ard2.Field__c = 'StageName';
        ard2.Operator__c = 'contains';
        ard2.Value__c = 'Closed Won';

        Assignment_Rule_Detail__c ard3 = (Assignment_Rule_Detail__c)GeneralTestFactory.createSObject(new Assignment_Rule_Detail__c());
        ard3.Assignment_Rule__c = assignmentRule2.Id;
        ard3.Rule_Id__c = '1';
        ard3.Field__c = 'Name';
        ard3.Operator__c = 'contains';
        ard3.Value__c = 'Test BU';
        
        insert new List<Assignment_Rule_Detail__c>{ard1, ard2, ard3};

        List<User> users = (List<User>)GeneralTestFactory.createSObjectList(new User(), 4);

        // Query for the System Administrator Profile
        Profile p = [SELECT Id FROM Profile WHERE Name=:'System Administrator' LIMIT 1];

         // Create a new test user with System Administrator profile
        integer userInde = 0;
        for(User user : users){
            user.ProfileId = p.Id;
            user.LanguageLocaleKey = 'en_US';
            user.LocaleSidKey='en_US';
            user.EmailEncodingKey='UTF-8';
            user.Username = 'UtestJohn'+userInde+'@gmail.com';
            user.LastName= 'Utest last';
            user.Email = 'UtestJohn'+userInde+'@gmail.com';
            user.Alias = 'Aleas'+userInde;
            user.TimeZoneSidKey='America/New_York';

            userInde++;
        }
        
        insert users;

        CapacityDefinition__c capacityDefinition = (CapacityDefinition__c)GeneralTestFactory.createSObject(new CapacityDefinition__c(),'GeneralTestFactory.CapacityDefinitionDetailDefaults');
        capacityDefinition.Name = 'SOC';
        insert capacityDefinition;

        list<UserRole__c> userRoles = new list<UserRole__c>();
        Decimal count = 1; 
        for(User relatedUser : users){
            UserRole__c userRoleForTesting = (UserRole__c)GeneralTestFactory.createSObject(new UserRole__c());
            userRoleForTesting.User__c = relatedUser.id;
            userRoleForTesting.CapacityDefinition__c = capacityDefinition.Id;
            userRoleForTesting.MaxCapacity__c = count*10;
            userRoleForTesting.Available__c = true;
            if(count <= 3){
                userRoleForTesting.Role__c = 'SOC';
            }
            else{
                userRoleForTesting.Role__c = 'BU';
            }
            userRoles.add(userRoleForTesting);
            count++;
        }
        insert userRoles;

        list<Pooling_Member__c> userMembers = new list<Pooling_Member__c>();
        for(UserRole__c userRole : userRoles){
            Pooling_Member__c member = (Pooling_Member__c)GeneralTestFactory.createSObject(new Pooling_Member__c());
            member.User_Role__c = userRole.Id;
            if(userRole.MaxCapacity__c <= 30){
                member.Pooling_Group__c = pgorup1.Id;
            }
            else{
                member.Pooling_Group__c = pgorup2.Id;
            }
            userMembers.add(member);
        }
        insert userMembers;
    }

    @isTest 
    static void test_assignSOC() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.Name = 'Test SOC';
        insert opp1;

        test.stopTest();

        List<UserRole__c> userRoles = [SELECT Id, User__c FROM UserRole__c where MaxCapacity__c = 30];

        opp1 = [Select Id,Sales_Ops_Coordinator__c from Opportunity where Id = :opp1.Id];

        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,opp1);
        Assert.areEqual(userRoles[0].User__c,opp1.Sales_Ops_Coordinator__c);

        List<OpportunityShare> oppShares = [SELECT Id,UserOrGroupId from OpportunityShare where OpportunityId = :opp1.Id and RowCause = 'Manual'];
        Assert.isTrue(!oppShares.isEmpty());
        Assert.areEqual(opp1.Sales_Ops_Coordinator__c,oppShares[0].UserOrGroupId);
    }

    @isTest 
    static void test_updateSOC() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.Name = 'Test SOC';
        insert opp1;

        List<UserRole__c> userRoles = [SELECT Id, User__c FROM UserRole__c where MaxCapacity__c = 10];
        opp1.Sales_Ops_Coordinator__c = userRoles[0].User__c;
        update opp1;

        test.stopTest();

        opp1 = [Select Id,Sales_Ops_Coordinator__c from Opportunity where Id = :opp1.Id];

        Assert.areNotEqual(null,opp1);
        Assert.areEqual(userRoles[0].User__c,opp1.Sales_Ops_Coordinator__c);

        List<OpportunityShare> oppShares = [SELECT Id,UserOrGroupId from OpportunityShare where OpportunityId = :opp1.Id and RowCause = 'Manual'];
        Assert.isTrue(!oppShares.isEmpty());
        Assert.areEqual(userRoles[0].User__c,oppShares[0].UserOrGroupId);
    }


    @isTest 
    static void test_assignBU() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.Name = 'Test BU';
        insert opp1;

        test.stopTest();

        List<UserRole__c> userRoles = [SELECT Id, User__c FROM UserRole__c where MaxCapacity__c = 40];
        opp1 = [Select Id,OwnerId from Opportunity where Id = :opp1.Id];

        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,opp1);
    }

    @isTest 
    static void test_assignBU_FileQueue_Unassigned() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.Name = 'Test BU';
        opp1.File_Queue__c = 'Unassigned';
        insert opp1;

        test.stopTest();

        List<UserRole__c> userRoles = [SELECT Id, User__c  FROM UserRole__c where MaxCapacity__c = 40];

        opp1 = [Select Id,OwnerId,File_Queue__c from Opportunity where Id = :opp1.Id];

        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,opp1);
        //Assert.areEqual(userRoles[0].User__c,opp1.OwnerId);
    }

    @isTest 
    static void test_assignBU_FileQueue_InProgress() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.Name = 'Test BU';
        opp1.File_Queue__c = 'Inbound In-Progress';
        insert opp1;

        test.stopTest();

        List<UserRole__c> userRoles = [SELECT Id, User__c FROM UserRole__c where MaxCapacity__c = 40];

        opp1 = [Select Id,OwnerId from Opportunity where Id = :opp1.Id];

        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,opp1);
        Assert.areNotEqual(userRoles[0].User__c,opp1.OwnerId);
    }
}