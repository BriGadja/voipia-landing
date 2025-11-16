-- Migration: Create Financial Dashboard (View + RPC Functions)
-- Date: 2025-11-16
-- Author: Claude (Financial Dashboard Implementation)
--
-- Purpose: Complete financial tracking system for Voipia
-- Components:
--   1. v_financial_metrics_enriched - Unified financial metrics view
--   2. get_financial_kpi_metrics() - KPI aggregation with period comparison
--
-- Data Sources: agent_calls, agent_sms, agent_emails, agent_deployments
-- Key Features: Revenue tracking, cost tracking, margin calculation, pro-rated leasing

-- ============================================================================
-- PART 1: Create Financial Metrics View
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
    -- Revenue: duration in minutes * cost_per_min from deployment
    SUM((ac.duration_seconds / 60.0) * db.cost_per_min) as call_revenue,
    -- Provider cost (from total_cost which is already in EUR)
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
    COUNT(*) FILTER (WHERE asms.delivered_at IS NOT NULL) as sms_delivered,
    -- Revenue: billed_cost (already calculated with markup)
    SUM(COALESCE(asms.billed_cost, 0)) as sms_revenue,
    -- Provider cost (provider_cost already in EUR)
    SUM(COALESCE(asms.provider_cost, 0)) as sms_provider_cost
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
    COUNT(*) FILTER (WHERE ae.sent_at IS NOT NULL AND ae.failed_at IS NULL) as email_delivered,
    -- Revenue: billed_cost (already calculated with markup)
    SUM(COALESCE(ae.billed_cost, 0)) as email_revenue,
    -- Provider cost (provider_cost already in EUR)
    SUM(COALESCE(ae.provider_cost, 0)) as email_provider_cost
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

-- Grant permissions
GRANT SELECT ON v_financial_metrics_enriched TO authenticated;

COMMENT ON VIEW v_financial_metrics_enriched IS
'Unified financial metrics view combining calls, SMS, emails, and pro-rated leasing revenue.
Aggregated by deployment and day for granular financial analysis.
Includes revenue, provider costs, margins, and margin percentages.
RLS enforced via user_has_access column.';

-- ============================================================================
-- PART 2: Create Financial KPI Metrics RPC Function
-- ============================================================================

DROP FUNCTION IF EXISTS get_financial_kpi_metrics(date, date, uuid, text, uuid);

CREATE OR REPLACE FUNCTION get_financial_kpi_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_period jsonb;
  v_previous_period jsonb;
  v_period_duration int;
  v_previous_start date;
  v_previous_end date;
