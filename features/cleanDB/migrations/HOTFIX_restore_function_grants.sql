-- ============================================
-- HOTFIX: RESTORE EXECUTE GRANTS ON RPC FUNCTIONS
-- Date: 2025-01-13
-- Issue: Dashboard filters not working - missing EXECUTE permissions
-- ============================================
--
-- Problem: After migration, RPC functions exist but EXECUTE grants are missing
-- Solution: Restore all necessary EXECUTE grants on RPC functions
--
-- Duration: < 10 seconds
-- Impact: Restores dashboard filter functionality immediately
--
-- Root Cause Analysis:
-- The migration converted views from SECURITY DEFINER to SECURITY INVOKER.
-- This is more secure but requires explicit grants on all underlying objects.
-- RPC functions used by dashboards lost their EXECUTE permissions during cleanup.
--
-- ============================================

-- ============================================
-- LOUIS DASHBOARD FUNCTIONS
-- ============================================

-- Main KPI metrics function for Louis dashboard
GRANT EXECUTE ON FUNCTION get_kpi_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid,
  p_deployment_id uuid,
  p_agent_type_name text
) TO authenticated, anon;

-- Chart data function for Louis dashboard
GRANT EXECUTE ON FUNCTION get_chart_data(
  p_start_date date,
  p_end_date date,
  p_client_id uuid,
  p_deployment_id uuid,
  p_agent_type_name text
) TO authenticated, anon;

-- ============================================
-- ARTHUR DASHBOARD FUNCTIONS
-- ============================================

-- Arthur-specific KPI metrics
GRANT EXECUTE ON FUNCTION get_arthur_kpi_metrics(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid,
  p_agent_type_id uuid
) TO authenticated, anon;

-- Arthur-specific chart data
GRANT EXECUTE ON FUNCTION get_arthur_chart_data(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid,
  p_agent_type_id uuid
) TO authenticated, anon;

-- ============================================
-- GLOBAL DASHBOARD FUNCTIONS
-- ============================================

-- Global KPI metrics (all agents)
GRANT EXECUTE ON FUNCTION get_global_kpis(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid,
  p_deployment_id uuid,
  p_agent_type_name text
) TO authenticated, anon;

-- Global chart data (all agents)
GRANT EXECUTE ON FUNCTION get_global_chart_data(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid,
  p_deployment_id uuid,
  p_agent_type_name text
) TO authenticated, anon;

-- Agent cards data (grouped by agent deployment)
GRANT EXECUTE ON FUNCTION get_agent_cards_data(
  p_start_date date,
  p_end_date date,
  p_client_ids uuid[]
) TO authenticated, anon;

-- Agent type cards data (grouped by agent type)
GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(
  p_start_date date,
  p_end_date date,
  p_client_ids uuid[]
) TO authenticated, anon;

-- Client cards data (grouped by client)
GRANT EXECUTE ON FUNCTION get_client_cards_data(
  p_start_date date,
  p_end_date date
) TO authenticated, anon;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify EXECUTE grants are applied (should return 9 functions × 2 grantees = 18 rows minimum)
SELECT
  r.routine_name,
  p.grantee,
  p.privilege_type
FROM information_schema.routines r
JOIN information_schema.routine_privileges p
  ON r.routine_name = p.routine_name AND r.routine_schema = p.routine_schema
WHERE r.routine_schema = 'public'
  AND r.routine_type = 'FUNCTION'
  AND r.routine_name LIKE 'get_%'
  AND p.grantee IN ('authenticated', 'anon')
ORDER BY r.routine_name, p.grantee;

-- Test that functions are now executable (should return data, not permission errors)
SELECT 'get_kpi_metrics test' as function_test,
  (SELECT COUNT(*) FROM get_kpi_metrics(
    (CURRENT_DATE - INTERVAL '30 days')::date,
    CURRENT_DATE::date,
    NULL, NULL, 'louis'
  )) as result;

-- ============================================
-- END OF HOTFIX
-- ============================================
