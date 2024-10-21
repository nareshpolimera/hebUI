@isTest
public with sharing class RFRoutingServiceTest {
    @testSetup
    public static void initializeData(){

        //create pooling group
        Pooling_Group__c pgorup1 = (Pooling_Group__c)GeneralTestFactory.createSObject(new Pooling_Group__c());
        pgorup1.Name = 'SOC1';

        Pooling_Group__c pgorup2 = (Pooling_Group__c)GeneralTestFactory.createSObject(new Pooling_Group__c());
        pgorup2.Name = 'SOC2';
        pgorup2.Active__c = false;

        insert new list<Pooling_Group__c>{pgorup1,pgorup2};

        // Creating assignment rule
        Assignment_Rule__c assignmentRule1 = (Assignment_Rule__c)GeneralTestFactory.createSObject(new Assignment_Rule__c());
        assignmentRule1.Role__c = 'SOC';
        assignmentRule1.Pooling_Group__c = pgorup1.Id;

        Assignment_Rule__c assignmentRule2 = (Assignment_Rule__c)GeneralTestFactory.createSObject(new Assignment_Rule__c());
        assignmentRule2.Role__c = 'SOC';
        assignmentRule2.Rule_Logic__c = '1';
        assignmentRule2.Pooling_Group__c = pgorup2.Id;

        insert new list<Assignment_Rule__c>{assignmentRule1,assignmentRule2};

        // Creating assignment rule details
        Assignment_Rule_Detail__c ard1 = (Assignment_Rule_Detail__c)GeneralTestFactory.createSObject(new Assignment_Rule_Detail__c());
        ard1.Assignment_Rule__c = assignmentRule1.Id;
        ard1.Rule_Id__c = '1';
        ard1.Field__c = 'Name';
        ard1.Operator__c = 'contains';
        ard1.Value__c = 'Test';
        
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
        ard3.Value__c = 'Test2';
        
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
            userRoleForTesting.Role__c = 'SOC';
            userRoleForTesting.Available__c = true;
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
    static void test_getWinnignUser_byCapacity() {

        test.startTest();
		
        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        Opportunity opp2 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        
        RFRoutingService rfService =  new RFRoutingService();
        List<RFRoutingUser> result = rfService.getWinningUser(new list<Opportunity>{opp1,opp2},'SOC');
		
        test.stopTest();

        List<UserRole__c> userRoles = [SELECT Id, User__c, MaxCapacity__c, Role__c, Available__c, User_name__c FROM UserRole__c where MaxCapacity__c = 30];

        RFRoutingUser testUser = new RFRoutingUser(opp1.Id, new RFUserRoleCapacity(userRoles[0], 1));
        
        Assert.isTrue(!result.isEmpty());
        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,result[0].record);
        Assert.areNotEqual(null,result[0].userRole);
        Assert.areEqual(userRoles[0].User__c,result[0].userRole.userId);
        Assert.areEqual(2,result[0].userRole.occupation);
        
    }

    @isTest 
    static void test_getCandidates_byCapacity() {

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        
        RFRoutingService rfService =  new RFRoutingService();
        List<RFUserRoleCapacity> result = rfService.getCandicateUsers(opp1,'SOC');

        test.stopTest();

        Assert.isTrue(!result.isEmpty());
        Assert.areEqual(3,result.size());

        List<UserRole__c> userRoles = [SELECT Id, User__c, MaxCapacity__c FROM UserRole__c];
        Assert.isTrue(!userRoles.isEmpty());

        for(RFUserRoleCapacity capacity : result){
            for(UserRole__c uRole : userRoles){
                if(capacity.userId == uRole.User__c){
                    Assert.areEqual(uRole.MaxCapacity__c,capacity.maxCapacity);
                    Assert.areEqual(0,capacity.occupation);
                    Assert.areEqual(uRole.MaxCapacity__c,capacity.getCapacity());
                }
            }
        }
        
    }

    @isTest 
    static void test_getWinnignUser_NoUserAvailable() {

        //disable all user roles
        List<UserRole__c> userRoles = [SELECT Id, User__c, MaxCapacity__c FROM UserRole__c];
        Assert.isTrue(!userRoles.isEmpty());

        for(UserRole__c uRole : userRoles){
            uRole.Available__c = false;
        }

        update userRoles;

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        
        RFRoutingService rfService =  new RFRoutingService();
        List<RFRoutingUser> result = rfService.getWinningUser(new list<Opportunity>{opp1},'SOC');

        test.stopTest();

        Assert.areEqual(null,result);
    }

    @isTest 
    static void test_getWinnignUser_MultipleAssignmentRules() {
        //disable some user roles
        List<UserRole__c> userRoles = [SELECT Id, User__c, MaxCapacity__c FROM UserRole__c where MaxCapacity__c <= 30];
        Assert.isTrue(!userRoles.isEmpty());

        for(UserRole__c uRole : userRoles){
            uRole.Available__c = false;
        }
        update userRoles;

        //enable pooling group
        List<Pooling_Group__c> pgroups = [SELECT Id,Active__c FROM Pooling_Group__c WHERE Name = 'SOC2'];
        Assert.isTrue(!pgroups.isEmpty());
        pgroups[0].Active__c = true;

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp1.name = 'Test2';
        
        RFRoutingService rfService =  new RFRoutingService();
        List<RFRoutingUser> result = rfService.getWinningUser(new list<Opportunity>{opp1},'SOC');

        test.stopTest();

        userRoles = [SELECT Id, User__c FROM UserRole__c where MaxCapacity__c = 40];

        Assert.isTrue(!result.isEmpty());
        Assert.isTrue(!userRoles.isEmpty());
        Assert.areNotEqual(null,result[0].record);
        Assert.areNotEqual(null,result[0].userRole);
        Assert.areEqual(userRoles[0].User__c,result[0].userRole.userId);
        Assert.areEqual(1,result[0].userRole.occupation);
    }

    @isTest 
    static void test_getCandidates_NoCapacity() {

        List<UserRole__c> userRoles = [SELECT Id, User__c, MaxCapacity__c FROM UserRole__c];
        Assert.isTrue(!userRoles.isEmpty());

        for(UserRole__c uRole : userRoles){
            uRole.MaxCapacity__c = 0;
        }
        update userRoles;

        test.startTest();

        Opportunity opp1 = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        
        RFRoutingService rfService =  new RFRoutingService();
        List<RFRoutingUser> result = rfService.getWinningUser(new list<Opportunity>{opp1},'SOC');

        test.stopTest();

        Assert.areEqual(null,result);
        
    }
}