public with sharing class LoanApplicantHandler {
    
    public LoanApplicantHandler(List<LoanApplicant> records) {
        init(records);
    }

    public void beforeInsert(List<LoanApplicant> records)
    {
        new LoanApplicantDomain().beforeInsert(records);
    }
    
    public void afterInsert(List<LoanApplicant> records, Map<Id, LoanApplicant> newMap)
    {
        new LoanApplicantDomain().afterInsert(records, newMap);
    }

    public void beforeUpdate(List<LoanApplicant> records, Map<Id, LoanApplicant> oldMap )
    {
        new LoanApplicantDomain().beforeUpdate(records, oldMap);
    }
    
    public void afterUpdate(List<LoanApplicant> records, Map<Id, LoanApplicant> oldMap )
    {
        new LoanApplicantDomain().afterUpdate(records, oldMap);
    }

    public void beforeDelete( Map<Id, LoanApplicant> oldMap )
    {
        new LoanApplicantDomain().beforeDelete(oldMap);
    }
    
    public void afterDelete(List<LoanApplicant> records)
    {
        new LoanApplicantDomain().afterDelete(records);
    }

    private void init(List<LoanApplicant> records)
    {
    }
    
}