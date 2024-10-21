@IsTest
private class CustomMetadataLWCServicesTest {
    
    @IsTest
    static void testGetCustomMetadata() {
        
        String metadataName = 'Area_Codes_List__mdt'; 
        String[] fields = new String[]{'Id'};
            String filters = 'Id != NULL';
        
        Test.startTest();
        List<sObject> results = CustomMetadataLWCServices.getCustomMetadata(metadataName, fields, filters);
        System.assertNotEquals(results, null);
        System.assertEquals(results.size()>0, true);
        Test.stopTest();   
    }
}