-- Migration: RLS Policies for agent_sms
-- Date: 2025-11-13
-- Author: Claude (SMS Tracking Feature)
--
-- Purpose: Configure Row-Level Security for agent_sms table
--
-- Changes:
-- 1. Enable RLS on agent_sms table
-- 2. Create policy for authenticated users (view SMS for their accessible clients)
-- 3. Create policy for admins (manage SMS for their clients)
-- 4. Create policies for service_role (n8n INSERT/UPDATE)
-- 5. Grant appropriate permissions
--
-- Security Model:
-- - Users can only see SMS from deployments linked to their accessible clients
-- - Inherits permissions from user_client_permissions table (same as agent_calls)
-- - n8n (service_role) can insert new SMS and update delivery status
-- - Admins can manage SMS for their clients
--
-- Expected Impact:
-- - RLS enforced on all queries
-- - n8n can insert/update via service_role key
-- - Users see only their authorized data

-- ============================================================================
-- ENABLE ROW-LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.agent_sms ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLICY 1: Users can view SMS for their accessible clients
-- ============================================================================

CREATE POLICY users_view_accessible_sms ON public.agent_sms
FOR SELECT
TO authenticated
USING (
    -- User can see SMS if deployment belongs to a client they have access to
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid()
    )
);

COMMENT ON POLICY users_view_accessible_sms ON public.agent_sms IS 'Authenticated users can view SMS from deployments linked to clients they have permission to access (via user_client_permissions)';

-- ============================================================================
-- POLICY 2: Admins can manage SMS for their clients
-- ============================================================================

CREATE POLICY admins_manage_sms ON public.agent_sms
FOR ALL
TO authenticated
USING (
    -- User can manage SMS if they are admin for the client
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid()
          AND ucp.permission_level = 'admin'
    )
)
WITH CHECK (
    -- Same check for INSERT/UPDATE
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid()
          AND ucp.permission_level = 'admin'
    )
);

COMMENT ON POLICY admins_manage_sms ON public.agent_sms IS 'Admin users can INSERT/UPDATE/DELETE SMS for clients they administer';

-- ============================================================================
-- POLICY 3: Service role (n8n) can insert SMS
-- ============================================================================

CREATE POLICY service_insert_sms ON public.agent_sms
FOR INSERT
TO service_role
WITH CHECK (true);

COMMENT ON POLICY service_insert_sms ON public.agent_sms IS 'n8n workflows (using service_role key) can insert new SMS records after sending via Twilio';

-- ============================================================================
-- POLICY 4: Service role (n8n webhooks) can update SMS status
-- ============================================================================

CREATE POLICY service_update_sms ON public.agent_sms
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON POLICY service_update_sms ON public.agent_sms IS 'n8n webhooks (using service_role key) can update SMS delivery status when Twilio sends callbacks';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Authenticated users can SELECT (RLS policies will filter)
GRANT SELECT ON public.agent_sms TO authenticated;

-- Service role (n8n) can INSERT and UPDATE
GRANT INSERT, UPDATE ON public.agent_sms TO service_role;

-- Admin users can DELETE (via admins_manage_sms policy)
-- No explicit GRANT DELETE needed - covered by FOR ALL policy

-- ============================================================================
-- VERIFICATION QUERIES (Commented out - uncomment to test)
-- ============================================================================

-- Check RLS is enabled
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE tablename = 'agent_sms';

-- List all policies on agent_sms
-- SELECT policyname, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'agent_sms';

-- Test RLS as authenticated user (replace user_id with real UUID)
-- SET ROLE authenticated;
-- SET request.jwt.claims.sub = 'user-uuid-here';
-- SELECT COUNT(*) FROM agent_sms; -- Should only see accessible SMS
-- RESET ROLE;

-- Test service_role can insert (requires valid deployment_id)
-- SET ROLE service_role;
-- INSERT INTO agent_sms (
--     deployment_id, phone_number, message_content, sent_at
-- ) VALUES (
--     'valid-deployment-id'::UUID, '+33612345678', 'Test from service_role', NOW()
-- );
-- RESET ROLE;

-- Verify permissions
-- SELECT grantee, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_name = 'agent_sms';
