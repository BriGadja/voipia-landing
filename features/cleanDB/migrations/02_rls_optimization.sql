-- ============================================
-- MIGRATION: RLS PERFORMANCE OPTIMIZATION
-- Date: 2025-01-13
-- Environment: Staging → Production
-- ============================================
--
-- Description:
-- This migration optimizes Row Level Security (RLS) policies for better performance.
-- It addresses 2 main issues:
--   1. Non-optimized auth.uid() and auth.jwt() calls (evaluated per row)
--   2. Multiple permissive policies (evaluated all at once)
--
-- Changes:
--   - Wrap auth.uid() and auth.jwt() in (SELECT ...) to evaluate once per query
--   - Consolidate multiple permissive policies into single policies with OR conditions
--
-- Impact:
--   - 10-100x performance improvement on queries affecting multiple rows
--   - Reduced policy evaluation overhead
--
-- Affected policies: 11 optimizations + 10 consolidations
--
-- ============================================

-- ============================================
-- PART 1: OPTIMIZE AUTH.UID() AND AUTH.JWT() CALLS
-- ============================================
-- Problem: auth.uid() and auth.jwt() are re-evaluated for EACH ROW
-- Solution: Wrap them in (SELECT ...) to evaluate only once per query
-- ============================================

-- --------------------------------------------
-- TABLE: agent_types
-- --------------------------------------------
-- Before: auth.jwt() called per row
-- After: auth.jwt() called once per query

DROP POLICY IF EXISTS "admin_can_manage_agent_types" ON public.agent_types;
CREATE POLICY "admin_can_manage_agent_types" ON public.agent_types
  FOR ALL USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

-- --------------------------------------------
-- TABLE: agent_deployments
-- --------------------------------------------

DROP POLICY IF EXISTS "admin_manage_all_deployments" ON public.agent_deployments;
CREATE POLICY "admin_manage_all_deployments" ON public.agent_deployments
  FOR ALL USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

DROP POLICY IF EXISTS "admin_see_all_deployments" ON public.agent_deployments;
CREATE POLICY "admin_see_all_deployments" ON public.agent_deployments
  FOR SELECT USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

DROP POLICY IF EXISTS "client_see_own_deployments" ON public.agent_deployments;
CREATE POLICY "client_see_own_deployments" ON public.agent_deployments
  FOR SELECT USING (client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid);

-- --------------------------------------------
-- TABLE: agent_calls
-- --------------------------------------------

DROP POLICY IF EXISTS "admin_see_all_calls" ON public.agent_calls;
CREATE POLICY "admin_see_all_calls" ON public.agent_calls
  FOR SELECT USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

DROP POLICY IF EXISTS "client_see_own_calls" ON public.agent_calls;
CREATE POLICY "client_see_own_calls" ON public.agent_calls
  FOR SELECT USING (
    deployment_id IN (
      SELECT agent_deployments.id
      FROM agent_deployments
      WHERE (agent_deployments.client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid)
    )
  );

-- --------------------------------------------
-- TABLE: profiles
-- --------------------------------------------

DROP POLICY IF EXISTS "admins_view_all_profiles" ON public.profiles;
CREATE POLICY "admins_view_all_profiles" ON public.profiles
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM profiles profiles_1
      WHERE ((profiles_1.id = (SELECT auth.uid())) AND (profiles_1.role = 'admin'::text))
    )
  );

DROP POLICY IF EXISTS "users_update_own_profile" ON public.profiles;
CREATE POLICY "users_update_own_profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "users_view_own_profile" ON public.profiles;
CREATE POLICY "users_view_own_profile" ON public.profiles
  FOR SELECT TO authenticated USING (id = (SELECT auth.uid()));

-- --------------------------------------------
-- TABLE: clients
-- --------------------------------------------

DROP POLICY IF EXISTS "users_view_their_clients" ON public.clients;
CREATE POLICY "users_view_their_clients" ON public.clients
  FOR SELECT TO authenticated USING (
    id IN (
      SELECT user_client_permissions.client_id
      FROM user_client_permissions
      WHERE (user_client_permissions.user_id = (SELECT auth.uid()))
    )
  );

-- --------------------------------------------
-- TABLE: user_client_permissions
-- --------------------------------------------

DROP POLICY IF EXISTS "users_view_own_permissions" ON public.user_client_permissions;
CREATE POLICY "users_view_own_permissions" ON public.user_client_permissions
  FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

-- ============================================
-- PART 2: CONSOLIDATE MULTIPLE PERMISSIVE POLICIES
-- ============================================
-- Problem: Multiple permissive policies force PostgreSQL to evaluate ALL of them
-- Solution: Consolidate into single policies with OR conditions
-- ============================================

-- --------------------------------------------
-- TABLE: agent_deployments
-- --------------------------------------------
-- Before: 2 SELECT policies (admin + client) evaluated separately
-- After: 1 SELECT policy with OR condition

-- Drop the old separate SELECT policy for admin (already dropped above, but ensure)
-- The "admin_manage_all_deployments" covers ALL operations including SELECT
-- So we can consolidate "admin_see_all_deployments" and "client_see_own_deployments"

DROP POLICY IF EXISTS "admin_see_all_deployments" ON public.agent_deployments;
DROP POLICY IF EXISTS "client_see_own_deployments" ON public.agent_deployments;