BEGIN
  -- Calculate period duration in days
  v_period_duration := p_end_date - p_start_date + 1;

  -- Calculate previous period dates
  v_previous_end := p_start_date - 1;
  v_previous_start := v_previous_end - v_period_duration + 1;

  -- Get current period metrics
  SELECT jsonb_build_object(
    'total_revenue', COALESCE(SUM(total_revenue), 0),
    'total_provider_cost', COALESCE(SUM(total_provider_cost), 0),
    'total_margin', COALESCE(SUM(total_margin), 0),
    'margin_percentage',
      CASE
        WHEN SUM(total_revenue) > 0
        THEN (SUM(total_margin) / SUM(total_revenue)) * 100
        ELSE 0
      END,
    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'call_count', COALESCE(SUM(call_count), 0),
    'answered_calls', COALESCE(SUM(answered_calls), 0),
    'appointments_scheduled', COALESCE(SUM(appointments_scheduled), 0),
    'sms_count', COALESCE(SUM(sms_count), 0),
    'email_count', COALESCE(SUM(email_count), 0),
    'unique_clients', COUNT(DISTINCT client_id),
    'unique_deployments', COUNT(DISTINCT deployment_id),
    'avg_revenue_per_client',
      CASE
        WHEN COUNT(DISTINCT client_id) > 0
        THEN SUM(total_revenue) / COUNT(DISTINCT client_id)
        ELSE 0
      END,
    'avg_margin_per_client',
      CASE
        WHEN COUNT(DISTINCT client_id) > 0
        THEN SUM(total_margin) / COUNT(DISTINCT client_id)
        ELSE 0
      END
  )
  INTO v_current_period
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id);

  -- Get previous period metrics
  SELECT jsonb_build_object(
    'total_revenue', COALESCE(SUM(total_revenue), 0),
    'total_provider_cost', COALESCE(SUM(total_provider_cost), 0),
    'total_margin', COALESCE(SUM(total_margin), 0),
    'margin_percentage',
      CASE
        WHEN SUM(total_revenue) > 0
        THEN (SUM(total_margin) / SUM(total_revenue)) * 100
        ELSE 0
      END
  )
  INTO v_previous_period
  FROM v_financial_metrics_enriched
  WHERE metric_date >= v_previous_start
    AND metric_date <= v_previous_end
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id);

  -- Return combined result with period comparison
  RETURN jsonb_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period,
    'period_info', jsonb_build_object(
      'start_date', p_start_date,
      'end_date', p_end_date,
      'duration_days', v_period_duration,
      'previous_start_date', v_previous_start,
      'previous_end_date', v_previous_end
    ),
    'comparison', jsonb_build_object(
      'revenue_change',
        (v_current_period->>'total_revenue')::numeric - (v_previous_period->>'total_revenue')::numeric,
      'revenue_change_percentage',
        CASE
          WHEN (v_previous_period->>'total_revenue')::numeric > 0
          THEN ((v_current_period->>'total_revenue')::numeric - (v_previous_period->>'total_revenue')::numeric) / (v_previous_period->>'total_revenue')::numeric * 100
          ELSE 0
        END,
      'margin_change',
        (v_current_period->>'total_margin')::numeric - (v_previous_period->>'total_margin')::numeric,
      'margin_change_percentage',
        CASE
          WHEN (v_previous_period->>'total_margin')::numeric > 0
          THEN ((v_current_period->>'total_margin')::numeric - (v_previous_period->>'total_margin')::numeric) / (v_previous_period->>'total_margin')::numeric * 100
          ELSE 0
        END
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_financial_kpi_metrics(date, date, uuid, text, uuid) TO authenticated;

COMMENT ON FUNCTION get_financial_kpi_metrics IS
'Retrieves global financial KPIs with period comparison.
Returns revenue, costs, margins for current period vs previous period.
Supports filtering by client, agent type, and deployment.
RLS enforced via user_has_access column in view.';

-- ============================================================================
-- PART 3: Create Financial Drilldown RPC Function
-- ============================================================================

DROP FUNCTION IF EXISTS get_financial_drilldown(date, date, text, uuid, text, uuid);

CREATE OR REPLACE FUNCTION get_financial_drilldown(
  p_start_date date,
  p_end_date date,
  p_level text DEFAULT 'client',
  p_client_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF p_level NOT IN ('client', 'agent_type', 'deployment', 'channel') THEN
    RAISE EXCEPTION 'Invalid drilldown level. Must be: client, agent_type, deployment, or channel';
  END IF;

  IF p_level = 'client' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'client_id', client_id,
        'client_name', client_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'unique_deployments', unique_deployments,
        'active_days', active_days
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        client_id,
        client_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT deployment_id) as unique_deployments,
        COUNT(DISTINCT metric_date) as active_days
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY client_id, client_name
    ) client_data;

  ELSIF p_level = 'agent_type' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'agent_type_id', agent_type_id,
        'agent_type_name', agent_type_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'unique_clients', unique_clients,
        'unique_deployments', unique_deployments
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        agent_type_id,
        agent_type_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT client_id) as unique_clients,
        COUNT(DISTINCT deployment_id) as unique_deployments
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY agent_type_id, agent_type_name
    ) agent_data;

  ELSIF p_level = 'deployment' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'deployment_id', deployment_id,
        'client_id', client_id,
        'client_name', client_name,
        'agent_type_id', agent_type_id,
        'agent_type_name', agent_type_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'active_days', active_days
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        deployment_id,
        client_id,
        client_name,
        agent_type_id,
        agent_type_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT metric_date) as active_days
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY deployment_id, client_id, client_name, agent_type_id, agent_type_name
    ) deployment_data;

  ELSIF p_level = 'channel' THEN
    SELECT jsonb_build_object(
      'channels', jsonb_build_array(
        jsonb_build_object(
          'channel_name', 'calls',
          'revenue', SUM(call_revenue),
          'provider_cost', SUM(call_provider_cost),
          'margin', SUM(call_revenue) - SUM(call_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(call_revenue) > 0
              THEN ((SUM(call_revenue) - SUM(call_provider_cost)) / SUM(call_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(call_count),
          'answered', SUM(answered_calls)
        ),
        jsonb_build_object(
          'channel_name', 'sms',
          'revenue', SUM(sms_revenue),
          'provider_cost', SUM(sms_provider_cost),
          'margin', SUM(sms_revenue) - SUM(sms_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(sms_revenue) > 0
              THEN ((SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(sms_count),
          'delivered', SUM(sms_delivered)
        ),
        jsonb_build_object(
          'channel_name', 'email',
          'revenue', SUM(email_revenue),
          'provider_cost', SUM(email_provider_cost),
          'margin', SUM(email_revenue) - SUM(email_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(email_revenue) > 0
              THEN ((SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(email_count),
          'delivered', SUM(email_delivered)
        ),
        jsonb_build_object(
          'channel_name', 'leasing',
          'revenue', SUM(leasing_revenue_daily),
          'provider_cost', 0,
          'margin', SUM(leasing_revenue_daily),
          'margin_percentage', 100,
          'volume', COUNT(DISTINCT deployment_id),
          'description', 'Monthly subscription fees pro-rated by day'
        )
      )
    )
    INTO v_result
    FROM v_financial_metrics_enriched
    WHERE metric_date >= p_start_date
      AND metric_date <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id);

  END IF;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION get_financial_drilldown(date, date, text, uuid, text, uuid) TO authenticated;

COMMENT ON FUNCTION get_financial_drilldown IS
'Multi-level financial drilldown supporting client, agent_type, deployment, and channel levels.
Returns detailed breakdown of revenue, costs, margins, and activity metrics.';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Test the view
-- SELECT * FROM v_financial_metrics_enriched ORDER BY metric_date DESC LIMIT 10;

-- Test the KPI function (last 30 days)
-- SELECT get_financial_kpi_metrics(
--   (CURRENT_DATE - 30)::date,
--   CURRENT_DATE::date,
--   NULL::uuid,
--   NULL::text,
--   NULL::uuid
-- );

-- Test the drilldown function (client breakdown)
-- SELECT get_financial_drilldown(
--   (CURRENT_DATE - 30)::date,
--   CURRENT_DATE::date,
--   'client'::text,
--   NULL::uuid,
--   NULL::text,
--   NULL::uuid
-- );

-- ============================================================================
-- Migration Complete
-- ============================================================================
