-- City wise revenue distribution across all platforms
select 
  city,
  to_char( sum( case when platform = 'Blinkit' then revenue_inr else 0 end), 'FM₹999,999,999') as blinkit_revenue,
  to_char(sum(case when platform = 'Zepto' then revenue_inr else 0 end), 'FM₹999,999,999') as zepto_revenue,
  to_char(sum(case when platform = 'Instamart' then revenue_inr else 0 end), 'FM₹999,999,999') as instamart_revenue
from qcomm
group by city
order by city;

-- cross-platform price consistency check AND price variance
WITH platform_avg_price AS (
    SELECT
        platform,
        product_name,
        ROUND(AVG(revenue_inr / NULLIF(units_sold, 0))::numeric, 2) AS avg_implied_price
    FROM qcomm
    WHERE units_sold > 0
      AND revenue_inr IS NOT NULL
    GROUP BY platform, product_name
),
ranked AS (
    SELECT
        product_name,
        platform,
        avg_implied_price,
        MIN(avg_implied_price) OVER (PARTITION BY product_name) AS min_price,
        MAX(avg_implied_price) OVER (PARTITION BY product_name) AS max_price,
        ROUND(((MAX(avg_implied_price) OVER (PARTITION BY product_name) - 
                MIN(avg_implied_price) OVER (PARTITION BY product_name)) /
                NULLIF(MIN(avg_implied_price) OVER (PARTITION BY product_name), 0) * 100)::numeric, 2) AS variance_pct
    FROM platform_avg_price
)
    SELECT
        product_name,
        MAX(CASE WHEN avg_implied_price = min_price THEN platform END) AS min_price_platform,
        MIN(min_price) AS min_price,
        MAX(CASE WHEN avg_implied_price = max_price THEN platform END) AS max_price_platform,
        MAX(max_price) AS max_price,
        MAX(variance_pct) AS variance_pct
    FROM ranked
    GROUP BY product_name



-- data quality check
SELECT
    platform,

    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE revenue_inr IS NULL
    ) AS missing_revenue_rows,

    COUNT(*) FILTER (
        WHERE units_sold = 0
    ) AS zero_quantity_rows,

    COUNT(*) FILTER (
        WHERE units_sold IS NULL
    ) AS missing_quantity_rows

FROM qcomm
GROUP BY platform
ORDER BY platform;

-- SKU revenuw share percentage based on platform and city
WITH city_platform_revenue AS (
    SELECT
        platform,
        city,
        product_name,
        SUM(revenue_inr) AS sku_revenue,
        SUM(SUM(revenue_inr)) OVER (PARTITION BY platform, city) AS total_revenue
    FROM qcomm
    WHERE revenue_inr IS NOT NULL
      AND units_sold > 0
    GROUP BY platform, city, product_name
)
SELECT
    platform,
    city,
    product_name,
    ROUND(sku_revenue::numeric, 2) AS sku_revenue,
    ROUND((sku_revenue / total_revenue * 100)::numeric, 2) AS revenue_share_pct
FROM city_platform_revenue
WHERE (sku_revenue / total_revenue * 100) > 40
ORDER BY revenue_share_pct DESC;
