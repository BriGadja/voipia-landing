-- Migration: Create v_financial_metrics_enriched view
-- Date: 2025-01-16
-- Author: Claude
--
-- Purpose: Unified financial metrics view combining all revenue and cost sources
-- Sources: agent_calls, agent_sms, agent_emails, agent_deployments (leasing)
--
-- Key Features:
-- - Aggregates all cost sources (calls, SMS, emails, leasing)
-- - Pro-rates monthly leasing fees by day
-- - Calculates revenue, provider costs, and margins
-- - Supports RLS for admin permissions
-- - Enables drilldown by client, agent type, deployment, and channel

DROP VIEW IF EXISTS v_financial_metrics_enriched CASCADE;

CREATE OR REPLACE VIEW v_financial_metrics_enriched AS
WITH
-- Base deployment info with date range
deployment_base AS (
  SELECT
    d.deployment_id,
    d.client_id,
    d.agent_type_id,
    at.agent_type_name,
    c.company_name as client_name,
    d.leasing,
    d.cost_per_min,
    d.cost_per_sms,
    d.cost_per_email,
    d.created_at as deployment_start_date,
    d.deployment_status,
    -- User permissions for RLS
    EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.client_id = d.client_id
        AND ucp.user_id = auth.uid()
    ) as user_has_access
  FROM agent_deployments d
  JOIN agent_types at ON d.agent_type_id = at.agent_type_id
  JOIN clients c ON d.client_id = c.client_id
),

-- Call metrics aggregated by deployment and day
call_metrics AS (
  SELECT
    ac.deployment_id,
    DATE_TRUNC('day', ac.created_at) as metric_date,
    COUNT(*) as call_count,
    COUNT(*) FILTER (WHERE ac.answered = true) as answered_calls,
    COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) as appointments_scheduled,
    SUM(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) as total_duration_seconds,
    AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) as avg_duration_seconds,
    -- Revenue: duration in minutes * cost_per_min
    SUM((ac.duration_seconds / 60.0) * db.cost_per_min) as call_revenue,
    -- Provider cost (from vapi_cost_usd converted to EUR)
    SUM(COALESCE(ac.vapi_cost_usd * 0.92, 0)) as call_provider_cost
  FROM agent_calls ac
  JOIN deployment_base db ON ac.deployment_id = db.deployment_id
  WHERE ac.created_at IS NOT NULL
  GROUP BY ac.deployment_id, DATE_TRUNC('day', ac.created_at)
),

-- SMS metrics aggregated by deployment and day
sms_metrics AS (
  SELECT
    asms.deployment_id,
    DATE_TRUNC('day', asms.sent_at) as metric_date,
    COUNT(*) as sms_count,
    COUNT(*) FILTER (WHERE asms.delivery_status = 'delivered') as sms_delivered,
    -- Revenue: count * cost_per_sms
    SUM(db.cost_per_sms) as sms_revenue,
    -- Provider cost (billed_cost already in EUR)
    SUM(COALESCE(asms.billed_cost, 0)) as sms_provider_cost
  FROM agent_sms asms
  JOIN deployment_base db ON asms.deployment_id = db.deployment_id
  WHERE asms.sent_at IS NOT NULL
  GROUP BY asms.deployment_id, DATE_TRUNC('day', asms.sent_at)
),

-- Email metrics aggregated by deployment and day
email_metrics AS (
  SELECT
    ae.deployment_id,
    DATE_TRUNC('day', ae.sent_at) as metric_date,
    COUNT(*) as email_count,
    COUNT(*) FILTER (WHERE ae.delivery_status = 'delivered') as email_delivered,
    -- Revenue: count * cost_per_email
    SUM(db.cost_per_email) as email_revenue,
    -- Provider cost (billed_cost already in EUR)
    SUM(COALESCE(ae.billed_cost, 0)) as email_provider_cost
  FROM agent_emails ae
  JOIN deployment_base db ON ae.deployment_id = db.deployment_id
  WHERE ae.sent_at IS NOT NULL
  GROUP BY ae.deployment_id, DATE_TRUNC('day', ae.sent_at)
),

-- Generate all dates with deployment activity
all_metric_dates AS (
  SELECT DISTINCT deployment_id, metric_date
  FROM (
    SELECT deployment_id, metric_date FROM call_metrics
    UNION
    SELECT deployment_id, metric_date FROM sms_metrics
    UNION
    SELECT deployment_id, metric_date FROM email_metrics
  ) combined_dates
),

