/******************************************************//**
@Class      LeadHandler
@brief      Handler for trigger for the Lead object.

@revision   2020-10-08 Sneha Namdeo
            Created
@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public with sharing class LeadHandler
{
    public void beforeInsert(List<Lead> records)
    {
        new LeadDomain().beforeInsert(records);
    }
    
    public void beforeUpdate(List<Lead> records, Map<Id, Lead> oldRecords)
    {
        new LeadDomain().beforeUpdate(records, oldRecords);
    }

    public void afterInsert(List<Lead> records)
    {
        new LeadDomain().afterInsert(records);
    }
    
    public void afterUpdate(List<Lead> records, Map<Id, Lead> oldRecords)
    {      
         new LeadDomain().afterUpdate(records, oldRecords);
    }    
       
}