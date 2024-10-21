/******************************************************//**
@Class      IndividualDomain
@brief      Handler class for trigger of the Individual object.

@revision   2024-08-12 Adriano Silva
            Added after update and after insert
/******************************************************/
public class IndividualHandler {
 public IndividualHandler(List<Individual> records)
    {
        init(records);
    }
    
    public void beforeUpdate(List<Individual> records, Map<Id, Individual> oldRecords){
        new IndividualDomain().beforeUpdate(records, oldRecords);
    }
    
    public void afterUpdate(List<Individual> records, Map<Id, Individual> oldRecords){
        new IndividualDomain().afterUpdate(records, oldRecords);
    }

    public void afterInsert(List<Individual> records){
        new IndividualDomain().afterInsert(records);
    }
    
    private void init(List<Individual> records){
    }

}