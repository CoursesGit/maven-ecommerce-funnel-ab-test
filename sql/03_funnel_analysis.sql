-- Maven Fuzzy Factory：第 3 阶段购买漏斗分析
-- 固定 cohort：
-- 2012-08-05（含）至 2012-09-05（不含）
-- gsearch + nonbrand 流量
--
-- 以 website_session_id 为分析单位。
-- 每个 Session 在每个漏斗阶段最多计算一次。
-- 使用 website_pageview_id 判断同一 Session 内页面先后顺序。

USE maven_fuzzy_factory;


WITH cohort_sessions AS (

    -- 1. 筛选本次漏斗分析使用的 Session
    SELECT
        website_session_id
    FROM website_sessions
    WHERE created_at >= '2012-08-05'
      AND created_at < '2012-09-05'
      AND utm_source = 'gsearch'
      AND utm_campaign = 'nonbrand'
),


first_pageviews AS (

    -- 2. 记录每个 Session 首次到达各漏斗页面的 pageview_id
    SELECT
        c.website_session_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/lander-1'
                THEN p.website_pageview_id
            END
        ) AS landing_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/products'
                THEN p.website_pageview_id
            END
        ) AS products_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/the-original-mr-fuzzy'
                THEN p.website_pageview_id
            END
        ) AS product_detail_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/cart'
                THEN p.website_pageview_id
            END
        ) AS cart_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/shipping'
                THEN p.website_pageview_id
            END
        ) AS shipping_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/billing'
                THEN p.website_pageview_id
            END
        ) AS billing_pv_id,

        MIN(
            CASE
                WHEN p.pageview_url = '/thank-you-for-your-order'
                THEN p.website_pageview_id
            END
        ) AS purchase_pv_id

    FROM cohort_sessions AS c

    LEFT JOIN website_pageviews AS p
        ON c.website_session_id = p.website_session_id

    GROUP BY
        c.website_session_id
),


session_funnel AS (

    -- 3. 只有按照正确页面顺序到达时，
    --    才将该 Session 计入对应漏斗阶段
    SELECT
        website_session_id,

        CASE
            WHEN landing_pv_id IS NOT NULL
            THEN 1 ELSE 0
        END AS reached_landing,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
            THEN 1 ELSE 0
        END AS reached_products,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
             AND product_detail_pv_id > products_pv_id
            THEN 1 ELSE 0
        END AS reached_product_detail,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
             AND product_detail_pv_id > products_pv_id
             AND cart_pv_id > product_detail_pv_id
            THEN 1 ELSE 0
        END AS reached_cart,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
             AND product_detail_pv_id > products_pv_id
             AND cart_pv_id > product_detail_pv_id
             AND shipping_pv_id > cart_pv_id
            THEN 1 ELSE 0
        END AS reached_shipping,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
             AND product_detail_pv_id > products_pv_id
             AND cart_pv_id > product_detail_pv_id
             AND shipping_pv_id > cart_pv_id
             AND billing_pv_id > shipping_pv_id
            THEN 1 ELSE 0
        END AS reached_billing,

        CASE
            WHEN landing_pv_id IS NOT NULL
             AND products_pv_id > landing_pv_id
             AND product_detail_pv_id > products_pv_id
             AND cart_pv_id > product_detail_pv_id
             AND shipping_pv_id > cart_pv_id
             AND billing_pv_id > shipping_pv_id
             AND purchase_pv_id > billing_pv_id
            THEN 1 ELSE 0
        END AS reached_purchase

    FROM first_pageviews
),


stage_counts AS (

    -- 4. 汇总每个漏斗阶段到达的 Session 数
    SELECT
        SUM(reached_landing) AS landing_sessions,
        SUM(reached_products) AS products_sessions,
        SUM(reached_product_detail) AS product_detail_sessions,
        SUM(reached_cart) AS cart_sessions,
        SUM(reached_shipping) AS shipping_sessions,
        SUM(reached_billing) AS billing_sessions,
        SUM(reached_purchase) AS purchase_sessions

    FROM session_funnel
),


funnel_rows AS (

    -- 5. 将横向结果整理成纵向漏斗表

    SELECT
        1 AS step_number,
        'Landing' AS funnel_stage,
        '/lander-1' AS pageview_url,
        landing_sessions AS reached_sessions,
        NULL AS previous_stage_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        2,
        'Products',
        '/products',
        products_sessions,
        landing_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        3,
        'Product Detail',
        '/the-original-mr-fuzzy',
        product_detail_sessions,
        products_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        4,
        'Cart',
        '/cart',
        cart_sessions,
        product_detail_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        5,
        'Shipping',
        '/shipping',
        shipping_sessions,
        cart_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        6,
        'Billing',
        '/billing',
        billing_sessions,
        shipping_sessions
    FROM stage_counts

    UNION ALL

    SELECT
        7,
        'Purchase',
        '/thank-you-for-your-order',
        purchase_sessions,
        billing_sessions
    FROM stage_counts
)


-- 6. 最终漏斗结果
SELECT
    step_number,
    funnel_stage,
    pageview_url,
    reached_sessions,

    ROUND(
        reached_sessions
        / NULLIF(previous_stage_sessions, 0),
        4
    ) AS step_conversion_rate,

    ROUND(
        1 - reached_sessions
        / NULLIF(previous_stage_sessions, 0),
        4
    ) AS drop_off_rate

FROM funnel_rows

ORDER BY
    step_number;