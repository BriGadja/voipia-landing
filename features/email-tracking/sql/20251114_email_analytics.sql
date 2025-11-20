-- Migration: Analytics Views and RPC Functions for agent_emails
-- Date: 2025-11-14
-- Author: Claude
-- Feature: Email Tracking System - Analytics Layer
--
-- Changes:
-- 1. Create v_agent_emails_enriched view (emails with client/agent context)
-- 2. Update v_agent_communications_unified to include emails (calls + sms + emails)
-- 3. Create get_email_metrics() RPC function (KPIs with period comparison)
--
-- Dependencies:
-- - agent_emails table (from 20251114_create_agent_emails_table.sql)
-- - RLS policies (from 20251114_email_rls_policies.sql)
-- - Existing views: v_agent_calls_enriched, v_agent_sms_enriched (if exists)

-- ============================================================================
-- 1. DROP EXISTING (if any)
-- ============================================================================

-- Drop views (in reverse order of dependencies)
DROP VIEW IF EXISTS public.v_agent_communications_unified;
DROP VIEW IF EXISTS public.v_agent_emails_enriched CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.get_email_metrics(
    TIMESTAMP WITH TIME ZONE,
    TIMESTAMP WITH TIME ZONE,
    UUID,
    UUID,
    TEXT
);

-- ============================================================================
-- 2. CREATE VIEW v_agent_emails_enriched
-- ============================================================================

CREATE OR REPLACE VIEW public.v_agent_emails_enriched AS
SELECT
    -- Email core fields (all columns from agent_emails)
    em.*,

    -- Deployment context
    ad.name AS deployment_name,
    ad.slug AS deployment_slug,

    -- Client context
    ad.client_id,
    c.name AS client_name,

    -- Agent type context
    ad.agent_type_id,
    at.name AS agent_type_name,
    at.display_name AS agent_display_name,

    -- Calculated boolean fields (for easier querying)
    CASE WHEN em.status = 'sent' THEN true ELSE false END AS is_sent,
    CASE WHEN em.status = 'failed' THEN true ELSE false END AS is_failed,
    CASE WHEN em.status = 'queued' THEN true ELSE false END AS is_queued,

    -- Future tracking (v2.0) - will be populated when pixel/link tracking is enabled
    CASE WHEN em.opened_at IS NOT NULL THEN true ELSE false END AS is_opened,
    CASE WHEN em.first_clicked_at IS NOT NULL THEN true ELSE false END AS is_clicked,
    CASE WHEN em.bounce_type IS NOT NULL THEN true ELSE false END AS is_bounced

FROM public.agent_emails em
JOIN public.agent_deployments ad ON em.deployment_id = ad.id
JOIN public.clients c ON ad.client_id = c.id
JOIN public.agent_types at ON ad.agent_type_id = at.id;

COMMENT ON VIEW public.v_agent_emails_enriched IS 'Enriched view of agent_emails with client, deployment, and agent type context. Includes calculated boolean fields for easier analytics.';

-- Grant SELECT to authenticated (RLS policies will filter rows)
GRANT SELECT ON public.v_agent_emails_enriched TO authenticated;

-- ============================================================================
-- 3. CREATE/UPDATE VIEW v_agent_communications_unified
-- ============================================================================

-- This view combines calls + sms + emails for unified communication analytics
CREATE OR REPLACE VIEW public.v_agent_communications_unified AS

-- Calls
SELECT
    'call'::TEXT AS communication_type,
    ac.id,
    ac.deployment_id,
    ac.phone_number AS contact_info,
    ac.started_at AS timestamp,
    ac.outcome AS result,
    ac.total_cost AS cost,
    ac.duration_seconds,
    NULL::TEXT AS message_content,
    NULL::INTEGER AS word_count,
    NULL::TEXT AS email_subject
FROM public.agent_calls ac

UNION ALL

-- SMS (if table exists)
SELECT
    'sms'::TEXT AS communication_type,
    sms.id,
    sms.deployment_id,
    sms.phone_number AS contact_info,
    sms.sent_at AS timestamp,
    sms.status AS result,
    sms.billed_cost AS cost,
    NULL::INTEGER AS duration_seconds,
    sms.message_content,
    sms.character_count AS word_count,
    NULL::TEXT AS email_subject
