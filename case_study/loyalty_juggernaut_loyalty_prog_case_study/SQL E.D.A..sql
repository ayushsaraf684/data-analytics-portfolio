select * from kinara_kirana_loyalty;

-- finding redemption rate by tiers, understanding the behaviour
-- below query investigated for any 0 or negative values in denominator, since non exists so query simplified later
with cte as(
select *, (case when total_points_earned > 0 then round(total_points_redeemed*100.0/total_points_earned,2) else null end) as redemp_rate 
from kinara_kirana_loyalty
)
select member_id from cte where redemp_rate IS NULL

-- simplified query, earlier used cte here but then inserted as might be required later on multiple times
ALTER TABLE kinara_kirana_loyalty
ADD COLUMN redemp_rate DECIMAL;
UPDATE kinara_kirana_loyalty
SET redemp_rate =
ROUND(total_points_redeemed * 100.0 / total_points_earned, 2);



-- adding a new column in this cte for points liability flag, but before that some checks need to be done
-- all 3 queries were used to find the distribution for redemption rate for liability flags and engagement score
-- distribution of redemption rate
with redemp_rate_pct as(
SELECT
    ROUND(total_points_redeemed::numeric / 
          NULLIF(total_points_earned, 0) * 100, 2) AS redemption_rate_pct,
    COUNT(*) as member_count
FROM kinara_kirana_loyalty
GROUP BY 1
)
SELECT
    CASE
        WHEN redemption_rate_pct = 0 THEN '0'
        WHEN redemption_rate_pct > 0  AND redemption_rate_pct <= 10 THEN '0-10%'
        WHEN redemption_rate_pct > 10 AND redemption_rate_pct <= 20 THEN '10-20%'
        WHEN redemption_rate_pct > 20 AND redemption_rate_pct <= 30 THEN '20-30%'
        WHEN redemption_rate_pct > 30 AND redemption_rate_pct <= 40 THEN '30-40%'
        WHEN redemption_rate_pct > 40 AND redemption_rate_pct <= 50 THEN '40-50%'
        WHEN redemption_rate_pct > 50 AND redemption_rate_pct <= 60 THEN '50-60%'
        WHEN redemption_rate_pct > 60 AND redemption_rate_pct <= 70 THEN '60-70%'
        WHEN redemption_rate_pct > 70 AND redemption_rate_pct <= 80 THEN '70-80%'
        WHEN redemption_rate_pct > 80 AND redemption_rate_pct <= 90 THEN '80-90%'
        WHEN redemption_rate_pct > 90 AND redemption_rate_pct <= 100 THEN '90-100%'
        ELSE 'Above 100%'
    END AS redemption_bucket,
	COUNT(*) as member_counts
from redemp_rate_pct
group by 1

-- percentile distribution of unredeemed points
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY points_unredeemed) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY points_unredeemed) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY points_unredeemed) AS p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY points_unredeemed) AS p90,
    MAX(points_unredeemed) AS max_unredeemed
FROM kinara_kirana_loyalty;

-- redemption rate percentiles
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP 
        (ORDER BY total_points_redeemed::numeric / NULLIF(total_points_earned,0)) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP 
        (ORDER BY total_points_redeemed::numeric / NULLIF(total_points_earned,0)) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP 
        (ORDER BY total_points_redeemed::numeric / NULLIF(total_points_earned,0)) AS p90
FROM kinara_kirana_loyalty;

with  as(
select *,  end as liability_flag
from kinara_kirana_loyalty
)
-- again added permanently, why not in pandas - i think row level operations are easier
ALTER TABLE kinara_kirana_loyalty
ADD COLUMN liability_flag INT;
UPDATE kinara_kirana_loyalty
SET liability_flag =
case when redemp_rate <= 10.00 and points_unredeemed >= 5000 then 1 else 0 end

-- adding a new column callled engagement score
with max_values as (
select
max(transaction_count) as max_txn,
max(coupon_redemptions) as max_coupon,
max(referral_count) as max_referral
from kinara_kirana_loyalty
)

update kinara_kirana_loyalty k
set engagement_score = round(
(
(
coalesce(transaction_count,0)::numeric / max_txn * 10 +
coalesce(coupon_redemptions,0)::numeric / max_coupon * 10 +
coalesce(referral_count,0)::numeric / max_referral * 10
) / 3
)::numeric,
2
)
from max_values;



select * from kinara_kirana_loyalty



