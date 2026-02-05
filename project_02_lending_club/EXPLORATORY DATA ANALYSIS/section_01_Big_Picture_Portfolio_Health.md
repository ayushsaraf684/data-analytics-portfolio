# Section 1 — Portfolio Health & Baseline Risk Profiling (SQL)

## Objective
Understand overall portfolio quality, risk distribution, and how risk varies across credit grades, income groups, and loan sizes.

### There were some errors that were taken care of during the EDA, mentioned the changes in comment lines too.
### All the queries of this section are here serially, you can run anyone of them to find an output, which can be matched with respective section output given as EXCEL files in this repo
---


``` sql

-- Nan as emp_title and verification_income_joint  where it should be NULL
-- changing that
UPDATE lendings
SET emp_title = NULL
WHERE emp_title= 'Nan';
UPDATE lendings
SET verification_income_joint = NULL
WHERE verification_income_joint = 'Nan';


-- Before we dig deeper — what does our loan book look like?

-- checking loan health, 1% is late 94% current 4.5% is fully paid rest is charged off
-- overall good picture
select loan_status, COUNT(*) AS counts
from lendings
group by loan_status

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BASELINE PORTFOLIO PROFILING

-- A. Portfolio Compostition
-- COUNTS BASED ON LOAN STATUS
select loan_status, COUNT(*) AS counts
from lendings
group by loan_status
-- COUNTS and TOTAL LOAN BASED ON LOAN GRADE
select grade, COUNT(*) AS counts,FORMAT(SUM(loan_amount),'N0') AS total_loan
from lendings
group by grade
order by grade
-- COUNTS and TOTAL LOAN BASED ON RISK INTENSITY SCORE/FLAG
SELECT 
risk_intensity_score,
counts,
total_loan,
CAST(ROUND(counts * 100.0 / SUM(counts) OVER(),2) AS FLOAT) AS count_percent,
CAST(ROUND(total_loan_numeric * 100.0 / SUM(total_loan_numeric) OVER(),2) AS FLOAT) AS loan_amount_percent
FROM (
SELECT 
risk_intensity_score,
COUNT(*) AS counts,
SUM(loan_amount) AS total_loan_numeric,
FORMAT(SUM(loan_amount), 'N0') AS total_loan
FROM lendings
GROUP BY risk_intensity_score
) a
ORDER BY risk_intensity_score;

--risk_score distribution by loan grade
SELECT 
 grade,
SUM(CASE WHEN risk_intensity_score = 0 THEN counts ELSE 0 END) AS [0],
SUM(CASE WHEN risk_intensity_score = 25 THEN counts ELSE 0 END) AS [25],
SUM(CASE WHEN risk_intensity_score = 50 THEN counts ELSE 0 END) AS [50],
SUM(CASE WHEN risk_intensity_score = 75 THEN counts ELSE 0 END) AS [75]
FROM (
SELECT 
risk_intensity_score, 
grade,
COUNT(*) as counts
    FROM lendings
    GROUP BY risk_intensity_score, grade
) AS source_data
GROUP BY grade
ORDER BY grade;

-- avg annual income across loan grades
select grade, FORMAT(cast(ROUND(AVG(annual_income),2) AS float), 'N2' )as avg_annual_income
from lendings   
group by grade
order by grade


-- PROPORTIONS OF LOANS IN WHICH INCOME BANDS
WITH cte AS (
    SELECT *,
        CASE 
WHEN annual_income <= 40000 THEN '<= 40k'
WHEN annual_income < 70000 THEN '40k – 70k'
WHEN annual_income < 100000 THEN '70k – 100k'
            WHEN annual_income < 150000 THEN '100k – 150k'
WHEN annual_income >= 150000 THEN '>= 150k'
        END AS income_bucket
    FROM lendings
)
SELECT 
    income_bucket, 
    COUNT(*) AS counts,
    FORMAT(SUM(loan_amount), 'N0') AS total_loan,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score > 0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS FLOAT) AS total_risky_counts_percent,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score > 0 THEN loan_amount ELSE 0 END)*100.0/SUM(loan_amount),2) AS FLOAT) AS total_risky_loan_percent
FROM cte 
GROUP BY income_bucket;

-- avg risk score by income buckets
WITH cte AS (
    SELECT *,
        CASE 
            WHEN annual_income <= 40000 THEN '<= 40k'
            WHEN annual_income < 70000 THEN '40k – 70k'
            WHEN annual_income < 100000 THEN '70k – 100k'
            WHEN annual_income < 150000 THEN '100k – 150k'
            WHEN annual_income >= 150000 THEN '>= 150k'
        END AS income_bucket
    FROM lendings
)

select income_bucket, CAST(ROUND(AVG(risk_intensity_score),2) as float) as avg_risk_score
from cte
group by income_bucket



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- PROPORTIONS OF LOANS IN WHICH LOAN BANDS
WITH cte AS (
    SELECT *,
        CASE 
            WHEN loan_amount <= 5000 THEN '<= 5k'
WHEN loan_amount < 10000 THEN '5k – 10k'
WHEN loan_amount < 20000 THEN '10k – 20k'
       WHEN loan_amount < 30000 THEN '20k – 30k'
            WHEN loan_amount >= 30000 THEN '>= 30k'
        END AS loan_bucket
    FROM lendings
)
SELECT 
    loan_bucket, 
    COUNT(*) AS counts,
    FORMAT(SUM(loan_amount), 'N0') AS total_loan,
 CAST(ROUND(SUM(CASE WHEN risk_intensity_score > 0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS FLOAT) AS total_risky_counts_percent,
    CAST(ROUND(SUM(CASE WHEN risk_intensity_score > 0 THEN loan_amount ELSE 0 END)*100.0/SUM(loan_amount),2) AS FLOAT) AS total_risky_loan_percent
FROM cte 
GROUP BY loan_bucket;

-- avg risk score by loan buckets
WITH cte AS (
    SELECT *,
        CASE 
            WHEN loan_amount <= 5000 THEN '<= 5k'
            WHEN loan_amount < 10000 THEN '5k – 10k'
            WHEN loan_amount < 20000 THEN '10k – 20k'
            WHEN loan_amount < 30000 THEN '20k – 30k'
            WHEN loan_amount >= 30000 THEN '>= 30k'
        END AS loan_bucket
    FROM lendings
)

select loan_bucket, CAST(ROUND(AVG(risk_intensity_score),2) as float) as avg_risk_score
from cte
group by loan_bucket

