-- Migration: SMS Analytics Views and Functions
-- Date: 2025-11-13
-- Author: Claude (SMS Tracking Feature)
--
-- Purpose: Create analytics infrastructure for SMS tracking
--
-- Changes:
-- 1. Create v_agent_sms_enriched view (SMS with client/agent/deployment context)
-- 2. Create v_agent_communications view (unified calls + SMS)
-- 3. Create get_sms_metrics() RPC function for KPI calculations
-- 4. Grant permissions to authenticated users
--
-- Expected Impact:
-- - Views provide context-rich data for dashboards
-- - RPC function enables efficient KPI queries with period comparison
-- - Ready for frontend integration

-- ============================================================================
-- VIEW 1: v_agent_sms_enriched
-- Enriches agent_sms with client, agent type, and deployment context
-- ============================================================================

CREATE OR REPLACE VIEW public.v_agent_sms_enriched AS
SELECT
    -- SMS core fields
    sms.id,
    sms.deployment_id,
    sms.call_id,
    sms.prospect_id,
    sms.sequence_id,

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

    -- Recipient info
    sms.phone_number,
    sms.first_name,
    sms.last_name,

    -- Message details
    sms.message_content,
    sms.message_type,
    sms.character_count,

    -- Provider details
    sms.provider,
    sms.provider_message_sid,
    sms.provider_status,

    -- Delivery status
    sms.status,
    sms.sent_at,
    sms.delivered_at,
    sms.failed_at,
    sms.failure_reason,

    -- Costs
    sms.provider_cost,
    sms.voipia_margin,
    sms.billed_cost,
    sms.currency,

    -- n8n tracking
    sms.workflow_id,
    sms.workflow_execution_id,

    -- Metadata
    sms.metadata,

    -- Timestamps
    sms.created_at,
    sms.updated_at,

    -- Calculated fields
    CASE
        WHEN sms.status = 'delivered' THEN true
        ELSE false
    END AS is_delivered,

    CASE
        WHEN sms.status = 'failed' THEN true
        ELSE false
    END AS is_failed,

    CASE
        WHEN sms.delivered_at IS NOT NULL AND sms.sent_at IS NOT NULL THEN
            EXTRACT(EPOCH FROM (sms.delivered_at - sms.sent_at))
        ELSE NULL
    END AS delivery_time_seconds

FROM public.agent_sms sms
JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
JOIN public.clients c ON ad.client_id = c.id
JOIN public.agent_types at ON ad.agent_type_id = at.id;

COMMENT ON VIEW public.v_agent_sms_enriched IS 'Enriched view of SMS messages with deployment, client, and agent type context. Includes calculated fields for delivery status and timing.';

-- Grant SELECT to authenticated users (RLS from base table applies)
GRANT SELECT ON public.v_agent_sms_enriched TO authenticated;

-- ============================================================================
-- VIEW 2: v_agent_communications
-- Unified view combining calls and SMS for holistic touchpoint tracking
-- ============================================================================

CREATE OR REPLACE VIEW public.v_agent_communications AS
-- Calls
SELECT
    'call'::TEXT AS communication_type,
    ac.id,
    ac.deployment_id,
    ac.phone_number,
    ac.first_name,
    ac.last_name,
    ac.started_at AS timestamp,
    ac.outcome AS result,
    ac.total_cost AS cost,
    ac.duration_seconds,
    NULL::TEXT AS message_content,
    NULL::TEXT AS message_type,
    NULL::TEXT AS provider_message_sid,
    ac.metadata
FROM public.agent_calls ac

UNION ALL

-- SMS
SELECT
    'sms'::TEXT AS communication_type,
    sms.id,
    sms.deployment_id,
    sms.phone_number,
    sms.first_name,
    sms.last_name,
    sms.sent_at AS timestamp,
    sms.status AS result,
    sms.billed_cost AS cost,
    NULL::INTEGER AS duration_seconds,
    sms.message_content,
    sms.message_type,
    sms.provider_message_sid,
    sms.metadata
FROM public.agent_sms sms;

COMMENT ON VIEW public.v_agent_communications IS 'Unified view of all agent communications (calls + SMS) for complete customer touchpoint tracking. Useful for timeline views and multi-channel analytics.';

-- Grant SELECT to authenticated users (RLS from base tables apply)
GRANT SELECT ON public.v_agent_communications TO authenticated;

