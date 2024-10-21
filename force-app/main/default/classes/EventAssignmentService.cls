public class EventAssignmentService
{
    @auraEnabled(cacheable = true)
    public static List<Specialist__c> getSortedSpecialistList()
    {
        return [
            SELECT Id, User__r.Name, User__c, Assigned_Leads_Count__c
            FROM Specialist__c
            WHERE Unavailable_For_Meetings__c = false and User__c!=null
            ORDER BY Assigned_Leads_Count__c ASC, Total_Lead_Assignment_Count__c ASC
            LIMIT 40
        ];
    }
    

    public static void incrementAssignmentCount(Set<Id> specialistIDs)
    {
        List<Specialist__c> spls = [
            SELECT Id, Assigned_Leads_Count__c, Total_Lead_Assignment_Count__c 
            FROM Specialist__c
            WHERE Id IN :specialistIDs
        ];
        
        for (Specialist__c sp : spls)
        {
            sp.Assigned_Leads_Count__c += 1;
            sp.Total_Lead_Assignment_Count__c += 1;
        }
        
        update spls;
    }


}