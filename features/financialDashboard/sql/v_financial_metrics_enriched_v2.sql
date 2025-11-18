-- Migration: Update v_financial_metrics_enriched view to separate leasing and consumption
-- Date: 2025-01-18
-- Author: Claude
-- Version: 2.0
--
-- Changes from v1:
-- 1. Added explicit leasing_revenue and consumption_revenue columns
-- 2. Added consumption_margin and consumption_margin_pct columns
-- 3. Separated leasing metrics from consumption metrics
-- 4. Total metrics remain for backward compatibility
--
-- Purpose: Enable toggle view between Leasing and Consumption in dashboard

DROP VIEW IF EXISTS v_financial_metrics_enriched CASCADE;

CREATE OR REPLACE VIEW v_financial_metrics_enriched AS
WITH
-- Base deployment info with date range
deployment_base AS (
  SELECT
    d.id as deployment_id,
    d.client_id,
    d.agent_type_id,
    at.name as agent_type_name,
    c.name as client_name,
    d.leasing,
    d.cost_per_min,
    d.cost_per_sms,
    d.cost_per_email,
    d.created_at as deployment_start_date,
    d.status as deployment_status,
    -- User permissions for RLS
    EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.client_id = d.client_id
        AND ucp.user_id = auth.uid()
    ) as user_has_access
  FROM agent_deployments d
  JOIN agent_types at ON d.agent_type_id = at.id
  JOIN clients c ON d.client_id = c.id
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

    -- === NEW: SEPARATED LEASING AND CONSUMPTION METRICS ===

    -- Pro-rated daily leasing revenue (100% margin, no provider cost)
    COALESCE(db.leasing / 30.0, 0) as leasing_revenue_daily,
    COALESCE(db.leasing / 30.0, 0) as leasing_margin_daily,  -- Same as revenue (100% margin)

    -- Consumption revenue (calls + sms + emails only, excluding leasing)
    COALESCE(cm.call_revenue, 0) +
    COALESCE(sm.sms_revenue, 0) +
    COALESCE(em.email_revenue, 0) as consumption_revenue,

    -- Consumption provider cost (calls + sms + emails)
    COALESCE(cm.call_provider_cost, 0) +
    COALESCE(sm.sms_provider_cost, 0) +
    COALESCE(em.email_provider_cost, 0) as consumption_provider_cost,

    -- Consumption margin (consumption revenue - consumption provider cost)
    (COALESCE(cm.call_revenue, 0) +
     COALESCE(sm.sms_revenue, 0) +
     COALESCE(em.email_revenue, 0)) -
    (COALESCE(cm.call_provider_cost, 0) +
     COALESCE(sm.sms_provider_cost, 0) +
     COALESCE(em.email_provider_cost, 0)) as consumption_margin,

    -- === END NEW COLUMNS ===

    -- Total revenue (leasing + consumption)
    COALESCE(cm.call_revenue, 0) +
    COALESCE(sm.sms_revenue, 0) +
    COALESCE(em.email_revenue, 0) +
    COALESCE(db.leasing / 30.0, 0) as total_revenue,

    -- Total provider cost (consumption only, no leasing cost)
    COALESCE(cm.call_provider_cost, 0) +
    COALESCE(sm.sms_provider_cost, 0) +
    COALESCE(em.email_provider_cost, 0) as total_provider_cost,

    -- Total margin (total revenue - provider cost)
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

-- Final view with margin percentages
SELECT
  *,

  -- Consumption margin percentage (consumption only)
  CASE
    WHEN consumption_revenue > 0 THEN (consumption_margin / consumption_revenue) * 100
    ELSE 0
  END as consumption_margin_pct,

  -- Total margin percentage (leasing + consumption)
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
'Unified financial metrics view (v2) with separated leasing and consumption metrics.
Aggregated by deployment and day for granular financial analysis.

NEW in v2:
- leasing_revenue_daily: Daily pro-rated leasing revenue
- leasing_margin_daily: Daily leasing margin (100% = same as revenue)
- consumption_revenue: Revenue from calls + SMS + emails only
- consumption_provider_cost: Provider costs for consumption only
- consumption_margin: Margin on consumption (revenue - provider cost)
- consumption_margin_pct: Margin percentage on consumption only

Legacy columns maintained for backward compatibility:
- total_revenue: leasing_revenue_daily + consumption_revenue
- total_provider_cost: consumption_provider_cost (no leasing cost)
- total_margin: total_revenue - total_provider_cost
- margin_percentage: total_margin / total_revenue * 100

RLS enforced via user_has_access column.';

-- ============================================================================
-- Verification queries
-- ============================================================================

/*
-- Test 1: Check new columns exist
SELECT
  deployment_id,
  metric_date,
  client_name,
  leasing_revenue_daily,
  consumption_revenue,
  consumption_provider_cost,
  consumption_margin,
  consumption_margin_pct,
  total_revenue,
  total_margin,
  margin_percentage
FROM v_financial_metrics_enriched
LIMIT 10;

-- Test 2: Verify separation (leasing + consumption = total)
SELECT
  metric_date,
  SUM(leasing_revenue_daily) as leasing_rev,
  SUM(consumption_revenue) as consumption_rev,
  SUM(leasing_revenue_daily + consumption_revenue) as calculated_total,
  SUM(total_revenue) as reported_total,
  CASE
    WHEN SUM(total_revenue) > 0
    THEN ROUND(ABS(SUM(leasing_revenue_daily + consumption_revenue) - SUM(total_revenue))::numeric, 2)
    ELSE 0
  END as difference
FROM v_financial_metrics_enriched
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY metric_date
ORDER BY metric_date DESC
LIMIT 30;

-- Test 3: Compare margin percentages
SELECT
  client_name,
  COUNT(DISTINCT metric_date) as days_active,
  ROUND(SUM(consumption_revenue)::numeric, 2) as consumption_revenue,
  ROUND(SUM(consumption_margin)::numeric, 2) as consumption_margin,
  ROUND(AVG(consumption_margin_pct)::numeric, 2) as avg_consumption_margin_pct,
  ROUND(SUM(leasing_revenue_daily)::numeric, 2) as leasing_revenue,
  ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
  ROUND(SUM(total_margin)::numeric, 2) as total_margin,
  ROUND(AVG(margin_percentage)::numeric, 2) as avg_total_margin_pct
FROM v_financial_metrics_enriched
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY client_name
ORDER BY total_revenue DESC;

-- Test 4: Clients with high leasing ratio
SELECT
  client_name,
  ROUND(SUM(leasing_revenue_daily)::numeric, 2) as leasing_revenue,
  ROUND(SUM(consumption_revenue)::numeric, 2) as consumption_revenue,
  ROUND(SUM(total_revenue)::numeric, 2) as total_revenue,
  CASE
    WHEN SUM(total_revenue) > 0
    THEN ROUND((SUM(leasing_revenue_daily) / SUM(total_revenue) * 100)::numeric, 2)
    ELSE 0
  END as leasing_percentage
FROM v_financial_metrics_enriched
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY client_name
HAVING SUM(total_revenue) > 0
ORDER BY leasing_percentage DESC;
*/
