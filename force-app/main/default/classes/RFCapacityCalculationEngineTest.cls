/* **************************************************************************
* Trigger: RFCapacityCalculationEngineTest
* Created by Jordan Ojeda, June 20, 2024
*
* Purpose/Methods: unit tetss class for UserRoleCapacity class
*
* Unit Test: 
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */
@isTest
public with sharing class RFCapacityCalculationEngineTest {
    
 

    private static list<UserRole__c> createUserRoles(integer numberOfUserRoles, User relatedUser, CapacityDefinition__c capacityDefinition)
    {
        list<UserRole__c> userRolesForTesting = (list<UserRole__c> )GeneralTestFactory.createSObjectList(new UserRole__c(), numberOfUserRoles);
        for(UserRole__c userRoleForTesting: userRolesForTesting)
        {
            userRoleForTesting.User__c = relatedUser.id;
            userRoleForTesting.CapacityDefinition__c = capacityDefinition.Id;
            userRoleForTesting.MaxCapacity__c = 10;
        }
        insert userRolesForTesting;
        return userRolesForTesting;
    }

    private static list<CapacityDefinition__c> createCapaicityDefinitions(integer numberOfCapDefs)
    {
        list<CapacityDefinition__c> capacityDefinitions = (list<CapacityDefinition__c>)GeneralTestFactory.createSObjectList(new CapacityDefinition__c(), numberOfCapDefs);
        insert capacityDefinitions;
        return capacityDefinitions;
    }

    private static List<User> createUsers(integer numberOfUsers){
        List<User> users = (List<User>)GeneralTestFactory.createSObjectList(new User(), numberOfUsers);

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
        return users;
    }




    @testSetup
    public static void initializeData() 
    {
        list<User> users = createUsers(1);
        list<CapacityDefinition__c> capacityDefinitions = createCapaicityDefinitions(1);
        list<UserRole__c> roles = createUserRoles(1, users[0], capacityDefinitions[0]);

    }

    private static opportunity createOpportunity(User owner, boolean insertRecord)
    {
        Opportunity opp = (Opportunity)GeneralTestFactory.createSObject(new Opportunity());
        opp.OwnerId = owner.id;
        opp.Type = 'New Customer';

        if(insertRecord)
        {
            insert opp;
        }
        
        return opp;
    }

    private static opportunity createOpportunity(User owner)
    {
        return createOpportunity(owner, true);
    }


    @isTest 
    static void testRoleCapacityCalcuation() {

        List<RFUserRoleCapacity> capacities = new List<RFUserRoleCapacity>();

        CapacityDefinition__c capacityDefinition = [SELECT ID FROM CapacityDefinition__c LIMIT 1];
        capacityDefinition.GroupField__c = 'OwnerId';
        capacityDefinition.CapacityFilter__c = 'Type = \'New Customer\' AND OwnerID IN filter';
        //capacityDefinition.CapacityFilter__c = 'OwnerID IN filter';
        capacityDefinition.APIObjectName__c = 'Opportunity';
        update capacityDefinition;

        User usr = (User)[SELECT ID FROM USER WHERE Username like '%UtestJohn%' LIMIT 1];
        Opportunity opp = createOpportunity(usr);


        Test.startTest();

            list<UserRole__c> roles = [SELECT Id, CapacityDefinition__c,MaxCapacity__c, User__c,Name, Role__c, Available__c, User_name__c FROM UserRole__c LIMIT 1];
            RFCapacityCalculationEngine service = new RFCapacityCalculationEngine();
            capacities =  service.calculateUserRoleCapacity(roles);
           

        Test.stopTest();

        Assert.isTrue(!capacities.isEmpty());
        Assert.areEqual(9,capacities[0].getCapacity());

        
    }

    @isTest 
    static void testFullRoleCapacityCalcuation() {

        List<RFUserRoleCapacity> capacities = new List<RFUserRoleCapacity>();

        CapacityDefinition__c capacityDefinition = [SELECT ID FROM CapacityDefinition__c LIMIT 1];
        capacityDefinition.GroupField__c = 'OwnerId';
        capacityDefinition.CapacityFilter__c = 'Type = \'New Customer\' AND OwnerID IN filter';
        //capacityDefinition.CapacityFilter__c = 'OwnerID IN filter';
        capacityDefinition.APIObjectName__c = 'Opportunity';
        update capacityDefinition;

        User usr = (User)[SELECT ID FROM USER WHERE Username like '%UtestJohn%' LIMIT 1];
        integer index = 0;

        List<Opportunity> opps = new List<Opportunity>();
        for(index=0; index < 9; index++)
        {
            opps.add(createOpportunity(usr, false));
        }
        insert opps;


        Opportunity opp = createOpportunity(usr);


        Test.startTest();

            list<UserRole__c> roles = [SELECT Id, CapacityDefinition__c,MaxCapacity__c, User__c,Name, Role__c, Available__c, User_name__c FROM UserRole__c LIMIT 1];
            RFCapacityCalculationEngine service = new RFCapacityCalculationEngine();
            capacities =  service.calculateUserRoleCapacity(roles);
           

        Test.stopTest();

        Assert.isTrue(!capacities.isEmpty());
        Assert.areEqual(0,capacities[0].getCapacity());

        
    }
}