FROM public.agent_sms sms

UNION ALL

-- Emails
SELECT
    'email'::TEXT AS communication_type,
    em.id,
    em.deployment_id,
    em.email_address AS contact_info,
    em.sent_at AS timestamp,
    em.status AS result,
    em.billed_cost AS cost,  -- Use billed_cost (charged to client) for consistency with SMS
    NULL::INTEGER AS duration_seconds,
    em.email_body_text AS message_content,
    em.word_count,
    em.email_subject
FROM public.agent_emails em;

COMMENT ON VIEW public.v_agent_communications_unified IS 'Unified view of all communications (calls + sms + emails) for cross-channel analytics';

-- Grant SELECT to authenticated (RLS policies will filter rows)
GRANT SELECT ON public.v_agent_communications_unified TO authenticated;

-- ============================================================================
-- 4. CREATE FUNCTION get_email_metrics()
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_email_metrics(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_client_id UUID DEFAULT NULL,
    p_deployment_id UUID DEFAULT NULL,
    p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_period_duration INTERVAL;
    v_previous_start_date TIMESTAMP WITH TIME ZONE;
    v_previous_end_date TIMESTAMP WITH TIME ZONE;
    v_current_metrics JSONB;
    v_previous_metrics JSONB;
    v_comparison JSONB;
BEGIN
    -- Calculate period duration for comparison
    v_period_duration := p_end_date - p_start_date;
    v_previous_start_date := p_start_date - v_period_duration;
    v_previous_end_date := p_start_date;

    -- Get current period metrics
    WITH current_period AS (
        SELECT
            COUNT(*) AS total_emails,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_emails,
            COUNT(*) FILTER (WHERE status = 'failed') AS failed_emails,
            COUNT(*) FILTER (WHERE status = 'queued') AS queued_emails,

            -- Delivery rate (sent / total)
            CASE
                WHEN COUNT(*) > 0 THEN
                    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
                ELSE 0
            END AS delivery_rate,

            -- Cost metrics (dynamic pricing model - same as SMS)
            COALESCE(SUM(provider_cost), 0) AS total_provider_cost,
            COALESCE(SUM(billed_cost), 0) AS total_revenue,
            COALESCE(SUM(margin), 0) AS total_margin,
            CASE
                WHEN SUM(billed_cost) > 0 THEN
                    ROUND((SUM(margin) / SUM(billed_cost)) * 100, 2)
                ELSE 0
            END AS margin_percentage,
            ROUND(COALESCE(AVG(provider_cost), 0), 4) AS avg_provider_cost,
            ROUND(COALESCE(AVG(billed_cost), 0), 4) AS avg_billed_cost,
            ROUND(COALESCE(AVG(margin), 0), 4) AS avg_margin,

            -- Content metrics
            ROUND(COALESCE(AVG(word_count), 0), 2) AS avg_word_count,
            ROUND(COALESCE(AVG(html_size_bytes), 0), 2) AS avg_html_size_bytes,
            ROUND(COALESCE(AVG(html_size_bytes) / 1024.0, 0), 2) AS avg_html_size_kb,

            -- Recipients
            COUNT(DISTINCT email_address) AS unique_recipients,

            -- Attachments
            COUNT(*) FILTER (WHERE has_attachments = TRUE) AS emails_with_attachments,

            -- Linked to other entities
            COUNT(*) FILTER (WHERE call_id IS NOT NULL) AS emails_linked_to_calls,
            COUNT(*) FILTER (WHERE prospect_id IS NOT NULL) AS emails_linked_to_prospects,
            COUNT(*) FILTER (WHERE sequence_id IS NOT NULL) AS emails_in_sequences,

            -- Future tracking metrics (v2.0 - will be 0 until implemented)
            COUNT(*) FILTER (WHERE opened_at IS NOT NULL) AS opened_emails,
            COUNT(*) FILTER (WHERE first_clicked_at IS NOT NULL) AS clicked_emails,
            COUNT(*) FILTER (WHERE bounce_type IS NOT NULL) AS bounced_emails,

            -- Email types breakdown (JSONB array)
            JSONB_AGG(DISTINCT JSONB_BUILD_OBJECT(
                'type', email_type,
                'count', COUNT(*) FILTER (WHERE email_type = em.email_type)
            )) AS by_email_type

        FROM public.agent_emails em
        WHERE em.sent_at >= p_start_date
            AND em.sent_at < p_end_date
            AND (p_client_id IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad WHERE ad.client_id = p_client_id
            ))
            AND (p_deployment_id IS NULL OR em.deployment_id = p_deployment_id)
            AND (p_agent_type_name IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                JOIN public.agent_types at ON ad.agent_type_id = at.id
                WHERE at.name = p_agent_type_name
            ))
    )
    SELECT JSONB_BUILD_OBJECT(
        'total_emails', cp.total_emails,
        'sent_emails', cp.sent_emails,
        'failed_emails', cp.failed_emails,
        'queued_emails', cp.queued_emails,
        'delivery_rate', cp.delivery_rate,
        'total_provider_cost', cp.total_provider_cost,
        'total_revenue', cp.total_revenue,
        'total_margin', cp.total_margin,
        'margin_percentage', cp.margin_percentage,
        'avg_provider_cost', cp.avg_provider_cost,
        'avg_billed_cost', cp.avg_billed_cost,
        'avg_margin', cp.avg_margin,
        'avg_word_count', cp.avg_word_count,
        'avg_html_size_bytes', cp.avg_html_size_bytes,
        'avg_html_size_kb', cp.avg_html_size_kb,
        'unique_recipients', cp.unique_recipients,
        'emails_with_attachments', cp.emails_with_attachments,
        'emails_linked_to_calls', cp.emails_linked_to_calls,
        'emails_linked_to_prospects', cp.emails_linked_to_prospects,
        'emails_in_sequences', cp.emails_in_sequences,
        'opened_emails', cp.opened_emails,
        'clicked_emails', cp.clicked_emails,
        'bounced_emails', cp.bounced_emails,
        'open_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.opened_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END,
        'click_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.clicked_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END,
        'bounce_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.bounced_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END,
        'by_email_type', cp.by_email_type
    ) INTO v_current_metrics
    FROM current_period cp;

    -- Get previous period metrics (same logic with different date range)
    WITH previous_period AS (
        SELECT
            COUNT(*) AS total_emails,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_emails,
            CASE
                WHEN COUNT(*) > 0 THEN
                    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
                ELSE 0
            END AS delivery_rate,
            COALESCE(SUM(provider_cost), 0) AS total_provider_cost,
            COALESCE(SUM(billed_cost), 0) AS total_revenue,
            COALESCE(SUM(margin), 0) AS total_margin
        FROM public.agent_emails em
        WHERE em.sent_at >= v_previous_start_date
            AND em.sent_at < v_previous_end_date
            AND (p_client_id IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad WHERE ad.client_id = p_client_id
            ))
            AND (p_deployment_id IS NULL OR em.deployment_id = p_deployment_id)
            AND (p_agent_type_name IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                JOIN public.agent_types at ON ad.agent_type_id = at.id
                WHERE at.name = p_agent_type_name
            ))
    )
    SELECT JSONB_BUILD_OBJECT(
        'total_emails', pp.total_emails,
        'sent_emails', pp.sent_emails,
        'delivery_rate', pp.delivery_rate,
        'total_provider_cost', pp.total_provider_cost,
        'total_revenue', pp.total_revenue,
        'total_margin', pp.total_margin
    ) INTO v_previous_metrics
    FROM previous_period pp;

    -- Calculate comparison (percentage change)
    v_comparison := JSONB_BUILD_OBJECT(
        'total_emails_change', CASE
            WHEN (v_previous_metrics->>'total_emails')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_emails')::NUMERIC - (v_previous_metrics->>'total_emails')::NUMERIC) / (v_previous_metrics->>'total_emails')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'sent_emails_change', CASE
            WHEN (v_previous_metrics->>'sent_emails')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'sent_emails')::NUMERIC - (v_previous_metrics->>'sent_emails')::NUMERIC) / (v_previous_metrics->>'sent_emails')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'delivery_rate_change', (v_current_metrics->>'delivery_rate')::NUMERIC - (v_previous_metrics->>'delivery_rate')::NUMERIC,
        'total_provider_cost_change', CASE
            WHEN (v_previous_metrics->>'total_provider_cost')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_provider_cost')::NUMERIC - (v_previous_metrics->>'total_provider_cost')::NUMERIC) / (v_previous_metrics->>'total_provider_cost')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'total_revenue_change', CASE
            WHEN (v_previous_metrics->>'total_revenue')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_revenue')::NUMERIC - (v_previous_metrics->>'total_revenue')::NUMERIC) / (v_previous_metrics->>'total_revenue')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'total_margin_change', CASE
            WHEN (v_previous_metrics->>'total_margin')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_margin')::NUMERIC - (v_previous_metrics->>'total_margin')::NUMERIC) / (v_previous_metrics->>'total_margin')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'margin_percentage_change', (v_current_metrics->>'margin_percentage')::NUMERIC - (v_previous_metrics->>'margin_percentage')::NUMERIC
    );

    -- Return combined result
    RETURN JSONB_BUILD_OBJECT(
        'current_period', v_current_metrics,
        'previous_period', v_previous_metrics,
        'comparison', v_comparison,
        'period_info', JSONB_BUILD_OBJECT(
            'start_date', p_start_date,
            'end_date', p_end_date,
            'previous_start_date', v_previous_start_date,
            'previous_end_date', v_previous_end_date
        )
    );
