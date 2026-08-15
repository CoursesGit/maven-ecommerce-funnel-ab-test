-- Maven Fuzzy Factory：第 4 阶段 Billing Page A/B Test 样本提取
-- 本脚本只提取实验样本并输出描述性检查，不进行统计显著性检验。

USE maven_fuzzy_factory;

-- 1. 实验样本明细：一行代表一个 website_session_id
WITH billing_exposures AS (
    -- 找出实验窗口内所有 Billing 实验页面访问
    SELECT
        p.website_session_id,
        p.website_pageview_id,
        p.created_at,
        p.pageview_url,
        ROW_NUMBER() OVER (
            PARTITION BY p.website_session_id
            ORDER BY p.website_pageview_id
        ) AS exposure_order
    FROM website_pageviews AS p
    WHERE p.created_at >= '2012-09-10'
      AND p.created_at < '2012-11-10'
      AND p.pageview_url IN ('/billing', '/billing-2')
),
first_billing_exposure AS (
    -- 使用 website_pageview_id 确定每个 Session 的首次实验曝光
    SELECT
        website_session_id,
        website_pageview_id AS billing_pageview_id,
        created_at AS billing_exposure_at,
        CASE
            WHEN pageview_url = '/billing' THEN 'control'
            WHEN pageview_url = '/billing-2' THEN 'treatment'
        END AS billing_version
    FROM billing_exposures
    WHERE exposure_order = 1
),
orders_after_exposure AS (
    -- 汇总 Billing 曝光之后，同一 Session 实际产生的订单
    SELECT
        e.website_session_id,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.price_usd), 0) AS revenue
    FROM first_billing_exposure AS e
    LEFT JOIN orders AS o
        ON e.website_session_id = o.website_session_id
       AND o.created_at >= e.billing_exposure_at
    GROUP BY e.website_session_id
),
experiment_sample AS (
    SELECT
        e.website_session_id,
        s.user_id,
        e.billing_version,
        e.billing_pageview_id,
        e.billing_exposure_at,
        s.device_type,
        s.is_repeat_session,
        s.utm_source,
        s.utm_campaign,
        CASE WHEN o.order_count > 0 THEN 1 ELSE 0 END AS purchased,
        o.order_count,
        ROUND(o.revenue, 2) AS revenue
    FROM first_billing_exposure AS e
    INNER JOIN website_sessions AS s
        ON e.website_session_id = s.website_session_id
    INNER JOIN orders_after_exposure AS o
        ON e.website_session_id = o.website_session_id
)
SELECT
    website_session_id,
    user_id,
    billing_version,
    billing_pageview_id,
    billing_exposure_at,
    device_type,
    is_repeat_session,
    utm_source,
    utm_campaign,
    purchased,
    order_count,
    revenue
FROM experiment_sample
ORDER BY billing_pageview_id;


-- 2. 实验样本量、交叉曝光和描述性结果检查
WITH billing_exposures AS (
    SELECT
        p.website_session_id,
        p.website_pageview_id,
        p.created_at,
        p.pageview_url,
        ROW_NUMBER() OVER (
            PARTITION BY p.website_session_id
            ORDER BY p.website_pageview_id
        ) AS exposure_order
    FROM website_pageviews AS p
    WHERE p.created_at >= '2012-09-10'
      AND p.created_at < '2012-11-10'
      AND p.pageview_url IN ('/billing', '/billing-2')
),
first_billing_exposure AS (
    SELECT
        website_session_id,
        website_pageview_id AS billing_pageview_id,
        created_at AS billing_exposure_at,
        CASE
            WHEN pageview_url = '/billing' THEN 'control'
            WHEN pageview_url = '/billing-2' THEN 'treatment'
        END AS billing_version
    FROM billing_exposures
    WHERE exposure_order = 1
),
cross_exposure AS (
    -- 同一个 Session 同时访问两个版本时记为交叉曝光
    SELECT
        website_session_id
    FROM billing_exposures
    GROUP BY website_session_id
    HAVING COUNT(DISTINCT pageview_url) = 2
),
orders_after_exposure AS (
    SELECT
        e.website_session_id,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.price_usd), 0) AS revenue
    FROM first_billing_exposure AS e
    LEFT JOIN orders AS o
        ON e.website_session_id = o.website_session_id
       AND o.created_at >= e.billing_exposure_at
    GROUP BY e.website_session_id
),
experiment_sample AS (
    SELECT
        e.website_session_id,
        e.billing_version,
        CASE WHEN o.order_count > 0 THEN 1 ELSE 0 END AS purchased,
        o.order_count,
        o.revenue
    FROM first_billing_exposure AS e
    INNER JOIN orders_after_exposure AS o
        ON e.website_session_id = o.website_session_id
)
SELECT
    SUM(CASE WHEN billing_version = 'control' THEN 1 ELSE 0 END)
        AS control_sessions,
    SUM(CASE WHEN billing_version = 'treatment' THEN 1 ELSE 0 END)
        AS treatment_sessions,
    (SELECT COUNT(*) FROM cross_exposure)
        AS cross_exposure_sessions,
    SUM(CASE WHEN billing_version = 'control' THEN order_count ELSE 0 END)
        AS control_orders,
    SUM(CASE WHEN billing_version = 'control' THEN purchased ELSE 0 END)
        AS control_purchasing_sessions,
    SUM(CASE WHEN billing_version = 'treatment' THEN order_count ELSE 0 END)
        AS treatment_orders,
    SUM(CASE WHEN billing_version = 'treatment' THEN purchased ELSE 0 END)
        AS treatment_purchasing_sessions,
    ROUND(
        SUM(CASE WHEN billing_version = 'control' THEN purchased ELSE 0 END)
        / NULLIF(SUM(CASE WHEN billing_version = 'control' THEN 1 ELSE 0 END), 0),
        4
    ) AS control_purchase_cr,
    ROUND(
        SUM(CASE WHEN billing_version = 'treatment' THEN purchased ELSE 0 END)
        / NULLIF(SUM(CASE WHEN billing_version = 'treatment' THEN 1 ELSE 0 END), 0),
        4
    ) AS treatment_purchase_cr,
    ROUND(
        SUM(CASE WHEN billing_version = 'control' THEN revenue ELSE 0 END)
        / NULLIF(SUM(CASE WHEN billing_version = 'control' THEN 1 ELSE 0 END), 0),
        2
    ) AS control_revenue_per_billing_session,
    ROUND(
        SUM(CASE WHEN billing_version = 'treatment' THEN revenue ELSE 0 END)
        / NULLIF(SUM(CASE WHEN billing_version = 'treatment' THEN 1 ELSE 0 END), 0),
        2
    ) AS treatment_revenue_per_billing_session
FROM experiment_sample;
