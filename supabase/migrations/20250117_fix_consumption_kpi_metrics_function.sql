-- Migration: Fix get_consumption_kpi_metrics function
-- Date: 2025-01-17
-- Author: Claude
--
-- Problem: Function tries to access consumption_revenue, consumption_provider_cost, consumption_margin that don't exist
-- Solution: Calculate consumption metrics from existing call/sms/email columns
--
-- Changes:
-- - consumption_revenue = call_revenue + sms_revenue + email_revenue
-- - consumption_provider_cost = call_provider_cost + sms_provider_cost + email_provider_cost
-- - consumption_margin = consumption_revenue - consumption_provider_cost

DROP FUNCTION IF EXISTS get_consumption_kpi_metrics(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_consumption_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- SECURITY CHECK: Verify user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required to view consumption metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate consumption metrics (consumption = calls + sms + emails, excluding leasing)
  SELECT jsonb_build_object(
    'total_consumption_revenue', COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0),
    'total_provider_cost', COALESCE(SUM(call_provider_cost + sms_provider_cost + email_provider_cost), 0),
    'total_consumption_margin', COALESCE(SUM(
      (call_revenue + sms_revenue + email_revenue) -
      (call_provider_cost + sms_provider_cost + email_provider_cost)
    ), 0),
    'consumption_margin_pct', CASE
      WHEN COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0) > 0
      THEN (COALESCE(SUM(
        (call_revenue + sms_revenue + email_revenue) -
        (call_provider_cost + sms_provider_cost + email_provider_cost)
      ), 0) / COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0) * 100)
      ELSE 0
    END,

    'total_calls', COALESCE(SUM(call_count), 0),
    'total_sms', COALESCE(SUM(sms_count), 0),
    'total_emails', COALESCE(SUM(email_count), 0),
    'total_answered_calls', COALESCE(SUM(answered_calls), 0),
    'total_appointments', COALESCE(SUM(appointments_scheduled), 0),

    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'call_margin', COALESCE(SUM(call_revenue - call_provider_cost), 0),
    'call_margin_pct', CASE
      WHEN COALESCE(SUM(call_revenue), 0) > 0
      THEN (COALESCE(SUM(call_revenue - call_provider_cost), 0) / COALESCE(SUM(call_revenue), 0) * 100)
      ELSE 0
    END,

    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'sms_margin', COALESCE(SUM(sms_revenue - sms_provider_cost), 0),
    'sms_margin_pct', CASE
      WHEN COALESCE(SUM(sms_revenue), 0) > 0
      THEN (COALESCE(SUM(sms_revenue - sms_provider_cost), 0) / COALESCE(SUM(sms_revenue), 0) * 100)
      ELSE 0
    END,

    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'email_margin', COALESCE(SUM(email_revenue - email_provider_cost), 0),
    'email_margin_pct', CASE
      WHEN COALESCE(SUM(email_revenue), 0) > 0
      THEN (COALESCE(SUM(email_revenue - email_provider_cost), 0) / COALESCE(SUM(email_revenue), 0) * 100)
      ELSE 0
    END,

    'avg_cost_per_minute', CASE
      WHEN COALESCE(SUM(total_duration_seconds), 0) > 0
      THEN (COALESCE(SUM(call_provider_cost), 0) / (COALESCE(SUM(total_duration_seconds), 0) / 60.0))
      ELSE 0
    END,
    'avg_cost_per_sms', CASE
      WHEN COALESCE(SUM(sms_count), 0) > 0
      THEN (COALESCE(SUM(sms_provider_cost), 0) / COALESCE(SUM(sms_count), 0))
      ELSE 0
    END,
    'avg_cost_per_email', CASE
      WHEN COALESCE(SUM(email_count), 0) > 0
      THEN (COALESCE(SUM(email_provider_cost), 0) / COALESCE(SUM(email_count), 0))
      ELSE 0
    END,
    'avg_revenue_per_minute', CASE
      WHEN COALESCE(SUM(total_duration_seconds), 0) > 0
      THEN (COALESCE(SUM(call_revenue), 0) / (COALESCE(SUM(total_duration_seconds), 0) / 60.0))
      ELSE 0
    END,
    'avg_revenue_per_sms', CASE
      WHEN COALESCE(SUM(sms_count), 0) > 0
      THEN (COALESCE(SUM(sms_revenue), 0) / COALESCE(SUM(sms_count), 0))
      ELSE 0
    END,
    'avg_revenue_per_email', CASE
      WHEN COALESCE(SUM(email_count), 0) > 0
      THEN (COALESCE(SUM(email_revenue), 0) / COALESCE(SUM(email_count), 0))
      ELSE 0
    END,

    'avg_consumption_per_client', CASE
      WHEN COUNT(DISTINCT client_id) > 0
      THEN (COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0) / COUNT(DISTINCT client_id))
      ELSE 0
    END,
    'consumption_client_count', COUNT(DISTINCT client_id),
    'active_deployment_count', COUNT(DISTINCT deployment_id)
  )
  INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true;

  RETURN v_result;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_consumption_kpi_metrics(DATE, DATE) TO authenticated;

-- Verification query
-- SELECT jsonb_pretty(get_consumption_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE));
