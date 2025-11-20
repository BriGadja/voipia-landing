-- Migration: Create agent_sms table for SMS tracking
-- Date: 2025-11-13
-- Author: Claude (SMS Tracking Feature)
--
-- Purpose: Track SMS messages sent via n8n workflows using Twilio
--
-- Changes:
-- 1. Create agent_sms table with comprehensive SMS tracking fields
-- 2. Add indexes optimized for time-series queries and lookups
-- 3. Add trigger for auto-updating updated_at timestamp
-- 4. Add documentation comments
--
-- Expected Impact:
-- - New table, no impact on existing data
-- - Ready for n8n integration via service_role
-- - Supports 1000-10000 SMS/month with optimal performance

-- ============================================================================
-- TABLE: agent_sms
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.agent_sms (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys (following existing patterns)
    deployment_id UUID NOT NULL REFERENCES public.agent_deployments(id) ON DELETE CASCADE,
    call_id UUID REFERENCES public.agent_calls(id) ON DELETE SET NULL,
    prospect_id UUID REFERENCES public.agent_arthur_prospects(id) ON DELETE SET NULL,
    sequence_id UUID REFERENCES public.agent_arthur_prospect_sequences(id) ON DELETE SET NULL,

    -- Recipient information
    phone_number TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,

    -- Message content
    message_content TEXT NOT NULL,
    message_type TEXT DEFAULT 'transactional' CHECK (message_type IN ('transactional', 'marketing', 'notification', 'appointment_reminder')),
    character_count INTEGER GENERATED ALWAYS AS (LENGTH(message_content)) STORED,

    -- Provider details (Twilio integration)
    provider TEXT DEFAULT 'twilio',
    provider_message_sid TEXT UNIQUE, -- Twilio Message SID (unique identifier)
    provider_status TEXT CHECK (provider_status IN ('queued', 'sending', 'sent', 'delivered', 'undelivered', 'failed', 'unknown')),

    -- Delivery tracking (simplified status for KPIs)
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'failed')),
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL,
    delivered_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,

    -- Cost tracking (detailed breakdown)
    provider_cost NUMERIC(10, 4) CHECK (provider_cost >= 0), -- What Twilio/provider charges
    voipia_margin NUMERIC(10, 4) DEFAULT 0 CHECK (voipia_margin >= 0), -- Voipia's margin
    billed_cost NUMERIC(10, 4) GENERATED ALWAYS AS (COALESCE(provider_cost, 0) + COALESCE(voipia_margin, 0)) STORED, -- Total billed to client
    currency TEXT DEFAULT 'EUR',

    -- n8n workflow tracking
    workflow_id TEXT, -- n8n workflow ID that sent the SMS
    workflow_execution_id TEXT, -- Specific execution ID for debugging

    -- Additional metadata (flexible JSONB for extensibility)
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE public.agent_sms IS 'SMS messages sent via n8n workflows for agent communications (Louis, Arthur, Alexandra). Tracks content, delivery status, costs (real + margin), and provider details.';

COMMENT ON COLUMN public.agent_sms.id IS 'Unique identifier for the SMS record';
COMMENT ON COLUMN public.agent_sms.deployment_id IS 'Foreign key to agent_deployments - which agent sent this SMS (REQUIRED)';
COMMENT ON COLUMN public.agent_sms.call_id IS 'Optional link to agent_calls if SMS is a follow-up to a call (e.g., appointment confirmation after call)';
COMMENT ON COLUMN public.agent_sms.prospect_id IS 'Optional link to prospect (for Arthur agent sequences - cold outreach)';
COMMENT ON COLUMN public.agent_sms.sequence_id IS 'Optional link to prospect sequence (for Arthur multi-touch campaigns)';
COMMENT ON COLUMN public.agent_sms.phone_number IS 'Recipient phone number in E.164 format (e.g., +33612345678)';
COMMENT ON COLUMN public.agent_sms.message_content IS 'Full text content of the SMS message sent';
COMMENT ON COLUMN public.agent_sms.message_type IS 'Type of SMS: transactional (appointment confirm), marketing (promo), notification (reminder), appointment_reminder';
COMMENT ON COLUMN public.agent_sms.character_count IS 'Auto-calculated length of message_content (GENERATED column, updated automatically)';
COMMENT ON COLUMN public.agent_sms.provider IS 'SMS provider used (default: twilio)';
COMMENT ON COLUMN public.agent_sms.provider_message_sid IS 'Twilio Message SID (unique identifier, used for webhook updates). Format: SMxxx';
COMMENT ON COLUMN public.agent_sms.provider_status IS 'Detailed Twilio status (queued/sending/sent/delivered/undelivered/failed/unknown) for debugging';
COMMENT ON COLUMN public.agent_sms.status IS 'Simplified delivery status for KPIs (sent, delivered, failed). Used in dashboard analytics.';
COMMENT ON COLUMN public.agent_sms.sent_at IS 'Timestamp when SMS was sent by provider';
COMMENT ON COLUMN public.agent_sms.delivered_at IS 'Timestamp when SMS was delivered to recipient (updated by Twilio webhook)';
COMMENT ON COLUMN public.agent_sms.failed_at IS 'Timestamp when SMS delivery failed (updated by Twilio webhook)';
COMMENT ON COLUMN public.agent_sms.failure_reason IS 'Error message if delivery failed (from Twilio)';
COMMENT ON COLUMN public.agent_sms.provider_cost IS 'Real cost charged by SMS provider (Twilio) in EUR';
COMMENT ON COLUMN public.agent_sms.voipia_margin IS 'Voipia margin added on top of provider cost in EUR';
COMMENT ON COLUMN public.agent_sms.billed_cost IS 'Total cost billed to client = provider_cost + voipia_margin (GENERATED column, auto-calculated)';
COMMENT ON COLUMN public.agent_sms.currency IS 'Currency for costs (default: EUR)';
COMMENT ON COLUMN public.agent_sms.workflow_id IS 'n8n workflow ID that sent this SMS (for analytics and debugging)';
COMMENT ON COLUMN public.agent_sms.workflow_execution_id IS 'n8n execution ID for debugging failed workflows';
COMMENT ON COLUMN public.agent_sms.metadata IS 'Additional flexible data (JSONB). Examples: campaign_id, template_id, appointment_id, link_clicked, user_replied, custom_variables';

