-- Migration: Remove call_classification column from agent_calls
-- Date: 2025-11-20
-- Author: Claude
--
-- Context:
-- The call_classification column in agent_calls is always empty ("") and unused.
-- It appears in SELECT lists of 3 views but is never used in WHERE/JOIN clauses.
--
-- Changes:
-- 1. Drop 3 views that reference call_classification (v_agent_calls_enriched, v_arthur_calls_enriched, v_global_kpis)
-- 2. Recreate views WITHOUT call_classification in SELECT lists
-- 3. Drop call_classification column from agent_calls table
-- 4. Restore permissions on views
--
-- Safety:
-- - Uses transaction to ensure atomicity
-- - Preserves all other columns (sentiment_analysis, call_status, etc.)
-- - Maintains exact same structure for computed columns (answered, appointment_scheduled)
--
-- Expected Impact:
-- - Removes unused column, reducing table size
-- - No functional impact (column was never used)
-- - Cleaner schema for future development

BEGIN;

-- =============================================================================
-- STEP 1: Drop views that reference call_classification
-- =============================================================================

DROP VIEW IF EXISTS v_global_kpis CASCADE;
DROP VIEW IF EXISTS v_arthur_calls_enriched CASCADE;
DROP VIEW IF EXISTS v_agent_calls_enriched CASCADE;

-- =============================================================================
-- STEP 2: Recreate v_agent_calls_enriched WITHOUT call_classification
-- =============================================================================

CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT
    id,
    deployment_id,
    first_name,
    last_name,
    email,
    phone_number,
    started_at,
    ended_at,
    duration_seconds,
    outcome,
    emotion,
    total_cost,
    transcript,
    transcript_summary,
    recording_url,
    metadata,
    created_at,
    prospect_id,
    sequence_id,
    conversation_id,
    -- call_classification removed (was always empty)
    call_quality_score,
    sentiment_analysis,
    -- Computed columns
    CASE
        WHEN outcome IN ('voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected') THEN false
        WHEN outcome IS NULL THEN false
        ELSE true
    END AS answered,
    CASE
        WHEN outcome = 'appointment_scheduled' THEN true
        ELSE false
    END AS appointment_scheduled
FROM agent_calls ac;

-- =============================================================================
-- STEP 3: Recreate v_arthur_calls_enriched WITHOUT call_classification
-- =============================================================================

CREATE OR REPLACE VIEW v_arthur_calls_enriched AS
SELECT
    ac.id,
    ac.deployment_id,
    ac.first_name,
    ac.last_name,
    ac.email,
    ac.phone_number,
    ac.started_at,
    ac.ended_at,
    ac.duration_seconds,
    ac.outcome,
    ac.emotion,
    ac.total_cost,
    ac.transcript,
    ac.transcript_summary,
    ac.recording_url,
    ac.metadata,
    ac.created_at,
    ac.prospect_id,
    ac.sequence_id,
    ac.conversation_id,
    ac.call_sid,
    ac.stt_cost,
    ac.tts_cost,
    ac.llm_cost,
    ac.telecom_cost,
    ac.dipler_commission,
    ac.cost_per_minute,
    -- call_classification removed (was always empty)
    ac.call_quality_score,
    ac.sentiment_analysis,
    ac.llm_model,
    ac.tts_provider,
    ac.tts_voice_id,
    ac.stt_provider,
    ac.direction,
    ac.call_status,
    ac.provider,
    -- Computed columns
    CASE
        WHEN ac.outcome IN ('voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected') THEN false
        WHEN ac.outcome IS NULL THEN false
        ELSE true
    END AS answered,
    CASE
        WHEN ac.outcome = 'appointment_scheduled' THEN true
        ELSE false
    END AS appointment_scheduled,
    -- Joined columns
    ad.name AS deployment_name,
    ad.slug AS deployment_slug,
    ad.client_id,
    c.name AS client_name,
    at.name AS agent_type_name,
    at.display_name AS agent_type_display_name
FROM agent_calls ac
JOIN agent_deployments ad ON ac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
JOIN clients c ON ad.client_id = c.id
WHERE at.name = 'arthur';

