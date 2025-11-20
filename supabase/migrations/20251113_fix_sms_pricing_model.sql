-- Migration: Fix SMS Pricing Model
-- Date: 2025-11-13
-- Author: Claude (SMS Tracking Feature - Pricing Correction)
--
-- Purpose: Corriger le modèle de pricing SMS
--
-- ANCIEN MODÈLE (incorrect):
-- - provider_cost (input) + voipia_margin (input) = billed_cost (calculé)
-- - Marge fixe par SMS
--
-- NOUVEAU MODÈLE (correct):
-- - provider_cost (variable, coût réel Twilio)
-- - billed_cost (fixe, prix facturé au client depuis deployment.cost_per_sms)
-- - margin (calculé = billed_cost - provider_cost)
--
-- Changes:
-- 1. DROP colonne voipia_margin (obsolète)
-- 2. ALTER billed_cost : de GENERATED vers colonne normale (INPUT, pas OUTPUT)
-- 3. ADD colonne margin GENERATED (calculé dynamiquement)
-- 4. UPDATE comments pour refléter nouveau modèle

-- ============================================================================
-- STEP 1: Backup existing data (if any)
-- ============================================================================

-- Note: Cette migration doit être exécutée AVANT d'avoir des données en production
-- Si des données existent déjà, un script de migration des données serait nécessaire

-- ============================================================================
-- STEP 2: Modify table structure
-- ============================================================================

-- Drop old GENERATED column (must drop before altering)
ALTER TABLE public.agent_sms DROP COLUMN IF EXISTS billed_cost;

-- Drop obsolete margin column
ALTER TABLE public.agent_sms DROP COLUMN IF EXISTS voipia_margin;

-- Add billed_cost as regular column (not GENERATED)
-- This is the FIXED price charged to client (from deployment.cost_per_sms)
ALTER TABLE public.agent_sms
ADD COLUMN billed_cost NUMERIC(10, 4) CHECK (billed_cost >= 0);

-- Add margin as GENERATED column (calculated: billed - provider)
-- This is the CALCULATED profit margin per SMS
ALTER TABLE public.agent_sms
ADD COLUMN margin NUMERIC(10, 4) GENERATED ALWAYS AS (
    COALESCE(billed_cost, 0) - COALESCE(provider_cost, 0)
) STORED;

-- ============================================================================
-- STEP 3: Update comments
-- ============================================================================

COMMENT ON COLUMN public.agent_sms.provider_cost IS 'Real cost charged by SMS provider (Twilio) in EUR. VARIABLE per SMS (depends on destination country, message length, etc.)';

COMMENT ON COLUMN public.agent_sms.billed_cost IS 'Fixed price charged to client in EUR (copied from agent_deployments.cost_per_sms at send time). This is the REVENUE per SMS.';

COMMENT ON COLUMN public.agent_sms.margin IS 'Profit margin per SMS in EUR (CALCULATED = billed_cost - provider_cost). Can be negative if provider cost exceeds billed price.';

-- ============================================================================
-- STEP 4: Update views (margin replaces voipia_margin)
-- ============================================================================

CREATE OR REPLACE VIEW public.v_agent_sms_enriched AS
SELECT
    sms.id,
    sms.deployment_id,
    sms.call_id,
    sms.prospect_id,
    sms.sequence_id,
    ad.name AS deployment_name,
    ad.slug AS deployment_slug,
    ad.client_id,
    c.name AS client_name,
    ad.agent_type_id,
    at.name AS agent_type_name,
    at.display_name AS agent_display_name,
    sms.phone_number,
    sms.first_name,
    sms.last_name,
    sms.message_content,
    sms.message_type,
    sms.character_count,
    sms.provider,
    sms.provider_message_sid,
    sms.provider_status,
    sms.status,
    sms.sent_at,
    sms.delivered_at,
    sms.failed_at,
    sms.failure_reason,
    sms.provider_cost,
    sms.billed_cost,
    sms.margin, -- NEW: replaces voipia_margin
    sms.currency,
    sms.workflow_id,
    sms.workflow_execution_id,
    sms.metadata,
    sms.created_at,
    sms.updated_at,
    CASE WHEN sms.status = 'delivered' THEN true ELSE false END AS is_delivered,
    CASE WHEN sms.status = 'failed' THEN true ELSE false END AS is_failed,
    CASE
        WHEN sms.delivered_at IS NOT NULL AND sms.sent_at IS NOT NULL THEN
            EXTRACT(EPOCH FROM (sms.delivered_at - sms.sent_at))
        ELSE NULL
    END AS delivery_time_seconds
FROM public.agent_sms sms
JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
JOIN public.clients c ON ad.client_id = c.id
JOIN public.agent_types at ON ad.agent_type_id = at.id;

