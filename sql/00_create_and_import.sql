-- Maven Fuzzy Factory：建库、建表和原始数据导入
-- 运行前请确认客户端允许 LOAD DATA LOCAL INFILE。
-- 本脚本不删除、不清空已有表；同名表已存在时会停止，避免覆盖原始数据。

CREATE DATABASE IF NOT EXISTS maven_fuzzy_factory
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE maven_fuzzy_factory;

CREATE TABLE website_sessions (
    website_session_id BIGINT UNSIGNED,
    created_at DATETIME,
    user_id BIGINT UNSIGNED,
    is_repeat_session TINYINT UNSIGNED,
    utm_source VARCHAR(50),
    utm_campaign VARCHAR(50),
    utm_content VARCHAR(100),
    device_type VARCHAR(20),
    http_referer VARCHAR(255)
);

CREATE TABLE website_pageviews (
    website_pageview_id BIGINT UNSIGNED,
    created_at DATETIME,
    website_session_id BIGINT UNSIGNED,
    pageview_url VARCHAR(255)
);

CREATE TABLE orders (
    order_id BIGINT UNSIGNED,
    created_at DATETIME,
    website_session_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    primary_product_id BIGINT UNSIGNED,
    items_purchased INT UNSIGNED,
    price_usd DECIMAL(10,2),
    cogs_usd DECIMAL(10,2)
);

CREATE TABLE order_item_refunds (
    order_item_refund_id BIGINT UNSIGNED,
    created_at DATETIME,
    order_item_id BIGINT UNSIGNED,
    order_id BIGINT UNSIGNED,
    refund_amount_usd DECIMAL(10,2)
);

-- 空字符串按缺失值导入；不改变原始 CSV。
LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Desktop/data/website_sessions.csv'
INTO TABLE website_sessions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@website_session_id, @created_at, @user_id, @is_repeat_session,
 @utm_source, @utm_campaign, @utm_content, @device_type, @http_referer)
SET
    website_session_id = NULLIF(@website_session_id, ''),
    created_at = NULLIF(@created_at, ''),
    user_id = NULLIF(@user_id, ''),
    is_repeat_session = NULLIF(@is_repeat_session, ''),
    utm_source = NULLIF(@utm_source, ''),
    utm_campaign = NULLIF(@utm_campaign, ''),
    utm_content = NULLIF(@utm_content, ''),
    device_type = NULLIF(@device_type, ''),
    http_referer = NULLIF(@http_referer, '');

LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Desktop/data/website_pageviews.csv'
INTO TABLE website_pageviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@website_pageview_id, @created_at, @website_session_id, @pageview_url)
SET
    website_pageview_id = NULLIF(@website_pageview_id, ''),
    created_at = NULLIF(@created_at, ''),
    website_session_id = NULLIF(@website_session_id, ''),
    pageview_url = NULLIF(@pageview_url, '');

LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Desktop/data/orders.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@order_id, @created_at, @website_session_id, @user_id,
 @primary_product_id, @items_purchased, @price_usd, @cogs_usd)
SET
    order_id = NULLIF(@order_id, ''),
    created_at = NULLIF(@created_at, ''),
    website_session_id = NULLIF(@website_session_id, ''),
    user_id = NULLIF(@user_id, ''),
    primary_product_id = NULLIF(@primary_product_id, ''),
    items_purchased = NULLIF(@items_purchased, ''),
    price_usd = NULLIF(@price_usd, ''),
    cogs_usd = NULLIF(@cogs_usd, '');

LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Desktop/data/order_item_refunds.csv'
INTO TABLE order_item_refunds
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@order_item_refund_id, @created_at, @order_item_id, @order_id,
 @refund_amount_usd)
SET
    order_item_refund_id = NULLIF(@order_item_refund_id, ''),
    created_at = NULLIF(@created_at, ''),
    order_item_id = NULLIF(@order_item_id, ''),
    order_id = NULLIF(@order_id, ''),
    refund_amount_usd = NULLIF(@refund_amount_usd, '');

-- 导入完成后仅返回四张表的数据量。
SELECT 'website_sessions' AS table_name, COUNT(*) AS row_count FROM website_sessions
UNION ALL
SELECT 'website_pageviews', COUNT(*) FROM website_pageviews
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_item_refunds', COUNT(*) FROM order_item_refunds;
