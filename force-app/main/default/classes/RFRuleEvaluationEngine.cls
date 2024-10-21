public without sharing class RFRuleEvaluationEngine {
    
    private Logger theLogger;
    private string classContext;

    public RFRuleEvaluationEngine(){
        this.theLogger = new Logger('Routing Framework');
        this.classContext = 'RFRuleEvaluationEngine';
    }

    public RFRuleEvaluationEngine(Logger log){
        this.theLogger = log;
        this.classContext = 'RFRuleEvaluationEngine';
    }

    // Method to filter sObjects based on custom rules
    public List<RFRuleMatch> evaluateRules(List<sObject> records) {
        return evaluateRules(records,null);
    }

    // Method to filter sObjects based on custom rules
    public List<RFRuleMatch> evaluateRules(List<sObject> records, String role) {
        List<RFRuleMatch> listOfRuleEvaluations = new List<RFRuleMatch>(); 
        Map<Id, String> logicRuleMap = new Map<Id, String>();

        if (records.isEmpty()) {
            //log
            theLogger.debug(' {0} | No records to calculate', new Object[]{classContext});
            return listOfRuleEvaluations;
        }

        //log
        theLogger.info(' {0} | START ', new Object[]{classContext});
        
        String objectName = records[0].getSObjectType().getDescribe().getName();
        theLogger.debug(' {0} | Evaluate rules for {1}', new Object[]{classContext,objectName});

        // Query the assignment rules for the object
        List<Assignment_Rule__c> listOfAssignmentRules;
        if(String.isBlank(role)){
            listOfAssignmentRules = [SELECT Id, 
                                        Rule_Logic__c, 
                                        Active__c,
                                        Pooling_Group__c
                                        FROM Assignment_Rule__c
                                        WHERE Active__c = true AND 
                                        Object__c = :objectName
                                        ORDER BY Order_of_Priority__c ASC];
        }
        else{
            listOfAssignmentRules = [SELECT Id, 
                                        Rule_Logic__c, 
                                        Active__c,
                                        Pooling_Group__c
                                        FROM Assignment_Rule__c
                                        WHERE Active__c = true AND 
                                        Object__c = :objectName AND 
                                        Role__c =: role
                                        ORDER BY Order_of_Priority__c ASC];
        }

        System.debug('[RFRuleEvaluationEngine] - listOfAssignmentRules: '+listOfAssignmentRules);
        
        if (listOfAssignmentRules.isEmpty()) {
            //log
            theLogger.debug(' {0} | No assignment rules found', new Object[]{classContext});
            return listOfRuleEvaluations; // No rules defined for this object
        } 

        Set<Id> setOfAssignmentRules = new Set<Id>();
        for (Assignment_Rule__c assignmentRule : listOfAssignmentRules) {
            setOfAssignmentRules.add(assignmentRule.Id);
        }

        // Query the assignment rule details for the rule
        List<Assignment_Rule_Detail__c> ruleDetails = [SELECT Id, Field__c, Value__c, Operator__c, Rule_Id__c,
                                                        Assignment_Rule__r.Id, Assignment_Rule__r.Rule_Logic__c
                                                       FROM Assignment_Rule_Detail__c
                                                       WHERE Assignment_Rule__c IN :setOfAssignmentRules];

        System.debug('[RFRuleEvaluationEngine] - ruleDetails: '+ruleDetails);
        RFRuleLogicEvaluation ruleEval = new RFRuleLogicEvaluation(this.theLogger);
        
        if (ruleDetails.isEmpty()) {
            //log
            theLogger.debug(' {0} | No assignment rule details found', new Object[]{classContext});
            return listOfRuleEvaluations; // No rule details found
        }

        for (sObject record : records) {
            RFRuleMatch re = new RFRuleMatch(record);

            for (Assignment_Rule_Detail__c ruleDetail : ruleDetails) {
                Integer matchResult = ruleEval.evaluateRule(record, ruleDetail) ? 1 : 0;
                
                if (!logicRuleMap.containsKey(ruleDetail.Assignment_Rule__r.Id)) {
                    logicRuleMap.put(ruleDetail.Assignment_Rule__r.Id, ruleDetail.Assignment_Rule__r.Rule_Logic__c);
                }

                String convertedRuleLogic = logicRuleMap.get(ruleDetail.Assignment_Rule__r.Id);
                convertedRuleLogic = convertedRuleLogic.replace(String.valueOf(ruleDetail.Rule_Id__c), String.valueOf(matchResult));
                convertedRuleLogic = convertedRuleLogic.replace(' AND ', '*').replace(' OR ', '+');       
                logicRuleMap.put(ruleDetail.Assignment_Rule__r.Id, convertedRuleLogic); 
                System.debug('[RFRuleEvaluationEngine] - convertedRuleLogic: '+convertedRuleLogic);         
            }

            for (Assignment_Rule__c assignmentRule : listOfAssignmentRules) {
                //log
                theLogger.debug(' {0} | START | Evaluation of Assignment rule: {1} ', 
                                new Object[]{classContext,assignmentRule.Id});
                //log
                theLogger.debug(' {0} | Expression = {1}', 
                    new Object[]{classContext,assignmentRule.Rule_Logic__c});
                //log
                theLogger.debug(' {0} | Expression converted = {1}', 
                    new Object[]{classContext,logicRuleMap.get(assignmentRule.Id)});

                boolean isRuleMatch = evaluateBooleanExpression(logicRuleMap.get(assignmentRule.Id));
                System.debug('[RFRuleEvaluationEngine] - isRuleMatch: '+isRuleMatch);      

                //log
                theLogger.debug(' {0} | Evaluation = {1}', 
                                new Object[]{classContext,isRuleMatch});

                if (isRuleMatch) {
                    re.addRule(assignmentRule,logicRuleMap.get(assignmentRule.Id),isRuleMatch);
                }
                theLogger.debug(' {0} | END | Assignment rule: {1}', 
                                new Object[]{classContext,assignmentRule.Id});
            }
            
            listOfRuleEvaluations.add(re);
        }

        //log
        theLogger.info(' {0} | END ', new Object[]{classContext});
        
        return listOfRuleEvaluations;
    }

    // Helper method to evaluate a boolean expression given as a string
    private Boolean evaluateBooleanExpression(String expression) {
        RFRuleLogicEvaluation ruleEval = new RFRuleLogicEvaluation(this.theLogger);
        return ruleEval.evaluateExpression(expression) != 0;
    }
}