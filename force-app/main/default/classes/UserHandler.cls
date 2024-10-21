public with sharing class UserHandler
{

    public UserHandler(List<User> records)
    {
        init(records);
    }
    
    public void afterUpdate(List<User> records, Map<Id, User> oldRecords)
    {
        System.debug('in habdle after update');
        new UserDomain().afterUpdate(records, oldRecords);
    }
    
    private void init(List<User> records)
    {
    }
    
       
}