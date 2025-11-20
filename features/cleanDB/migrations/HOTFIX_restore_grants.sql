-- ============================================
-- HOTFIX: RESTORE GRANTS ON VIEWS
-- Date: 2025-01-13
-- Issue: Dashboard filters not working - missing grants
-- ============================================
--
-- Problem: After migration, views exist but grants are missing
-- Solution: Restore all necessary grants on views
--
-- Duration: < 10 seconds
-- Impact: Restores dashboard functionality immediately
--
-- ============================================

-- Grant access to filter views
GRANT SELECT ON v_user_accessible_clients TO authenticated, anon;
GRANT SELECT ON v_user_accessible_agents TO authenticated, anon;

-- Grant access to enriched views
GRANT SELECT ON v_agent_calls_enriched TO authenticated, anon;
GRANT SELECT ON v_arthur_calls_enriched TO authenticated, anon;

-- Grant access to performance views
GRANT SELECT ON v_louis_agent_performance TO authenticated, anon;

-- Grant access to global KPI views
GRANT SELECT ON v_global_kpis TO authenticated, anon;
GRANT SELECT ON v_global_outcome_distribution TO authenticated, anon;
GRANT SELECT ON v_global_call_volume_by_day TO authenticated, anon;
GRANT SELECT ON v_global_agent_type_performance TO authenticated, anon;
GRANT SELECT ON v_global_top_clients TO authenticated, anon;

-- Grant access to Arthur next calls views
GRANT SELECT ON v_arthur_next_calls TO authenticated, anon;
GRANT SELECT ON v_arthur_next_calls_global TO authenticated, anon;
GRANT SELECT ON v_arthur_next_call_norloc TO authenticated, anon;
GRANT SELECT ON v_arthur_next_call_stefanodesign TO authenticated, anon;
GRANT SELECT ON v_arthur_next_call_exoticdesign TO authenticated, anon;

-- Grant access to prospects view
GRANT SELECT ON v_prospects_attempts_exceeded TO authenticated, anon;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify grants are applied (should return 16 rows minimum)
SELECT
  table_name,
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name LIKE 'v_%'
  AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee;

-- Test that views are now accessible
SELECT 'v_user_accessible_clients' as view_test, COUNT(*) FROM v_user_accessible_clients
UNION ALL
SELECT 'v_user_accessible_agents', COUNT(*) FROM v_user_accessible_agents
UNION ALL
SELECT 'v_agent_calls_enriched', COUNT(*) FROM v_agent_calls_enriched;

-- ============================================
-- END OF HOTFIX
-- ============================================
