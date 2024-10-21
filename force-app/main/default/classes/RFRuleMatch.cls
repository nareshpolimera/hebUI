public without sharing class RFRuleMatch {
    public sObject record { get; set; }
    public List<RFRuleMatchEvaluation> listOfAssignmentRules { get; set; }
    private Set<Id> groupIds;

    public RFRuleMatch(){
        listOfAssignmentRules = new List<RFRuleMatchEvaluation>();
        groupIds = new Set<Id>();
    }

    public RFRuleMatch(sObject record){
        listOfAssignmentRules = new List<RFRuleMatchEvaluation>();
        groupIds = new Set<Id>();
        this.record = record;
    }

    public void addRule(Assignment_Rule__c ar, String convertedRuleLogic, boolean resultEvaluation){
        if(ar != null ){
            listOfAssignmentRules.add(new RFRuleMatchEvaluation(ar, convertedRuleLogic, resultEvaluation));
            groupIds.add(ar.Pooling_Group__c);
        }
    }

    public Set<Id> getGroupIds(){
        return groupIds;
    }

    public Boolean hasMatch(){
        return listOfAssignmentRules != null && !listOfAssignmentRules.isEmpty();
    }

    public class RFRuleMatchEvaluation{
        public Id groupId { get; set; }
        public Id ruleId { get; set; }
        public String ruleLogic { get; set; }
        public String convertedRuleLogic { get; set; }
        public boolean ruleLogicResult { get; set; }

        public RFRuleMatchEvaluation(Assignment_Rule__c rule, String convertedRuleLogic, boolean resultEvaluation){
            this.ruleId = rule.Id;
            this.groupId = rule.Pooling_Group__c;
            this.ruleLogic = rule.Rule_Logic__c;
            this.convertedRuleLogic = convertedRuleLogic;
            this.ruleLogicResult = resultEvaluation;
        }

        public String print(){
            String message = 'Rule {0} | Group {1} | Rule Logic {2} | Converted Rule Logic {3} | Logic Result {4}';
            List<Object> args = new List<Object>{ruleId,groupId,ruleLogic,convertedRuleLogic,ruleLogicResult};
            return String.format(message, args);
        }
    }
}