-- ============================================================================
-- INDEXES (Performance Optimization)
-- ============================================================================

-- Primary time-series index (matches agent_calls pattern)
-- Most common query: "Get recent SMS for a deployment"
CREATE INDEX idx_agent_sms_deployment_sent_at
ON public.agent_sms (deployment_id, sent_at DESC);

COMMENT ON INDEX idx_agent_sms_deployment_sent_at IS 'Primary index for time-series queries (recent SMS by deployment). Supports dashboard KPIs.';

-- Status filtering for KPIs (delivery rate, failed count)
-- Query: "Count delivered SMS" or "Find failed SMS"
CREATE INDEX idx_agent_sms_status
ON public.agent_sms (status)
WHERE status IN ('delivered', 'failed');

COMMENT ON INDEX idx_agent_sms_status IS 'Partial index for status filtering in KPI calculations (delivered/failed only, excludes sent)';

-- Call relationship lookup
-- Query: "Find SMS sent after a specific call"
CREATE INDEX idx_agent_sms_call_id
ON public.agent_sms (call_id)
WHERE call_id IS NOT NULL;

COMMENT ON INDEX idx_agent_sms_call_id IS 'Partial index for call-to-SMS tracking (follow-up SMS analytics)';

-- Provider webhook updates (Twilio status callbacks)
-- Query: "Update SMS status by provider_message_sid" (webhook from Twilio)
CREATE INDEX idx_agent_sms_provider_sid
ON public.agent_sms (provider_message_sid)
WHERE provider_message_sid IS NOT NULL;

COMMENT ON INDEX idx_agent_sms_provider_sid IS 'Unique partial index for fast webhook updates from Twilio (status changes)';

-- Cost analysis by deployment
-- Query: "Total SMS costs for a deployment"
CREATE INDEX idx_agent_sms_deployment_cost
ON public.agent_sms (deployment_id, billed_cost DESC);

COMMENT ON INDEX idx_agent_sms_deployment_cost IS 'Index for cost aggregation queries (total costs per deployment)';

-- Prospect/sequence lookups (Arthur agent)
-- Query: "Find all SMS sent to a prospect" or "SMS in a sequence"
CREATE INDEX idx_agent_sms_prospect
ON public.agent_sms (prospect_id)
WHERE prospect_id IS NOT NULL;

COMMENT ON INDEX idx_agent_sms_prospect IS 'Partial index for prospect SMS history (Arthur agent)';

CREATE INDEX idx_agent_sms_sequence
ON public.agent_sms (sequence_id)
WHERE sequence_id IS NOT NULL;

COMMENT ON INDEX idx_agent_sms_sequence IS 'Partial index for sequence SMS tracking (Arthur multi-touch campaigns)';

-- ============================================================================
-- TRIGGER: Auto-update updated_at
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_agent_sms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_agent_sms_updated_at() IS 'Trigger function to automatically update updated_at timestamp on row modifications';

-- Trigger on UPDATE
CREATE TRIGGER agent_sms_updated_at
BEFORE UPDATE ON public.agent_sms
FOR EACH ROW
EXECUTE FUNCTION update_agent_sms_updated_at();

COMMENT ON TRIGGER agent_sms_updated_at ON public.agent_sms IS 'Auto-update updated_at timestamp when SMS record is modified (e.g., status changes from webhook)';

-- ============================================================================
-- VERIFICATION QUERIES (Commented out - uncomment to test)
-- ============================================================================

-- Check table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'agent_sms'
-- ORDER BY ordinal_position;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'agent_sms';

-- Insert test SMS (requires valid deployment_id)
-- INSERT INTO agent_sms (
--     deployment_id,
--     phone_number,
--     first_name,
--     message_content,
--     message_type,
--     provider_message_sid,
--     sent_at,
--     provider_cost,
--     voipia_margin
-- ) VALUES (
--     'your-deployment-id-here'::UUID,
--     '+33612345678',
--     'Test',
--     'Bonjour, ceci est un test SMS de Voipia',
--     'notification',
--     'SM_test_' || gen_random_uuid(),
--     NOW(),
--     0.0500,
--     0.0200
-- );

-- Verify auto-calculated columns
-- SELECT id, message_content, character_count, provider_cost, voipia_margin, billed_cost
-- FROM agent_sms
-- LIMIT 1;
