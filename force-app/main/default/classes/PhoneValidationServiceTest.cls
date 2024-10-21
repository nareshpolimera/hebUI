/******************************************************//**
@Test Class      PhoneValidationServiceTest
@brief      Class with logic test and code coverage for PhoneValidationService.

@revision   2024-04-20 Diego Guerrero
Porting from legacy SF org.
/******************************************************/
@IsTest
private class PhoneValidationServiceTest
{
    @testSetup
    static void setupTestData()
    {
        //TestFactory.initTestData();
    }
    
    @IsTest
    static void testPhoneValidation()
    {
        ModelPhoneValidation.Phone p = new ModelPhoneValidation.Phone();
        List<ModelPhoneValidation.Phone> pvr = new List<ModelPhoneValidation.Phone>();
        List<ModelPhoneValidation.PhoneInfo> linfo = new List<ModelPhoneValidation.PhoneInfo>(); 
        p.id = '123456';
        p.PhoneNumber = '4162229999';
        pvr.add(p);
        
        
        Test.setMock(HttpCalloutMock.class, new PhoneValidationRequestMockCallout());
        Test.startTest();
        String res = PhonevalidationService.sendRequest(pvr);
        linfo = PhonevalidationService.processResponse(res);
        TokenService.TokenResponse t = new TokenService.TokenResponse(); 
        Test.stopTest();
        
        System.assertEquals(linfo[0].status,'Valid','Status should be Valid');
    }
    
}