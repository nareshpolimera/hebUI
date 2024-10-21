public with sharing class ProductLWCFieldsetController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldSetFieldsWithValues(String recordId, String objectName, String fieldSetName) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            // Describe the SObject
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType == null) {
                throw new AuraHandledException('Invalid SObject type: ' + objectName);
            }

            // Get Field Set
            Schema.FieldSet fieldSet = objectType.getDescribe().fieldSets.getMap().get(fieldSetName);
            if (fieldSet == null) {
                throw new AuraHandledException('Invalid Field Set name: ' + fieldSetName);
            }

            // Prepare dynamic SOQL query
            String soql = 'SELECT OpportunityId';
            List<String> opportunityFieldPaths = new List<String>();

            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                String fieldPath = field.getFieldPath();

                if (fieldPath.contains('Opportunity.')) {
                    opportunityFieldPaths.add('Opportunity.' + fieldPath.replace('Opportunity.', ''));
                }
            }

            if (!opportunityFieldPaths.isEmpty()) {
                soql += ', ' + String.join(opportunityFieldPaths, ', ');
            }

            soql += ' FROM ' + objectName + ' WHERE Id = :recordId';

            System.debug('SBT SOQL Query: ' + soql);

            // Execute query
            SObject record = Database.query(soql);

            // Prepare response with field metadata and values
            List<Map<String, Object>> fieldsWithValues = new List<Map<String, Object>>();
            
            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                if (field.getFieldPath().contains('Opportunity.')) {
                    boolean readonly=false;
                    Map<String, Object> fieldInfo = new Map<String, Object>();
                    String cleanFieldPath = field.getFieldPath().replace('Opportunity.', '');
                    fieldInfo.put('fieldPath', cleanFieldPath);
                    fieldInfo.put('label', field.getLabel());
                    system.debug('field.getFieldPath().'+field.getFieldPath());
                    if(field.getFieldPath().contains('Opportunity.SyncedQuoteId')) readonly=true;
                    fieldInfo.put('readOnly', readonly);
                    fieldInfo.put('value', record.getSObject('Opportunity').get(cleanFieldPath));
                    
                    // Get field type and add to the response
                    fieldInfo.put('type', field.getType().name());

                    fieldsWithValues.add(fieldInfo);
                }
            }

            System.debug('SBT fieldsWithValues: ' + fieldsWithValues);

            response.put('fields', fieldsWithValues);

            // Add the OpportunityId to the response
            if (record.get('OpportunityId') != null) {
                response.put('OpportunityId', record.get('OpportunityId'));
            }

        } catch (Exception e) {
            System.debug('Error in getFieldSetFieldsWithValues: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        System.debug('SBT response: ' + response);
        return response;
    }
        @AuraEnabled
        public static void saveOpportunityFields(Map<String, Map<String, Object>> fieldsToUpdate, Id opportunityId) {
            try {
                // Retrieve the Opportunity record
                Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                System.debug('SBT opp: ' + opp);
    
                // Update the fields on the Opportunity record
                for (String fieldPath : fieldsToUpdate.keySet()) {
                    System.debug('SBT fieldPath: ' + fieldPath);
                    // Exclude specific fields from being updated
                    if (fieldPath == 'Quote_Amount__c' || fieldPath == 'Quote_LTV__c' || fieldPath == 'Home_Value_for_Quote__c') {
                        continue; // Skip this iteration if the field is one of the excluded fields
                    }
    
                    Map<String, Object> fieldData = fieldsToUpdate.get(fieldPath);
                    String fieldType = (String) fieldData.get('type');
                    Object fieldValue = fieldData.get('value');
    				system.debug('fieldValue '+fieldValue);
                    if(fieldValue!=null){
                        if (fieldType == 'DATE') {
                            opp.put(fieldPath, Date.valueOf(fieldValue instanceof String ? (String) fieldValue : fieldValue.toString()));
                        } else if (fieldType == 'DATETIME') {
                            opp.put(fieldPath, DateTime.valueOf(fieldValue instanceof String ? (String) fieldValue : fieldValue.toString()));
                        } else if (fieldType == 'DOUBLE' || fieldType == 'CURRENCY' || fieldType == 'PERCENT') {
                            opp.put(fieldPath, Decimal.valueOf(fieldValue instanceof String ? (String) fieldValue : fieldValue.toString()));
                        } else {
                            // Direct assignment if no conversion is needed
                            opp.put(fieldPath, fieldValue);
                        }
                    }
                }
    
                // Perform the update
                System.debug('SBT before update: ' + opp);
                update opp;
                System.debug('SBT after update: ' + opp);
    
            } catch (Exception e) {
                System.debug('Error in saveOpportunityFields: ' + e.getMessage());
                throw new AuraHandledException('Error saving Opportunity fields: ' + e.getMessage());
            }
        }  
}