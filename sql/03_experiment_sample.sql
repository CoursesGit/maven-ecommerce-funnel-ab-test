-- Reconstruct the historical Billing Page experiment from observed exposure.
-- No randomization log or pre-analysis plan is available.
USE maven_fuzzy_factory;
SET @experiment_start=TIMESTAMP('2012-09-10 00:00:00');
SET @experiment_end=TIMESTAMP('2012-11-10 00:00:00');
DROP TABLE IF EXISTS experiment_session_profile;
CREATE TABLE experiment_session_profile AS
WITH billing_exposures AS (
 SELECT p.website_session_id,p.website_pageview_id,p.created_at,p.pageview_url,
 ROW_NUMBER() OVER(PARTITION BY p.website_session_id ORDER BY p.website_pageview_id) exposure_order
 FROM website_pageviews p WHERE p.created_at>=@experiment_start AND p.created_at<@experiment_end
 AND p.pageview_url IN('/billing','/billing-2')),
session_exposure_summary AS (
 SELECT website_session_id,COUNT(DISTINCT pageview_url) versions_seen_in_session
 FROM billing_exposures GROUP BY website_session_id),
first_exposure AS (
 SELECT b.website_session_id,b.website_pageview_id billing_pageview_id,
 b.created_at billing_exposure_at,DATE(b.created_at) experiment_date,
 CASE WHEN b.pageview_url='/billing' THEN 'control' ELSE 'treatment' END billing_version,
 CASE WHEN x.versions_seen_in_session>1 THEN 1 ELSE 0 END session_cross_exposure_flag
 FROM billing_exposures b JOIN session_exposure_summary x USING(website_session_id)
 WHERE b.exposure_order=1),
user_exposure AS (
 SELECT s.user_id,COUNT(DISTINCT e.billing_version) versions_seen_by_user
 FROM first_exposure e JOIN website_sessions s USING(website_session_id) GROUP BY s.user_id),
orders_after AS (
 SELECT e.website_session_id,MAX(o.order_id) order_id,COUNT(o.order_id) order_count,
 COALESCE(SUM(o.price_usd),0) gross_revenue
 FROM first_exposure e LEFT JOIN orders o ON e.website_session_id=o.website_session_id
 AND o.created_at>=e.billing_exposure_at GROUP BY e.website_session_id),
refunds_by_order AS (
 SELECT order_id,SUM(refund_amount_usd) refund_amount FROM order_item_refunds GROUP BY order_id)
SELECT e.website_session_id,s.user_id,e.billing_version,e.billing_pageview_id,
e.billing_exposure_at,e.experiment_date,s.device_type,s.is_repeat_session,
s.utm_source,s.utm_campaign,e.session_cross_exposure_flag,
CASE WHEN u.versions_seen_by_user>1 THEN 1 ELSE 0 END user_cross_group_flag,
CASE WHEN o.order_count>0 THEN 1 ELSE 0 END purchased,o.order_id,
CAST(o.gross_revenue AS DECIMAL(12,2)) gross_revenue,
CAST(COALESCE(r.refund_amount,0) AS DECIMAL(12,2)) refund_amount,
CAST(o.gross_revenue-COALESCE(r.refund_amount,0) AS DECIMAL(12,2)) net_revenue,
CASE WHEN COALESCE(r.refund_amount,0)>0 THEN 1 ELSE 0 END refunded_order_flag
FROM first_exposure e JOIN website_sessions s USING(website_session_id)
JOIN user_exposure u ON s.user_id=u.user_id JOIN orders_after o USING(website_session_id)
LEFT JOIN refunds_by_order r ON o.order_id=r.order_id;
ALTER TABLE experiment_session_profile ADD PRIMARY KEY(website_session_id),
 ADD INDEX idx_experiment_user(user_id),
 ADD INDEX idx_experiment_group_date(billing_version,experiment_date);
SELECT COUNT(*) sessions_with_multiple_post_exposure_orders FROM(
 SELECT e.website_session_id FROM experiment_session_profile e JOIN orders o
 ON e.website_session_id=o.website_session_id AND o.created_at>=e.billing_exposure_at
 GROUP BY e.website_session_id HAVING COUNT(*)>1)x;
SELECT * FROM experiment_session_profile ORDER BY billing_pageview_id;