-- ============================================================================
-- STEP 5: Update get_sms_metrics function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_sms_metrics(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_client_id UUID DEFAULT NULL,
    p_deployment_id UUID DEFAULT NULL,
    p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_result JSONB;
    v_period_days INTEGER;
BEGIN
    v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

    WITH current_period AS (
        SELECT
            COUNT(*) AS total_sms,
            COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_sms,
            COUNT(*) FILTER (WHERE status = 'failed') AS failed_sms,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_sms,
            SUM(billed_cost) AS total_revenue, -- Revenue (what we charge)
            SUM(provider_cost) AS total_cost, -- Cost (what we pay)
            SUM(margin) AS total_margin, -- Profit (revenue - cost)
            AVG(margin) AS avg_margin_per_sms,
            AVG(character_count) AS avg_characters,
            MIN(character_count) AS min_characters,
            MAX(character_count) AS max_characters,
            COUNT(DISTINCT phone_number) AS unique_recipients,
            COUNT(DISTINCT deployment_id) AS active_deployments,
            COUNT(DISTINCT workflow_id) AS active_workflows,
            COUNT(*) FILTER (WHERE call_id IS NOT NULL) AS sms_linked_to_calls,
            AVG(
                CASE
                    WHEN delivered_at IS NOT NULL AND sent_at IS NOT NULL THEN
                        EXTRACT(EPOCH FROM (delivered_at - sent_at))
                    ELSE NULL
                END
            ) AS avg_delivery_time_seconds
        FROM v_agent_sms_enriched
        WHERE sent_at >= p_start_date
          AND sent_at <= p_end_date
          AND (p_client_id IS NULL OR client_id = p_client_id)
          AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    ),
    previous_period AS (
        SELECT
            COUNT(*) AS total_sms,
            COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_sms,
            COUNT(*) FILTER (WHERE status = 'failed') AS failed_sms,
            SUM(billed_cost) AS total_revenue,
            SUM(provider_cost) AS total_cost,
            SUM(margin) AS total_margin,
            AVG(character_count) AS avg_characters,
            COUNT(DISTINCT phone_number) AS unique_recipients
        FROM v_agent_sms_enriched
        WHERE sent_at >= (p_start_date - (v_period_days || ' days')::INTERVAL)
          AND sent_at < p_start_date
          AND (p_client_id IS NULL OR client_id = p_client_id)
          AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    ),
    by_message_type AS (
        SELECT
            message_type,
            COUNT(*) AS count,
            COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,
            SUM(billed_cost) AS revenue,
            SUM(margin) AS margin
        FROM v_agent_sms_enriched
        WHERE sent_at >= p_start_date
          AND sent_at <= p_end_date
          AND (p_client_id IS NULL OR client_id = p_client_id)
          AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        GROUP BY message_type
    )
    SELECT jsonb_build_object(
        'current_period', jsonb_build_object(
            'total_sms', cp.total_sms,
            'delivered_sms', cp.delivered_sms,
            'failed_sms', cp.failed_sms,
            'sent_sms', cp.sent_sms,
            'delivery_rate', CASE WHEN cp.total_sms > 0 THEN ROUND((cp.delivered_sms::NUMERIC / cp.total_sms::NUMERIC) * 100, 2) ELSE 0 END,
            'failure_rate', CASE WHEN cp.total_sms > 0 THEN ROUND((cp.failed_sms::NUMERIC / cp.total_sms::NUMERIC) * 100, 2) ELSE 0 END,
            'total_revenue', ROUND(COALESCE(cp.total_revenue, 0), 2),
            'total_cost', ROUND(COALESCE(cp.total_cost, 0), 2),
            'total_margin', ROUND(COALESCE(cp.total_margin, 0), 2),
            'margin_percentage', CASE WHEN cp.total_revenue > 0 THEN ROUND((cp.total_margin::NUMERIC / cp.total_revenue::NUMERIC) * 100, 2) ELSE 0 END,
            'avg_revenue_per_sms', CASE WHEN cp.total_sms > 0 THEN ROUND(cp.total_revenue / cp.total_sms, 4) ELSE 0 END,
            'avg_cost_per_sms', CASE WHEN cp.total_sms > 0 THEN ROUND(cp.total_cost / cp.total_sms, 4) ELSE 0 END,
            'avg_margin_per_sms', ROUND(COALESCE(cp.avg_margin_per_sms, 0), 4),
            'avg_characters', ROUND(COALESCE(cp.avg_characters, 0), 0),
            'min_characters', cp.min_characters,
            'max_characters', cp.max_characters,
            'unique_recipients', cp.unique_recipients,
            'active_deployments', cp.active_deployments,
            'active_workflows', cp.active_workflows,
            'sms_linked_to_calls', cp.sms_linked_to_calls,
            'call_linkage_rate', CASE WHEN cp.total_sms > 0 THEN ROUND((cp.sms_linked_to_calls::NUMERIC / cp.total_sms::NUMERIC) * 100, 2) ELSE 0 END,
            'avg_delivery_time_seconds', ROUND(COALESCE(cp.avg_delivery_time_seconds, 0), 2),
            'by_message_type', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'message_type', bmt.message_type,
                        'count', bmt.count,
                        'delivered', bmt.delivered,
                        'delivery_rate', CASE WHEN bmt.count > 0 THEN ROUND((bmt.delivered::NUMERIC / bmt.count::NUMERIC) * 100, 2) ELSE 0 END,
                        'revenue', ROUND(COALESCE(bmt.revenue, 0), 2),
                        'margin', ROUND(COALESCE(bmt.margin, 0), 2)
                    )
                )
                FROM by_message_type bmt
            )
        ),
        'previous_period', jsonb_build_object(
            'total_sms', pp.total_sms,
            'delivered_sms', pp.delivered_sms,
            'failed_sms', pp.failed_sms,
            'delivery_rate', CASE WHEN pp.total_sms > 0 THEN ROUND((pp.delivered_sms::NUMERIC / pp.total_sms::NUMERIC) * 100, 2) ELSE 0 END,
            'failure_rate', CASE WHEN pp.total_sms > 0 THEN ROUND((pp.failed_sms::NUMERIC / pp.total_sms::NUMERIC) * 100, 2) ELSE 0 END,
            'total_revenue', ROUND(COALESCE(pp.total_revenue, 0), 2),
            'total_cost', ROUND(COALESCE(pp.total_cost, 0), 2),
            'total_margin', ROUND(COALESCE(pp.total_margin, 0), 2),
            'avg_revenue_per_sms', CASE WHEN pp.total_sms > 0 THEN ROUND(pp.total_revenue / pp.total_sms, 4) ELSE 0 END,
            'avg_cost_per_sms', CASE WHEN pp.total_sms > 0 THEN ROUND(pp.total_cost / pp.total_sms, 4) ELSE 0 END,
            'avg_characters', ROUND(COALESCE(pp.avg_characters, 0), 0),
            'unique_recipients', pp.unique_recipients
        ),
        'comparison', jsonb_build_object(
            'total_sms_change', cp.total_sms - pp.total_sms,
            'total_sms_change_pct', CASE WHEN pp.total_sms > 0 THEN ROUND(((cp.total_sms - pp.total_sms)::NUMERIC / pp.total_sms::NUMERIC) * 100, 2) ELSE NULL END,
            'delivered_sms_change', cp.delivered_sms - pp.delivered_sms,
            'revenue_change', ROUND(COALESCE(cp.total_revenue, 0) - COALESCE(pp.total_revenue, 0), 2),
            'revenue_change_pct', CASE WHEN pp.total_revenue > 0 THEN ROUND(((cp.total_revenue - pp.total_revenue)::NUMERIC / pp.total_revenue::NUMERIC) * 100, 2) ELSE NULL END,
            'margin_change', ROUND(COALESCE(cp.total_margin, 0) - COALESCE(pp.total_margin, 0), 2),
            'margin_change_pct', CASE WHEN pp.total_margin > 0 THEN ROUND(((cp.total_margin - pp.total_margin)::NUMERIC / pp.total_margin::NUMERIC) * 100, 2) ELSE NULL END
        )
    ) INTO v_result
    FROM current_period cp
    CROSS JOIN previous_period pp;

    RETURN v_result;
