# Section 3 — Grade, Income & Risk Concentration Analysis

## Objective
To analyze how credit grades and income levels interact to shape portfolio risk, identify high-risk borrower pockets, and evaluate whether current risk-based pricing properly compensates for the level of risk across different borrower segments.

### You can run these queries in MS SQL SERVER and see the output, which matches with the respective section EXCEL file which are uploaded in this repo

``` sql

-- Risk Concentration by Loan Grade
-- Which loan grades hold most of the risky money?

select grade,
    count(loan_amount) AS total_loans, 
    FORMAT(SUM(LOan_amount),'N0') as total_loan_amount,
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    cast(ROUND(SUM(case when risk_intensity_score = 0 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% No Risk Loans],
    cast(ROUND(SUM(case when risk_intensity_score = 25 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% Moderate Risk Loans],
    CAST(round(sum(case when risk_intensity_score in (50,75) then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% High-Risk Loans]
    from lendings
    group by grade
    order by grade

---------------------------------------------------------------------------------------------------------------------------------

-- RISK CONCENTRATION BY INCOME BUCKETS
WITH cte AS (
    SELECT *,
        case 
            WHEN annual_income <= 40000 THEN '1. <= 40k'
            WHEN annual_income < 70000 THEN '2. 40k – 70k'
            WHEN annual_income < 100000 THEN '3. 70k – 100k'
            WHEN annual_income < 150000 THEN '4. 100k – 150k'
            WHEN annual_income >= 150000 THEN '5. >= 150k'
        END AS income_bucket
    FROM lendings
)
SELECT 
    income_bucket, 
   count(loan_amount) AS total_loans, 
    FORMAT(SUM(LOan_amount),'N0') as total_loan_amount,
    cast(round(AVG(risk_intensity_score),2) as float) AS avg_risk_score,
    cast(ROUND(SUM(case when risk_intensity_score = 0 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% No Risk Loans],
    cast(ROUND(SUM(case when risk_intensity_score = 25 then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% Moderate Risk Loans],
    CAST(round(sum(case when risk_intensity_score in (50,75) then loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount), 2) AS FLOAT) AS [% High-Risk Loans]
from cte
GROUP BY income_bucket
order by income_bucket;

---------------------------------------------------------------------------------------------------------------------------------
-- INCOME BUCKETS AND GRADE HEATMAP SHOWING LOAN AMOUNT CONCENTRATION
-- For SUM of loan amounts

WITH cte AS (
    SELECT *,
        case 
            WHEN annual_income <= 40000 THEN '1. <= 40k'
            WHEN annual_income < 70000 THEN '2. 40k – 70k'
            WHEN annual_income < 100000 THEN '3. 70k – 100k'
            WHEN annual_income < 150000 THEN '4. 100k – 150k'
            WHEN annual_income >= 150000 THEN '5. >= 150k'
        END AS income_bucket
    FROM lendings
)
SELECT 
    income_bucket,
    FORMAT(SUM(case WHEN grade = 'A' THEN loan_amount ELSE 0 END), 'N0') as Grade_A,
    FORMAT(SUM(case WHEN grade = 'B' THEN loan_amount ELSE 0 END), 'N0') as Grade_B,
    FORMAT(SUM(case WHEN grade = 'C' THEN loan_amount ELSE 0 END), 'N0') as Grade_C,
    FORMAT(SUM(case WHEN grade = 'D' THEN loan_amount ELSE 0 END), 'N0') as Grade_D,
    FORMAT(SUM(case WHEN grade = 'E' THEN loan_amount ELSE 0 END), 'N0') as Grade_E,
    FORMAT(SUM(case WHEN grade = 'F' THEN loan_amount ELSE 0 END), 'N0') as Grade_F,
    FORMAT(SUM(case WHEN grade = 'G' THEN loan_amount ELSE 0 END), 'N0') as Grade_G
from cte
group BY income_bucket
order BY income_bucket;

-- for percentage of loans 

WITH cte AS (
    SELECT *,
        case 
            WHEN annual_income <= 40000 THEN '1. <= 40k'
            WHEN annual_income < 70000 THEN '2. 40k – 70k'
            WHEN annual_income < 100000 THEN '3. 70k – 100k'
            WHEN annual_income < 150000 THEN '4. 100k – 150k'
            WHEN annual_income >= 150000 THEN '5. >= 150k'
        END AS income_bucket
    FROM lendings
)
SELECT 
   income_bucket,
ROUND(CAST(SUM(case WHEN grade = 'A' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_A,
ROUND(CAST(SUM(case WHEN grade = 'B' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_B,
ROUND(CAST(SUM(case WHEN grade = 'C' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_C,
ROUND(CAST(SUM(case WHEN grade = 'D' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_D,
ROUND(CAST(SUM(case WHEN grade = 'E' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_E,
ROUND(CAST(SUM(case WHEN grade = 'F' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_F,
ROUND(CAST(SUM(case WHEN grade = 'G' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount) AS FLOAT), 2) as Grade_G
from cte
group BY income_bucket
order BY income_bucket;






---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TOXICITY HEATMAP

  with cte as(
    SELECT *,
        case 
            WHEN annual_income <= 40000 THEN '1. <= 40k'
            WHEN annual_income < 70000 THEN '2. 40k – 70k'
            WHEN annual_income < 100000 THEN '3. 70k – 100k'
            WHEN annual_income < 150000 THEN '4. 100k – 150k'
            WHEN annual_income >= 150000 THEN '5. >= 150k'
        END AS income_bucket
    FROM lendings
),
cte2 AS (
    SELECT
        income_bucket,
        grade,
        ROUND(SUM(case WHEN risk_intensity_score >= 50 THEN loan_amount ELSE 0 END) * 100.0 / NULLIF(SUM(loan_amount), 0), 2) AS pct_toxic_money
    FROM cte
    GROUP BY income_bucket, grade
)
SELECT
    income_bucket,
    CAST(MAX(case WHEN grade = 'A' THEN pct_toxic_money END) AS FLOAT) AS Grade_A,
    CAST(MAX(case WHEN grade = 'B' THEN pct_toxic_money END) AS FLOAT) AS Grade_B,
    CAST(MAX(case WHEN grade = 'C' THEN pct_toxic_money END) AS FLOAT) AS Grade_C,
    CAST(MAX(case WHEN grade = 'D' THEN pct_toxic_money END) AS FLOAT) AS Grade_D,
    CAST(MAX(case WHEN grade = 'E' THEN pct_toxic_money END) AS FLOAT) AS Grade_E,
    CAST(MAX(case WHEN grade = 'F' THEN pct_toxic_money END) AS FLOAT) AS Grade_F,
    CAST(MAX(case WHEN grade = 'G' THEN pct_toxic_money END) AS FLOAT) AS Grade_G
FROM cte2
GROUP BY income_bucket
ORDER BY income_bucket;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Are we charging enough interest to cover the risk we are taking?
SELECT 
    grade,
    ROUND(AVG(interest_rate), 2) AS avg_interest_rate,
    ROUND(AVG(CAST(risk_intensity_score AS FLOAT)), 2) AS avg_actual_risk,
    
    -- The "Efficiency" Ratio: How much Interest do we get per unit of Risk?
    -- Lower number = BAD (We are taking risk for free)
    ROUND(AVG(interest_rate) / NULLIF(AVG(CAST(risk_intensity_score AS FLOAT)), 0), 2) AS return_on_risk_ratio
FROM lendings
GROUP BY grade
ORDER BY grade;




