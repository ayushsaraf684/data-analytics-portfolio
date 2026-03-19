# SQL Analytics Project – Global Retail Sales

## Overview

This repository contains a SQL-focused analytics project built to improve my skills as a data analyst.  
The project is based on a global retail sales dataset and focuses on writing real-world SQL queries that handle messy data, complex joins, time-based logic, and customer behavior analysis.

The emphasis of this project is **SQL-first thinking** rather than dashboards or visualization tools.

---

## Tools & Environment

- **SQL Server (T-SQL)**
- **Python (Pandas)** – used initially for light data preparation
- **Jupyter Notebook** – for basic cleaning and data export
- **GitHub (Private Repository)**

---
## Project Structure
```
project_01_global_electronics/
│
├── 01_data_understanding_and_quality.sql
├── 02_fact_sales_enrichment.sql
├── 03_customer_lifecycle_and_retention.sql
├── 04_miscellaneous_questions.sql
│
├── DATA CLEANING.ipynb
│
├── Datasets/
│   ├── Customers.csv
│   ├── Data_Dictionary.csv
│   ├── Exchange_Rates.csv
│   ├── Products.csv
│   ├── Sales.csv
│   └── Stores.csv
│
└── README.md
```

## Initial Data Preparation (Python)

Before starting SQL analysis, a small amount of preprocessing was done using Pandas:

- Renamed some columns for consistency
- Fixed incorrect data types (e.g. numeric values stored as strings)
- Created a database connection string
- Exported cleaned tables directly into MS SQL Server

No heavy data transformation was done in Python — the main logic is handled in SQL.

---

Each SQL file represents a different stage of analysis.

---

## 01. Data Understanding & Quality

This file focuses on understanding the dataset and handling data quality issues.

Key work in this file includes:
- Counting orders, customers, and stores
- Identifying missing `order_date` and `delivery_date`
- Creating flags to control time-based analysis
- Validating joins and detecting data inconsistencies
- Basic exploration of exchange rate data

This step helped ensure that later analysis was based on **controlled and valid data**, without deleting important records.

---

## 02. Fact Sales Enrichment

This file creates the core analytical layer used throughout the project.

### Key Questions Covered

1. Total quantity sold by each product category  
2. Total quantity of orders processed by each store country  
3. Revenue, cost, and profit calculation at product level  
4. Revenue and profit analysis by product category  
5. Identifying high-revenue but low-margin products  
6. Store performance analysis (revenue, profit, revenue per square meter)  
7. Monthly revenue trends (year & month)  
8. Top 3 products per category by revenue (ties handled)  
9. Cumulative revenue over time by store  
10. Best-performing store(s) by profit for each year  

### Important Notes
- Rows with missing price or cost were **not deleted**
- Such rows were excluded only from revenue/profit calculations
- This avoids undercounting real sales activity

---

## 03. Customer Lifecycle & Retention

This file focuses on customer behavior and repeat purchases.

### Key Questions Covered

1. Age-based revenue distribution (only where age is known)  
2. Identification of repeat customers with:
   - total orders  
   - first order date  
   - last order date  
3. Customer repeat purchase & retention summary, including:
   - order frequency  
   - time gaps between purchases  
   - revenue contribution  

Customers with missing order dates were excluded only from time-based logic, not from revenue analysis.

---

## 04. Miscellaneous Analysis

This file contains additional analytical questions that did not fit cleanly into one category.

### Key Questions Covered

1. Identification of stores with zero sales  
2. Cross-border purchases (customer country ≠ store country)  
3. Average delivery time by store (valid dates only)  
4. Cumulative delivery time distribution (e.g. % delivered within X days)  

These queries focus on operational and geographical insights.

---

## SQL Concepts & Techniques Used (Selected)

Some of the important SQL concepts applied in this project:

- Aggregations (`SUM`, `COUNT`, `AVG`)
- Window functions (`DENSE_RANK`, `LAG`, cumulative `SUM`)
- Date calculations (`DATEDIFF`, `YEAR`)
- CASE-based segmentation
- Handling NULL values safely
- Multi-table joins
- Customer-level and store-level analysis
- Filtering invalid data without deleting records

The goal was correctness and clarity rather than short queries.

---

## Screenshots & Outputs

Screenshots of selected query outputs are stored separately.
Here I thought of adding some screenshots of the outputs of questions I tried to solve
Note that the outputs may not be the full outputs, as these are just screenshots of first few rows

- Top 3 products by revenue within each product category
  
 <img width="824" height="417" alt="image" src="https://github.com/user-attachments/assets/863d5b0f-2a29-461e-bcff-5a0f3a80834f" />

- Monthly revenue trend based on order date
  
   <img width="472" height="413" alt="image" src="https://github.com/user-attachments/assets/886512d1-7623-4a07-950c-1745b4c9bc49" />

- Stores with zero recorded sales
  
  <img width="324" height="317" alt="image" src="https://github.com/user-attachments/assets/4200ccf3-cf90-4af0-9815-57db48e0163c" />
  
- Cumulative delivery time distribution (orders delivered within X days)
  
  <img width="566" height="506" alt="image" src="https://github.com/user-attachments/assets/e5190345-c422-4d27-b30a-faebc4827299" />
  
- Store performance based on revenue, profit, and size
  
  <img width="756" height="398" alt="image" src="https://github.com/user-attachments/assets/4022482e-c94b-4285-a1e5-f1eb3eb46716" />

- High-revenue but low-margin products
  
  <img width="940" height="342" alt="image" src="https://github.com/user-attachments/assets/cc5d8644-163b-4055-9db9-e9ce16011a6e" />
  
- Cumulative revenue growth over time for each store
  
  <img width="867" height="409" alt="image" src="https://github.com/user-attachments/assets/fec49759-29cf-41a1-9862-3202e38bc74c" />

