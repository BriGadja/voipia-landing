-- ============================================================================
-- Migration: Create financial timeseries function
-- Date: 2025-01-17
-- Author: Claude
--
-- Changes:
-- 1. Create get_financial_timeseries() function for charting time series data
-- 2. Support daily, weekly, and monthly granularity
-- 3. Return comprehensive metrics (revenue, cost, margin, volume)
-- 4. Respect RLS (user_has_access)
--
-- Expected Impact:
-- - Enable time series charts in financial dashboards
-- - Support drill down with temporal analysis
-- - Improve performance with pre-aggregated data
-- ============================================================================

-- Drop existing function if exists (prevent "function is not unique" error)
DROP FUNCTION IF EXISTS public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT);

-- Create the function
CREATE OR REPLACE FUNCTION public.get_financial_timeseries(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_granularity TEXT DEFAULT 'day' -- 'day', 'week', 'month'
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
  -- Validate granularity parameter
  IF p_granularity NOT IN ('day', 'week', 'month') THEN
    RAISE EXCEPTION 'Invalid granularity. Must be day, week, or month';
  END IF;

  -- Set date truncation format based on granularity
  v_date_trunc_format := p_granularity;

  -- Build time series data
  WITH timeseries_data AS (
    SELECT
      DATE_TRUNC(v_date_trunc_format, metric_date)::DATE as period_date,

      -- Revenue metrics
      SUM(call_revenue) as call_revenue,
      SUM(sms_revenue) as sms_revenue,
      SUM(email_revenue) as email_revenue,
      SUM(leasing_revenue_daily) as leasing_revenue,
      SUM(call_revenue + sms_revenue + email_revenue + leasing_revenue_daily) as total_revenue,

      -- Cost metrics
      SUM(call_provider_cost) as call_cost,
      SUM(sms_provider_cost) as sms_cost,
      SUM(email_provider_cost) as email_cost,
      SUM(call_provider_cost + sms_provider_cost + email_provider_cost) as total_cost,

      -- Margin metrics
      SUM(call_revenue + sms_revenue + email_revenue + leasing_revenue_daily) -
      SUM(call_provider_cost + sms_provider_cost + email_provider_cost) as total_margin,

      -- Volume metrics
      SUM(call_count) as call_count,
      SUM(answered_calls) as answered_calls,
      SUM(sms_count) as sms_count,
      SUM(email_count) as email_count,
      SUM(appointments_scheduled) as appointments_scheduled,

      -- Unique counts
      COUNT(DISTINCT client_id) as unique_clients,
      COUNT(DISTINCT deployment_id) as unique_deployments

    FROM v_financial_metrics_enriched
    WHERE metric_date BETWEEN p_start_date AND p_end_date
      AND user_has_access = true
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
    GROUP BY DATE_TRUNC(v_date_trunc_format, metric_date)
    ORDER BY period_date ASC
  )
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'date', period_date,
      'revenue', JSONB_BUILD_OBJECT(
        'total', COALESCE(total_revenue, 0),
        'calls', COALESCE(call_revenue, 0),
        'sms', COALESCE(sms_revenue, 0),
        'email', COALESCE(email_revenue, 0),
        'leasing', COALESCE(leasing_revenue, 0)
      ),
      'cost', JSONB_BUILD_OBJECT(
        'total', COALESCE(total_cost, 0),
        'calls', COALESCE(call_cost, 0),
        'sms', COALESCE(sms_cost, 0),
        'email', COALESCE(email_cost, 0)
      ),
      'margin', JSONB_BUILD_OBJECT(
        'total', COALESCE(total_margin, 0),
        'percentage', CASE
          WHEN COALESCE(total_revenue, 0) > 0
          THEN (COALESCE(total_margin, 0) / COALESCE(total_revenue, 1)) * 100
          ELSE 0
        END
      ),
      'volume', JSONB_BUILD_OBJECT(
        'calls', COALESCE(call_count, 0),
        'answered_calls', COALESCE(answered_calls, 0),
        'sms', COALESCE(sms_count, 0),
        'email', COALESCE(email_count, 0),
        'appointments', COALESCE(appointments_scheduled, 0)
      ),
      'metrics', JSONB_BUILD_OBJECT(
        'unique_clients', COALESCE(unique_clients, 0),
        'unique_deployments', COALESCE(unique_deployments, 0),
        'answer_rate', CASE
          WHEN COALESCE(call_count, 0) > 0
          THEN (COALESCE(answered_calls, 0)::NUMERIC / COALESCE(call_count, 1)) * 100
          ELSE 0
        END,
        'conversion_rate', CASE
          WHEN COALESCE(answered_calls, 0) > 0
          THEN (COALESCE(appointments_scheduled, 0)::NUMERIC / COALESCE(answered_calls, 1)) * 100
          ELSE 0
        END
      )
    )
  ) INTO v_result
  FROM timeseries_data;

  -- Return empty array if no data
  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT) TO authenticated;

-- ============================================================================
-- Verification Queries (commented out, uncomment to test)
-- ============================================================================

-- Test 1: Get daily data for last 30 days
-- SELECT get_financial_timeseries(
--   (CURRENT_DATE - 30)::DATE,
--   CURRENT_DATE::DATE,
--   NULL::UUID,
--   NULL::TEXT,
--   NULL::UUID,
--   'day'
-- );

-- Test 2: Get weekly data for last 90 days
-- SELECT get_financial_timeseries(
--   (CURRENT_DATE - 90)::DATE,
--   CURRENT_DATE::DATE,
--   NULL::UUID,
--   NULL::TEXT,
--   NULL::UUID,
--   'week'
-- );

-- Test 3: Get monthly data for current year
-- SELECT get_financial_timeseries(
--   DATE_TRUNC('year', CURRENT_DATE)::DATE,
--   CURRENT_DATE::DATE,
--   NULL::UUID,
--   NULL::TEXT,
--   NULL::UUID,
--   'month'
-- );

-- Test 4: Verify function exists
-- SELECT proname, proargnames, prokind
-- FROM pg_proc
-- WHERE proname = 'get_financial_timeseries';

-- Test 5: Verify permissions
-- SELECT grantee, privilege_type
-- FROM information_schema.routine_privileges
-- WHERE routine_name = 'get_financial_timeseries';
