# Section 4 — Credit Usage Patterns & Borrowing Behaviour Risk

## Objective
To analyze how credit usage patterns (such as card usage intensity, revolving depth, and borrowing frequency) influence borrower risk, and to identify behavioural signals that indicate financial stress beyond traditional income or demographic factors.

**Note:**  
You can run these queries in MS SQL SERVER and see the output, which matches with the respective section EXCEL file which are uploaded in this repo.

``` sql


--Revolving Depth
--open_credit_lines just shows access. A rich person with 20 unused credit cards is safe (they have high capacity).
--num_cc_carrying_balance shows behavior. A person with balances on 10 cards is "juggling" payments. They are borrowing from RAM to pay SHYAM.
with cte as(
SELECT *,
    CASE 
        WHEN num_cc_carrying_balance = 0 THEN '0. Transactor (Pays in Full)'
        WHEN num_cc_carrying_balance = 1 THEN '1. Focused (1 Card)'
        WHEN num_cc_carrying_balance BETWEEN 2 AND 3 THEN '2. Normal (2-3 Cards)'
        WHEN num_cc_carrying_balance BETWEEN 4 AND 6 THEN '3. Juggler (4-6 Cards)'
        WHEN num_cc_carrying_balance BETWEEN 7 AND 9 THEN '4. Submerged (7-9 Cards)'
        WHEN num_cc_carrying_balance >= 10 THEN '5. Extreme (10+ Cards)' 
    END AS revolving_depth
    from lendings)
select
revolving_depth,
ROUND(CAST(AVG(CASE WHEN application_type = 'Joint' THEN annual_income ELSE annual_income_joint end) AS FLOAT),2) as avg_income,
COUNT(loan_amount) AS total_loans,
ROUND(AVG(cr_util_ratio), 2) AS avg_utilization, 
ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
CAST(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS FLOAT) AS [% High Risk Loan Amount]
FROM cte
GROUP BY revolving_depth
ORDER BY revolving_depth;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Credit Binge
with cte as(
SELECT *,
    CASE 
        WHEN accounts_opened_24m = 0 THEN '0. Dormant (No New Accts)'
        WHEN accounts_opened_24m BETWEEN 1 AND 2 THEN '1. Conservative (1-2)'
        WHEN accounts_opened_24m BETWEEN 3 AND 5 THEN '2. Active (3-5)'
        WHEN accounts_opened_24m BETWEEN 6 AND 9 THEN '3. Aggressive (6-9)'
        WHEN accounts_opened_24m >= 10 THEN '4. Binge Borrower (10+)'
    END AS borrowing_counts
    FROM lendings)
    select
    borrowing_counts,
    COUNT(loan_amount) AS total_loans,
    ROUND(AVG(effective_dti), 2) AS avg_dti,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_risk_score,
    cast(ROUND(SUM(CASE WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) as float) AS [% High Risk Loan Amounts]
FROM cte
GROUP BY borrowing_counts
ORDER BY borrowing_counts;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DOES EXPERIENCE MATTERS? DO PEOPLE WHO HAD A LONG CREDIT HISTORY PERFORM BETTER?
with cte as(
select *,
case
-- calculating age relative to a fixed date (e.g., 2026), in dataset the current date is not give so assumed date is 2026
        WHEN (2026 - earliest_credit_line) BETWEEN 11 AND 15 THEN '1. Established (11-15 Years)'
        WHEN (2026 - earliest_credit_line) BETWEEN 16 AND 20 THEN '2. Seasoned (16-20 Years)'
        WHEN (2026 - earliest_credit_line) BETWEEN 21 AND 30 THEN '3. Deep History (21-30 Years)'
        WHEN (2026 - earliest_credit_line) >= 31 THEN '4. Lifetime (30+ Years)'
        ELSE 'Unknown'
    end as credit_history_bucket
from lendings)
select 
credit_history_bucket,
count(loan_amount) as total_loans ,
round(avg(case when application_type = 'Joint' THEN annual_income_joint else annual_income end),0)as avg_income,
round(avg(cast(risk_intensity_score as float ) ),2 ) as avg_risk_score,
round(cast(sum(case when risk_intensity_score >=50 then loan_amount else 0 end)*100.0 / nullif(sum(loan_amount),0) as float),2) as [% high risk loans]
from cte
group by credit_history_bucket
order by  credit_history_bucket;


