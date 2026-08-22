-- Exposure validity audit for the reconstructed historical sample.
USE maven_fuzzy_factory;
DROP TABLE IF EXISTS experiment_exposure_audit;
CREATE TABLE experiment_exposure_audit AS
WITH user_session_counts AS (
 SELECT user_id,COUNT(*) experiment_sessions FROM experiment_session_profile GROUP BY user_id)
SELECT COUNT(*) experiment_sessions,COUNT(DISTINCT p.user_id) experiment_users,
SUM(p.billing_version='control') control_sessions,
SUM(p.billing_version='treatment') treatment_sessions,
SUM(p.session_cross_exposure_flag=1) session_cross_exposure_sessions,
COUNT(DISTINCT CASE WHEN p.user_cross_group_flag=1 THEN p.user_id END) cross_group_users,
SUM(p.user_cross_group_flag=1) sessions_from_cross_group_users,
COUNT(DISTINCT CASE WHEN u.experiment_sessions>1 THEN p.user_id END) multiple_experiment_session_users,
MIN(p.billing_exposure_at) first_exposure_at,MAX(p.billing_exposure_at) last_exposure_at
FROM experiment_session_profile p JOIN user_session_counts u ON p.user_id=u.user_id;
SELECT * FROM experiment_exposure_audit;
SELECT * FROM experiment_session_profile
WHERE session_cross_exposure_flag=1 OR user_cross_group_flag=1
ORDER BY user_id,billing_exposure_at;

-- SRM inputs and chi-square statistic for an expected 50/50 split.
-- The chi-square p-value is calculated in Python because MySQL has no
-- native chi-square CDF.
WITH group_counts AS (
 SELECT
  SUM(billing_version='control') control_sessions,
  SUM(billing_version='treatment') treatment_sessions,
  COUNT(*) total_sessions
 FROM experiment_session_profile)
SELECT control_sessions,treatment_sessions,
 control_sessions/total_sessions control_actual_share,
 treatment_sessions/total_sessions treatment_actual_share,
 0.5 control_expected_share,0.5 treatment_expected_share,
 POWER(control_sessions-total_sessions/2,2)/(total_sessions/2)
 +POWER(treatment_sessions-total_sessions/2,2)/(total_sessions/2)
 AS chi_square_statistic
FROM group_counts;

-- Category counts for covariate balance tests.
DROP TABLE IF EXISTS experiment_balance_counts;
CREATE TABLE experiment_balance_counts AS
SELECT 'device_type' covariate,COALESCE(device_type,'(missing)') category,
 SUM(billing_version='control') control_count,
 SUM(billing_version='treatment') treatment_count
FROM experiment_session_profile GROUP BY COALESCE(device_type,'(missing)')
UNION ALL
SELECT 'is_repeat_session',CAST(is_repeat_session AS CHAR),
 SUM(billing_version='control'),SUM(billing_version='treatment')
FROM experiment_session_profile GROUP BY is_repeat_session
UNION ALL
SELECT 'utm_source',COALESCE(utm_source,'(missing)'),
 SUM(billing_version='control'),SUM(billing_version='treatment')
FROM experiment_session_profile GROUP BY COALESCE(utm_source,'(missing)')
UNION ALL
SELECT 'utm_campaign',COALESCE(utm_campaign,'(missing)'),
 SUM(billing_version='control'),SUM(billing_version='treatment')
FROM experiment_session_profile GROUP BY COALESCE(utm_campaign,'(missing)')
UNION ALL
SELECT 'experiment_date',CAST(experiment_date AS CHAR),
 SUM(billing_version='control'),SUM(billing_version='treatment')
FROM experiment_session_profile GROUP BY experiment_date;

SELECT covariate,category,control_count,treatment_count,
 control_count/SUM(control_count) OVER(PARTITION BY covariate) control_share,
 treatment_count/SUM(treatment_count) OVER(PARTITION BY covariate) treatment_share,
 treatment_count/SUM(treatment_count) OVER(PARTITION BY covariate)
 -control_count/SUM(control_count) OVER(PARTITION BY covariate) share_difference
FROM experiment_balance_counts
ORDER BY covariate,category;
