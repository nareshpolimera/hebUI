public class LoanApplicantDomain {
    private LoanApplicantService service = new LoanApplicantService();

    public void beforeInsert(List<LoanApplicant> records) {
        service.generateAutoName(records);
        service.setOwnerId(records);
        service.setContactId(records, null);
        service.checkUseForQuoteBeforeInsert(records, null);
        service.onePrimaryBorrowerBefore(records, new Map<Id, LoanApplicant>());
    }

    public void afterInsert(List<LoanApplicant> records, Map<Id, LoanApplicant> newMap) {
        service.leadValidation(records);
        service.updateQuote(records, null); 
    }

    public void beforeUpdate(List<LoanApplicant> records, Map<Id, LoanApplicant> oldMap) {
        service.setContactId(records, oldMap);
        service.checkUseForQuoteBeforeUpdate(records, oldMap);
        service.onePrimaryBorrowerBefore(records, oldMap);
    }

    public void afterUpdate(List<LoanApplicant> records, Map<Id, LoanApplicant> oldMap) {
        service.leadValidation(records);
    }

    public void beforeDelete(Map<Id, LoanApplicant> oldMap) {
        service.validatePropertyMemberDeletion(oldMap);
    }

    public void afterDelete(List<LoanApplicant> records) {
        service.leadValidation(records);
    }
}