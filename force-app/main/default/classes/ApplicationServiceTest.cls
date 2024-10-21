/******************************************************/ /**
@Class      ApplicationServiceTest
@brief      Unit Test for ApplicationTrigger.

@revision   2024-07-03 Juan Contreras 
Task 6389.
/******************************************************/
@IsTest
public with sharing class ApplicationServiceTest {
    @TestSetup
    static void makeData() {
        Account account = new Account(FirstName = 'Test', LastName = 'Test');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'Test',
            AccountId = account.Id,
            StageName = OpportunityService.DEFAULT_OPP_STAGE,
            CloseDate = System.today()
        );
        insert opportunity;
    }
}