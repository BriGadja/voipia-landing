-- ============================================================================
-- Function: get_leasing_kpi_metrics
-- Description: Returns KPI metrics for LEASING ONLY (subscription revenue)
-- Author: Claude
-- Date: 2025-01-18
-- Version: 1.0
-- ============================================================================
--
-- Purpose: Calculate KPIs specific to leasing/subscription business model
-- Returns: JSONB object with leasing-specific metrics
--
-- Usage:
--   SELECT get_leasing_kpi_metrics(
--     '2024-12-01',
--     '2025-01-18'
--   );
-- ============================================================================

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
  -- Calculate period duration
  v_duration_days := p_end_date - p_start_date + 1;

  -- Build result with leasing KPIs
  SELECT JSONB_BUILD_OBJECT(
    -- Total leasing revenue (pro-rated for period)
    'total_leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),

    -- Number of active deployments with leasing
    'active_leasing_count', COUNT(DISTINCT CASE
      WHEN leasing_revenue_daily > 0 THEN deployment_id
      ELSE NULL
    END),

    -- Average leasing revenue per client
    'avg_leasing_per_client', CASE
      WHEN COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN client_id ELSE NULL END) > 0
      THEN ROUND((SUM(leasing_revenue_daily) /
                  COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN client_id ELSE NULL END))::numeric, 2)
      ELSE 0
    END,

    -- Monthly Recurring Revenue (MRR) - Annualized leasing
    'mrr', CASE
      WHEN v_duration_days > 0
      THEN ROUND((SUM(leasing_revenue_daily) / v_duration_days * 30)::numeric, 2)
      ELSE 0
    END,

    -- Average leasing per deployment (monthly equivalent)
    'avg_monthly_leasing', CASE
      WHEN COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END) > 0
        AND v_duration_days > 0
      THEN ROUND((
        (SUM(leasing_revenue_daily) / v_duration_days * 30) /
        COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END)
      )::numeric, 2)
      ELSE 0
    END,

    -- Total number of unique clients with leasing
    'leasing_client_count', COUNT(DISTINCT CASE
      WHEN leasing_revenue_daily > 0 THEN client_id
      ELSE NULL
    END),

    -- Leasing adoption rate (deployments with leasing / total deployments)
    'leasing_adoption_rate', CASE
      WHEN COUNT(DISTINCT deployment_id) > 0
      THEN ROUND((
        COUNT(DISTINCT CASE WHEN leasing_revenue_daily > 0 THEN deployment_id ELSE NULL END)::numeric /
        COUNT(DISTINCT deployment_id) * 100
      )::numeric, 2)
      ELSE 0
    END,

    -- Total margin (same as revenue since leasing has 100% margin)
    'total_leasing_margin', COALESCE(SUM(leasing_margin_daily), 0),

    -- Margin percentage (always 100% for leasing)
    'leasing_margin_pct', 100

  ) INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true;

  -- Return result
  RETURN COALESCE(v_result, JSONB_BUILD_OBJECT(
    'total_leasing_revenue', 0,
    'active_leasing_count', 0,
    'avg_leasing_per_client', 0,
    'mrr', 0,
    'avg_monthly_leasing', 0,
    'leasing_client_count', 0,
    'leasing_adoption_rate', 0,
    'total_leasing_margin', 0,
    'leasing_margin_pct', 100
  ));

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_leasing_kpi_metrics: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_leasing_kpi_metrics(DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_leasing_kpi_metrics IS
  'Returns KPI metrics for leasing/subscription revenue only. Includes MRR, adoption rate, and per-client averages.';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames
-- FROM pg_proc
-- WHERE proname = 'get_leasing_kpi_metrics';

-- Test 2: Get leasing KPIs for last 30 days
-- SELECT get_leasing_kpi_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE
-- );

-- Test 3: Format result for readability
-- SELECT
--   result->>'total_leasing_revenue' as total_revenue,
--   result->>'active_leasing_count' as active_count,
--   result->>'avg_leasing_per_client' as avg_per_client,
--   result->>'mrr' as monthly_recurring_revenue,
--   result->>'leasing_adoption_rate' as adoption_rate,
--   result->>'leasing_margin_pct' as margin_percentage
-- FROM (
--   SELECT get_leasing_kpi_metrics(CURRENT_DATE - 30, CURRENT_DATE) as result
-- ) sub;
