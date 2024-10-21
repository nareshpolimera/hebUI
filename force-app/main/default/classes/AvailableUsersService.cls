public with sharing class AvailableUsersService
{
    
    @AuraEnabled(cacheable=true)
    public static String getUsernameById(String userId)
    {
        List<User> userList = [
            SELECT FirstName, LastName
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        
        String userString = userList[0].FirstName + ' ' + userList[0].LastName;
        return userString;
    }
}