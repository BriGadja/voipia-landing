-- Migration: Add cost_per_email column to agent_deployments
-- Date: 2025-11-14
-- Author: Claude
-- Feature: Email Tracking System - Dynamic Pricing Model
--
-- Changes:
-- 1. Add cost_per_email column to agent_deployments table
-- 2. Set default value to 0 (free, can be changed per deployment)
-- 3. Similar to cost_per_sms column (dynamic pricing per deployment)
--
-- Purpose:
-- - Enable future email billing if needed (currently free with cost_per_email = 0)
-- - Allow different pricing per client/deployment
-- - Consistent with SMS pricing model (3 columns: provider_cost, billed_cost, margin)

-- ============================================================================
-- 1. ADD COLUMN cost_per_email
-- ============================================================================

-- Check if column already exists (idempotent migration)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'agent_deployments'
          AND column_name = 'cost_per_email'
    ) THEN
        -- Add column with default value 0 and CHECK constraint
        ALTER TABLE public.agent_deployments
        ADD COLUMN cost_per_email NUMERIC(10, 4) DEFAULT 0 CHECK (cost_per_email >= 0);

        COMMENT ON COLUMN public.agent_deployments.cost_per_email IS 'Unit price charged to client per email (default 0€, can be modified to enable billing)';
    END IF;
END $$;

-- ============================================================================
-- 2. VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- Verify column exists
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'agent_deployments'
--   AND column_name = 'cost_per_email';
-- Expected: cost_per_email | numeric | 0 | YES

-- Check current values (should be 0 for all existing deployments)
-- SELECT
--     id,
--     name,
--     cost_per_sms,
--     cost_per_email
-- FROM public.agent_deployments
-- ORDER BY name;
-- Expected: cost_per_email = 0 for all rows

-- Example: Enable billing for specific deployment
-- UPDATE public.agent_deployments
-- SET cost_per_email = 0.01  -- 0.01€ per email
-- WHERE id = 'YOUR-DEPLOYMENT-UUID';

-- Example: Different pricing per client
-- Client A: Free emails
-- UPDATE agent_deployments SET cost_per_email = 0 WHERE client_id = 'CLIENT_A_UUID';
--
-- Client B: Symbolic pricing
-- UPDATE agent_deployments SET cost_per_email = 0.01 WHERE client_id = 'CLIENT_B_UUID';
--
-- Client C: Premium pricing
-- UPDATE agent_deployments SET cost_per_email = 0.05 WHERE client_id = 'CLIENT_C_UUID';

-- ============================================================================
-- 3. USAGE NOTES
-- ============================================================================

-- This column will be used by:
-- 1. n8n workflows: Fetch cost_per_email and insert into agent_emails.billed_cost
-- 2. agent_emails table: Calculate margin = billed_cost - provider_cost
-- 3. get_email_metrics() RPC: Calculate total revenue, margin, margin %
--
-- Pricing examples:
-- - cost_per_email = 0     → Free (current default)
-- - cost_per_email = 0.01  → 1 cent per email (symbolic)
-- - cost_per_email = 0.02  → 2 cents per email
-- - cost_per_email = 0.05  → 5 cents per email (premium)
--
-- Revenue calculation:
-- Total Revenue = SUM(agent_emails.billed_cost)
--               = COUNT(emails) × agent_deployments.cost_per_email
--
-- Example: 5000 emails/month × 0.01€ = 50€/month revenue

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Next steps:
-- 1. Apply this migration in STAGING first
-- 2. Verify column exists with default value 0
-- 3. Apply migrations for agent_emails table (with new financial columns)
-- 4. Update n8n workflows to fetch cost_per_email dynamically
-- 5. Test with cost_per_email = 0 (free) and cost_per_email = 0.01 (billed)
-- 6. Document results in features/email-tracking/MIGRATION_TESTED.md
