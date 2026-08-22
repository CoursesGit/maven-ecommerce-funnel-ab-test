-- Schema and raw import. Historical dataset; no randomization claim.
CREATE DATABASE IF NOT EXISTS maven_fuzzy_factory CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE maven_fuzzy_factory;
CREATE TABLE website_sessions (
 website_session_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, created_at DATETIME NOT NULL,
 user_id BIGINT UNSIGNED NOT NULL, is_repeat_session TINYINT UNSIGNED NOT NULL,
 utm_source VARCHAR(50), utm_campaign VARCHAR(50), utm_content VARCHAR(100),
 device_type VARCHAR(20) NOT NULL, http_referer VARCHAR(255),
 INDEX idx_sessions_user(user_id), INDEX idx_sessions_created(created_at));
CREATE TABLE website_pageviews (
 website_pageview_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, created_at DATETIME NOT NULL,
 website_session_id BIGINT UNSIGNED NOT NULL, pageview_url VARCHAR(255) NOT NULL,
 INDEX idx_pageviews_session_order(website_session_id,website_pageview_id),
 INDEX idx_pageviews_experiment(pageview_url,created_at),
 CONSTRAINT fk_pageviews_session FOREIGN KEY(website_session_id)
 REFERENCES website_sessions(website_session_id));
CREATE TABLE orders (
 order_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, created_at DATETIME NOT NULL,
 website_session_id BIGINT UNSIGNED NOT NULL, user_id BIGINT UNSIGNED NOT NULL,
 primary_product_id BIGINT UNSIGNED NOT NULL, items_purchased INT UNSIGNED NOT NULL,
 price_usd DECIMAL(10,2) NOT NULL, cogs_usd DECIMAL(10,2) NOT NULL,
 UNIQUE KEY uq_orders_session(website_session_id), INDEX idx_orders_user(user_id),
 CONSTRAINT fk_orders_session FOREIGN KEY(website_session_id)
 REFERENCES website_sessions(website_session_id));
CREATE TABLE order_item_refunds (
 order_item_refund_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, created_at DATETIME NOT NULL,
 order_item_id BIGINT UNSIGNED NOT NULL, order_id BIGINT UNSIGNED NOT NULL,
 refund_amount_usd DECIMAL(10,2) NOT NULL, INDEX idx_refunds_order(order_id),
 CONSTRAINT fk_refunds_order FOREIGN KEY(order_id) REFERENCES orders(order_id));
-- Replace /ABSOLUTE/PATH/TO/maven_ecommerce_ab with the local project directory.
-- MySQL LOAD DATA LOCAL INFILE requires a path accessible to the client.
LOAD DATA LOCAL INFILE '/ABSOLUTE/PATH/TO/maven_ecommerce_ab/data/raw/website_sessions.csv'
INTO TABLE website_sessions CHARACTER SET utf8mb4 FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE '/ABSOLUTE/PATH/TO/maven_ecommerce_ab/data/raw/website_pageviews.csv'
INTO TABLE website_pageviews CHARACTER SET utf8mb4 FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE '/ABSOLUTE/PATH/TO/maven_ecommerce_ab/data/raw/orders.csv'
INTO TABLE orders CHARACTER SET utf8mb4 FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE '/ABSOLUTE/PATH/TO/maven_ecommerce_ab/data/raw/order_item_refunds.csv'
INTO TABLE order_item_refunds CHARACTER SET utf8mb4 FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
SELECT 'website_sessions' table_name,COUNT(*) row_count FROM website_sessions
UNION ALL SELECT 'website_pageviews',COUNT(*) FROM website_pageviews
UNION ALL SELECT 'orders',COUNT(*) FROM orders
UNION ALL SELECT 'order_item_refunds',COUNT(*) FROM order_item_refunds;
