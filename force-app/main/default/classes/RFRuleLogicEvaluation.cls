public without sharing class RFRuleLogicEvaluation {
    
    private Logger theLogger;
    private String classContext;

    public RFRuleLogicEvaluation(Logger log){
        this.theLogger = log;
        this.classContext = 'RFRuleLogicEvaluation';
    }

    // Helper method to match the rule based on the operator
    public Boolean evaluateRule(sObject record, Assignment_Rule_Detail__c ruleDetail) {
        Object fieldValue = record.get(ruleDetail.Field__c);
        String operator = ruleDetail.Operator__c;
        String ruleValue = ruleDetail.Value__c;

        //log
        theLogger.debug(' {0} | Rule Id = {1} ', 
            new Object[]{classContext,ruleDetail.Rule_Id__c});

        //log
        theLogger.debug(' {0} | Expression = {1} {2} {3}', 
            new Object[]{classContext,ruleDetail.Field__c,operator,ruleValue});

        if (fieldValue == null) {
            return false;
        }

        String fieldValueString = getFieldValueString(fieldValue);   
        Boolean evalResult = evaluateOperator(fieldValueString, operator.toLowerCase(), ruleValue);

        //log
        theLogger.debug(' {0} | Result = {1}', new Object[]{classContext,evalResult});

        return evalResult;
    }

    // Method to evaluate the operator
    private Boolean evaluateOperator(String fieldValueString, String operator, String ruleValue) {
            switch on operator {
            when 'equals' {
                return fieldValueString == ruleValue;
            }
            when 'not equals to' {
                return fieldValueString != ruleValue;
            }
            when 'contains' {
                return fieldValueString.contains(ruleValue);
            }
            when 'does not contains' {
                return !fieldValueString.contains(ruleValue);
            }
            when 'greater than' {
                return Decimal.valueOf(fieldValueString) > Decimal.valueOf(ruleValue);
            }
            when 'greater or equal' {
                return Decimal.valueOf(fieldValueString) >= Decimal.valueOf(ruleValue);
            }
            when 'less than' {
                return Decimal.valueOf(fieldValueString) < Decimal.valueOf(ruleValue);
            }
            when 'less or equal' {
                return Decimal.valueOf(fieldValueString) <= Decimal.valueOf(ruleValue); 
            }
            when else {
                    return false;
            }
        }
    }

    public Integer evaluateExpression(String expression) {
        Integer result = 0;
        Integer currentNumber = 0;
        String operator = '+';
        Integer i = 0;

        while (i < expression.length()) {
            String currentChar = expression.substring(i, i + 1);
            
            if (isDigit(currentChar)) {
                currentNumber = 0;
                while (i < expression.length() && isDigit(expression.substring(i, i + 1))) {
                    currentNumber = currentNumber * 10 + Integer.valueOf(expression.substring(i, i + 1));
                    i++;
                }
                i--;
                
                result = applyOperation(result, currentNumber, operator);
            } else if (currentChar == '(') {
                Integer j = i;
                Integer parenthesisCount = 0;
                while (i < expression.length()) {
                    if (expression.substring(i, i + 1) == '(') parenthesisCount++;
                    if (expression.substring(i, i + 1) == ')') parenthesisCount--;
                    if (parenthesisCount == 0) break;
                    i++;
                }
                
                currentNumber = evaluateExpression(expression.substring(j + 1, i));
                result = applyOperation(result, currentNumber, operator);
            } else if (isOperator(currentChar)) {
                operator = currentChar;
            }
            i++;
        }
        return result;
    }

    private Boolean isOperator(String c) {
        return c == '+' || c == '-' || c == '*' || c == '/';
    }

    private Boolean isDigit(String c) {
        if (c == null || c.length() != 1) {
            return false;
        }
        String digits = '0123456789';
        return digits.contains(c);
    }    

    private Integer applyOperation(Integer result, Integer currentNumber, String operator) {
         switch on operator {
             when '+'{return result + currentNumber;}
             when '*' {return result * currentNumber;}                            
             when else{return 1;}              
        }
    }

    // Private method to convert field value to string
    private String getFieldValueString(Object fieldValue) {
        return String.valueOf(fieldValue);
    }
}