END;
$$;

COMMENT ON FUNCTION public.get_email_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) IS 'Returns comprehensive email metrics with period-over-period comparison. Filters by date range, client, deployment, and agent type.';

-- Grant EXECUTE to authenticated
GRANT EXECUTE ON FUNCTION public.get_email_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- 5. VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- Verify views exist
-- SELECT viewname FROM pg_views
-- WHERE schemaname = 'public' AND viewname IN ('v_agent_emails_enriched', 'v_agent_communications_unified');

-- Verify function exists
-- SELECT routine_name, routine_type
-- FROM information_schema.routines
-- WHERE routine_schema = 'public' AND routine_name = 'get_email_metrics';

-- Test v_agent_emails_enriched (should return emails with client/agent context)
-- SELECT
--     email_subject,
--     client_name,
--     agent_display_name,
--     deployment_name,
--     is_sent,
--     sent_at
-- FROM public.v_agent_emails_enriched
-- ORDER BY sent_at DESC
-- LIMIT 10;

-- Test v_agent_communications_unified (should return calls + sms + emails)
-- SELECT
--     communication_type,
--     contact_info,
--     timestamp,
--     result,
--     cost
-- FROM public.v_agent_communications_unified
-- ORDER BY timestamp DESC
-- LIMIT 20;

