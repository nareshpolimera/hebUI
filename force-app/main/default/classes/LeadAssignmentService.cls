public class LeadAssignmentService
{
    @auraEnabled(cacheable = true)
    public static List<Specialist__c> getSortedSpecialistList()
    {
        return [
            SELECT Id, User__r.Name, User__c, Assigned_Leads_Count__c
            FROM Specialist__c
            WHERE Unavailable_For_Meetings__c = false
            ORDER BY Assigned_Leads_Count__c ASC, Total_Lead_Assignment_Count__c ASC
            LIMIT 40
        ];
    }
    
    public static void resetLeadAssignmentCount(Set<Id> specialistIDs)
    {
        List<Specialist__c> spls = [
            SELECT Id, Assigned_Leads_Count__c
            FROM Specialist__c
            WHERE Id IN :specialistIDs
        ];
        
        for (Specialist__c s : spls)
        {
            s.Assigned_Leads_Count__c = 0;
        }
        
        update spls;
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

    public static void decrementAssignmentCount(Set<Id> specialistIDs)
    {
        List<Specialist__c> spls = [
            SELECT Id, Assigned_Leads_Count__c, Total_Lead_Assignment_Count__c 
            FROM Specialist__c
            WHERE Id IN :specialistIDs
        ];
        
        for (Specialist__c s : spls)
        {
            s.Assigned_Leads_Count__c        = Math.max(0, s.Assigned_Leads_Count__c - 1);
            s.Total_Lead_Assignment_Count__c = Math.max(0, s.Total_Lead_Assignment_Count__c - 1);

        }        
        update spls;
    }
}