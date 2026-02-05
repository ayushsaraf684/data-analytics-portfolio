# Section 2 — Credit Behavior, Utilization, Delinquency , Risk Analysis

## Objective
To understand how borrower credit behaviour — such as credit utilization, debt pressure, delinquency history, and credit stress indicators — impacts loan risk, and to identify early warning signals that appear before actual defaults occur.

### You can run this queries in MS SQL SERVER and see the output, which matches with the respective section EXCEL file which are uploaded in this repo

```sql
-- utilization vs risk
with cte as(
select *,
	case
            WHEN cr_util_ratio IS NULL THEN 'Unknown'
            WHEN cr_util_ratio <= 30 THEN 'Healthy'
            WHEN cr_util_ratio < 50 THEN 'Moderate'
            when cr_util_ratio < 75 THEN 'Elevated'
            ELSE 'Stress'
	end as cru_buckets
from lendings) 

select  cru_buckets,
    count(loan_amount) AS total_loans, 
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    cast(ROUND(SUM(CASE when risk_intensity_score = 0 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH NO RISK],
    cast(ROUND(SUM(CASE when risk_intensity_score = 25 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH MODERATE RISK],
    cast(ROUND(SUM(CASE when risk_intensity_score >= 50 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH HIGH RISK]
from cte
group by cru_buckets
order BY 
    case 
        when cru_buckets = 'Unknown' THEN 0
        when cru_buckets = 'Healthy' THEN 1
        when cru_buckets = 'Moderate' THEN 2
        when cru_buckets = 'Elevated' THEN 3
        when cru_buckets = 'Stress' THEN 4
    end;


--High Debt Burden (effective dti > 40%)
with cte as(
select *,
	case
          when debt_to_income >= 25 THEN 'Debt Burden' ELSE 'No Debt Burden'
	end as debt_burden_buckets
from lendings) 

select  debt_burden_buckets,
    count(loan_amount) AS total_loans, 
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    CAST(round(sum(CASE when risk_intensity_score >= 50 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% High Risk Loan Amount(Score >= 50)]
from cte
group by debt_burden_buckets

--Since 0 borrowers crossed the 40% DTI threshold, a 30% cutoff was used to better reflect meaningful variation in debt burden within the dataset.”
--Debt burden (DTI) did not meaningfully separate risk levels in this dataset and was therefore not used as a primary risk driver.

--HIGH CREDIT STRESS 
with cte as(
select *,
	case
          when high_credit_stress_flag = 1 THEN 'CREDIT STRESS' ELSE 'NO CREDIT STRESS'
	end as credit_burden_buckets
from lendings) 

select  credit_burden_buckets,
    count(loan_amount) AS total_loans, 
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    CAST(round(sum(CASE when risk_intensity_score >= 50 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% High Risk (Score >= 50)]
from cte
group by credit_burden_buckets


--Check whether high utilization becomes worse when overall debt burden is also high.

with cte as(
select *,
	case
            when cr_util_ratio <= 50 and debt_to_income < 25 THEN 'Low Util – Low Debt'
            when cr_util_ratio <= 50 and debt_to_income >= 25 THEN 'Low Util – HIgh Debt'
            when cr_util_ratio > 75 and debt_to_income < 25 THEN 'High Util – Low Debt'
            when cr_util_ratio > 75 and debt_to_income >= 25 THEN 'High Util – High Debt'            
	end as util_debt_buckets
from lendings) 

select  
    util_debt_buckets,
    count(loan_amount) AS total_loans,
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    cast(ROUND(SUM(CASE when risk_intensity_score = 0 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH NO RISK],
    cast(ROUND(SUM(CASE when risk_intensity_score = 25 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH MODERATE RISK],
    cast(ROUND(SUM(CASE when risk_intensity_score >= 50 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% LOAN AMT WITH HIGH RISK]from cte
where util_debt_buckets IS NOT NULL
-- For the interaction analysis, only extreme utilization segments were considered to clearly observe how high/LOW utilization and
-- THERE ARE NULL VALUES FOR CR UTIL RATION BETWEEN 50 AND 75, THAT'S WHY FILTERED
-- Borrowers in the middle utilization range were excluded to avoid diluting the contrast.
group by util_debt_buckets
order BY 
    case 
        when util_debt_buckets = 'Low Util – Low Debt' THEN 0
        when util_debt_buckets = 'Low Util – HIgh Debt' THEN 1
        when util_debt_buckets = 'High Util – Low Debt' THEN 2
        when util_debt_buckets = 'High Util – High Debt' THEN 3
    end;



-- BROKEN BORROWERS, WHO HAD PUBLIC RECORD ISSUES
with cte as(
SELECT *,
CASE 
    when severe_credit_event_flag = 1 THEN 'SEVERE EVENT (Bankruptcy/Liens/Coll)' 
  ELSE 'CLEAN PUBLIC RECORD' 
    END AS derog_buckets
    from lendings) 
    select 
    derog_buckets,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    CAST(ROUND(SUM(CASE when risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS FLOAT) AS [% High Risk (Score >= 50)]
FROM cte
GROUP BY derog_buckets
ORDER BY avg_risk_score DESC;

---------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

-- how recent delinquency shows risk
with cte as(
SELECT *,
    CASE 
        when months_since_last_delinq IS NULL THEN 'Never Delinquent'
        when months_since_last_delinq <= 12 THEN 'Recent (0-12 Months)'
        when months_since_last_delinq <= 24 THEN 'Mid-Term (13-24 Months)'
        ELSE 'Old History (25+ Months)'
    END AS delinquency_recency
    from lendings)
select 
    delinquency_recency,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(effective_dti), 2) AS avg_dti,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    cast(ROUND(SUM(CASE when risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) as float) AS [% High Risk (Score >= 50)]
FROM cte
GROUP BY delinquency_recency
ORDER by
    case 
    when delinquency_recency = 'Never Delinquent' THEN 1
    when delinquency_recency = 'Recent (0-12 Months)' THEN 2
    when delinquency_recency = 'Mid-Term (13-24 Months)'  THEN 3
    when delinquency_recency = 'Old History (25+ Months)' THEN 4
    END

--Are they Delinquent AND Stressed
WITH CTE AS(
SELECT *,
    CASE 
        when recent_delinquency_flag = 0 AND high_credit_stress_flag = 0 THEN '1. Stable (Clean & Low Util)'
        when recent_delinquency_flag = 0 AND high_credit_stress_flag = 1 THEN '2. Stressed but Paying (High Util)'
        WHEN recent_delinquency_flag = 1 AND high_credit_stress_flag = 0 THEN '3. Disorganized (Delinquent but Low Util)'
        WHEN recent_delinquency_flag = 1 AND high_credit_stress_flag = 1 THEN '4. CRISIS (Delinquent + Maxed Out)'
    END AS borrower_condition
    from lendings)

select borrower_condition,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(effective_dti), 2) AS avg_dti,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS FLOAT) AS [% High Risk (Score >= 50)]
FROM cte
GROUP BY borrower_condition
ORDER BY borrower_condition;

--HOW DELINQUENCY AND DEROGATORY EVENTS SHOW RISK TOGETHER
WITH CTE AS(
SELECT *,
    CASE 
        when recent_delinquency_flag = 0 AND severe_credit_event_flag = 0 THEN '1. Clean History'
        when recent_delinquency_flag = 0 AND severe_credit_event_flag= 1 THEN '2. Recent Delinquency Only'
        WHEN recent_delinquency_flag = 1 AND severe_credit_event_flag = 0 THEN '3. Derogatory Event Only'
        WHEN recent_delinquency_flag = 1 AND severe_credit_event_flag = 1 THEN '4. Recent Delinquency + Derogatory Event'
    END AS credit_event_segment
    from lendings)

select credit_event_segment,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(effective_dti), 2) AS avg_dti,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS FLOAT) AS [% High Risk (Score >= 50)]
FROM cte
GROUP BY credit_event_segment
ORDER BY credit_event_segment;


--Credit Hunger (Recent Inquiries)
WITH CTE AS(
SELECT *,
    CASE 
        WHEN inquiries_last_12m = 0 THEN '0. Passive (0)'
        WHEN inquiries_last_12m BETWEEN 1 AND 3 THEN '1. Normal (1-3)'
        WHEN inquiries_last_12m BETWEEN 4 AND 6 THEN '2. Active (4-6)'
        WHEN inquiries_last_12m BETWEEN 7 AND 9 THEN '3. Desperate (7-9)'
        WHEN inquiries_last_12m >= 10 THEN '4. Extreme (10+)' 
    END AS credit_hunger_buckets_12m
    from lendings)

select credit_hunger_buckets_12m,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(effective_dti), 2) AS avg_dti,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS FLOAT) AS [% High Risk (Score >= 50)]
FROM cte
GROUP BY credit_hunger_buckets_12m
ORDER BY credit_hunger_buckets_12m;

