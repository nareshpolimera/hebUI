public class RollUpSummaryUtility {
	
	//the following class will be used to house the field names
    //and desired operations
    public class fieldDefinition {
        public String operation {get;set;}
        public String childField {get;set;}
        public String parentField {get;set;}
        
        public fieldDefinition (String o, String c, String p) {
            operation = o;
            childField = c;
            parentField = p;
        }
    }
    
    public static void rollUpTrigger(list<fieldDefinition> fieldDefinitions,
    list<sObject> records, String childObject, String childParentLookupField, 
    String parentObject, String queryFilter) {
        
        //Limit the size of list by using Sets which do not contain duplicate
        //elements prevents hitting governor limits
        set<Id> parentIds = new set<Id>();
        
        for (sObject s : records) {
            parentIds.add((Id)s.get(childParentLookupField));
        }
        
        //populate query text strings to be used in child aggregrator and 
        //parent value assignment
        String fieldsToAggregate = '';
        String parentFields = '';
        
        for (fieldDefinition d : fieldDefinitions) {
            fieldsToAggregate += d.operation + '(' + d.childField + ') ' + 
            ', ';
            parentFields += d.parentField + ', ';
        }
        
        //Using dynamic SOQL with aggergate results to populate parentValueMap
        String aggregateQuery = 'Select ' + fieldsToAggregate + 
        childParentLookupField + ' from ' + childObject + ' where  ' + 
        childParentLookupField + ' IN :parentIds ' + queryFilter + ' ' +
        ' group by ' + childParentLookupField;
        
        //Map will contain one parent record Id per one aggregate object
        map<Id, AggregateResult> parentValueMap = 
        new map <Id, AggregateResult>();
        
        for (AggregateResult q : Database.query(aggregateQuery)) {
            parentValueMap.put((Id)q.get(childParentLookupField), q);
        }
        
        //list of parent object records to update
        list<sObject> parentsToUpdate = new list<sObject>();
        
        String parentQuery = 'select ' + parentFields + ' Id ' +
         ' from ' + parentObject + ' where Id IN :parentIds';
        
        //for each affected parent object, retrieve aggregate results and 
        //for each field definition add aggregate value to parent field
        for (sObject s : Database.query(parentQuery)) {
            
            Integer row = 0; //row counter reset for every parent record
            for (fieldDefinition d : fieldDefinitions) {
            	String field = 'expr' + row.format();
                AggregateResult r = parentValueMap.get(s.Id);
                //r will be null if no records exist 
                //(e.g. last record deleted)
                if (r != null) {
                    Decimal value = ((Decimal)r.get(field) == null ) ? 0 : 
                        (Decimal)r.get(field);
                    s.put(d.parentField, value);
                } else {
                    s.put(d.parentField, 0);
                }
                row += 1; //plus 1 for every field definition after first
            }
            parentsToUpdate.add(s);
        }
        
        //if parent records exist, perform update of all parent records 
        //with a single DML statement
        if (parentsToUpdate.Size() > 0) {
            update parentsToUpdate;
        }
        
    }

}