END;
$$;

-- ============================================================================
-- VERIFICATION QUERIES (Commented out - uncomment to test)
-- ============================================================================

-- Check new structure
-- SELECT column_name, data_type, is_generated
-- FROM information_schema.columns
-- WHERE table_name = 'agent_sms'
--   AND column_name IN ('provider_cost', 'billed_cost', 'margin', 'voipia_margin')
-- ORDER BY ordinal_position;

-- Test with sample data
-- INSERT INTO agent_sms (
--     deployment_id, phone_number, message_content, sent_at,
--     provider_cost, billed_cost
-- ) VALUES (
--     'valid-deployment-id'::UUID,
--     '+33612345678',
--     'Test pricing model',
--     NOW(),
--     0.0489, -- Real Twilio cost (variable)
--     0.0700  -- Fixed price charged to client
-- );
-- Expected: margin = 0.0700 - 0.0489 = 0.0211 (auto-calculated)

-- SELECT
--     phone_number,
--     provider_cost,
--     billed_cost,
--     margin,
--     CASE
--         WHEN margin < 0 THEN 'LOSS'
--         WHEN margin > 0 THEN 'PROFIT'
--         ELSE 'BREAK-EVEN'
--     END AS profitability
-- FROM agent_sms
-- ORDER BY sent_at DESC
-- LIMIT 10;
