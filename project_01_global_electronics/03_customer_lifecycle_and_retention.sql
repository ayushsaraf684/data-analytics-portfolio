--Customer behavior over time.

--Age-based revenue distribution for customers with known age.
-- we are making buckets here for ages, if not known then put under unknown
with cte as(
SELECT *,
    CASE 
        WHEN datediff = 0 THEN 'Unknown'
        WHEN datediff < 25 THEN '<25'
        WHEN datediff >= 25 AND datediff <= 34 THEN '25-34'
        WHEN datediff >= 35 AND datediff <= 44 THEN '35-44'
        WHEN datediff >= 45 AND datediff <= 54 THEN '45-54'
        WHEN datediff >= 55 THEN '55+'
    END AS age_group
FROM (
    SELECT s.customer_key, s.order_date, c.birthday,
        CASE WHEN s.order_date IS NULL OR c.birthday IS NULL THEN 0 
             ELSE DATEDIFF(day, c.birthday, s.order_date)/365 
        END AS datediff,
        ROUND(SUM(p.unit_price_usd * s.quantity), 2) AS total_rev,
    ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2) AS total_profit,
    s.quantity as quantity
    FROM sales s
    LEFT JOIN customers c
        ON s.customer_key = c.customer_key
    LEFT JOIN products p
        on s.product_key = p.product_key
    group by s.customer_key, s.order_date, c.birthday,
        CASE WHEN s.order_date IS NULL OR c.birthday IS NULL THEN 0 
             ELSE DATEDIFF(day, c.birthday, s.order_date)/365 
        END, s.quantity
) a )
SELECT age_group, ROUND(SUM(total_rev),2) AS total_revenue, SUM(total_profit) AS total_profit, COUNT(quantity) as total_quantity
FROM cte
GROUP BY age_group
order by total_revenue, total_profit

-- Age-based segmentation was included for completeness but not used as a primary driver due to limited demographic coverage.
--Age cannot be computed if either is missing
--did not fabricate data
--preserved all revenue
--kept time-dependent logic clean

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Identify repeat customers and return:
--customer id
--number of orders
--first order date
--last order date

select *, DATEDIFF(DAY, first_order, last_order) as diff_bet
from(
select c.customer_key, MIN(s.order_date) as first_order, MAX(s.order_date) as last_order, COUNT(*) as total_orders
from sales s
join customers c
on s.customer_key = c.customer_key
where s.order_date is not null 
group by c.customer_key) a

-- above gives me all the customers with valid dates who have repeat orders, here since we are doing time analysis
-- having valid order dates is important, null dates can be used for revenue analysis

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Customer Repeat Purchase & Retention Summary
-- Customer-level analysis showing order frequency, time gaps between purchases, and revenue contribution

WITH CTE AS(
select c.customer_key, s.order_date, s.quantity, s.total_revenue, s.total_profit,
LAG(s.order_date) OVER(PARTITION BY c.customer_key order by s.order_date) as next_order,
DATEDIFF(DAY,LAG(s.order_date) OVER(PARTITION BY c.customer_key order by s.order_date),s.order_date) as diff
from sales_products_combined s
join customers c
on s.customer_key = c.customer_key
where s.order_date is not null),
cte2 as(
SELECT customer_key, MAX(diff) as max_gap, avg(diff) as avg_gap, COUNT(*) as total_orders,
sum(quantity) as total_quantity, SUM(total_revenue) as total_revenue, SUM(total_profit) as total_profit,
CASE
    WHEN avg(diff) <= 30 THEN 'Frequent'
    WHEN avg(diff) >= 31 AND avg(diff)<= 90 THEN 'Regular'
    WHEN avg(diff) >= 91 AND avg(diff) <= 180 THEN 'Occasional'
    WHEN avg(diff) > 180 THEN 'At Risk'
END AS customer_segment
from CTE
group by customer_key )
SELECT *
from cte2
where customer_segment is not null

-- customer segment null means no repeat purchases


