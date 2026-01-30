-- MISC QUESTIONS

--SHOW STORES WITH 0 SALES
with cte as(
select  
st.store_key,
st.square_meters,
ROUND(SUM(p.unit_price_usd * s.quantity), 2) AS total_rev,
ROUND(SUM(p.unit_price_usd * s.quantity) - SUM(p.unit_cost_usd * s.quantity), 2) AS total_profit
from sales s
left join products p
on s.product_key = p.product_key -- can also show location of store here
left join stores st
on s.store_key = st.store_key
group by st.store_key, st.square_meters)

select st.store_key, st.square_meters
from stores st
left join cte c
on st.store_key = c.store_key
where c.total_rev IS NULL
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Find countries where:
--customers frequently purchase from stores in other countries
--Show:
--customer country
--store country
--number of such orders

WITH cte AS (
SELECT 
c.country AS customer_country, 
st.country AS store_country
FROM sales s
left join stores st
ON s.store_key = st.store_key
left join customers c
ON s.customer_key = c.customer_key
where c.country IS NOT NULL 
AND st.country is not null
)
select 
customer_country, 
store_country, 
count(*) AS total_orders
from cte
WHERE customer_country <> store_country 
group by customer_country, store_country
order by total_orders desc;

-- people used only the online mode to purchase from different countries

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--For orders with valid order dates, calculate:
--average delivery time in days per store
--Exclude rows where delivery date < order date.

select st.country as mode, ROUND(CAST(AVG(DATEDIFF(day,s.order_date,s.delivery_date))AS bigint),2) AS average_delivery_time
from sales s
left join stores st
on s.store_key = st.store_key
where date_flag = 'VALID' and s.order_date < s.delivery_date
group by st.country

-- order date and delivery date valid only for online purchases
-- no delivery date means in store purchase

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
--BELOW IS CUMULATIVE PERCENTAGE TO FIND LETS SAY, HOW MANY ORDERS ARE DELIVERED WITHIN 7 DAYS THEN FROM BELOW YOU WILL GET 32.6 %
-- YOU CAN SEE THAT 55.25% ORDERS DELIVERED LESS THAN 38 DAYS, BUT THE TIME SPIKES AFTER THIS TO 63 DAYS AND SO ON

WITH cte AS (
    SELECT 
DATEDIFF(day, s.order_date, s.delivery_date) AS delivery_time, 
COUNT(*) AS orders
FROM sales s
LEFT JOIN stores st
ON s.store_key = st.store_key
WHERE date_flag = 'VALID' 
AND s.order_date < s.delivery_date
GROUP BY DATEDIFF(day, s.order_date, s.delivery_date)
),
cte1 AS (
SELECT *, 
SUM(orders) OVER() AS total
   FROM cte
)
SELECT *,
 CAST(ROUND(SUM(orders) OVER (ORDER BY delivery_time) * 100.0 / total, 2) AS FLOAT) AS cumulative_percentage
FROM cte1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------