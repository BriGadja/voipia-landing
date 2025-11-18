-- ============================================================================
-- Migration: Separate Leasing and Consumption Metrics - Phase 1 (FIXED)
-- Date: 2025-01-18
-- Author: Claude
-- Version: 1.1
-- ============================================================================
--
-- Purpose: Add capability to separate leasing revenue (100% margin) from
--          consumption revenue (variable margin based on provider costs)
--
-- Changes:
-- 1. Update v_financial_metrics_enriched view with separated columns
-- 2. Create get_leasing_kpi_metrics function
-- 3. Create get_consumption_kpi_metrics function
-- 4. Create get_consumption_pricing_by_agent function
--
-- FIXES from v1.0:
-- - Use v_agent_calls_enriched instead of agent_calls (for answered, appointment_scheduled)
-- - Use total_cost instead of vapi_cost_usd (already in EUR)
-- - Use status instead of delivery_status for SMS/emails
-- - Count SMS/emails via JOIN instead of assuming columns exist
--
-- Impact: Backward compatible - existing columns maintained
-- ============================================================================

-- ============================================================================
-- PART 1: Update v_financial_metrics_enriched view (v2)
-- ============================================================================

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

-- Call metrics aggregated by deployment and day (using enriched view)
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
    -- Provider cost: use total_cost (already in EUR, no conversion needed)
    SUM(COALESCE(ac.total_cost, 0)) as call_provider_cost
  FROM v_agent_calls_enriched ac
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
    COUNT(*) FILTER (WHERE asms.status = 'delivered') as sms_delivered,
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
    COUNT(*) FILTER (WHERE ae.status = 'delivered') as email_delivered,
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

    -- Total revenue (leasing + consumption) - BACKWARD COMPATIBLE
    COALESCE(cm.call_revenue, 0) +
    COALESCE(sm.sms_revenue, 0) +
    COALESCE(em.email_revenue, 0) +
    COALESCE(db.leasing / 30.0, 0) as total_revenue,

    -- Total provider cost (consumption only, no leasing cost) - BACKWARD COMPATIBLE
    COALESCE(cm.call_provider_cost, 0) +
    COALESCE(sm.sms_provider_cost, 0) +
    COALESCE(em.email_provider_cost, 0) as total_provider_cost,

    -- Total margin (total revenue - provider cost) - BACKWARD COMPATIBLE
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

  -- NEW: Consumption margin percentage (consumption only)
  CASE
    WHEN consumption_revenue > 0 THEN (consumption_margin / consumption_revenue) * 100
    ELSE 0
  END as consumption_margin_pct,

  -- BACKWARD COMPATIBLE: Total margin percentage (leasing + consumption)
  CASE
    WHEN total_revenue > 0 THEN (total_margin / total_revenue) * 100
    ELSE 0
  END as margin_percentage

FROM combined_metrics;

-- Grant permissions
ALTER VIEW v_financial_metrics_enriched OWNER TO postgres;
GRANT SELECT ON v_financial_metrics_enriched TO authenticated;

COMMENT ON VIEW v_financial_metrics_enriched IS
'Unified financial metrics view (v2) with separated leasing and consumption metrics.
NEW in v2: leasing_revenue_daily, consumption_revenue, consumption_margin, consumption_margin_pct.
Legacy columns (total_revenue, total_margin, margin_percentage) maintained for backward compatibility.';

-- ============================================================================
-- PART 2: Create get_leasing_kpi_metrics function
-- ============================================================================

