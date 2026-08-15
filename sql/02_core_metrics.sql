-- Maven Fuzzy Factory：第 2 阶段整体业务指标
-- 只读取原始表，不修改数据，也不创建中间表。

USE maven_fuzzy_factory;

-- 1. 网站整体业务表现
-- 先将订单汇总到 Session 粒度，避免连接后重复计算 Session。
WITH orders_by_session AS (
    SELECT
        website_session_id,
        COUNT(*) AS order_count,
        SUM(price_usd) AS revenue
    FROM orders
    GROUP BY website_session_id
)
SELECT
    COUNT(*) AS sessions,
    COUNT(DISTINCT s.user_id) AS users,
    SUM(COALESCE(o.order_count, 0)) AS orders,
    ROUND(
        SUM(CASE WHEN o.order_count > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        4
    ) AS purchase_conversion_rate,
    ROUND(SUM(COALESCE(o.revenue, 0)), 2) AS revenue,
    ROUND(
        SUM(COALESCE(o.revenue, 0)) / NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_session,
    ROUND(
        SUM(COALESCE(o.revenue, 0))
        / NULLIF(SUM(COALESCE(o.order_count, 0)), 0),
        2
    ) AS aov
FROM website_sessions AS s
LEFT JOIN orders_by_session AS o
    ON s.website_session_id = o.website_session_id;

-- 2. 按月观察整体业务表现
-- 月份按 Session 的 created_at 归属，订单和收入归入对应 Session 的月份。
WITH orders_by_session AS (
    SELECT
        website_session_id,
        COUNT(*) AS order_count,
        SUM(price_usd) AS revenue
    FROM orders
    GROUP BY website_session_id
)
SELECT
    DATE_FORMAT(s.created_at, '%Y-%m') AS month,
    COUNT(*) AS sessions,
    SUM(COALESCE(o.order_count, 0)) AS orders,
    ROUND(
        SUM(CASE WHEN o.order_count > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        4
    ) AS purchase_conversion_rate,
    ROUND(SUM(COALESCE(o.revenue, 0)), 2) AS revenue,
    ROUND(
        SUM(COALESCE(o.revenue, 0)) / NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_session
FROM website_sessions AS s
LEFT JOIN orders_by_session AS o
    ON s.website_session_id = o.website_session_id
GROUP BY
    YEAR(s.created_at),
    MONTH(s.created_at),
    DATE_FORMAT(s.created_at, '%Y-%m')
ORDER BY
    YEAR(s.created_at),
    MONTH(s.created_at);
