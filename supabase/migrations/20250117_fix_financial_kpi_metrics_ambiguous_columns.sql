-- Migration: Fix get_financial_kpi_metrics ambiguous column references
-- Date: 2025-01-17
-- Author: Claude
--
-- Problem: Column references like "total_revenue" are ambiguous in JOIN between curr and prev periods
-- Solution: Prefix all column references with table aliases (curr. or prev.)
--
-- Changes:
-- - All column references in SELECT now explicitly use curr. or prev. prefix
-- - Fixes "column reference is ambiguous" error

DROP FUNCTION IF EXISTS get_financial_kpi_metrics(DATE, DATE, UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION public.get_financial_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
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
    RAISE EXCEPTION 'Access denied: Admin permission required to view financial metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate KPIs with period comparison
  SELECT jsonb_build_object(
    'current_period', current_metrics,
    'previous_period', previous_metrics,
    'period_info', period_info,
    'comparison', comparison
  )
  INTO v_result
  FROM (
    SELECT
      jsonb_build_object(
        'total_revenue', COALESCE(SUM(curr.total_revenue), 0),
        'total_provider_cost', COALESCE(SUM(curr.total_provider_cost), 0),
        'total_margin', COALESCE(SUM(curr.total_margin), 0),
        'margin_percentage', CASE
          WHEN COALESCE(SUM(curr.total_revenue), 0) > 0
          THEN (COALESCE(SUM(curr.total_margin), 0) / COALESCE(SUM(curr.total_revenue), 0) * 100)
          ELSE 0
        END,
        'call_revenue', COALESCE(SUM(curr.call_revenue), 0),
        'sms_revenue', COALESCE(SUM(curr.sms_revenue), 0),
        'email_revenue', COALESCE(SUM(curr.email_revenue), 0),
        'leasing_revenue', COALESCE(SUM(curr.leasing_revenue_daily), 0),
        'call_provider_cost', COALESCE(SUM(curr.call_provider_cost), 0),
        'sms_provider_cost', COALESCE(SUM(curr.sms_provider_cost), 0),
        'email_provider_cost', COALESCE(SUM(curr.email_provider_cost), 0),
        'call_count', COALESCE(SUM(curr.call_count), 0),
        'answered_calls', COALESCE(SUM(curr.answered_calls), 0),
        'appointments_scheduled', COALESCE(SUM(curr.appointments_scheduled), 0),
        'sms_count', COALESCE(SUM(curr.sms_count), 0),
        'email_count', COALESCE(SUM(curr.email_count), 0),
        'unique_clients', COUNT(DISTINCT curr.client_id),
        'unique_deployments', COUNT(DISTINCT curr.deployment_id),
        'avg_revenue_per_client', CASE
          WHEN COUNT(DISTINCT curr.client_id) > 0
          THEN COALESCE(SUM(curr.total_revenue), 0) / COUNT(DISTINCT curr.client_id)
          ELSE 0
        END,
        'avg_margin_per_client', CASE
          WHEN COUNT(DISTINCT curr.client_id) > 0
          THEN COALESCE(SUM(curr.total_margin), 0) / COUNT(DISTINCT curr.client_id)
          ELSE 0
        END
      ) AS current_metrics,

      jsonb_build_object(
        'total_revenue', COALESCE(SUM(prev.total_revenue), 0),
        'total_provider_cost', COALESCE(SUM(prev.total_provider_cost), 0),
        'total_margin', COALESCE(SUM(prev.total_margin), 0),
        'margin_percentage', CASE
          WHEN COALESCE(SUM(prev.total_revenue), 0) > 0
          THEN (COALESCE(SUM(prev.total_margin), 0) / COALESCE(SUM(prev.total_revenue), 0) * 100)
          ELSE 0
        END
      ) AS previous_metrics,

      jsonb_build_object(
        'start_date', p_start_date,
        'end_date', p_end_date,
        'duration_days', p_end_date - p_start_date + 1,
        'previous_start_date', p_start_date - (p_end_date - p_start_date + 1),
        'previous_end_date', p_start_date - 1
      ) AS period_info,

      jsonb_build_object(
        'revenue_change', COALESCE(SUM(curr.total_revenue), 0) - COALESCE(SUM(prev.total_revenue), 0),
        'revenue_change_percentage', CASE
          WHEN COALESCE(SUM(prev.total_revenue), 0) > 0
          THEN ((COALESCE(SUM(curr.total_revenue), 0) - COALESCE(SUM(prev.total_revenue), 0)) / COALESCE(SUM(prev.total_revenue), 0) * 100)
          ELSE 0
        END,
        'margin_change', COALESCE(SUM(curr.total_margin), 0) - COALESCE(SUM(prev.total_margin), 0),
        'margin_change_percentage', CASE
          WHEN COALESCE(SUM(prev.total_margin), 0) > 0
          THEN ((COALESCE(SUM(curr.total_margin), 0) - COALESCE(SUM(prev.total_margin), 0)) / COALESCE(SUM(prev.total_margin), 0) * 100)
          ELSE 0
        END
      ) AS comparison
    FROM v_financial_metrics_enriched curr
    LEFT JOIN v_financial_metrics_enriched prev ON
      prev.deployment_id = curr.deployment_id
      AND prev.metric_date >= (p_start_date - (p_end_date - p_start_date + 1))
      AND prev.metric_date < p_start_date
    WHERE curr.metric_date >= p_start_date
      AND curr.metric_date <= p_end_date
      AND curr.user_has_access = true
      AND (p_client_id IS NULL OR curr.client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR curr.agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR curr.deployment_id = p_deployment_id)
  ) sub;

  RETURN v_result;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_financial_kpi_metrics(DATE, DATE, UUID, TEXT, UUID) TO authenticated;

-- Verification query
-- SELECT jsonb_pretty(get_financial_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE));
