@isTest
public class RFUserSelectionEngineTest {

    @testSetup
    static void initializeTestData() {
        // No database setup needed for wrapper classes
    }

    @isTest
    static void testSelectWinningUserWithValidData() {
        // Test data setup
        List<RFUserRoleCapacity> userRoleCapacities = new List<RFUserRoleCapacity>();
        
        List<UserRole__c> userRoles = new List<UserRole__c>();
        UserRole__c userRole1 = new UserRole__c();
        userRole1.User__c = '0051I0000000abcQAA';
        userRole1.Role__c = 'Manager';
        userRole1.MaxCapacity__c = 10;
        userRoles.add(userRole1);

        UserRole__c userRole2 = new UserRole__c();
        userRole2.User__c = '0051I0000000defQAA';
        userRole2.Role__c = 'Manager';
        userRole2.MaxCapacity__c = 25;
        userRoles.add(userRole2);

        RFUserRoleCapacity userRoleCapacity1 = new RFUserRoleCapacity(userRole1,5);
        userRoleCapacities.add(userRoleCapacity1);

        RFUserRoleCapacity userRoleCapacity2 = new RFUserRoleCapacity(userRole2,10);
        userRoleCapacities.add(userRoleCapacity2);

        List<RFUserRoleCandidates> userRoleOptions = new List<RFUserRoleCandidates>();
        Account acc = new Account(Id='0011I000001gXYZQAO');
        RFUserRoleCandidates userRoleOption = new RFUserRoleCandidates(acc);
        userRoleOption.addCandicates(userRoles);
        userRoleOptions.add(userRoleOption);

        // Execute the method
        RFUserSelectionEngine engine = new RFUserSelectionEngine();
        List<RFRoutingUser> result = engine.selectWinningUser(userRoleOptions, userRoleCapacities);

        // Assert the results
        System.assertEquals(1, result.size());
        System.assertEquals('0011I000001gXYZQAO', result[0].recordId);
        System.assertEquals('0051I0000000defQAA', result[0].userRole.userId);
        System.assertEquals('Manager', result[0].userRole.role);
        System.assertEquals(11, result[0].userRole.occupation); // 10 + 1 after selection
    }

    @isTest
    static void testSelectWinningUserWithNoUserRoleOptions() {
        // Test data setup
        List<RFUserRoleCandidates> userRoleOptions = new List<RFUserRoleCandidates>();
        List<RFUserRoleCapacity> userRoleCapacities = new List<RFUserRoleCapacity>();

        // Execute the method
        RFUserSelectionEngine engine = new RFUserSelectionEngine();
        List<RFRoutingUser> result = engine.selectWinningUser(userRoleOptions, userRoleCapacities);

        // Assert the results
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testSelectWinningUserWithNoMatchingCapacities() {
        // Test data setup
        List<RFUserRoleCapacity> userRoleCapacities = new List<RFUserRoleCapacity>();

        List<UserRole__c> userRoles = new List<UserRole__c>();
        UserRole__c userRole1 = new UserRole__c();
        userRole1.User__c = '0051I0000000xyzQAA';
        userRole1.Role__c = 'Employee';
        userRole1.MaxCapacity__c = 10;
        userRoles.add(userRole1);

        RFUserRoleCapacity userRoleCapacity1 = new RFUserRoleCapacity(userRole1,5);
        userRoleCapacity1.role = 'SOC';
        userRoleCapacities.add(userRoleCapacity1);

        List<RFUserRoleCandidates> userRoleOptions = new List<RFUserRoleCandidates>();
        RFUserRoleCandidates userRoleOption = new RFUserRoleCandidates(new Account(Id='0011I000001gXYZQAO'));
        userRoleOption.addCandicates(userRoles);
        userRoleOptions.add(userRoleOption);

        // Execute the method
        RFUserSelectionEngine engine = new RFUserSelectionEngine();
        List<RFRoutingUser> result = engine.selectWinningUser(userRoleOptions, userRoleCapacities);

        // Assert the results
        System.assertEquals(0, result.size());
    }
}