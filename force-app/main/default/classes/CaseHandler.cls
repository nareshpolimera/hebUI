/******************************************************//**
@trigger    Case
@brief      Handler for trigger for the Case object.

@revision   2022-02-16 Richard W.
            Created
/******************************************************/
public with sharing class CaseHandler
{

    public static final String COMPLAINT = 'Complaint';
    

    public CaseHandler(List<Case> records)
    {
        init(records);
    }

    public void beforeInsert(List<Case> records)
    {
        new CaseDomain().beforeInsert(records);
        
    }
    
    
    public void beforeUpdate(List<Case> records, Map<Id, Case> oldRecords)
    {
        new CaseDomain().beforeUpdate(records, oldRecords);
        
        
    }
    public void beforeUpdateWithMap(Map<Id, Case>records, Map<Id, Case> oldRecords)
    {
    new CaseDomain().beforeUpdateWithMap(records, oldRecords);
    }
    public void afterInsert(List<Case> records)
    {
        new CaseDomain().afterInsert(records);

    }
    
    public void afterUpdate(List<Case> records, Map<Id, Case> oldRecords)
    {
        new CaseDomain().afterUpdate(records, oldRecords);
        
    }
    
    private void init(List<Case> records)
    {
        
    }

}