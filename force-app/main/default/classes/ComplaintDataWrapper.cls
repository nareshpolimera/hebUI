public class ComplaintDataWrapper {
    public String Language { get; set; }
    public Boolean IsCustomerSatisfied { get; set; }
    public String Source { get; set; }
    public Datetime ReceivedOn { get; set; }
    public String StatementOfFact { get; set; }
    public String ResolutionSought { get; set; }
    public String Category { get; set; }
    public String Subcategory { get; set; }
    public String CategoryDescription { get; set; }
    public String SubcategoryDescription { get; set; }
    public String HandlingLevel { get; set; }
    public String ComplaintLetterType { get; set; }
    public String ComplainantFirstName { get; set; }
    public String ComplainantLastName { get; set; }
    public String CorrespondenceMethod { get; set; }
    public List<Redress> Redresses { get; set; }
    
    public class Redress {
        public String Type { get; set; }
        public String Method { get; set; }
        public Decimal Amount { get; set; }
        public String Rationale { get; set; }
    }
}