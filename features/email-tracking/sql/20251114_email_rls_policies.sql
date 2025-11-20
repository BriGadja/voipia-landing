-- Migration: RLS Policies and Grants for agent_emails
-- Date: 2025-11-14
-- Author: Claude
-- Feature: Email Tracking System - Security Layer
--
-- Changes:
-- 1. Enable RLS on agent_emails table
-- 2. Create 4 RLS policies (users view, admins manage, service insert/update)
-- 3. Grant appropriate permissions to roles
--
-- Security Model:
-- - Users can SELECT emails from their accessible clients (via user_client_permissions)
-- - Admins can ALL (SELECT, INSERT, UPDATE, DELETE) on their clients' emails
-- - Service role (n8n) can INSERT new emails and UPDATE existing ones
--
-- Inherited from: agent_sms RLS policies (same security logic)

-- ============================================================================
-- 1. DROP EXISTING POLICIES (if any)
-- ============================================================================

-- Drop policies
DROP POLICY IF EXISTS users_view_accessible_emails ON public.agent_emails;
DROP POLICY IF EXISTS admins_manage_emails ON public.agent_emails;
DROP POLICY IF EXISTS service_insert_emails ON public.agent_emails;
DROP POLICY IF EXISTS service_update_emails ON public.agent_emails;

-- Disable RLS (will re-enable after creating policies)
ALTER TABLE public.agent_emails DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.agent_emails ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agent_emails IS 'Tracks all emails sent by Voipia agents (RLS enabled)';

-- ============================================================================
-- 3. CREATE RLS POLICIES
-- ============================================================================

-- Policy 1: Users can view emails from their accessible clients (SELECT)
-- Users can only see emails sent by deployments belonging to clients they have access to
CREATE POLICY users_view_accessible_emails ON public.agent_emails
FOR SELECT
TO authenticated
USING (
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid()
    )
);

COMMENT ON POLICY users_view_accessible_emails ON public.agent_emails IS 'Users can SELECT emails from deployments of their accessible clients';

-- Policy 2: Admins can manage emails for their clients (ALL operations)
-- Admins with permission_level = 'admin' can perform all operations
CREATE POLICY admins_manage_emails ON public.agent_emails
FOR ALL
TO authenticated
USING (
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid() AND ucp.permission_level = 'admin'
    )
)
WITH CHECK (
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid() AND ucp.permission_level = 'admin'
    )
);

COMMENT ON POLICY admins_manage_emails ON public.agent_emails IS 'Admins can perform all operations (SELECT, INSERT, UPDATE, DELETE) on their clients emails';

-- Policy 3: Service role can insert emails (n8n workflows)
-- n8n workflows use service_role credentials to log emails after sending via Gmail
CREATE POLICY service_insert_emails ON public.agent_emails
FOR INSERT
TO service_role
WITH CHECK (true);

COMMENT ON POLICY service_insert_emails ON public.agent_emails IS 'Service role (n8n) can INSERT new emails';

-- Policy 4: Service role can update emails (webhooks, status updates)
-- Future webhooks (Gmail API, SendGrid, etc.) can update status, opened_at, etc.
CREATE POLICY service_update_emails ON public.agent_emails
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON POLICY service_update_emails ON public.agent_emails IS 'Service role can UPDATE emails (webhooks, status updates, tracking)';

-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

-- Grant SELECT to authenticated users (filtered by RLS policies)
GRANT SELECT ON public.agent_emails TO authenticated;

-- Grant INSERT, UPDATE to service_role (n8n workflows, webhooks)
GRANT INSERT, UPDATE ON public.agent_emails TO service_role;

-- Note: DELETE is not granted to anyone except admins via RLS policy
-- This prevents accidental deletion of email logs

COMMENT ON TABLE public.agent_emails IS 'Email tracking table with RLS enabled. Authenticated users: SELECT (filtered by client access). Service role: INSERT, UPDATE. Admins: ALL (via RLS policy).';

-- ============================================================================
-- 5. VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- Verify RLS is enabled
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public' AND tablename = 'agent_emails';
-- Expected: rowsecurity = true

-- Verify policies exist
-- SELECT policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public' AND tablename = 'agent_emails';
-- Expected: 4 policies (users_view_accessible_emails, admins_manage_emails, service_insert_emails, service_update_emails)

-- Verify grants
-- SELECT grantee, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'public' AND table_name = 'agent_emails';
-- Expected: authenticated → SELECT, service_role → INSERT + UPDATE

-- Test RLS as authenticated user (replace USER_UUID and CLIENT_ID)
-- SET LOCAL ROLE authenticated;
-- SET LOCAL request.jwt.claims.sub = 'USER_UUID';
-- SELECT COUNT(*) FROM public.agent_emails;
-- Expected: Only emails from accessible clients

-- Test RLS as service_role (should see all)
-- SET LOCAL ROLE service_role;
-- SELECT COUNT(*) FROM public.agent_emails;
-- Expected: All emails

-- Test INSERT as service_role
-- SET LOCAL ROLE service_role;
-- INSERT INTO public.agent_emails (
--     deployment_id,
--     email_address,
--     email_subject,
--     email_body_text,
--     email_type,
--     status,
--     sent_at
-- ) VALUES (
--     'YOUR-DEPLOYMENT-UUID',
--     'test-rls@example.com',
--     'RLS Test Email',
--     'Testing RLS policies',
--     'transactional',
--     'sent',
--     NOW()
-- ) RETURNING *;
-- Expected: Success

-- Test INSERT as authenticated user (should fail - no INSERT grant)
-- SET LOCAL ROLE authenticated;
-- SET LOCAL request.jwt.claims.sub = 'USER_UUID';
-- INSERT INTO public.agent_emails (deployment_id, email_address, email_subject, status)
-- VALUES ('UUID', 'test@example.com', 'Test', 'sent');
-- Expected: ERROR - permission denied

-- Reset role
-- RESET ROLE;

-- ============================================================================
-- 6. SECURITY VALIDATION CHECKLIST
-- ============================================================================

-- Run these checks to ensure RLS is properly configured:
--
-- [ ] RLS is enabled on agent_emails table
-- [ ] 4 policies exist (users_view, admins_manage, service_insert, service_update)
-- [ ] authenticated role can SELECT (filtered by client access)
-- [ ] authenticated role CANNOT INSERT/UPDATE/DELETE (unless admin)
-- [ ] service_role can INSERT and UPDATE (for n8n workflows)
-- [ ] Admins can perform ALL operations on their clients' emails
-- [ ] Non-admin users cannot see emails from other clients
-- [ ] service_role can see all emails (for background jobs)

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Next steps:
-- 1. Run this migration in STAGING first
-- 2. Run verification queries above
-- 3. Test RLS with different user roles (user, admin, service_role)
-- 4. Apply migration 20251114_email_analytics.sql
-- 5. Document results in features/email-tracking/MIGRATION_TESTED.md

-- Security chain:
-- User → user_client_permissions → clients ← agent_deployments ← agent_emails
--
-- This ensures users can only access emails from clients they have permissions to view.