-- ============================================================================
-- RPC FUNCTION: get_sms_metrics
-- Calculate SMS KPI metrics with current vs previous period comparison
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
    -- Calculate period length for previous period comparison
    v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

    -- Build result with current and previous period metrics
    WITH current_period AS (
        SELECT
            COUNT(*) AS total_sms,
            COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_sms,
            COUNT(*) FILTER (WHERE status = 'failed') AS failed_sms,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_sms,
            SUM(billed_cost) AS total_cost,
            SUM(provider_cost) AS total_provider_cost,
            SUM(voipia_margin) AS total_margin,
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
            SUM(billed_cost) AS total_cost,
            SUM(provider_cost) AS total_provider_cost,
            SUM(voipia_margin) AS total_margin,
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
            SUM(billed_cost) AS cost
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
            -- Volume metrics
            'total_sms', cp.total_sms,
            'delivered_sms', cp.delivered_sms,
            'failed_sms', cp.failed_sms,
            'sent_sms', cp.sent_sms,

            -- Rate metrics
            'delivery_rate', CASE
                WHEN cp.total_sms > 0
                THEN ROUND((cp.delivered_sms::NUMERIC / cp.total_sms::NUMERIC) * 100, 2)
                ELSE 0
            END,
            'failure_rate', CASE
                WHEN cp.total_sms > 0
                THEN ROUND((cp.failed_sms::NUMERIC / cp.total_sms::NUMERIC) * 100, 2)
                ELSE 0
            END,

            -- Cost metrics
            'total_cost', ROUND(COALESCE(cp.total_cost, 0), 2),
            'total_provider_cost', ROUND(COALESCE(cp.total_provider_cost, 0), 2),
            'total_margin', ROUND(COALESCE(cp.total_margin, 0), 2),
            'margin_percentage', CASE
                WHEN cp.total_cost > 0
                THEN ROUND((cp.total_margin::NUMERIC / cp.total_cost::NUMERIC) * 100, 2)
                ELSE 0
            END,
            'avg_cost_per_sms', CASE
                WHEN cp.total_sms > 0
                THEN ROUND(cp.total_cost / cp.total_sms, 4)
                ELSE 0
            END,

            -- Message metrics
            'avg_characters', ROUND(COALESCE(cp.avg_characters, 0), 0),
            'min_characters', cp.min_characters,
            'max_characters', cp.max_characters,

            -- Engagement metrics
            'unique_recipients', cp.unique_recipients,
            'active_deployments', cp.active_deployments,
            'active_workflows', cp.active_workflows,
            'sms_linked_to_calls', cp.sms_linked_to_calls,
            'call_linkage_rate', CASE
                WHEN cp.total_sms > 0
                THEN ROUND((cp.sms_linked_to_calls::NUMERIC / cp.total_sms::NUMERIC) * 100, 2)
                ELSE 0
            END,

            -- Timing metrics
            'avg_delivery_time_seconds', ROUND(COALESCE(cp.avg_delivery_time_seconds, 0), 2),

            -- Breakdown by message type
            'by_message_type', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'message_type', bmt.message_type,
                        'count', bmt.count,
                        'delivered', bmt.delivered,
                        'delivery_rate', CASE
                            WHEN bmt.count > 0
                            THEN ROUND((bmt.delivered::NUMERIC / bmt.count::NUMERIC) * 100, 2)
                            ELSE 0
                        END,
                        'cost', ROUND(COALESCE(bmt.cost, 0), 2)
                    )
                )
                FROM by_message_type bmt
            )
        ),
        'previous_period', jsonb_build_object(
            'total_sms', pp.total_sms,
            'delivered_sms', pp.delivered_sms,
            'failed_sms', pp.failed_sms,
            'delivery_rate', CASE
                WHEN pp.total_sms > 0
                THEN ROUND((pp.delivered_sms::NUMERIC / pp.total_sms::NUMERIC) * 100, 2)
                ELSE 0
            END,
            'failure_rate', CASE
                WHEN pp.total_sms > 0
                THEN ROUND((pp.failed_sms::NUMERIC / pp.total_sms::NUMERIC) * 100, 2)
                ELSE 0
            END,
            'total_cost', ROUND(COALESCE(pp.total_cost, 0), 2),
            'total_margin', ROUND(COALESCE(pp.total_margin, 0), 2),
            'avg_cost_per_sms', CASE
                WHEN pp.total_sms > 0
                THEN ROUND(pp.total_cost / pp.total_sms, 4)
                ELSE 0
            END,
            'avg_characters', ROUND(COALESCE(pp.avg_characters, 0), 0),
            'unique_recipients', pp.unique_recipients
        ),
        'comparison', jsonb_build_object(
            'total_sms_change', cp.total_sms - pp.total_sms,
            'total_sms_change_pct', CASE
                WHEN pp.total_sms > 0
                THEN ROUND(((cp.total_sms - pp.total_sms)::NUMERIC / pp.total_sms::NUMERIC) * 100, 2)
                ELSE NULL
            END,
            'delivered_sms_change', cp.delivered_sms - pp.delivered_sms,
            'cost_change', ROUND(COALESCE(cp.total_cost, 0) - COALESCE(pp.total_cost, 0), 2),
            'cost_change_pct', CASE
                WHEN pp.total_cost > 0
                THEN ROUND(((cp.total_cost - pp.total_cost)::NUMERIC / pp.total_cost::NUMERIC) * 100, 2)
                ELSE NULL
            END
        )
    ) INTO v_result
    FROM current_period cp
    CROSS JOIN previous_period pp;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.get_sms_metrics IS 'Calculate comprehensive SMS KPI metrics with current vs previous period comparison. Returns JSONB with volume, delivery, cost, and engagement metrics. Filterable by client, deployment, and agent type.';

-- Grant EXECUTE to authenticated users
GRANT EXECUTE ON FUNCTION public.get_sms_metrics TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES (Commented out - uncomment to test)
-- ============================================================================

-- Test v_agent_sms_enriched view
-- SELECT
--     deployment_name,
--     agent_type_name,
--     COUNT(*) AS sms_count,
--     AVG(character_count) AS avg_chars,
--     SUM(billed_cost) AS total_cost
-- FROM v_agent_sms_enriched
-- WHERE sent_at >= NOW() - INTERVAL '30 days'
-- GROUP BY deployment_name, agent_type_name;

-- Test v_agent_communications view (calls + SMS)
-- SELECT
--     communication_type,
--     COUNT(*) AS count,
--     SUM(cost) AS total_cost
-- FROM v_agent_communications
-- WHERE timestamp >= NOW() - INTERVAL '30 days'
-- GROUP BY communication_type;

-- Test get_sms_metrics function
-- SELECT get_sms_metrics(
--     (NOW() - INTERVAL '30 days')::TIMESTAMPTZ,
--     NOW()::TIMESTAMPTZ,
--     NULL, -- client_id
--     NULL, -- deployment_id
--     'louis' -- agent_type_name
-- );

-- Check grants
-- SELECT routine_name, grantee, privilege_type
-- FROM information_schema.routine_privileges
-- WHERE routine_name = 'get_sms_metrics';
