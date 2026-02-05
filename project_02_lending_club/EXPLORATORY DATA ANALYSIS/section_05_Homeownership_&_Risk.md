# Section 5 — Stability Indicators: Homeownership, Verification & Job Tenure

## Objective
To evaluate how real-world stability indicators such as homeownership status, income verification quality, and job tenure interact with borrower risk, and to understand whether these factors can strengthen or weaken traditional credit risk assessment.

**Note:**  
You can run these queries in MS SQL SERVER and see the output, which matches with the respective section EXCEL file which are uploaded in this repo.

``` sql

-- Stability & Demographic Resilience
SELECT 
homeownership, 
COUNT(loan_amount) AS total_loans,
ROUND(AVG(case when application_type = 'Joint' THEN annual_income_joint else annual_income end), 0) AS avg_income,
ROUND(AVG(effective_dti), 2) AS avg_dti, -- Renters usually have lower DTI (no mortgage), but are they safer?
ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
cast(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) as float) AS [% High Risk Loans]
FROM lendings
GROUP BY homeownership
ORDER BY avg_risk_score DESC;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- HOMEOWNERSHIP AND VERIFIED INCOME RELATIONSHIP BASED ON MORTGAGES
with cte as(
select
verified_income,
homeownership,
case when num_mort_accounts >=1 then 'has mortgage' else 'no mortgage' end as mort_flag,
round(sum(case when risk_intensity_score >=50 then loan_amount else 0 end)*100.0 / sum(loan_amount),2) as percent_high_risk_amount
from lendings
group by verified_income,
homeownership,
case when num_mort_accounts >=1 then 'has mortgage' else 'no mortgage' end)
SELECT
    homeownership,
    CAST(MAX(CASE WHEN verified_income = 'Not Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Not_Verified,
    CAST(MAX(CASE WHEN verified_income = 'Source Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Source_Verified,
    CAST(MAX(CASE WHEN verified_income = 'Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Verified
FROM cte
WHERE mort_flag = 'has mortgage'
GROUP BY homeownership;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

with cte as(
select
verified_income,
homeownership,
case when num_mort_accounts >=1 then 'has mortgage' else 'no mortgage' end as mort_flag,
round(sum(case when risk_intensity_score >=50 then loan_amount else 0 end)*100.0 / sum(loan_amount),2) as percent_high_risk_amount
from lendings
group by verified_income,
homeownership,
case when num_mort_accounts >=1 then 'has mortgage' else 'no mortgage' end)
SELECT
    homeownership,
    CAST(MAX(CASE WHEN verified_income = 'Not Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Not_Verified,
    CAST(MAX(CASE WHEN verified_income = 'Source Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Source_Verified,
    CAST(MAX(CASE WHEN verified_income = 'Verified' THEN percent_high_risk_amount END) AS FLOAT) AS Verified
FROM cte
WHERE mort_flag = 'no mortgage'
GROUP BY homeownership;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- JOB STABILITY AND ASSET STABILITY
with cte as(
SELECT *,
    CASE 
        WHEN emp_length <= 1 THEN '1. New Job (0-1 yr)'
        WHEN emp_length <= 4 THEN '2. Junior (2-4 yrs)'
        WHEN emp_length <=9 THEN '3. Mid-Career (5-9 yrs)'
        WHEN emp_length >= 10 THEN '4. Veteran (10+ yrs)'
        ELSE 'Unknown'
    END AS job_tenure
   from lendings),
  cte2 as(
select 
    job_tenure, 
    homeownership,
    ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS percent_high_risk_amount
FROM cte
GROUP BY homeownership,job_tenure)
select job_tenure,
    CAST(MAX(CASE WHEN homeownership = 'Rent' THEN percent_high_risk_amount END) AS FLOAT) AS RENT,
    CAST(MAX(CASE WHEN homeownership= 'Mortgage' THEN percent_high_risk_amount END) AS FLOAT) AS MORTGAGE,
    CAST(MAX(CASE WHEN homeownership = 'Own' THEN percent_high_risk_amount END) AS FLOAT) AS OWN
from cte2
group by job_tenure


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