-- Test get_email_metrics() (last 30 days, all clients)
-- SELECT public.get_email_metrics(
--     NOW() - INTERVAL '30 days',  -- p_start_date
--     NOW(),                        -- p_end_date
--     NULL,                         -- p_client_id (all clients)
--     NULL,                         -- p_deployment_id (all deployments)
--     NULL                          -- p_agent_type_name (all agent types)
-- );

-- Test get_email_metrics() filtered by agent type (Louis only)
-- SELECT public.get_email_metrics(
--     NOW() - INTERVAL '30 days',
--     NOW(),
--     NULL,
--     NULL,
--     'louis'  -- Only Louis emails
-- );

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Next steps:
-- 1. Run this migration in STAGING first
-- 2. Run verification queries above
-- 3. Insert test emails via n8n or manually
-- 4. Verify that views return correct data
-- 5. Test get_email_metrics() with different filters
-- 6. Document results in features/email-tracking/MIGRATION_TESTED.md

-- Analytics capabilities:
-- - v_agent_emails_enriched: Emails with full context (client, agent, deployment)
-- - v_agent_communications_unified: Cross-channel analytics (calls + sms + emails)
-- - get_email_metrics(): Comprehensive KPIs with period comparison
--
-- These analytics enable:
-- - Email volume tracking by client/agent/type
-- - Delivery rate monitoring
-- - Cost analysis (internal_cost)
-- - Content metrics (word count, HTML size)
-- - Future: Open rate, click rate, bounce rate (v2.0)
