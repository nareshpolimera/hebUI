/* **************************************************************************
* Class: GeneralTestFactory
* Created by: Third party code (for more information visit this link: https://github.com/dhoechst/Salesforce-Test-Factory) modified by Nubik
*
* Purpose/Methods: class to centrilize data creation for unit tests
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
************************************************************************** */

@isTest
public class GeneralTestFactory {

    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = 'GeneralTestFactory.' + objectName.replaceAll('__c|__', '') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        if (Type.forName(defaultClassName) != null) {
            sObj = createSObject(sObj, defaultClassName);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            Throw new GeneralTestFactoryException('Invalid defaults class.');
        }
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String)null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};
        SObject newObj;

        // Get one copy of the object
        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        // Get the name field for the object
        String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            if(clonedSObj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isCreateable())
            {
                clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
            }
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static void addFieldDefaults(SObject sObj, Map<String, Object> defaults) {
        // Loop through the map of fields and if they are null on the object, fill them.
        for (String field : defaults.keySet()) {
            if (sObj.get(field) == null) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // When we create a list of SObjects, we need to
    private static Map<String, String> nameFieldMap = new Map<String, String> {
        'Contact' => 'LastName',
        'Case' => 'Subject'
    };

    public class GeneralTestFactoryException extends Exception {}

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<String, Object> getFieldDefaults();
    }

    // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
    // For custom objects, omit the __c from the Object Name

    public class AccountDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => 'Test Account'
            };
        }
    }

    public class ContactDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'FirstName' => 'First',
                'LastName' => 'Last',
                'Email' => 'test@gmail.com'
            };
        }
    }

    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => 'Test Opportunity',
                'StageName' => 'Closed Won',
                'CloseDate' => System.today()
            };
        }
    }

    public class Assignment_RuleDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Object__c' => 'Opportunity',
                'Role__c' => 'SOC',
                'Rule_Logic__c' => '(1 AND 2)',
                'Active__c' => true
            };
        }
    }

    public class Assignment_Rule_DetailDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Rule_Id__c' => '1',
                'Field__c' => 'Name',
                'Operator__c' => 'contains',
                'Value__c' => 'Test'
            };
        }
    }

    public class CapacityDefinitionDetailDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'GroupField__c' => 'OwnerId',
                'APIObjectName__c' => 'Opportunity',
                'CapacityFilter__c' => 'OwnerID IN filter'
            };
        }
    }

    public class Pooling_GroupDetailDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'User_Selection_Type__c' => 'Capacity',
                'Active__c' => true,
                'Name' => 'TestSOC'
            };
        }
    }
}