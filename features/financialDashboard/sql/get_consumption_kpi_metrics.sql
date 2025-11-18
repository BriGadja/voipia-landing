-- ============================================================================
-- Function: get_consumption_kpi_metrics
-- Description: Returns KPI metrics for CONSUMPTION ONLY (calls, SMS, emails)
-- Author: Claude
-- Date: 2025-01-18
-- Version: 1.0
-- ============================================================================
--
-- Purpose: Calculate KPIs specific to consumption/usage business model
-- Returns: JSONB object with consumption-specific metrics
--
-- Usage:
--   SELECT get_consumption_kpi_metrics(
--     '2024-12-01',
--     '2025-01-18'
--   );
-- ============================================================================

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
  -- Build result with consumption KPIs
  SELECT JSONB_BUILD_OBJECT(
    -- === REVENUE & MARGIN ===

    -- Total consumption revenue (calls + SMS + emails)
    'total_consumption_revenue', COALESCE(SUM(consumption_revenue), 0),

    -- Total provider cost
    'total_provider_cost', COALESCE(SUM(consumption_provider_cost), 0),

    -- Total margin on consumption
    'total_consumption_margin', COALESCE(SUM(consumption_margin), 0),

    -- Margin percentage on consumption
    'consumption_margin_pct', CASE
      WHEN SUM(consumption_revenue) > 0
      THEN ROUND((SUM(consumption_margin) / SUM(consumption_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- === VOLUME METRICS ===

    -- Total calls, SMS, emails
    'total_calls', COALESCE(SUM(call_count), 0),
    'total_sms', COALESCE(SUM(sms_count), 0),
    'total_emails', COALESCE(SUM(email_count), 0),

    -- Total answered calls and appointments
    'total_answered_calls', COALESCE(SUM(answered_calls), 0),
    'total_appointments', COALESCE(SUM(appointments_scheduled), 0),

    -- === BREAKDOWN BY CHANNEL ===

    -- Call revenue breakdown
    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'call_margin', COALESCE(SUM(call_revenue - call_provider_cost), 0),
    'call_margin_pct', CASE
      WHEN SUM(call_revenue) > 0
      THEN ROUND(((SUM(call_revenue) - SUM(call_provider_cost)) / SUM(call_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- SMS revenue breakdown
    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'sms_margin', COALESCE(SUM(sms_revenue - sms_provider_cost), 0),
    'sms_margin_pct', CASE
      WHEN SUM(sms_revenue) > 0
      THEN ROUND(((SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- Email revenue breakdown
    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'email_margin', COALESCE(SUM(email_revenue - email_provider_cost), 0),
    'email_margin_pct', CASE
      WHEN SUM(email_revenue) > 0
      THEN ROUND(((SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_revenue) * 100)::numeric, 2)
      ELSE 0
    END,

    -- === UNIT PRICING (AVERAGE ACROSS ALL AGENTS) ===

    -- Average cost per minute (provider cost)
    'avg_cost_per_minute', CASE
      WHEN SUM(total_duration_seconds) > 0
      THEN ROUND((SUM(call_provider_cost) / (SUM(total_duration_seconds) / 60.0))::numeric, 4)
      ELSE 0
    END,

    -- Average cost per SMS (provider cost)
    'avg_cost_per_sms', CASE
      WHEN SUM(sms_count) > 0
      THEN ROUND((SUM(sms_provider_cost) / SUM(sms_count))::numeric, 4)
      ELSE 0
    END,

    -- Average cost per email (provider cost)
    'avg_cost_per_email', CASE
      WHEN SUM(email_count) > 0
      THEN ROUND((SUM(email_provider_cost) / SUM(email_count))::numeric, 4)
      ELSE 0
    END,

    -- Average revenue per minute (charged to client)
    'avg_revenue_per_minute', CASE
      WHEN SUM(total_duration_seconds) > 0
      THEN ROUND((SUM(call_revenue) / (SUM(total_duration_seconds) / 60.0))::numeric, 4)
      ELSE 0
    END,

    -- Average revenue per SMS
    'avg_revenue_per_sms', CASE
      WHEN SUM(sms_count) > 0
      THEN ROUND((SUM(sms_revenue) / SUM(sms_count))::numeric, 4)
      ELSE 0
    END,

    -- Average revenue per email
    'avg_revenue_per_email', CASE
      WHEN SUM(email_count) > 0
      THEN ROUND((SUM(email_revenue) / SUM(email_count))::numeric, 4)
      ELSE 0
    END,

    -- === BUSINESS METRICS ===

    -- Average consumption revenue per client
    'avg_consumption_per_client', CASE
      WHEN COUNT(DISTINCT client_id) > 0
      THEN ROUND((SUM(consumption_revenue) / COUNT(DISTINCT client_id))::numeric, 2)
      ELSE 0
    END,

    -- Total active clients with consumption
    'consumption_client_count', COUNT(DISTINCT client_id),

    -- Total active deployments with consumption
    'active_deployment_count', COUNT(DISTINCT deployment_id)

  ) INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true
    AND consumption_revenue > 0;  -- Only include records with actual consumption

  -- Return result
  RETURN COALESCE(v_result, JSONB_BUILD_OBJECT(
    'total_consumption_revenue', 0,
    'total_provider_cost', 0,
    'total_consumption_margin', 0,
    'consumption_margin_pct', 0,
    'total_calls', 0,
    'total_sms', 0,
    'total_emails', 0,
    'total_answered_calls', 0,
    'total_appointments', 0,
    'call_revenue', 0,
    'call_provider_cost', 0,
    'call_margin', 0,
    'call_margin_pct', 0,
    'sms_revenue', 0,
    'sms_provider_cost', 0,
    'sms_margin', 0,
    'sms_margin_pct', 0,
    'email_revenue', 0,
    'email_provider_cost', 0,
    'email_margin', 0,
    'email_margin_pct', 0,
    'avg_cost_per_minute', 0,
    'avg_cost_per_sms', 0,
    'avg_cost_per_email', 0,
    'avg_revenue_per_minute', 0,
    'avg_revenue_per_sms', 0,
    'avg_revenue_per_email', 0,
    'avg_consumption_per_client', 0,
    'consumption_client_count', 0,
    'active_deployment_count', 0
  ));

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_consumption_kpi_metrics: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_consumption_kpi_metrics(DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_consumption_kpi_metrics IS
  'Returns KPI metrics for consumption/usage revenue only (calls, SMS, emails). Includes unit pricing, margins, and volume metrics.';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames
-- FROM pg_proc
-- WHERE proname = 'get_consumption_kpi_metrics';

-- Test 2: Get consumption KPIs for last 30 days
-- SELECT get_consumption_kpi_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE
-- );

-- Test 3: Format result for readability
-- SELECT
--   result->>'total_consumption_revenue' as total_revenue,
--   result->>'total_provider_cost' as provider_cost,
--   result->>'total_consumption_margin' as margin,
--   result->>'consumption_margin_pct' as margin_pct,
--   result->>'total_calls' as calls,
--   result->>'total_sms' as sms,
--   result->>'total_emails' as emails,
--   result->>'avg_cost_per_minute' as cost_per_min,
--   result->>'avg_cost_per_sms' as cost_per_sms,
--   result->>'avg_cost_per_email' as cost_per_email
-- FROM (
--   SELECT get_consumption_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE) as result
-- ) sub;

-- Test 4: Compare margins by channel
-- WITH metrics AS (
--   SELECT get_consumption_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE) as result
-- )
-- SELECT
--   'Calls' as channel,
--   (result->>'call_revenue')::numeric as revenue,
--   (result->>'call_provider_cost')::numeric as cost,
--   (result->>'call_margin')::numeric as margin,
--   (result->>'call_margin_pct')::numeric as margin_pct
-- FROM metrics
-- UNION ALL
-- SELECT
--   'SMS' as channel,
--   (result->>'sms_revenue')::numeric as revenue,
--   (result->>'sms_provider_cost')::numeric as cost,
--   (result->>'sms_margin')::numeric as margin,
--   (result->>'sms_margin_pct')::numeric as margin_pct
-- FROM metrics
-- UNION ALL
-- SELECT
--   'Email' as channel,
--   (result->>'email_revenue')::numeric as revenue,
--   (result->>'email_provider_cost')::numeric as cost,
--   (result->>'email_margin')::numeric as margin,
--   (result->>'email_margin_pct')::numeric as margin_pct
-- FROM metrics;
