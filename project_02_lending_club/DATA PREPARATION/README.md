# Data Preparation using PYTHON PANDAS

### Overview
This notebook focuses on preparing the raw Lending Club loan dataset for analysis. The goal was to clean the data, validate financial logic, create behaviour-based risk indicators, and build a simple combined risk score for portfolio-level analysis in SQL.

---

### Data Loading and Cleaning
- Loaded dataset using pandas  
- Standardized state names to uppercase  
- Checked column types and missing values  

---

### Date Formatting
- Converted issue month into proper date format  

---

### Data Validation Checks
Performed logical financial checks:
- Total paid vs principal + interest + fees  
- Paid principal vs loan amount  
- Remaining balance validation  

---

## Creation of New Columns for ease in Analysis

#### Credit Utilization Ratio
Measures percentage of total credit limit currently being used.

#### Effective Debt-to-Income (DTI)
- Used standard DTI for individual applications  
- Used joint DTI for joint applications 

---

### Creating Important flags, as these may prove to be important indicators of financial stress, repayment burden and default risk. These are Binary Indicators

#### - High Debt Burden Flag
Triggered when DTI ≥ 40%.


#### - Recent Delinquency Flag
Triggered if missed payments occurred in the last 2 years.

#### - Severe Credit Event Flag
Includes:
- Bankruptcy  
- Collections  
- Tax liens  

#### - High Credit Stress Flag
Triggered when:
- Credit utilization > 75% OR  
- Maximum credit cards carrying balance  

### - Risk Intensity Score
- Combined all risk flags into a single score (0–100 scale).   
- Provides a simple way to segment borrowers based on overall risk behaviour.

---

### Data Export to SQL Server
- Established SQL connection  
- Uploaded cleaned and enriched dataset to SQL table  

---

### Outcome
This notebook created a clean, validated, and enriched dataset with behaviour-based risk signals, which was later used for portfolio risk analysis and strategy insights.
