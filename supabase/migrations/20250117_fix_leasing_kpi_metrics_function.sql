-- Migration: Fix get_leasing_kpi_metrics function
-- Date: 2025-01-17
-- Author: Claude
--
-- Problem: Function tries to access leasing_margin_daily that doesn't exist
-- Solution: Calculate leasing margin as leasing_revenue_daily (assuming 100% margin since it's pure subscription)
--
-- Changes:
-- - leasing_margin_daily = leasing_revenue_daily (100% margin, no provider cost for subscription)

DROP FUNCTION IF EXISTS get_leasing_kpi_metrics(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_leasing_kpi_metrics(
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
    RAISE EXCEPTION 'Access denied: Admin permission required to view leasing metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate leasing metrics
  -- Note: Leasing has 100% margin (no provider cost), so margin = revenue
  SELECT jsonb_build_object(
    'total_leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
    'active_leasing_count', COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0),
    'avg_leasing_per_client', CASE
      WHEN COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0) > 0
      THEN COALESCE(SUM(leasing_revenue_daily), 0) / COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0)
      ELSE 0
    END,
    'mrr', COALESCE(SUM(leasing_revenue_daily), 0) * 30 / NULLIF(p_end_date - p_start_date + 1, 0),
    'avg_monthly_leasing', COALESCE(SUM(leasing_revenue_daily), 0) * 30 / NULLIF(COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0), 0),
    'leasing_client_count', COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0),
    'leasing_adoption_rate', CASE
      WHEN COUNT(DISTINCT deployment_id) > 0
      THEN (COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0)::numeric / COUNT(DISTINCT deployment_id) * 100)
      ELSE 0
    END,
    'total_leasing_margin', COALESCE(SUM(leasing_revenue_daily), 0),
    'leasing_margin_pct', 100.0
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
GRANT EXECUTE ON FUNCTION get_leasing_kpi_metrics(DATE, DATE) TO authenticated;

-- Verification query
-- SELECT jsonb_pretty(get_leasing_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE));
