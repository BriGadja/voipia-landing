-- ============================================================================
-- Function: get_financial_timeseries
-- Description: Returns financial metrics as time series data for charts
-- Author: Claude
-- Date: 2025-01-17
-- ============================================================================

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
-- Example Usage
-- ============================================================================

-- Example 1: Daily data for last 30 days (all clients)
-- SELECT get_financial_timeseries(
--   (CURRENT_DATE - 30)::DATE,
--   CURRENT_DATE::DATE,
--   NULL::UUID,
--   NULL::TEXT,
--   NULL::UUID,
--   'day'
-- );

-- Example 2: Weekly data for specific client
-- SELECT get_financial_timeseries(
--   '2025-01-01'::DATE,
--   '2025-01-31'::DATE,
--   '123e4567-e89b-12d3-a456-426614174000'::UUID,
--   NULL::TEXT,
--   NULL::UUID,
--   'week'
-- );

-- Example 3: Monthly data for Louis agents only
-- SELECT get_financial_timeseries(
--   '2024-01-01'::DATE,
--   '2024-12-31'::DATE,
--   NULL::UUID,
--   'louis'::TEXT,
--   NULL::UUID,
--   'month'
-- );

-- ============================================================================
-- Notes
-- ============================================================================
--
-- This function:
-- - Returns time series data aggregated by day, week, or month
-- - Respects RLS (user_has_access column)
-- - Supports filtering by client, agent type, or deployment
-- - Returns comprehensive metrics for charting
-- - Handles NULL values gracefully (returns 0)
-- - Returns empty array if no data found
--
-- Performance:
-- - Uses v_financial_metrics_enriched view (pre-aggregated by day)
-- - Additional aggregation for week/month is fast
-- - Recommended to limit date ranges to < 365 days for optimal performance
--
-- Output structure:
-- [
--   {
--     "date": "2025-01-15",
--     "revenue": {"total": 450.50, "calls": 280, "sms": 35, "email": 0, "leasing": 135.50},
--     "cost": {"total": 40.20, "calls": 28, "sms": 10, "email": 2.20},
--     "margin": {"total": 410.30, "percentage": 91.08},
--     "volume": {"calls": 145, "answered_calls": 120, "sms": 520, "email": 0, "appointments": 18},
--     "metrics": {"unique_clients": 3, "unique_deployments": 5, "answer_rate": 82.76, "conversion_rate": 15.00}
--   },
--   ...
-- ]
