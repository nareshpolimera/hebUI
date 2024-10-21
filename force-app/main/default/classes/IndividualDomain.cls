/******************************************************//**
@Class      IndividualDomain
@brief      Domain class for trigger of the Individual object.

@revision   2024-07-22 Suvarna H
            Porting from legacy SF org.
@revision 2024-08-12 Adriano Silva
			Including aftereUpdate and afterInsert
			Added call to Mars Platform Event
/******************************************************/
public class IndividualDomain {
    private IndividualService service = new IndividualService();
    public void beforeUpdate(List<Individual> records, Map<Id, Individual> oldMap)				
    { 
        
    } 
     public void afterUpdate(List<Individual> records, Map<Id, Individual> oldMap){  
    }    
    
    public void afterInsert(List<Individual> records){ 
    } 
}