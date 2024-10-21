public class UserDomain {

    private UserService service = new UserService();

    public void afterUpdate(List<User> records, Map<Id, User> oldRecords)
    {
        UserService.updatePersonAccount( records, oldRecords );
    }
}