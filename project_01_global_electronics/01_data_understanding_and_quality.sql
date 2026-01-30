-- understaning the data by finding counts

SELECT COUNT(DISTINCT customer_key)
FROM customers; -- 15266 customers
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT COUNT(*)
FROM stores; --67 stores
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT COUNT(*)
FROM sales;

SELECT COUNT(DISTINCT order_number)
FROM sales;
-- 26326 distinct orders in a table of 62884 for rows,
--possibility that one customer has bought multiple items in one single order
-- SALES TABLE HAS SOME NULL VALUES IN order_date and delivery_date column

--finding rows with null values in date columns of sales.csv
select *,
CASE WHEN order_date IS NULL and delivery_date is null THEN 'NO DATE' ELSE(
CASE WHEN  order_date IS NULL and delivery_date is NOT null  THEN 'NO ORDER DATE' END) END AS date_flag
from sales;
-- there are 32499 rows with no order_date or no delivery_date
-- we will flag these rows

--CREATING A DATE FLAG AS THIS WILL BE IMPORTANT FOR FURTHER ANALYSIS
--permanently altering the table to make the flag
ALTER TABLE sales
ADD date_flag AS (
    CASE 
        WHEN order_date IS NULL AND delivery_date IS NULL THEN 'NO DATE'
        WHEN order_date IS NULL AND delivery_date IS NOT NULL THEN 'NO ORDER DATE'
        WHEN order_date IS NOT NULL AND delivery_date IS NULL THEN 'NO DELIVERY DATE'
        ELSE 'VALID' 
    END
);
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATING NEW TABLES AS I THOUGHT IT WOULD BE REQUIRED WHILE ANALYSIS
--1.
-- pivoting the exchange_rate table to have a better glimpse of the exchange rates on day to day to basis.
-- and created a new permanent table

SELECT date, 
    MAX(CASE WHEN currency = 'USD' THEN exchange END) AS USD,
    MAX(CASE WHEN currency = 'CAD' THEN exchange END) AS CAD,
    MAX(CASE WHEN currency = 'AUD' THEN exchange END) AS AUD,
    MAX(CASE WHEN currency = 'EUR' THEN exchange END) AS EUR,
    MAX(CASE WHEN currency = 'GBP' THEN exchange END) AS GBP
INTO exchange_rate_pivoted
FROM exchange_rate
GROUP BY date;

--2.
--- making a table for revenue and profit calculations - since it was frequent and too much required
select s.*,p.unit_cost_usd, p.unit_price_usd, ROUND(s.quantity * p.unit_cost_usd ,2) AS total_cost, 
ROUND(s.quantity * p.unit_price_usd ,2) as total_revenue,
ROUND(s.quantity * p.unit_price_usd ,2) - ROUND(s.quantity * p.unit_cost_usd ,2) as total_profit
INTO sales_products_combined
from sales s
join products p
on s.product_key = p.product_key

--Transactions with missing price or cost information were retained and excluded only from revenue or profit 
--computations where necessary, to avoid undercounting sales activity
--MADE THIS TABLE AFTER A VERY LONG TIME DURING MAKING THIS PROJECT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TO CHECK THE SCHEMA AND COLUMN NAMES
select top 5 *
from data_dictionary;

select TOP 5*
from exchange_rate;

select top 5 *
from products;

select top 5 *
from sales;

select top 5 *
from stores;


SELECT TOP 5 *
FROM sales_products_combined; -- NEW TABLE

select top 5 *
from exchange_rate_pivoted; -- NEW TABLE
