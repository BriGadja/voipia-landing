-- Migration: Create agent_emails table with indexes and triggers
-- Date: 2025-11-14
-- Author: Claude
-- Feature: Email Tracking System
--
-- Changes:
-- 1. Create agent_emails table for tracking all emails sent by Voipia agents
-- 2. Create 7 optimized indexes for time-series queries and analytics
-- 3. Create trigger for auto-updating updated_at timestamp
--
-- Inspired by: agent_sms table (features/sms-tracking/)
-- Key differences:
--   - 3 content columns (subject + html + text) vs 1 for SMS
--   - Dynamic pricing model (same as SMS): provider_cost, billed_cost, margin
--   - Billed cost fetched from agent_deployments.cost_per_email (default 0)
--   - Columns prepared for future tracking (opened_at, clicked_at, etc.)
--   - email_type adapted to use cases (follow_up, cold_email, etc.)

-- ============================================================================
-- 1. DROP EXISTING (if any) - Idempotent
-- ============================================================================

-- Drop table first (CASCADE will automatically remove all dependent objects: triggers, indexes, constraints)
DROP TABLE IF EXISTS public.agent_emails CASCADE;

-- Drop trigger function (independent of table)
DROP FUNCTION IF EXISTS update_agent_emails_updated_at();

-- ============================================================================
-- 2. CREATE TABLE agent_emails
-- ============================================================================

CREATE TABLE public.agent_emails (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    deployment_id UUID NOT NULL REFERENCES public.agent_deployments(id) ON DELETE CASCADE,
    call_id UUID REFERENCES public.agent_calls(id) ON DELETE SET NULL,
    prospect_id UUID REFERENCES public.agent_arthur_prospects(id) ON DELETE SET NULL,
    sequence_id UUID REFERENCES public.agent_arthur_prospect_sequences(id) ON DELETE SET NULL,

    -- Recipient information
    email_address TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,

    -- Email content
    email_subject TEXT NOT NULL,
    email_body_html TEXT,
    email_body_text TEXT,
    word_count INTEGER GENERATED ALWAYS AS (
        LENGTH(REGEXP_REPLACE(COALESCE(email_body_text, ''), '\s+', ' ', 'g'))
    ) STORED,
    html_size_bytes INTEGER GENERATED ALWAYS AS (
        LENGTH(COALESCE(email_body_html, ''))
    ) STORED,
    has_attachments BOOLEAN DEFAULT FALSE,
    attachment_names TEXT[],

    -- Email type (adapted to Voipia use cases)
    email_type TEXT DEFAULT 'transactional' CHECK (email_type IN (
        'follow_up',                 -- Follow-up after call
        'cold_email',                -- Prospecting (Arthur)
        'appointment_confirmation',  -- Appointment confirmation/reminder
        'sequence_step',             -- Step in automated sequence
        'transactional',             -- Generic transactional email
        'notification'               -- System notification
    )),

    -- Provider details (Gmail via n8n)
    provider TEXT DEFAULT 'gmail',
    workflow_message_id TEXT,        -- Gmail message ID (optional)
    gmail_thread_id TEXT,            -- Gmail thread ID (conversations)

    -- Status tracking (simplified - no external provider)
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'queued')),
    sent_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,

    -- Tracking metrics (FUTURES - NULL for now, ready for v2.0)
    opened_at TIMESTAMP WITH TIME ZONE,
    first_clicked_at TIMESTAMP WITH TIME ZONE,
    bounce_type TEXT CHECK (bounce_type IN ('hard', 'soft', 'none', NULL)),
    spam_reported_at TIMESTAMP WITH TIME ZONE,

    -- Cost tracking (dynamic pricing model - same as SMS)
    provider_cost NUMERIC(10, 4) CHECK (provider_cost >= 0),  -- Provider cost (Gmail = 0, SendGrid = variable)
    billed_cost NUMERIC(10, 4) CHECK (billed_cost >= 0),      -- Price charged to client (from agent_deployments.cost_per_email)
    margin NUMERIC(10, 4) GENERATED ALWAYS AS (COALESCE(billed_cost, 0) - COALESCE(provider_cost, 0)) STORED,  -- Calculated margin
    currency TEXT DEFAULT 'EUR',

    -- n8n workflow tracking
    workflow_id TEXT,
    workflow_execution_id TEXT,

    -- Metadata (flexible JSONB for additional data)
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.agent_emails IS 'Tracks all emails sent by Voipia agents (Louis, Arthur, Alexandra) via Gmail/n8n workflows';

COMMENT ON COLUMN public.agent_emails.deployment_id IS 'Agent deployment that sent the email';
COMMENT ON COLUMN public.agent_emails.call_id IS 'Related call (if follow-up email)';
COMMENT ON COLUMN public.agent_emails.prospect_id IS 'Related Arthur prospect (if cold email)';
COMMENT ON COLUMN public.agent_emails.sequence_id IS 'Related multi-touch sequence (if sequence step)';
COMMENT ON COLUMN public.agent_emails.email_type IS 'Type of email: follow_up, cold_email, appointment_confirmation, sequence_step, transactional, notification';
COMMENT ON COLUMN public.agent_emails.word_count IS 'Auto-calculated: word count in email_body_text';
COMMENT ON COLUMN public.agent_emails.html_size_bytes IS 'Auto-calculated: size of email_body_html in bytes';
COMMENT ON COLUMN public.agent_emails.opened_at IS 'Future v2.0: First email open timestamp (pixel tracking)';
COMMENT ON COLUMN public.agent_emails.first_clicked_at IS 'Future v2.0: First link click timestamp (link tracking)';
COMMENT ON COLUMN public.agent_emails.bounce_type IS 'Future v2.0: Bounce type (hard, soft, none)';
COMMENT ON COLUMN public.agent_emails.spam_reported_at IS 'Future v2.0: Spam report timestamp';
COMMENT ON COLUMN public.agent_emails.provider_cost IS 'Provider cost per email (Gmail = 0, SendGrid = ~0.0012€)';
COMMENT ON COLUMN public.agent_emails.billed_cost IS 'Price charged to client per email (fetched from agent_deployments.cost_per_email, default 0)';
COMMENT ON COLUMN public.agent_emails.margin IS 'Auto-calculated margin: billed_cost - provider_cost';