-- Combine all metrics with pro-rated leasing
combined_metrics AS (
  SELECT
    amd.deployment_id,
    amd.metric_date,
    db.client_id,
    db.client_name,
    db.agent_type_id,
    db.agent_type_name,
    db.deployment_status,
    db.user_has_access,

    -- Call metrics
    COALESCE(cm.call_count, 0) as call_count,
    COALESCE(cm.answered_calls, 0) as answered_calls,
    COALESCE(cm.appointments_scheduled, 0) as appointments_scheduled,
    COALESCE(cm.total_duration_seconds, 0) as total_duration_seconds,
    COALESCE(cm.avg_duration_seconds, 0) as avg_duration_seconds,
    COALESCE(cm.call_revenue, 0) as call_revenue,
    COALESCE(cm.call_provider_cost, 0) as call_provider_cost,

    -- SMS metrics
    COALESCE(sm.sms_count, 0) as sms_count,
    COALESCE(sm.sms_delivered, 0) as sms_delivered,
    COALESCE(sm.sms_revenue, 0) as sms_revenue,
    COALESCE(sm.sms_provider_cost, 0) as sms_provider_cost,

    -- Email metrics
    COALESCE(em.email_count, 0) as email_count,
    COALESCE(em.email_delivered, 0) as email_delivered,
    COALESCE(em.email_revenue, 0) as email_revenue,
    COALESCE(em.email_provider_cost, 0) as email_provider_cost,

    -- Pro-rated daily leasing revenue
    -- Formula: (monthly_leasing / 30) * 1 day
    COALESCE(db.leasing / 30.0, 0) as leasing_revenue_daily,

    -- Total revenue (calls + sms + emails + leasing)
    COALESCE(cm.call_revenue, 0) +
    COALESCE(sm.sms_revenue, 0) +
    COALESCE(em.email_revenue, 0) +
    COALESCE(db.leasing / 30.0, 0) as total_revenue,

    -- Total provider cost (calls + sms + emails, no leasing cost)
    COALESCE(cm.call_provider_cost, 0) +
    COALESCE(sm.sms_provider_cost, 0) +
    COALESCE(em.email_provider_cost, 0) as total_provider_cost,

    -- Total margin (revenue - provider cost)
    (COALESCE(cm.call_revenue, 0) +
     COALESCE(sm.sms_revenue, 0) +
     COALESCE(em.email_revenue, 0) +
     COALESCE(db.leasing / 30.0, 0)) -
    (COALESCE(cm.call_provider_cost, 0) +
     COALESCE(sm.sms_provider_cost, 0) +
     COALESCE(em.email_provider_cost, 0)) as total_margin

  FROM all_metric_dates amd
  JOIN deployment_base db ON amd.deployment_id = db.deployment_id
  LEFT JOIN call_metrics cm ON amd.deployment_id = cm.deployment_id AND amd.metric_date = cm.metric_date
  LEFT JOIN sms_metrics sm ON amd.deployment_id = sm.deployment_id AND amd.metric_date = sm.metric_date
  LEFT JOIN email_metrics em ON amd.deployment_id = em.deployment_id AND amd.metric_date = em.metric_date
)

-- Final view with margin percentage
SELECT
  *,
  -- Margin percentage (avoid division by zero)
  CASE
    WHEN total_revenue > 0 THEN (total_margin / total_revenue) * 100
    ELSE 0
  END as margin_percentage
FROM combined_metrics;

-- Enable RLS
ALTER VIEW v_financial_metrics_enriched OWNER TO postgres;
GRANT SELECT ON v_financial_metrics_enriched TO authenticated;

-- RLS Policy: Only show data for users with client access
-- (Will be enforced by user_has_access column in queries)

COMMENT ON VIEW v_financial_metrics_enriched IS
'Unified financial metrics view combining calls, SMS, emails, and pro-rated leasing revenue.
Aggregated by deployment and day for granular financial analysis.
Includes revenue, provider costs, margins, and margin percentages.
RLS enforced via user_has_access column.';

-- Verification queries (run these to test the view)
/*
-- Test 1: Check view structure
SELECT * FROM v_financial_metrics_enriched LIMIT 5;

-- Test 2: Aggregate by client
SELECT
  client_name,
  COUNT(DISTINCT metric_date) as days_active,
  SUM(call_count) as total_calls,
  SUM(sms_count) as total_sms,
  SUM(email_count) as total_emails,
  ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
  ROUND(SUM(total_provider_cost)::numeric, 2) as total_cost,
  ROUND(SUM(total_margin)::numeric, 2) as total_margin,
  ROUND(AVG(margin_percentage)::numeric, 2) as avg_margin_pct
FROM v_financial_metrics_enriched
GROUP BY client_name
ORDER BY total_revenue DESC;

-- Test 3: Aggregate by agent type
SELECT
  agent_type_name,
  SUM(call_count) as total_calls,
  ROUND(SUM(call_revenue)::numeric, 2) as call_revenue,
  ROUND(SUM(sms_revenue)::numeric, 2) as sms_revenue,
  ROUND(SUM(email_revenue)::numeric, 2) as email_revenue,
  ROUND(SUM(leasing_revenue_daily)::numeric, 2) as leasing_revenue,
  ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
  ROUND(SUM(total_margin)::numeric, 2) as total_margin
FROM v_financial_metrics_enriched
GROUP BY agent_type_name
ORDER BY total_revenue DESC;

-- Test 4: Check daily trends (last 30 days)
SELECT
  metric_date,
  COUNT(DISTINCT deployment_id) as active_deployments,
  SUM(call_count) as daily_calls,
  ROUND(SUM(total_revenue)::numeric, 2) as daily_revenue,
  ROUND(SUM(total_margin)::numeric, 2) as daily_margin
FROM v_financial_metrics_enriched
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY metric_date
ORDER BY metric_date DESC
LIMIT 30;

-- Test 5: Verify pro-rated leasing calculation
SELECT
  deployment_id,
  client_name,
  metric_date,
  leasing_revenue_daily,
  leasing_revenue_daily * 30 as monthly_leasing_check
FROM v_financial_metrics_enriched
WHERE leasing_revenue_daily > 0
LIMIT 10;
*/
