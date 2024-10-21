public without sharing class TDSRCalculationService {
    public static Boolean runTDSROnce = false;

    @AuraEnabled
    @future(callout=true)
    public static void runTDSRCalculation(String oppId, string appId) {
        TDSRrequest tdsrRequest = new TDSRrequest(oppId, appId);
        if (tdsrRequest != null) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                IntegrationService.getEndpoint(
                    IntegrationService.MARS_API.TDSR_Calculation
                )
            );
            req.setMethod(IntegrationService.METHOD_POST);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader(
                'Authorization',
                'Bearer ' + TokenService.getToken(TokenService.Target.MARS)
            );
            req.setBody(JSON.serialize(tdsrRequest));
            String sMsg = req.getBody();
            for (Integer i = 0; i < sMsg.length(); i = i + 299) {
            Integer iEffectiveEnd = (i + 299 > (sMsg.length())
                ? sMsg.length()
                : i + 299);
            System.debug(sMsg.substring(i, iEffectiveEnd));
            }

            req.setTimeout(IntegrationService.TIMEOUT_MAX);
            try {
                Http http = new Http();
                HTTPResponse res = http.send(req);
                if (res.getStatusCode() == IntegrationService.HTTP_OK) {
                    String responseStr = res.getBody();
                    System.debug(responseStr);
                    TDSRResult response = (TDSRResult) JSON.deserialize(
                        responseStr,
                        TDSRResult.class
                    );
                    ResidentialLoanApplication appToUpdate = new ResidentialLoanApplication(
                        Id = appId
                    );
                    appToUpdate.TDSR_percent_value__c = response.TDSRValue == null ? null : response.TDSRValue * 100;
                    update appToUpdate;
                } else {
                    System.debug(res);
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
                System.debug(e.getLineNumber());
                System.debug(e.getStackTraceString());
            }
        }
    }

    public class TDSRrequest {
        public Decimal PropertyTaxAmount;
        public String PropertyTaxFrequency;
        public Decimal InsuranceAmount;
        public String InsuranceFrequency;
        public Decimal CondoFeesAmount;
        public String CondoFeesFrequency;
        public Decimal GrossIncomeAmount;
        public String GrossIncomeFrequency;
        public List<Debt> Debts = new List<Debt>();

        public TDSRrequest(Id oppId, Id appId) {
            Opportunity ld = Utils.retrieveOpportunityForProperty(oppId);
            ResidentialLoanApplication app = Utils.retrieveActiveApplicationForProperty(
                appId
            );
            LoanApplicationProperty property = app.LoanApplicationProperties.size() >
                0
                ? app.LoanApplicationProperties[0]
                : new LoanApplicationProperty();
            this.PropertyTaxAmount = Utils.getNumeric(
                property.Annual_Property_Taxes__c
            );
            this.PropertyTaxFrequency = 'Annually';
            this.InsuranceAmount = Utils.getNumeric(
                property.Fire_Insurance_Premium__c
            );
            this.InsuranceFrequency = 'Annually';
            this.CondoFeesAmount = Utils.getNumeric(
                property.Monthly_Condo_Fees__c
            );
            this.CondoFeesFrequency = 'Monthly';

            Decimal grossIncome = 0.0;
            for (LoanApplicant applicant : app.LoanApplicants) {
                grossIncome += Utils.getNumeric(applicant.Total_Pension_Income__c);
                grossIncome += Utils.getNumeric(applicant.Total_Investment_Income__c);
                grossIncome += Utils.getNumeric(applicant.Total_Rental_Income__c);
                grossIncome += Utils.getNumeric(applicant.Total_Support_Income__c);
            }

            this.GrossIncomeAmount = grossIncome;
            this.GrossIncomeFrequency = 'Monthly';

            for (
                LoanApplicationLiability debt : app.LoanApplicationLiabilities
            ) {
                if (debt.Include_Debt__c == true) {
                    Debt newDebt = new Debt();
                    newDebt.Type = Utils.getString(debt.Type__c);
                    newDebt.IsSecured = debt.Secured__c;
                    newDebt.Amount = Utils.getNumeric(debt.CreditLimitAmount);
                    newDebt.Balance = Utils.getNumeric(debt.Balance_Amount__c);
                    newDebt.FinancialInstitutionCode = Utils.getString(
                        debt.Financial_Institution_Code__c
                    );
                    newDebt.FinancialInstitutionName = Utils.getString(
                        debt.CreditorName
                    );
                    newDebt.AccountNumber = Utils.getString(debt.AccountNumber);
                    newDebt.Source = Utils.getString(debt.Source__c);
                    newDebt.CreditLimit = Utils.getNumeric(
                        debt.CreditLimitAmount
                    );
                    newDebt.Frequency = Utils.getString(
                        debt.Payment_Frequency__c
                    );
                    newDebt.PaymentAmount = Utils.getNumeric(
                        debt.MonthlyPaymentAmount
                    );
                    newDebt.IsPayoutRequired = (debt.Payout_Recommendation__c ==
                    'Required');
                    this.Debts.add(newDebt);
                }
            }
        }
    }

    public class Debt {
        public String Type;
        public Boolean IsSecured;
        public Decimal Amount;
        public Decimal Balance;
        public String FinancialInstitutionCode;
        public String FinancialInstitutionName;
        public String AccountNumber;
        public String Source;
        public Decimal CreditLimit;
        public String Frequency;
        public Decimal PaymentAmount;
        public Boolean IsPayoutRequired;
    }

    public class TDSRResult {
        public Decimal TDSRValue;
        public Boolean IsSucessful;
        public String Error;
    }
}