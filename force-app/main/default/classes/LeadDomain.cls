/******************************************************//**
@Class      LeadDomain
@brief      Domain for trigger for the Lead object.

@revision   2024-04-20 Diego Guerrero
            Porting from legacy SF org.
/******************************************************/
public class LeadDomain {
    private LeadService service = new LeadService();
  
    public void beforeInsert(List<Lead> records) {
    } 
  
    public void beforeUpdate(List<Lead> records, Map<Id, Lead> oldRecords) {
    }
  
    public void afterInsert(List<Lead> records) {    
    }
    public void afterUpdate(List<Lead> records, Map<Id, Lead> oldRecords) {
          service.addLeadMarsPlatformEvent(records,oldRecords);
      }
  
    public class ReferralDomain {
      private LeadService service = new LeadService();
  
      public void beforeInsert(List<Lead> records) {
      }
  
      public void afterInsert(List<Lead> records) {
      }
  
      public void beforeUpdate(List<Lead> records, Map<Id, Lead> oldRecords) {
      }
  
      public void afterUpdate(List<Lead> records, Map<Id, Lead> oldRecords) { 
      }
    }
  }