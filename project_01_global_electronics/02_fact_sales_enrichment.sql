-- For each product category, find the total quantity sold.
select p.category, SUM(s.quantity) as total_quantity_sold
from sales s
join products p
on s.product_key = p.product_key
group by p.category
order by total_quantity_sold;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Find the TOTAL QUANTITY of orders processed by each store country.
select st.country, SUM(s.quantity) as quantity_per_store
from sales s
join stores st
on s.store_key = st.store_key
group by st.country
order by quantity_per_store;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- For each product, calculate:
--total revenue (USD)
--total cost (USD)
--total profit (USD)
--Exclude rows where quantity is NULL or zero.

SELECT 
    p.product_name,
    SUM(p.unit_price_usd * s.quantity) AS total_rev,
    SUM(p.unit_cost_usd * s.quantity) AS total_cost,
    SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity) AS total_profit
FROM sales s
JOIN products p
    ON s.product_key = p.product_key
WHERE s.quantity IS NOT NULL
GROUP BY p.product_name
ORDER BY total_profit DESC;

--HERE WHILE FINDING THE REVENUE AND COSTS FOR EACH PRODUCTS
-- unit cost and unit price were varchar, rookie mistake during data cleaning
-- changing it below
-- couldnt change, did in pandas and exported
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- For each product category, calculate:
--total revenue
--total profit
--average profit margin
--Order categories by total profit (descending).
SELECT 
    p.category,
    ROUND(SUM(p.unit_price_usd * s.quantity), 2) AS total_rev,
    ROUND(SUM(p.unit_cost_usd * s.quantity), 2) AS total_cost,
    ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2) AS total_profit,
    ROUND(
        (SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity)) / 
        NULLIF(SUM(p.unit_price_usd * s.quantity), 0) * 100, 
        2
    ) AS avg_profit_margin_pct
FROM sales s
JOIN products p
    ON s.product_key = p.product_key
WHERE s.quantity IS NOT NULL
GROUP BY p.category
ORDER BY total_profit DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Identify products that:
--fall in the top 25% by total revenue
--but fall in the bottom 25% by profit margin
with cte as(
SELECT 
 p.product_name,
  round(SUM(p.unit_price_usd * s.quantity), 2) AS total_rev,
round(SUM(p.unit_cost_usd * s.quantity), 2) AS total_cost,
round(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2) AS total_profit
from sales s
JOIN products p
ON s.product_key = p.product_key
WHERE s.quantity IS NOT NULL
GROUP BY p.product_name),
cte2 as(
select *, row_number() OVER(ORDER BY total_rev) as revenue_rn,
row_number() OVER(ORDER BY total_profit DESC) as profit_rn,
COUNT(*) OVER() AS total_count
from cte)

select *
from cte2
where revenue_rn <= 0.25 * total_count and profit_rn >=  0.75 * total_count

-- was thinking of removing the colores form product names
--colors not removed from product name because they 
--may have different costs
--may have different pricing
--may have different margins

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--For each store, calculate:
--total revenue
--total profit
--revenue per square meter
--Return only stores greater than overall average -- we can also make changes by analyszing minimum amount of stores
WITH CTE AS(
select  
st.store_key,
st.square_meters,
ROUND(SUM(p.unit_price_usd * s.quantity), 2) AS total_rev,
ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2) AS total_profit
from sales s
left join products p
on s.product_key = p.product_key
left join stores st
on s.store_key = st.store_key
group by st.store_key, st.square_meters)

SELECT *, ROUND(total_rev/square_meters,2) as rev_per_sq_meter
from CTE
where total_rev > (SELECT avg(total_rev) from CTE) -- average revenue was 744878.209
ORDER BY store_key

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Calculate monthly revenue trends using:
--year, month
--Exclude rows where order date is missing.
select 
DATENAME(MONTH, s.order_date) AS month_name,
FORMAT(ROUND(SUM(p.unit_price_usd * s.quantity), 2),'N2') AS total_rev,
FORMAT(ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2),'N2') AS total_profit
from sales s
left join products p
on s.product_key = p.product_key
where s.order_date IS NOT NULL
GROUP BY DATENAME(MONTH, s.order_date);

-- overall uniform distribution in months, no seasonal differences
-- max in february and least in june

select 
YEAR(s.order_date) AS month_name,
FORMAT(ROUND(SUM(p.unit_price_usd * s.quantity), 2),'N2') AS total_rev,
FORMAT(ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2),'N2') AS total_profit
from sales s
left join products p
on s.product_key = p.product_key
where s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date)
order BY YEAR(s.order_date);

-- max rev and max profit in 2019, increased from 2016 to 2019 then decreased by 25l in 2020
-- LEAST SALES IN 2021, ONLY SOLD 2 DAYS PER MONTH ALSO LEAST PROFIT

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--For each product category, return the top 3 products by total revenue.
--Ensure that ties are handled correctly.
with cte as(
SELECT p.product_key, p.product_name, p.category,
SUM(sp.total_cost) AS total_cost,
SUM(sp.total_revenue) AS total_revenue,
SUM(sp.total_profit) AS total_profit
from sales_products_combined sp
join products p
on sp.product_key = p.product_key
group by  p.product_key, p.product_name, p.category),
cte2 as(
select *, DENSE_RANK() over(partition by category order by total_revenue desc) as rn
from cte)
select category, product_name
from cte2
where rn <= 3

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- For each store, calculate cumulative revenue over time, ordered by order date.
--Exclude rows with missing order dates.
with cte as(
select st.store_key, st.country, s.order_date, SUM(s.total_revenue) AS total_revenue, SUM(s.total_profit) AS total_profit
from sales_products_combined s
left join stores st
on s.store_key = st.store_key
where s.order_date IS NOT NULL
group by  s.order_date,st.store_key, st.country)
select store_key, country, order_date,
SUM(total_revenue) OVER(PARTITION BY store_key ORDER BY order_date) AS cumulative_revenue,
SUM(total_profit) OVER(PARTITION BY store_key ORDER BY order_date) AS cumulative_profit
from cte
order by store_key, order_date
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--For each year, identify the store(s) with the highest total profit.
--If multiple stores tie, return all tied stores.

select *
from(
select sp.store_key,s.country,s.state, YEAR(sp.order_date) as order_year, SUM(sp.total_cost) as total_cost, SUM(sp.total_revenue) as total_revenue, SUM(sp.total_profit) as total_profit,
DENSE_RANK() OVER(PARTITION BY YEAR(sp.order_date) order by SUM(sp.total_revenue) desc) as rn
from sales_products_combined sp
left join stores s
on sp.store_key = s.store_key
where sp.order_date IS NOT NULL
group by sp.store_key, s.country,s.state,YEAR(sp.order_date) ) a
where rn = 1
--here online stores always ranked first when rn = 1, so i found the next best store based on revenue
-- except 2016, US stores did the most revenue every year, but there states are different















