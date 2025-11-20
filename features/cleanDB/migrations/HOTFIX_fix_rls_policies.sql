-- ============================================
-- HOTFIX: FIX RLS POLICIES WITH INVALID JWT CHECKS
-- Date: 2025-01-13
-- Issue: Dashboard filters not working - RLS policies use non-existent JWT keys
-- ============================================
--
-- Problem: RLS policies check for JWT keys that don't exist:
--   - auth.jwt() ->> 'role' = 'admin' ❌ (JWT contains 'authenticated', not 'admin')
--   - auth.jwt() ->> 'client_id' ❌ (this key doesn't exist in default Supabase JWT)
--
-- With SECURITY DEFINER, these broken policies were hidden (views bypassed RLS).
-- With SECURITY INVOKER, views now respect RLS, exposing the broken policies.
--
-- Solution: Replace JWT checks with proper auth.uid() + user_client_permissions joins
--
-- Duration: < 10 seconds
-- Impact: Restores dashboard filter functionality completely
--
-- ============================================

-- ============================================
-- 1. FIX agent_deployments RLS POLICIES
-- ============================================

-- Drop old broken policy
DROP POLICY IF EXISTS select_deployments ON agent_deployments;
DROP POLICY IF EXISTS admin_manage_all_deployments ON agent_deployments;

-- Create correct policy using user_client_permissions
CREATE POLICY "users_view_accessible_deployments"
ON agent_deployments
FOR SELECT
TO authenticated
USING (
  client_id IN (
    SELECT client_id
    FROM user_client_permissions
    WHERE user_id = auth.uid()
  )
);

-- Policy for admins to manage deployments (based on user_client_permissions.permission_level)
CREATE POLICY "admins_manage_deployments"
ON agent_deployments
FOR ALL
TO authenticated
USING (
  client_id IN (
    SELECT client_id
    FROM user_client_permissions
    WHERE user_id = auth.uid()
      AND permission_level = 'admin'
  )
)
WITH CHECK (
  client_id IN (
    SELECT client_id
    FROM user_client_permissions
    WHERE user_id = auth.uid()
      AND permission_level = 'admin'
  )
);

-- ============================================
-- 2. FIX agent_calls RLS POLICIES
-- ============================================

-- Drop old broken policy
DROP POLICY IF EXISTS select_calls ON agent_calls;

-- Create correct policy using user_client_permissions + agent_deployments join
CREATE POLICY "users_view_accessible_calls"
ON agent_calls
FOR SELECT
TO authenticated
USING (
  deployment_id IN (
    SELECT ad.id
    FROM agent_deployments ad
    INNER JOIN user_client_permissions ucp
      ON ucp.client_id = ad.client_id
    WHERE ucp.user_id = auth.uid()
  )
);

-- ============================================
-- 3. VERIFICATION
-- ============================================

-- Verify new policies are in place
SELECT
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('agent_deployments', 'agent_calls')
ORDER BY tablename, policyname;

-- Test that policies work (should return data for authenticated users)
-- Note: This will only work when executed as an authenticated user

SELECT 'agent_deployments test' as test_name, COUNT(*) as accessible_count
FROM agent_deployments;

SELECT 'agent_calls test' as test_name, COUNT(*) as accessible_count
FROM agent_calls;

-- Test the filter views that were failing
SELECT 'v_user_accessible_clients test' as test_name, COUNT(*) as count
FROM v_user_accessible_clients;

SELECT 'v_user_accessible_agents test' as test_name, COUNT(*) as count
FROM v_user_accessible_agents;

-- ============================================
-- EXPECTED RESULTS
-- ============================================
-- After applying this fix:
-- ✅ agent_deployments should return all accessible deployments
-- ✅ agent_calls should return all accessible calls
-- ✅ v_user_accessible_clients should return accessible clients
-- ✅ v_user_accessible_agents should return accessible agents
-- ✅ Dashboard filters should work correctly
--
-- The issue was: JWT-based policies don't work because JWT doesn't contain
-- the 'role' or 'client_id' keys that the old policies were checking for.
--
-- The solution: Use auth.uid() + join with user_client_permissions table
-- which is the correct Supabase RLS pattern.
--
-- ============================================
-- END OF HOTFIX
-- ============================================