-- FINDING 1: Engagement Score by Tier and Membership Status
WITH max_values AS (
    SELECT
        MAX(transaction_count)   AS max_txn,
        MAX(coupon_redemptions)  AS max_coupon,
        MAX(referral_count)      AS max_referral
    FROM kinara_kirana_loyalty
),
engagement AS (
    SELECT
        member_id,
        tier,
        membership_status,
       ROUND(
(
    (transaction_count::numeric / max_txn * 10) +
    (coupon_redemptions::numeric / max_coupon * 10) +
    (referral_count::numeric / max_referral * 10)
)::numeric / 3,
2
) AS engagement_score
    FROM kinara_kirana_loyalty, max_values
)
SELECT
    tier,
    ROUND(AVG(CASE WHEN membership_status = 'Active'     THEN engagement_score END)::numeric, 2) AS active_avg,
    ROUND(AVG(CASE WHEN membership_status = 'Dormant'    THEN engagement_score END)::numeric, 2) AS dormant_avg,
    ROUND(AVG(CASE WHEN membership_status = 'Churn Risk' THEN engagement_score END)::numeric, 2) AS churn_risk_avg
FROM engagement
GROUP BY tier
ORDER BY tier;


-- FINDING 2: Churn Rate by Join Year Cohort
SELECT
    DATE_PART('year', join_date)            AS join_year,
    COUNT(*)                                AS total_members,
    COUNT(*) FILTER (
        WHERE membership_status = 'Churn Risk'
    )                                       AS churned_members,
    ROUND(
        COUNT(*) FILTER (
            WHERE membership_status = 'Churn Risk'
        )::numeric / COUNT(*) * 100, 2
    )                                       AS churn_rate
FROM kinara_kirana_loyalty
GROUP BY join_year
ORDER BY join_year;


select
tier,
count(*) as members,
sum(points_unredeemed) as total_points_unredeemed,
round(avg(points_unredeemed), 2) as avg_points_unredeemed
from kinara_kirana_loyalty
group by tier
order by total_points_unredeemed desc;



with cte AS (
    SELECT
        tier,
        membership_status,
        COUNT(*)                          AS member_count,
        ROUND(AVG(engagement_score), 2)   AS avg_engagement_score
    FROM kinara_kirana_loyalty
    GROUP BY tier, membership_status
)
SELECT
    tier,
    MAX(CASE
        WHEN membership_status = 'Dormant'
        THEN CONCAT(member_count, ' members | ', avg_engagement_score, '%')
    END) AS "Dormant",
    MAX(CASE
        WHEN membership_status = 'Churn Risk'
        THEN CONCAT(member_count, ' members | ', avg_engagement_score, '%')
    END) AS "Churn Risk",
    MAX(CASE
        WHEN membership_status = 'Active'
        THEN CONCAT(member_count, ' members | ', avg_engagement_score, '%')
    END) AS "Active"
FROM cte
GROUP BY tier
ORDER BY tier;



-- FINDING 5: Loyalty Program Effectiveness by Tier
SELECT
    tier,
    ROUND(AVG(total_spend), 2)                              AS avg_spend,
    ROUND(AVG(transaction_count), 2)                        AS avg_transactions,
    ROUND(
        AVG(total_points_redeemed::numeric / 
            NULLIF(total_points_earned, 0) * 100), 2
    )                                                       AS avg_redemption_rate,
    ROUND(AVG(referral_count)::numeric, 2)                           AS avg_referrals
FROM kinara_kirana_loyalty
GROUP BY tier
ORDER BY avg_spend DESC;



-- FINDING 4: Points Liability Flag by Tier
SELECT
    tier,
    COUNT(*)                                             AS total_members,
    SUM(liability_flag)                           AS liability_members,
    ROUND(
        SUM(liability_flag)::numeric / COUNT(*) * 100, 2
    )                                                    AS liability_pct,
    SUM(points_unredeemed)                               AS total_points_at_risk
FROM kinara_kirana_loyalty
GROUP BY tier
ORDER BY liability_pct DESC;

-- exporting it to csv for dashboards
COPY (
    SELECT *
    FROM kinara_kirana_loyalty
) TO '/Users/piyushsaraf/Desktop/LJI CASE STUDY/Untitled.csv'
WITH CSV HEADER;


select
tier,
round(avg(total_spend)::numeric, 2) as avg_spend,
round(avg(transaction_count)::numeric, 2) as avg_transactions,
round(avg(redemp_rate)::numeric, 2) as avg_redemption_rate,
round(avg(referral_count)::numeric, 2) as avg_referrals
from kinara_kirana_loyalty
group by tier
order by avg_spend desc;