DROP FUNCTION IF EXISTS get_leasing_kpi_metrics(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_leasing_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_duration_days INTEGER;
BEGIN
  v_duration_days := p_end_date - p_start_date + 1;

  SELECT JSONB_BUILD_OBJECT(
    'total_leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
    'active_leasing_count', COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END),
    'avg_leasing_per_client', CASE
      WHEN COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN client_id ELSE NULL END) > 0
      THEN ROUND((SUM(leasing_revenue_daily) /
                  COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN client_id ELSE NULL END))::numeric, 2)
      ELSE 0
    END,
    'mrr', CASE
      WHEN v_duration_days > 0
      THEN ROUND((SUM(leasing_revenue_daily) / v_duration_days * 30)::numeric, 2)
      ELSE 0
    END,
    'avg_monthly_leasing', CASE
      WHEN COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END) > 0
        AND v_duration_days > 0
      THEN ROUND((
        (SUM(leasing_revenue_daily) / v_duration_days * 30) /
        COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END)
      )::numeric, 2)
      ELSE 0
    END,
    'leasing_client_count', COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN client_id ELSE NULL END),
    'leasing_adoption_rate', CASE
      WHEN COUNT(DISTINCT deployment_id) > 0
      THEN ROUND((
        COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END)::numeric /
        COUNT(DISTINCT deployment_id) * 100
      )::numeric, 2)
      ELSE 0
    END,
    'total_leasing_margin', COALESCE(SUM(leasing_margin_daily), 0),
    'leasing_margin_pct', 100
  ) INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true;

  RETURN COALESCE(v_result, JSONB_BUILD_OBJECT(
    'total_leasing_revenue', 0, 'active_leasing_count', 0, 'avg_leasing_per_client', 0,
    'mrr', 0, 'avg_monthly_leasing', 0, 'leasing_client_count', 0,
    'leasing_adoption_rate', 0, 'total_leasing_margin', 0, 'leasing_margin_pct', 100
  ));
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_leasing_kpi_metrics(DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_leasing_kpi_metrics IS
  'Returns KPI metrics for leasing/subscription revenue only (100% margin).';

-- ============================================================================
-- PART 3: Create get_consumption_kpi_metrics function
-- ============================================================================

DROP FUNCTION IF EXISTS get_consumption_kpi_metrics(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_consumption_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT JSONB_BUILD_OBJECT(
    -- Revenue & Margin
    'total_consumption_revenue', COALESCE(SUM(consumption_revenue), 0),
    'total_provider_cost', COALESCE(SUM(consumption_provider_cost), 0),
    'total_consumption_margin', COALESCE(SUM(consumption_margin), 0),
    'consumption_margin_pct', CASE
      WHEN SUM(consumption_revenue) > 0
      THEN ROUND((SUM(consumption_margin) / SUM(consumption_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- Volumes
    'total_calls', COALESCE(SUM(call_count), 0),
    'total_sms', COALESCE(SUM(sms_count), 0),
    'total_emails', COALESCE(SUM(email_count), 0),
    'total_answered_calls', COALESCE(SUM(answered_calls), 0),
    'total_appointments', COALESCE(SUM(appointments_scheduled), 0),

    -- Call breakdown
    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'call_margin', COALESCE(SUM(call_revenue - call_provider_cost), 0),
    'call_margin_pct', CASE
      WHEN SUM(call_revenue) > 0
      THEN ROUND(((SUM(call_revenue) - SUM(call_provider_cost)) / SUM(call_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- SMS breakdown
    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'sms_margin', COALESCE(SUM(sms_revenue - sms_provider_cost), 0),
    'sms_margin_pct', CASE
      WHEN SUM(sms_revenue) > 0
      THEN ROUND(((SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- Email breakdown
    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'email_margin', COALESCE(SUM(email_revenue - email_provider_cost), 0),
    'email_margin_pct', CASE
      WHEN SUM(email_revenue) > 0
      THEN ROUND(((SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- Unit pricing
    'avg_cost_per_minute', CASE
      WHEN SUM(total_duration_seconds) > 0
      THEN ROUND((SUM(call_provider_cost) / (SUM(total_duration_seconds) / 60.0))::numeric, 4)
      ELSE 0
    END,
    'avg_cost_per_sms', CASE
      WHEN SUM(sms_count) > 0
      THEN ROUND((SUM(sms_provider_cost) / SUM(sms_count))::numeric, 4)
      ELSE 0
    END,
    'avg_cost_per_email', CASE
      WHEN SUM(email_count) > 0
      THEN ROUND((SUM(email_provider_cost) / SUM(email_count))::numeric, 4)
      ELSE 0
    END,
    'avg_revenue_per_minute', CASE
      WHEN SUM(total_duration_seconds) > 0
      THEN ROUND((SUM(call_revenue) / (SUM(total_duration_seconds) / 60.0))::numeric, 4)
      ELSE 0
    END,
    'avg_revenue_per_sms', CASE
      WHEN SUM(sms_count) > 0
      THEN ROUND((SUM(sms_revenue) / SUM(sms_count))::numeric, 4)
      ELSE 0
    END,
    'avg_revenue_per_email', CASE
      WHEN SUM(email_count) > 0
      THEN ROUND((SUM(email_revenue) / SUM(email_count))::numeric, 4)
      ELSE 0
    END,

    -- Business metrics
    'avg_consumption_per_client', CASE
      WHEN COUNT(DISTINCT client_id) > 0
      THEN ROUND((SUM(consumption_revenue) / COUNT(DISTINCT client_id))::numeric, 2)
      ELSE 0
    END,
    'consumption_client_count', COUNT(DISTINCT client_id),
    'active_deployment_count', COUNT(DISTINCT deployment_id)
  ) INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true
    AND consumption_revenue > 0;

  RETURN COALESCE(v_result, JSONB_BUILD_OBJECT(
    'total_consumption_revenue', 0, 'total_provider_cost', 0, 'total_consumption_margin', 0,
    'consumption_margin_pct', 0, 'total_calls', 0, 'total_sms', 0, 'total_emails', 0,
    'total_answered_calls', 0, 'total_appointments', 0
  ));
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_consumption_kpi_metrics(DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_consumption_kpi_metrics IS
  'Returns KPI metrics for consumption/usage revenue only (calls, SMS, emails).';

-- ============================================================================
-- PART 4: Create get_consumption_pricing_by_agent function
-- ============================================================================

DROP FUNCTION IF EXISTS get_consumption_pricing_by_agent(DATE, DATE, UUID);
DROP FUNCTION IF EXISTS get_consumption_pricing_by_agent(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_consumption_pricing_by_agent(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'deployment_id', deployment_id,
      'deployment_name', deployment_name,
      'client_name', client_name,
      'agent_type_name', agent_type_name,
      'agent_type_label', agent_type_label,
      'status', status,
      'call_metrics', JSONB_BUILD_OBJECT(
        'total_calls', COALESCE(total_calls, 0),
        'answered_calls', COALESCE(answered_calls, 0),
        'total_minutes', COALESCE(total_minutes, 0),
        'cost_per_minute_provider', CASE
          WHEN COALESCE(total_minutes, 0) > 0
          THEN ROUND((COALESCE(call_provider_cost, 0) / total_minutes)::numeric, 4)
          ELSE 0
        END,
        'price_per_minute_charged', COALESCE(price_per_minute, 0),
        'margin_per_minute', CASE
          WHEN COALESCE(total_minutes, 0) > 0
          THEN ROUND((COALESCE(price_per_minute, 0) - (COALESCE(call_provider_cost, 0) / total_minutes))::numeric, 4)
          ELSE 0
        END,
        'margin_pct_calls', CASE
          WHEN COALESCE(call_revenue, 0) > 0
          THEN ROUND(((call_revenue - call_provider_cost) / call_revenue * 100)::numeric, 2)
          ELSE 0
        END,
        'total_call_revenue', COALESCE(call_revenue, 0),
        'total_call_cost', COALESCE(call_provider_cost, 0),
        'total_call_margin', COALESCE(call_revenue - call_provider_cost, 0)
      ),
      'sms_metrics', JSONB_BUILD_OBJECT(
        'total_sms_sent', COALESCE(total_sms, 0),
        'sms_delivered', COALESCE(sms_delivered, 0),
        'cost_per_sms_provider', CASE
          WHEN COALESCE(total_sms, 0) > 0
          THEN ROUND((COALESCE(sms_provider_cost, 0) / total_sms)::numeric, 4)
          ELSE 0
        END,
        'price_per_sms_charged', COALESCE(price_per_sms, 0),
        'margin_per_sms', CASE
          WHEN COALESCE(total_sms, 0) > 0
          THEN ROUND((COALESCE(price_per_sms, 0) - (COALESCE(sms_provider_cost, 0) / total_sms))::numeric, 4)
          ELSE 0
        END,
        'margin_pct_sms', CASE
          WHEN COALESCE(sms_revenue, 0) > 0
          THEN ROUND(((sms_revenue - sms_provider_cost) / sms_revenue * 100)::numeric, 2)
          ELSE 0
        END,
        'total_sms_revenue', COALESCE(sms_revenue, 0),
        'total_sms_cost', COALESCE(sms_provider_cost, 0),
        'total_sms_margin', COALESCE(sms_revenue - sms_provider_cost, 0)
      ),
      'email_metrics', JSONB_BUILD_OBJECT(
        'total_emails_sent', COALESCE(total_emails, 0),
        'emails_delivered', COALESCE(emails_delivered, 0),
        'cost_per_email_provider', CASE
          WHEN COALESCE(total_emails, 0) > 0
          THEN ROUND((COALESCE(email_provider_cost, 0) / total_emails)::numeric, 4)
          ELSE 0
        END,
        'price_per_email_charged', COALESCE(price_per_email, 0),
        'margin_per_email', CASE
          WHEN COALESCE(total_emails, 0) > 0
          THEN ROUND((COALESCE(price_per_email, 0) - (COALESCE(email_provider_cost, 0) / total_emails))::numeric, 4)
          ELSE 0
        END,
        'margin_pct_emails', CASE
          WHEN COALESCE(email_revenue, 0) > 0
          THEN ROUND(((email_revenue - email_provider_cost) / email_revenue * 100)::numeric, 2)
          ELSE 0
        END,
        'total_email_revenue', COALESCE(email_revenue, 0),
        'total_email_cost', COALESCE(email_provider_cost, 0),
        'total_email_margin', COALESCE(email_revenue - email_provider_cost, 0)
      ),
      'total_consumption', JSONB_BUILD_OBJECT(
        'total_consumption_revenue', COALESCE(call_revenue + sms_revenue + email_revenue, 0),
        'total_consumption_cost', COALESCE(call_provider_cost + sms_provider_cost + email_provider_cost, 0),
        'total_consumption_margin', COALESCE(
          (call_revenue + sms_revenue + email_revenue) -
          (call_provider_cost + sms_provider_cost + email_provider_cost), 0
        ),
        'consumption_margin_pct', CASE
          WHEN COALESCE(call_revenue + sms_revenue + email_revenue, 0) > 0
          THEN ROUND((
            ((call_revenue + sms_revenue + email_revenue) -
             (call_provider_cost + sms_provider_cost + email_provider_cost)) /
            (call_revenue + sms_revenue + email_revenue) * 100
          )::numeric, 2)
          ELSE 0
        END
      )
    )
  ) INTO v_result
  FROM (
    SELECT
      d.id AS deployment_id,
      d.name AS deployment_name,
      c.name AS client_name,
      at.name AS agent_type_name,
      at.display_name AS agent_type_label,
      d.status,
      d.cost_per_min AS price_per_minute,
      d.cost_per_sms AS price_per_sms,
      d.cost_per_email AS price_per_email,

      -- Call metrics (using enriched view)
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.answered = true) AS answered_calls,
      ROUND((SUM(ac.duration_seconds) / 60.0)::numeric, 2) AS total_minutes,
      SUM((ac.duration_seconds / 60.0) * d.cost_per_min) AS call_revenue,
      SUM(COALESCE(ac.total_cost, 0)) AS call_provider_cost,

      -- SMS metrics (via separate table)
      COALESCE((
        SELECT COUNT(*)
        FROM agent_sms asms
        WHERE asms.deployment_id = d.id
          AND asms.sent_at::date >= p_start_date
          AND asms.sent_at::date <= p_end_date
      ), 0) AS total_sms,
      COALESCE((
        SELECT COUNT(*)
        FROM agent_sms asms
        WHERE asms.deployment_id = d.id
          AND asms.sent_at::date >= p_start_date
          AND asms.sent_at::date <= p_end_date
          AND asms.status = 'delivered'
      ), 0) AS sms_delivered,
      COALESCE((
        SELECT COUNT(*) * d.cost_per_sms
        FROM agent_sms asms
        WHERE asms.deployment_id = d.id
          AND asms.sent_at::date >= p_start_date
          AND asms.sent_at::date <= p_end_date
      ), 0) AS sms_revenue,
      COALESCE((
        SELECT SUM(asms.billed_cost)
        FROM agent_sms asms
        WHERE asms.deployment_id = d.id
          AND asms.sent_at::date >= p_start_date
          AND asms.sent_at::date <= p_end_date
      ), 0) AS sms_provider_cost,

      -- Email metrics (via separate table)
      COALESCE((
        SELECT COUNT(*)
        FROM agent_emails ae
        WHERE ae.deployment_id = d.id
          AND ae.sent_at::date >= p_start_date
          AND ae.sent_at::date <= p_end_date
      ), 0) AS total_emails,
      COALESCE((
        SELECT COUNT(*)
        FROM agent_emails ae
        WHERE ae.deployment_id = d.id
          AND ae.sent_at::date >= p_start_date
          AND ae.sent_at::date <= p_end_date
          AND ae.status = 'delivered'
      ), 0) AS emails_delivered,
      COALESCE((
        SELECT COUNT(*) * d.cost_per_email
        FROM agent_emails ae
        WHERE ae.deployment_id = d.id
          AND ae.sent_at::date >= p_start_date
          AND ae.sent_at::date <= p_end_date
      ), 0) AS email_revenue,
      COALESCE((
        SELECT SUM(ae.billed_cost)
        FROM agent_emails ae
        WHERE ae.deployment_id = d.id
          AND ae.sent_at::date >= p_start_date
          AND ae.sent_at::date <= p_end_date
      ), 0) AS email_provider_cost

    FROM agent_deployments d
    INNER JOIN agent_types at ON d.agent_type_id = at.id
    INNER JOIN clients c ON d.client_id = c.id
    LEFT JOIN v_agent_calls_enriched ac ON ac.deployment_id = d.id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
    WHERE
      EXISTS (
        SELECT 1
        FROM user_client_permissions ucp
        WHERE ucp.client_id = d.client_id
          AND ucp.user_id = auth.uid()
      )
      AND (p_client_id IS NULL OR d.client_id = p_client_id)
    GROUP BY d.id, d.name, c.name, at.name, at.display_name, d.status,
             d.cost_per_min, d.cost_per_sms, d.cost_per_email
    HAVING
      COUNT(ac.id) > 0
      OR (SELECT COUNT(*) FROM agent_sms asms WHERE asms.deployment_id = d.id
          AND asms.sent_at::date >= p_start_date AND asms.sent_at::date <= p_end_date) > 0
      OR (SELECT COUNT(*) FROM agent_emails ae WHERE ae.deployment_id = d.id
          AND ae.sent_at::date >= p_start_date AND ae.sent_at::date <= p_end_date) > 0
    ORDER BY
      (SUM((ac.duration_seconds / 60.0) * d.cost_per_min) +
       COALESCE((SELECT COUNT(*) * d.cost_per_sms FROM agent_sms asms
                 WHERE asms.deployment_id = d.id
                 AND asms.sent_at::date >= p_start_date
                 AND asms.sent_at::date <= p_end_date), 0) +
       COALESCE((SELECT COUNT(*) * d.cost_per_email FROM agent_emails ae
                 WHERE ae.deployment_id = d.id
                 AND ae.sent_at::date >= p_start_date
                 AND ae.sent_at::date <= p_end_date), 0)) DESC
  ) sub;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_consumption_pricing_by_agent(DATE, DATE, UUID) TO authenticated;

COMMENT ON FUNCTION public.get_consumption_pricing_by_agent IS
  'Returns unit pricing metrics (cost, price, margin per unit) for each agent deployment.';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Test 1: Check view columns
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'v_financial_metrics_enriched'
--   AND column_name IN ('leasing_revenue_daily', 'consumption_revenue', 'consumption_margin', 'consumption_margin_pct')
-- ORDER BY column_name;

-- Test 2: Check functions exist
-- SELECT proname, proargnames
-- FROM pg_proc
-- WHERE proname IN ('get_leasing_kpi_metrics', 'get_consumption_kpi_metrics', 'get_consumption_pricing_by_agent')
-- ORDER BY proname;

-- Test 3: Test leasing KPIs (last 30 days)
-- SELECT jsonb_pretty(get_leasing_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE));

-- Test 4: Test consumption KPIs (last 30 days)
-- SELECT jsonb_pretty(get_consumption_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE));

-- Test 5: Test consumption pricing by agent (last 30 days)
-- SELECT jsonb_pretty(get_consumption_pricing_by_agent(CURRENT_DATE - 30, CURRENT_DATE));

-- Test 6: Verify leasing vs consumption separation
-- SELECT
--   ROUND(SUM(leasing_revenue_daily)::numeric, 2) as leasing_rev,
--   ROUND(SUM(consumption_revenue)::numeric, 2) as consumption_rev,
--   ROUND(SUM(total_revenue)::numeric, 2) as total_rev,
--   ROUND(AVG(consumption_margin_pct)::numeric, 2) as avg_consumption_margin_pct,
--   ROUND(AVG(margin_percentage)::numeric, 2) as avg_total_margin_pct
-- FROM v_financial_metrics_enriched
-- WHERE metric_date >= CURRENT_DATE - 30;

-- ============================================================================
-- Migration Complete
-- ============================================================================
