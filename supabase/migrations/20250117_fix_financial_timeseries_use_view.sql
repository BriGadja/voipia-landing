-- ============================================================================
-- Migration: Fix get_financial_timeseries to use v_financial_metrics_enriched
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 1 FINAL FIX
-- ============================================================================
--
-- Purpose: Use existing v_financial_metrics_enriched view instead of manual calculations
-- Previous version tried to access non-existent columns (pricing_model, etc.)
--
-- Changes:
-- 1. Use v_financial_metrics_enriched which already has all calculations
-- 2. RLS is already enforced in the view via user_has_access column
-- 3. Simpler, more maintainable code
--
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT);

-- Create corrected function using the view
CREATE OR REPLACE FUNCTION public.get_financial_timeseries(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_granularity TEXT DEFAULT 'day'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_date_trunc_format TEXT;
BEGIN
  -- Determine date truncation format based on granularity
  v_date_trunc_format := CASE p_granularity
    WHEN 'week' THEN 'week'
    WHEN 'month' THEN 'month'
    ELSE 'day'
  END;

  -- Build time series data from v_financial_metrics_enriched
  WITH time_series AS (
    SELECT
      DATE_TRUNC(v_date_trunc_format, metric_date)::date AS period_date,

      -- Revenue by channel (already calculated in view)
      SUM(call_revenue) AS call_revenue,
      SUM(sms_revenue) AS sms_revenue,
      SUM(email_revenue) AS email_revenue,
      SUM(leasing_revenue_daily) AS leasing_revenue,

      -- Provider costs (already calculated in view)
      SUM(call_provider_cost) AS call_cost,
      SUM(sms_provider_cost) AS sms_cost,
      SUM(email_provider_cost) AS email_cost,

      -- Volume metrics
      SUM(call_count) AS call_count,
      SUM(answered_calls) AS answered_calls,
      SUM(sms_count) AS sms_count,
      SUM(email_count) AS email_count,
      SUM(appointments_scheduled) AS appointments,

      -- Unique counts
      COUNT(DISTINCT client_id) AS unique_clients,
      COUNT(DISTINCT deployment_id) AS unique_deployments

    FROM v_financial_metrics_enriched
    WHERE metric_date >= p_start_date
      AND metric_date <= p_end_date
      AND user_has_access = true  -- RLS filtering
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
    GROUP BY DATE_TRUNC(v_date_trunc_format, metric_date)::date
  )
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'date', period_date,
      'revenue', JSONB_BUILD_OBJECT(
        'total', COALESCE(call_revenue + sms_revenue + email_revenue + leasing_revenue, 0),
        'calls', COALESCE(call_revenue, 0),
        'sms', COALESCE(sms_revenue, 0),
        'email', COALESCE(email_revenue, 0),
        'leasing', COALESCE(leasing_revenue, 0)
      ),
      'cost', JSONB_BUILD_OBJECT(
        'total', COALESCE(call_cost + sms_cost + email_cost, 0),
        'calls', COALESCE(call_cost, 0),
        'sms', COALESCE(sms_cost, 0),
        'email', COALESCE(email_cost, 0)
      ),
      'margin', JSONB_BUILD_OBJECT(
        'total', COALESCE(
          (call_revenue + sms_revenue + email_revenue + leasing_revenue) -
          (call_cost + sms_cost + email_cost),
          0
        ),
        'percentage', CASE
          WHEN COALESCE(call_revenue + sms_revenue + email_revenue + leasing_revenue, 0) > 0
          THEN ROUND((
            (call_revenue + sms_revenue + email_revenue + leasing_revenue - call_cost - sms_cost - email_cost) /
            (call_revenue + sms_revenue + email_revenue + leasing_revenue) * 100
          )::numeric, 2)
          ELSE 0
        END
      ),
      'volume', JSONB_BUILD_OBJECT(
        'calls', COALESCE(call_count, 0),
        'answered_calls', COALESCE(answered_calls, 0),
        'sms', COALESCE(sms_count, 0),
        'email', COALESCE(email_count, 0),
        'appointments', COALESCE(appointments, 0)
      ),
      'metrics', JSONB_BUILD_OBJECT(
        'unique_clients', COALESCE(unique_clients, 0),
        'unique_deployments', COALESCE(unique_deployments, 0),
        'answer_rate', CASE
          WHEN COALESCE(call_count, 0) > 0
          THEN ROUND((COALESCE(answered_calls, 0)::numeric / call_count * 100), 2)
          ELSE 0
        END,
        'conversion_rate', CASE
          WHEN COALESCE(answered_calls, 0) > 0
          THEN ROUND((COALESCE(appointments, 0)::numeric / answered_calls * 100), 2)
          ELSE 0
        END
      )
    ) ORDER BY period_date
  ) INTO v_result
  FROM time_series;

  -- Return result or empty array
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_financial_timeseries: %', SQLERRM;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.get_financial_timeseries IS
  'Returns financial time series data with daily/weekly/monthly granularity. Uses v_financial_metrics_enriched view with RLS.';

-- ============================================================================
-- Verification Query (run after migration)
-- ============================================================================

-- Test with 30-day period
-- SELECT jsonb_pretty(
--   get_financial_timeseries(
--     CURRENT_DATE - 30,
--     CURRENT_DATE,
--     NULL,  -- all clients
--     NULL,  -- all agent types
--     NULL,  -- all deployments
--     'day'  -- daily granularity
--   )
-- );
