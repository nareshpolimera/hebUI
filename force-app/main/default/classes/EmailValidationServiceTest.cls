/******************************************************//**
@Test Class      EmailValidationServiceTest
@brief      Class with logic test and code coverage for EmailValidationService.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
@IsTest
private class EmailValidationServiceTest
{
    @IsTest
    static void testEmailValidation()
    {
        ModelEmailValidation.Email p = new ModelEmailValidation.Email();
        List<ModelEmailValidation.Email> pvr = new List<ModelEmailValidation.Email>();
        List<ModelEmailValidation.EmailInfo> linfo = new List<ModelEmailValidation.EmailInfo>(); 
        p.id = '123456';
        p.EmailAddress = 'dummy_email@heb.ca';
        pvr.add(p);

        
        Test.setMock(HttpCalloutMock.class, new EmailValidationRequestMockCallout());
        Test.startTest();
            String res = EmailValidationService.sendRequest(pvr);
            linfo = EmailValidationService.processResponse(res);
        Test.stopTest();
        
        System.assertEquals(linfo[0].status,'Valid','Status should be Valid');
    }
    
}