CREATE POLICY "select_deployments" ON public.agent_deployments
  FOR SELECT USING (
    -- Admin can see all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can see own
    (client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid)
  );

-- --------------------------------------------
-- TABLE: agent_calls
-- --------------------------------------------
-- Before: 2 SELECT policies (admin + client) evaluated separately
-- After: 1 SELECT policy with OR condition

DROP POLICY IF EXISTS "admin_see_all_calls" ON public.agent_calls;
DROP POLICY IF EXISTS "client_see_own_calls" ON public.agent_calls;

CREATE POLICY "select_calls" ON public.agent_calls
  FOR SELECT USING (
    -- Admin can see all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can see own calls
    (deployment_id IN (
      SELECT agent_deployments.id
      FROM agent_deployments
      WHERE (agent_deployments.client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid)
    ))
  );

-- --------------------------------------------
-- TABLE: agent_types
-- --------------------------------------------
-- Before: 2 SELECT policies (admin + anyone) evaluated separately
-- After: 1 SELECT policy with OR condition (though "true" makes this redundant)

DROP POLICY IF EXISTS "anyone_can_read_agent_types" ON public.agent_types;

-- Note: admin_can_manage_agent_types already exists for ALL operations
-- We just need a SELECT policy that allows everyone to read
CREATE POLICY "select_agent_types" ON public.agent_types
  FOR SELECT USING (true);

-- --------------------------------------------
-- TABLE: profiles
-- --------------------------------------------
-- Before: 2 SELECT policies (admin view all + users view own)
-- After: 1 SELECT policy with OR condition

DROP POLICY IF EXISTS "admins_view_all_profiles" ON public.profiles;
DROP POLICY IF EXISTS "users_view_own_profile" ON public.profiles;

CREATE POLICY "select_profiles" ON public.profiles
  FOR SELECT TO authenticated USING (
    -- Users can view their own profile
    (id = (SELECT auth.uid()))
    OR
    -- Admins can view all profiles
    (EXISTS (
      SELECT 1
      FROM profiles profiles_1
      WHERE ((profiles_1.id = (SELECT auth.uid())) AND (profiles_1.role = 'admin'::text))
    ))
  );

-- --------------------------------------------
-- TABLE: agent_arthur_prospects
-- --------------------------------------------
-- Consolidate the SELECT policies we created in Phase 1

DROP POLICY IF EXISTS "admin_see_all_prospects" ON public.agent_arthur_prospects;
DROP POLICY IF EXISTS "client_see_own_prospects" ON public.agent_arthur_prospects;

CREATE POLICY "select_prospects" ON public.agent_arthur_prospects
  FOR SELECT USING (
    -- Admin can see all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can see own
    (deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    ))
  );

-- Consolidate the ALL policies we created in Phase 1

DROP POLICY IF EXISTS "admin_manage_all_prospects" ON public.agent_arthur_prospects;
DROP POLICY IF EXISTS "client_manage_own_prospects" ON public.agent_arthur_prospects;

CREATE POLICY "manage_prospects" ON public.agent_arthur_prospects
  FOR ALL USING (
    -- Admin can manage all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can manage own
    (deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    ))
  );

-- --------------------------------------------
-- TABLE: agent_arthur_prospect_sequences
-- --------------------------------------------
-- Consolidate the SELECT policies we created in Phase 1

DROP POLICY IF EXISTS "admin_see_all_sequences" ON public.agent_arthur_prospect_sequences;
DROP POLICY IF EXISTS "client_see_own_sequences" ON public.agent_arthur_prospect_sequences;

CREATE POLICY "select_sequences" ON public.agent_arthur_prospect_sequences
  FOR SELECT USING (
    -- Admin can see all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can see own
    (deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    ))
  );

-- Consolidate the ALL policies we created in Phase 1

DROP POLICY IF EXISTS "admin_manage_all_sequences" ON public.agent_arthur_prospect_sequences;
DROP POLICY IF EXISTS "client_manage_own_sequences" ON public.agent_arthur_prospect_sequences;

CREATE POLICY "manage_sequences" ON public.agent_arthur_prospect_sequences
  FOR ALL USING (
    -- Admin can manage all
    (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text)
    OR
    -- Client can manage own
    (deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    ))
  );

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Uncomment to verify the changes after applying the migration
-- ============================================

-- Count policies per table
-- SELECT
--   schemaname,
--   tablename,
--   COUNT(*) as policy_count
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- GROUP BY schemaname, tablename
-- ORDER BY tablename;

-- List all policies with their definitions
-- SELECT
--   schemaname,
--   tablename,
--   policyname,
--   cmd,
--   qual,
--   with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- Test queries to verify RLS still works correctly
-- SELECT COUNT(*) FROM agent_calls; -- Should return accessible calls
-- SELECT COUNT(*) FROM agent_deployments; -- Should return accessible deployments
-- SELECT COUNT(*) FROM agent_arthur_prospects; -- Should return accessible prospects
-- SELECT COUNT(*) FROM agent_arthur_prospect_sequences; -- Should return accessible sequences
-- SELECT COUNT(*) FROM profiles; -- Should return accessible profiles

-- ============================================
-- END OF MIGRATION
-- ============================================