-- =============================================================================
-- STEP 4: Recreate v_global_kpis WITHOUT call_classification
-- =============================================================================

CREATE OR REPLACE VIEW v_global_kpis AS
WITH period_calls AS (
    SELECT
        ac.id,
        ac.deployment_id,
        ac.first_name,
        ac.last_name,
        ac.email,
        ac.phone_number,
        ac.started_at,
        ac.ended_at,
        ac.duration_seconds,
        ac.outcome,
        ac.emotion,
        ac.total_cost,
        ac.transcript,
        ac.transcript_summary,
        ac.recording_url,
        ac.metadata,
        ac.created_at,
        ac.prospect_id,
        ac.sequence_id,
        ac.conversation_id,
        ac.call_sid,
        ac.stt_cost,
        ac.tts_cost,
        ac.llm_cost,
        ac.telecom_cost,
        ac.dipler_commission,
        ac.cost_per_minute,
        -- call_classification removed (was always empty)
        ac.call_quality_score,
        ac.sentiment_analysis,
        ac.llm_model,
        ac.tts_provider,
        ac.tts_voice_id,
        ac.stt_provider,
        ac.direction,
        ac.call_status,
        ac.provider,
        -- Computed columns
        CASE
            WHEN ac.outcome IN ('voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected') THEN false
            WHEN ac.outcome IS NULL THEN false
            ELSE true
        END AS answered,
        CASE
            WHEN ac.outcome = 'appointment_scheduled' THEN true
            ELSE false
        END AS appointment_scheduled
    FROM agent_calls ac
),
current_period AS (
    SELECT
        COUNT(*) AS total_calls,
        COUNT(*) FILTER (WHERE answered) AS answered_calls,
        COUNT(*) FILTER (WHERE appointment_scheduled) AS appointments_scheduled,
        ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0) AS avg_duration,
        SUM(total_cost) AS total_cost
    FROM period_calls
    WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
),
previous_period AS (
    SELECT
        COUNT(*) AS total_calls,
        COUNT(*) FILTER (WHERE answered) AS answered_calls,
        COUNT(*) FILTER (WHERE appointment_scheduled) AS appointments_scheduled,
        ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0) AS avg_duration,
        SUM(total_cost) AS total_cost
    FROM period_calls
    WHERE started_at >= CURRENT_DATE - INTERVAL '60 days'
      AND started_at < CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    jsonb_build_object(
        'total_calls', cp.total_calls,
        'answered_calls', cp.answered_calls,
        'appointments_scheduled', cp.appointments_scheduled,
        'avg_duration', cp.avg_duration,
        'total_cost', cp.total_cost
    ) AS current_period,
    jsonb_build_object(
        'total_calls', pp.total_calls,
        'answered_calls', pp.answered_calls,
        'appointments_scheduled', pp.appointments_scheduled,
        'avg_duration', pp.avg_duration,
        'total_cost', pp.total_cost
    ) AS previous_period
FROM current_period cp, previous_period pp;

-- =============================================================================
-- STEP 5: Restore permissions on views
-- =============================================================================

GRANT SELECT ON v_agent_calls_enriched TO authenticated;
GRANT SELECT ON v_arthur_calls_enriched TO authenticated;
GRANT SELECT ON v_global_kpis TO authenticated;

-- =============================================================================
-- STEP 6: Drop call_classification column from agent_calls table
-- =============================================================================

ALTER TABLE agent_calls DROP COLUMN IF EXISTS call_classification;

COMMIT;

-- =============================================================================
-- VERIFICATION QUERIES (Run these after migration to verify success)
-- =============================================================================

-- Verify column is gone from agent_calls
-- SELECT column_name
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'agent_calls'
--   AND column_name = 'call_classification';
-- Expected result: 0 rows (column should not exist)

-- Verify views are working and don't have call_classification
-- SELECT * FROM v_agent_calls_enriched LIMIT 1;
-- SELECT * FROM v_arthur_calls_enriched LIMIT 1;
-- SELECT * FROM v_global_kpis;
-- Expected result: No errors, call_classification column should not appear

-- Verify column count in views (should be one less than before)
-- SELECT COUNT(*)
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'v_agent_calls_enriched';
-- Expected result: One less column than before migration
