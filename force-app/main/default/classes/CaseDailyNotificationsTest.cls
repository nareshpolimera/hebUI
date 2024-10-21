@isTest
public class CaseDailyNotificationsTest {
  @isTest
  public static void activateNotificationsOnCaseTest() {
    Test.startTest();
    CaseDailyNotifications.activateNotificationsOnCase();
    Test.stopTest();
  }

  @testSetup
  public static void createRecords() {
    Case taskCase = createCase(-7);
    insert taskCase;

    Case case13 = createCase(-13);
    insert case13;

    Case case30 = createCase(-30);
    insert case30;

    Case case38 = createCase(-38);
    insert case38;

    Case case50 = createCase(-50);
    insert case50;

    Case case54 = createCase(-54);
    insert case54;
  }

  public static Case createCase(Integer days) {
    Case c = new Case();
    c.Subject = 'Case Test';
    c.Status = 'Ongoing';
    c.Origin = 'Email';
    c.Detail_of_Complaint__c = 'Test';
    c.Complaint_Date_Received__c = System.today().addDays(days);
    c.Complaint_Category__c = 'Interest Rate';
    c.Complainant_Type__c = 'Personal (made directly by complainant)';
    c.Complaint_Subcategory__c = 'Interest rate change letter';
    c.OwnerId = UserInfo.getUserId();
    return c;
  }
}