- Best-performing store(s) by profit for each year
  
  <img width="940" height="191" alt="image" src="https://github.com/user-attachments/assets/0c6c7fb2-284e-489d-8958-9c1999656a0e" />

  <img width="940" height="208" alt="image" src="https://github.com/user-attachments/assets/ae3a3259-e70f-46a3-93b8-831250ad2923" />

- Revenue distribution by customer age group
  
  <img width="641" height="219" alt="image" src="https://github.com/user-attachments/assets/e834cf6a-770e-462d-9abd-e18de547489f" />

- Repeat customers with first and last order details
  
- <img width="689" height="312" alt="image" src="https://github.com/user-attachments/assets/747b9037-2701-4ae0-bac3-82317d8ee42e" />

- Customer retention summary based on order frequency and time gaps
  
<img width="940" height="340" alt="image" src="https://github.com/user-attachments/assets/09e56bba-45f4-4410-975e-81534a8760de" />


 


  

(Images intentionally kept outside SQL files for clarity.)

---

## Project Overview
This project analyzes a global retail electronics dataset using SQL to derive insights across revenue trends, customer behavior, store performance, and operational efficiency. The goal is to simulate real-world business analysis using structured query techniques.

---

## Key Insights and Analysis

### Revenue Trends
- Revenue increased from approximately 1.85M in 2016 to 5.63M in 2019, reflecting nearly threefold growth
- Revenue declined to around 3.16M in 2020, indicating potential external disruption
- Monthly revenue remained stable in the range of 1.3M to 1.5M
- The business experienced strong growth followed by volatility, highlighting the need for forecasting and risk assessment.

---

### Store Performance Analysis
- Revenue per square meter ranged from approximately 380 to 810
- Stores with similar sizes showed significant differences in performance
- Identified multiple stores with zero recorded sales
- Store efficiency varies widely. Some locations may be underperforming or inactive, presenting opportunities for optimization or cost reduction.

---

### Delivery Performance
- Around 43 percent of orders were delivered within 33 days
- Approximately 22 percent of orders were delivered within 5 days
-  Delivery timelines indicate potential inefficiencies in logistics that could impact customer satisfaction.

---

### Product-Level Insights
- Identified products generating high revenue but relatively lower profit margins
- Several top-selling products do not contribute proportionally to profitability
- Pricing strategies or cost structures may need revision to improve margins.

---

### Customer Segmentation
- Majority of customers fall under the frequent purchase category
- Some customers exhibit large gaps between purchases, exceeding 400 days
- Clear segmentation exists between frequent and occasional buyers, enabling targeted retention strategies.

---

### Age Group Analysis
- The "Unknown" category contributes disproportionately high revenue compared to other age groups
- Other segments generate relatively balanced revenue levels
- This may indicate missing or poor-quality data, or an unclassified but significant customer segment.

---

### Best Performing Stores
- Online store consistently ranks highest in profit across all years
- Physical store performance varies by location and region
- Strong dominance of online channels suggests a shift towards digital retail.

---

### Time-Based Growth Analysis
- Cumulative revenue and profit show a steady upward trend over time
- Indicates consistent business expansion and customer retention.

---

## Key Learnings & Mistakes

While working on this project, I learned several practical lessons that go beyond writing long or complex SQL queries. Some of these came from mistakes I made during the process.

### 1. Importance of Correct Join Conditions
At one point, I mistakenly wrote a join condition like:
- joining a table to itself on the same column (e.g. `s.customer_key = s.customer_key`)

This caused incorrect results and took significant time to debug.  
It reinforced how critical it is to **carefully verify join logic**, especially when working with multiple tables.

---

### 2. Being Clear About the Level of Analysis
In customer retention analysis, I initially tried to use the first order date for logic that was already satisfied by my customer segmentation buckets.

This taught me to:
- clearly define the **goal of each query**
- avoid adding unnecessary logic when it does not change the outcome

---

### 3. Understanding the Side Effects of Formatting Functions
I learned that functions like `FORMAT()` convert numeric values into strings (`NVARCHAR`), which can cause issues in:
- further calculations
- UNION operations
- sorting and aggregation

As a result, formatting was applied only at the **final output stage**, not during intermediate calculations.

---

### 4. Data Type Consistency in UNION Operations
When combining results using `UNION`, I faced errors due to mismatched data types between columns.

This highlighted the importance of:
- explicitly casting columns
- ensuring consistent data types across all SELECT statements

---

### 5. Debugging Is Part of Real SQL Work
Some issues took a long time to identify and required stepping back, checking assumptions, and even asking for help.

This project made it clear that:
- debugging is a normal part of SQL work
- slow progress often means deeper understanding later

---

Overall, these mistakes helped me build better habits around validation, query structure, and defensive SQL writing.
 
## Personal Note

I am genuinely proud of this project because most of the work was done independently, without following tutorials or copying solutions.

I designed the majority of the questions myself, wrote the SQL queries from scratch, and spent significant time debugging and validating results on my own. Many issues—especially related to joins, date logic, and aggregation—were resolved through trial, error, and careful reasoning.

AI assistance was used selectively and responsibly, mainly for:
- minor tasks such as renaming columns during initial Pandas preprocessing,
- improving readability or formatting of some code,
- occasional debugging support when I was stuck for an extended period.

The core logic, problem framing, and analytical decisions throughout the project were my own. This project reflects my current understanding of SQL and my approach to solving real-world data problems.

## MY AIM IS TO BE SO GOOD THAT THAT THERE IS AT LEAST ONE THING COMMON BETWEEN ME AND AN A.I. - WE BOTH ARE IRREPLACEABLE 
