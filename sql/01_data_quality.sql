-- Maven Fuzzy Factory：第 1 阶段数据质量检查
-- 目标：
-- 只检查数据量、时间范围、主键重复、关键字段 NULL、
-- 表关联完整性、主要分类字段和基础数值合理性。
-- 不修改原始数据，不做无意义清洗。

USE maven_fuzzy_factory;


-- =========================================================
-- 1. 四张表数据量
-- =========================================================

SELECT 'website_sessions' AS table_name, COUNT(*) AS row_count
FROM website_sessions

UNION ALL

SELECT 'website_pageviews', COUNT(*)
FROM website_pageviews

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_item_refunds', COUNT(*)
FROM order_item_refunds;


-- =========================================================
-- 2. created_at 时间范围
-- =========================================================

SELECT
    'website_sessions' AS table_name,
    MIN(created_at) AS min_created_at,
    MAX(created_at) AS max_created_at
FROM website_sessions

UNION ALL

SELECT
    'website_pageviews',
    MIN(created_at),
    MAX(created_at)
FROM website_pageviews

UNION ALL

SELECT
    'orders',
    MIN(created_at),
    MAX(created_at)
FROM orders

UNION ALL

SELECT
    'order_item_refunds',
    MIN(created_at),
    MAX(created_at)
FROM order_item_refunds;


-- =========================================================
-- 3. 主键重复检查
-- duplicate_id_count：发生重复的 ID 数量
-- extra_row_count：由于重复多出来的记录数量
-- NULL 主键不在这里统计，下一部分单独检查
-- =========================================================

SELECT
    'website_sessions.website_session_id' AS primary_key,
    COUNT(*) AS duplicate_id_count,
    COALESCE(SUM(row_count - 1), 0) AS extra_row_count
FROM (
    SELECT
        website_session_id,
        COUNT(*) AS row_count
    FROM website_sessions
    WHERE website_session_id IS NOT NULL
    GROUP BY website_session_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT
    'website_pageviews.website_pageview_id',
    COUNT(*),
    COALESCE(SUM(row_count - 1), 0)
FROM (
    SELECT
        website_pageview_id,
        COUNT(*) AS row_count
    FROM website_pageviews
    WHERE website_pageview_id IS NOT NULL
    GROUP BY website_pageview_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT
    'orders.order_id',
    COUNT(*),
    COALESCE(SUM(row_count - 1), 0)
FROM (
    SELECT
        order_id,
        COUNT(*) AS row_count
    FROM orders
    WHERE order_id IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT
    'order_item_refunds.order_item_refund_id',
    COUNT(*),
    COALESCE(SUM(row_count - 1), 0)
FROM (
    SELECT
        order_item_refund_id,
        COUNT(*) AS row_count
    FROM order_item_refunds
    WHERE order_item_refund_id IS NOT NULL
    GROUP BY order_item_refund_id
    HAVING COUNT(*) > 1
) AS d;


-- =========================================================
-- 4. 核心字段 NULL 检查
-- =========================================================

SELECT
    'website_sessions' AS table_name,
    SUM(website_session_id IS NULL) AS primary_key_nulls,
    SUM(created_at IS NULL) AS created_at_nulls,
    SUM(user_id IS NULL) AS user_id_nulls,
    SUM(is_repeat_session IS NULL) AS is_repeat_session_nulls
FROM website_sessions;


SELECT
    'website_pageviews' AS table_name,
    SUM(website_pageview_id IS NULL) AS primary_key_nulls,
    SUM(created_at IS NULL) AS created_at_nulls,
    SUM(website_session_id IS NULL) AS website_session_id_nulls,
    SUM(pageview_url IS NULL) AS pageview_url_nulls
FROM website_pageviews;


SELECT
    'orders' AS table_name,
    SUM(order_id IS NULL) AS primary_key_nulls,
    SUM(created_at IS NULL) AS created_at_nulls,
    SUM(website_session_id IS NULL) AS website_session_id_nulls,
    SUM(user_id IS NULL) AS user_id_nulls,
    SUM(primary_product_id IS NULL) AS primary_product_id_nulls,
    SUM(items_purchased IS NULL) AS items_purchased_nulls,
    SUM(price_usd IS NULL) AS price_usd_nulls,
    SUM(cogs_usd IS NULL) AS cogs_usd_nulls
FROM orders;


SELECT
    'order_item_refunds' AS table_name,
    SUM(order_item_refund_id IS NULL) AS primary_key_nulls,
    SUM(created_at IS NULL) AS created_at_nulls,
    SUM(order_item_id IS NULL) AS order_item_id_nulls,
    SUM(order_id IS NULL) AS order_id_nulls,
    SUM(refund_amount_usd IS NULL) AS refund_amount_usd_nulls
FROM order_item_refunds;


-- =========================================================
-- 5. 外键完整性检查
-- orphan_rows：在父表中找不到对应记录的行数
-- =========================================================

SELECT
    'website_pageviews -> website_sessions' AS relationship,
    COUNT(*) AS orphan_rows
FROM website_pageviews AS p
LEFT JOIN website_sessions AS s
    ON p.website_session_id = s.website_session_id
WHERE p.website_session_id IS NOT NULL
  AND s.website_session_id IS NULL

UNION ALL

SELECT
    'orders -> website_sessions',
    COUNT(*)
FROM orders AS o
LEFT JOIN website_sessions AS s
    ON o.website_session_id = s.website_session_id
WHERE o.website_session_id IS NOT NULL
  AND s.website_session_id IS NULL

UNION ALL

SELECT
    'order_item_refunds -> orders',
    COUNT(*)
FROM order_item_refunds AS r
LEFT JOIN orders AS o
    ON r.order_id = o.order_id
WHERE r.order_id IS NOT NULL
  AND o.order_id IS NULL;


-- =========================================================
-- 6. device_type 取值和数量
-- =========================================================

SELECT
    device_type,
    COUNT(*) AS row_count
FROM website_sessions
GROUP BY device_type
ORDER BY row_count DESC;


-- =========================================================
-- 7. is_repeat_session 取值和数量
-- =========================================================

SELECT
    is_repeat_session,
    COUNT(*) AS row_count
FROM website_sessions
GROUP BY is_repeat_session
ORDER BY is_repeat_session;


-- =========================================================
-- 8. utm_source 取值和数量
-- NULL 在这里属于可能的正常业务情况，不直接判定为数据错误
-- =========================================================

SELECT
    utm_source,
    COUNT(*) AS row_count
FROM website_sessions
GROUP BY utm_source
ORDER BY row_count DESC;


-- =========================================================
-- 9. utm_campaign 取值和数量
-- NULL 在这里属于可能的正常业务情况，不直接判定为数据错误
-- =========================================================

SELECT
    utm_campaign,
    COUNT(*) AS row_count
FROM website_sessions
GROUP BY utm_campaign
ORDER BY row_count DESC;


-- =========================================================
-- 10. pageview_url 取值和数量
-- =========================================================

SELECT
    pageview_url,
    COUNT(*) AS row_count
FROM website_pageviews
GROUP BY pageview_url
ORDER BY row_count DESC;


-- =========================================================
-- 11. 数值字段基础合理性检查
-- 后续会使用 Revenue、AOV 和 Refund，因此检查基本异常值
-- =========================================================

SELECT
    SUM(items_purchased <= 0) AS invalid_items_purchased,
    SUM(price_usd <= 0) AS invalid_price_usd,
    SUM(cogs_usd < 0) AS invalid_cogs_usd
FROM orders;


SELECT
    SUM(refund_amount_usd <= 0) AS invalid_refund_amount_usd
FROM order_item_refunds;