-- ============================================================================
-- 3. CREATE INDEXES (7 optimized indexes)
-- ============================================================================

-- Index 1: Time-series queries (deployment + time)
-- Most common query pattern: "Get emails for this deployment in this date range"
CREATE INDEX idx_agent_emails_deployment_sent_at
ON public.agent_emails (deployment_id, sent_at DESC)
WHERE sent_at IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_deployment_sent_at IS 'Optimizes time-series queries by deployment (most common pattern)';

-- Index 2: Status filtering (partial index for performance)
-- Used for KPIs: delivery rate, failed count, etc.
CREATE INDEX idx_agent_emails_status
ON public.agent_emails (status)
WHERE status IN ('sent', 'failed');

COMMENT ON INDEX idx_agent_emails_status IS 'Optimizes status filtering for KPIs (sent vs failed)';

-- Index 3: Call relationship lookup
-- Used for "emails sent after this call" queries
CREATE INDEX idx_agent_emails_call_id
ON public.agent_emails (call_id)
WHERE call_id IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_call_id IS 'Optimizes lookup of emails related to specific calls';

-- Index 4: Email address lookup
-- Used for deduplication, frequency analysis, recipient history
CREATE INDEX idx_agent_emails_email_address
ON public.agent_emails (email_address)
WHERE email_address IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_email_address IS 'Optimizes recipient lookups and frequency analysis';

-- Index 5: Email type analytics
-- Used for "emails by type" reports (follow_up, cold_email, etc.)
CREATE INDEX idx_agent_emails_type
ON public.agent_emails (email_type, sent_at DESC)
WHERE email_type IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_type IS 'Optimizes analytics by email type';

-- Index 6: Prospect history (Arthur agent)
-- Used for "emails sent to this prospect" queries
CREATE INDEX idx_agent_emails_prospect
ON public.agent_emails (prospect_id)
WHERE prospect_id IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_prospect IS 'Optimizes lookup of emails sent to Arthur prospects';

-- Index 7: Sequence tracking
-- Used for "emails in this sequence" queries
CREATE INDEX idx_agent_emails_sequence
ON public.agent_emails (sequence_id)
WHERE sequence_id IS NOT NULL;

COMMENT ON INDEX idx_agent_emails_sequence IS 'Optimizes tracking of multi-touch sequence emails';

-- ============================================================================
-- 4. CREATE TRIGGER FUNCTION (auto-update updated_at)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_agent_emails_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_agent_emails_updated_at() IS 'Auto-updates updated_at timestamp on UPDATE';

-- ============================================================================
-- 5. CREATE TRIGGER (attach function to table)
-- ============================================================================

CREATE TRIGGER agent_emails_updated_at
BEFORE UPDATE ON public.agent_emails
FOR EACH ROW
EXECUTE FUNCTION update_agent_emails_updated_at();

COMMENT ON TRIGGER agent_emails_updated_at ON public.agent_emails IS 'Automatically updates updated_at on every UPDATE';

-- ============================================================================
-- 6. VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- Verify table exists
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name = 'agent_emails';

-- Verify columns
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'agent_emails'
-- ORDER BY ordinal_position;

-- Verify indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'agent_emails' AND schemaname = 'public';

-- Verify trigger function
-- SELECT routine_name, routine_type
-- FROM information_schema.routines
-- WHERE routine_schema = 'public' AND routine_name = 'update_agent_emails_updated_at';

-- Verify trigger
-- SELECT trigger_name, event_manipulation, event_object_table, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_table = 'agent_emails' AND trigger_schema = 'public';

-- Test insert (example - adapt to your data)
-- INSERT INTO public.agent_emails (
--     deployment_id,
--     email_address,
--     first_name,
--     last_name,
--     email_subject,
--     email_body_html,
--     email_body_text,
--     email_type,
--     status,
--     sent_at,
--     workflow_id
-- ) VALUES (
--     'YOUR-DEPLOYMENT-UUID',
--     'test@example.com',
--     'John',
--     'Doe',
--     'Test Email Subject',
--     '<html><body><p>This is a test email.</p></body></html>',
--     'This is a test email.',
--     'transactional',
--     'sent',
--     NOW(),
--     'test-workflow-id'
-- ) RETURNING *;

-- Test trigger (update and verify updated_at changed)
-- UPDATE public.agent_emails
-- SET email_subject = 'Updated Subject'
-- WHERE email_address = 'test@example.com'
-- RETURNING id, email_subject, updated_at;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Next steps:
-- 1. Run this migration in STAGING first
-- 2. Run verification queries above
-- 3. Test with n8n workflow (insert test emails)
-- 4. Apply migration 20251114_email_rls_policies.sql
-- 5. Apply migration 20251114_email_analytics.sql
-- 6. Document results in features/email-tracking/MIGRATION_TESTED.md
