-- ============================================
-- DIAGNOSTIC: CHECK ALL PERMISSIONS
-- Date: 2025-01-13
-- Purpose: Verify all grants and RLS policies are in place
-- ============================================

-- ============================================
-- 1. CHECK GRANTS ON VIEWS
-- ============================================
SELECT
  'GRANT CHECK - VIEWS' as check_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) >= 32 THEN '✅ OK (should be 16 views × 2 roles = 32)'
    ELSE '❌ MISSING GRANTS'
  END as status
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name LIKE 'v_%'
  AND grantee IN ('authenticated', 'anon')
  AND privilege_type = 'SELECT';

-- Details of missing grants on views
SELECT
  v.table_name,
  COALESCE(STRING_AGG(DISTINCT g.grantee, ', '), 'NO GRANTS') as grantees
FROM information_schema.views v
LEFT JOIN information_schema.role_table_grants g
  ON v.table_name = g.table_name
  AND v.table_schema = g.table_schema
  AND g.grantee IN ('authenticated', 'anon')
WHERE v.table_schema = 'public'
  AND v.table_name LIKE 'v_%'
GROUP BY v.table_name
HAVING COUNT(g.grantee) < 2
ORDER BY v.table_name;

-- ============================================
-- 2. CHECK GRANTS ON RPC FUNCTIONS
-- ============================================
SELECT
  'GRANT CHECK - RPC FUNCTIONS' as check_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) >= 18 THEN '✅ OK (should be 9 functions × 2 roles = 18)'
    ELSE '❌ MISSING GRANTS'
  END as status
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND routine_name LIKE 'get_%'
  AND grantee IN ('authenticated', 'anon')
  AND privilege_type = 'EXECUTE';

-- Details of missing grants on functions
SELECT
  r.routine_name,
  COALESCE(STRING_AGG(DISTINCT p.grantee, ', '), 'NO GRANTS') as grantees
FROM information_schema.routines r
LEFT JOIN information_schema.routine_privileges p
  ON r.routine_name = p.routine_name
  AND r.routine_schema = p.routine_schema
  AND p.grantee IN ('authenticated', 'anon')
WHERE r.routine_schema = 'public'
  AND r.routine_type = 'FUNCTION'
  AND r.routine_name LIKE 'get_%'
GROUP BY r.routine_name
HAVING COUNT(p.grantee) < 2
ORDER BY r.routine_name;

-- ============================================
-- 3. CHECK RLS POLICIES
-- ============================================
SELECT
  'RLS POLICIES CHECK' as check_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) >= 11 THEN '✅ OK (should have at least 11 consolidated policies)'
    ELSE '❌ MISSING POLICIES'
  END as status
FROM pg_policies
WHERE schemaname = 'public';

-- List all RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- 4. CHECK SECURITY INVOKER ON VIEWS
-- ============================================
SELECT
  'SECURITY INVOKER CHECK' as check_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ OK (all views use SECURITY INVOKER)'
    ELSE '❌ SOME VIEWS STILL USE SECURITY DEFINER'
  END as status
FROM pg_views v
WHERE v.schemaname = 'public'
  AND v.viewname LIKE 'v_%'
  AND EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = v.viewname
      AND n.nspname = v.schemaname
      AND c.reloptions::text LIKE '%security_invoker=false%'
  );

-- ============================================
-- 5. TEST DATA ACCESS (AS AUTHENTICATED USER)
-- ============================================
-- Note: These queries will only work if you're logged in as an authenticated user

-- Test accessible clients view
SELECT
  'v_user_accessible_clients' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ OK (data accessible)'
    ELSE '⚠️ NO DATA (check RLS policies and user permissions)'
  END as status
FROM v_user_accessible_clients;

-- Test accessible agents view
SELECT
  'v_user_accessible_agents' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ OK (data accessible)'
    ELSE '⚠️ NO DATA (check RLS policies and user permissions)'
  END as status
FROM v_user_accessible_agents;

-- Test agent calls enriched view
SELECT
  'v_agent_calls_enriched' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ OK (data accessible)'
    ELSE '⚠️ NO DATA (check RLS policies and user permissions)'
  END as status
FROM v_agent_calls_enriched;

-- ============================================
-- 6. TEST RPC FUNCTION EXECUTION
-- ============================================
-- Test get_kpi_metrics function
SELECT
  'get_kpi_metrics function test' as test_name,
  CASE
    WHEN (SELECT get_kpi_metrics(
      (CURRENT_DATE - INTERVAL '30 days')::date,
      CURRENT_DATE::date,
      NULL, NULL, 'louis'
    )) IS NOT NULL THEN '✅ OK (function executable and returns data)'
    ELSE '⚠️ FUNCTION RETURNS NULL'
  END as status;

-- ============================================
-- SUMMARY
-- ============================================
SELECT
  '=================== DIAGNOSTIC SUMMARY ===================' as summary;

-- Count issues
SELECT
  'TOTAL ISSUES FOUND' as metric,
  (
    -- Missing view grants
    (SELECT COUNT(*) FROM (
      SELECT v.table_name
      FROM information_schema.views v
      LEFT JOIN information_schema.role_table_grants g
        ON v.table_name = g.table_name
        AND v.table_schema = g.table_schema
        AND g.grantee IN ('authenticated', 'anon')
      WHERE v.table_schema = 'public'
        AND v.table_name LIKE 'v_%'
      GROUP BY v.table_name
      HAVING COUNT(g.grantee) < 2
    ) sub)
    +
    -- Missing function grants
    (SELECT COUNT(*) FROM (
      SELECT r.routine_name
      FROM information_schema.routines r
      LEFT JOIN information_schema.routine_privileges p
        ON r.routine_name = p.routine_name
        AND r.routine_schema = p.routine_schema
        AND p.grantee IN ('authenticated', 'anon')
      WHERE r.routine_schema = 'public'
        AND r.routine_type = 'FUNCTION'
        AND r.routine_name LIKE 'get_%'
      GROUP BY r.routine_name
      HAVING COUNT(p.grantee) < 2
    ) sub)
  ) as count;

SELECT 'Run HOTFIX_restore_grants.sql and HOTFIX_restore_function_grants.sql to fix missing grants.' as recommendation
WHERE (
  SELECT COUNT(*)
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND table_name LIKE 'v_%'
    AND grantee IN ('authenticated', 'anon')
) < 32
OR (
  SELECT COUNT(*)
  FROM information_schema.routine_privileges
  WHERE routine_schema = 'public'
    AND routine_name LIKE 'get_%'
    AND grantee IN ('authenticated', 'anon')
) < 18;

-- ============================================
-- END OF DIAGNOSTIC
-- ============================================
