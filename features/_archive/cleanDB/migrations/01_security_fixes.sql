-- ============================================
-- MIGRATION: SECURITY FIXES
-- Date: 2025-01-13
-- Environment: Production
-- Phase: 1/3
-- Author: Claude Code
-- ============================================

-- Description: This migration fixes 18 CRITICAL security issues:
-- - 16 views with SECURITY DEFINER → SECURITY INVOKER
-- - 2 tables with RLS enabled but no policies
--
-- Impact: HIGH (security vulnerabilities eliminated)
-- Risk: LOW (permissions already correctly set)
-- Duration: ~30 seconds
-- Rollback: Possible (revert to SECURITY DEFINER)

-- ============================================
-- SECTION 1: CONVERT SECURITY DEFINER VIEWS
-- ============================================

-- Fix: Change 16 views from SECURITY DEFINER to SECURITY INVOKER
-- Impact: Views will now respect user permissions correctly
-- Risk: LOW (existing grants ensure proper access)

BEGIN;

-- ============================================
-- 1.1 v_user_accessible_clients
-- ============================================
DROP VIEW IF EXISTS v_user_accessible_clients CASCADE;

CREATE VIEW v_user_accessible_clients WITH (security_invoker = true) AS
SELECT c.id AS client_id,
    c.name AS client_name,
    c.industry,
    ucp.user_id,
    ucp.permission_level,
    count(DISTINCT ad.id) AS total_agents,
    count(DISTINCT ad.id) FILTER (WHERE (ad.status = 'active'::text)) AS active_agents,
    count(DISTINCT at.name) AS agent_types_count,
    array_agg(DISTINCT at.display_name) FILTER (WHERE (at.display_name IS NOT NULL)) AS agent_types_list
FROM (((clients c
    JOIN user_client_permissions ucp ON ((c.id = ucp.client_id)))
    LEFT JOIN agent_deployments ad ON ((c.id = ad.client_id)))
    LEFT JOIN agent_types at ON ((ad.agent_type_id = at.id)))
GROUP BY c.id, c.name, c.industry, ucp.user_id, ucp.permission_level
ORDER BY c.name;

GRANT SELECT ON v_user_accessible_clients TO authenticated;
GRANT SELECT ON v_user_accessible_clients TO anon;

COMMENT ON VIEW v_user_accessible_clients IS 'Clients accessibles par l''utilisateur authentifié (SECURITY INVOKER)';

-- ============================================
-- 1.2 v_user_accessible_agents
-- ============================================
DROP VIEW IF EXISTS v_user_accessible_agents CASCADE;

CREATE VIEW v_user_accessible_agents WITH (security_invoker = true) AS
SELECT ad.id AS deployment_id,
    ad.name AS deployment_name,
    ad.slug,
    ad.client_id,
    c.name AS client_name,
    ad.agent_type_id,
    at.name AS agent_type_name,
    at.display_name AS agent_display_name,
    ad.status AS deployment_status,
    ucp.user_id,
    ucp.permission_level,
    max(ac.started_at) AS last_call_at,
    count(ac.id) AS total_calls_last_30d
FROM ((((agent_deployments ad
    JOIN clients c ON ((ad.client_id = c.id)))
    JOIN user_client_permissions ucp ON ((c.id = ucp.client_id)))
    JOIN agent_types at ON ((ad.agent_type_id = at.id)))
    LEFT JOIN agent_calls ac ON (((ad.id = ac.deployment_id) AND (ac.started_at >= (CURRENT_DATE - '30 days'::interval)))))
GROUP BY ad.id, ad.name, ad.slug, ad.client_id, c.name, ad.agent_type_id, at.name, at.display_name, ad.status, ucp.user_id, ucp.permission_level
ORDER BY c.name, at.display_name, ad.name;

GRANT SELECT ON v_user_accessible_agents TO authenticated;
GRANT SELECT ON v_user_accessible_agents TO anon;

COMMENT ON VIEW v_user_accessible_agents IS 'Agents déployés accessibles par l''utilisateur (SECURITY INVOKER)';

-- ============================================
-- 1.3 v_agent_calls_enriched
-- ============================================
DROP VIEW IF EXISTS v_agent_calls_enriched CASCADE;

CREATE VIEW v_agent_calls_enriched WITH (security_invoker = true) AS
SELECT id,
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
    call_classification,
    call_quality_score,
    sentiment_analysis,
    CASE
        WHEN (outcome = ANY (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) THEN false
        WHEN (outcome IS NULL) THEN false
        ELSE true
    END AS answered,
    CASE
        WHEN (outcome = 'appointment_scheduled'::text) THEN true
        ELSE false
    END AS appointment_scheduled
FROM agent_calls ac;

GRANT SELECT ON v_agent_calls_enriched TO authenticated;
GRANT SELECT ON v_agent_calls_enriched TO anon;

COMMENT ON VIEW v_agent_calls_enriched IS 'Vue enrichie des appels avec champs calculés (SECURITY INVOKER)';

-- ============================================
-- 1.4 v_arthur_calls_enriched
-- ============================================
DROP VIEW IF EXISTS v_arthur_calls_enriched CASCADE;

CREATE VIEW v_arthur_calls_enriched WITH (security_invoker = true) AS
SELECT ac.id,
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
    ac.call_classification,
    ac.call_quality_score,
    ac.sentiment_analysis,
    ac.llm_model,
    ac.tts_provider,
    ac.tts_voice_id,
    ac.stt_provider,
    ac.direction,
    ac.call_status,
    ac.provider,
    CASE
        WHEN (ac.outcome = ANY (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) THEN false
        WHEN (ac.outcome IS NULL) THEN false
        ELSE true
    END AS answered,
    CASE
        WHEN (ac.outcome = 'appointment_scheduled'::text) THEN true
        ELSE false
    END AS appointment_scheduled,
    ad.name AS deployment_name,
    ad.slug AS deployment_slug,
    ad.client_id,
    c.name AS client_name,
    at.name AS agent_type_name,
    at.display_name AS agent_type_display_name
FROM (((agent_calls ac
    JOIN agent_deployments ad ON ((ac.deployment_id = ad.id)))
    JOIN agent_types at ON ((ad.agent_type_id = at.id)))
    JOIN clients c ON ((ad.client_id = c.id)))
WHERE (at.name = 'arthur'::text);

GRANT SELECT ON v_arthur_calls_enriched TO authenticated;
GRANT SELECT ON v_arthur_calls_enriched TO anon;

COMMENT ON VIEW v_arthur_calls_enriched IS 'Vue enrichie des appels Arthur avec données client (SECURITY INVOKER)';

-- ============================================
-- 1.5 v_louis_agent_performance
-- ============================================
DROP VIEW IF EXISTS v_louis_agent_performance CASCADE;

CREATE VIEW v_louis_agent_performance WITH (security_invoker = true) AS
SELECT ad.id AS deployment_id,
    ad.name AS deployment_name,
    ad.slug AS deployment_slug,
    c.name AS client_name,
    count(ac.id) AS total_calls,
    count(ac.id) FILTER (WHERE ((ac.outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (ac.outcome IS NOT NULL))) AS answered_calls,
    count(ac.id) FILTER (WHERE (ac.outcome = 'appointment_scheduled'::text)) AS appointments_scheduled,
    round((((count(ac.id) FILTER (WHERE ((ac.outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (ac.outcome IS NOT NULL))))::numeric * 100.0) / (NULLIF(count(ac.id), 0))::numeric), 2) AS answer_rate,
    round((((count(ac.id) FILTER (WHERE (ac.outcome = 'appointment_scheduled'::text)))::numeric * 100.0) / (NULLIF(count(ac.id) FILTER (WHERE ((ac.outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (ac.outcome IS NOT NULL))), 0))::numeric), 2) AS conversion_rate,
    sum(ac.total_cost) AS total_cost,
    avg(ac.duration_seconds) FILTER (WHERE (ac.duration_seconds > 0)) AS avg_duration
FROM (((agent_calls ac
    JOIN agent_deployments ad ON ((ac.deployment_id = ad.id)))
    JOIN agent_types at ON ((ad.agent_type_id = at.id)))
    JOIN clients c ON ((ad.client_id = c.id)))
WHERE (at.name = 'louis'::text)
GROUP BY ad.id, ad.name, ad.slug, c.name
ORDER BY (count(ac.id)) DESC;

GRANT SELECT ON v_louis_agent_performance TO authenticated;
GRANT SELECT ON v_louis_agent_performance TO anon;

COMMENT ON VIEW v_louis_agent_performance IS 'Métriques de performance Louis (SECURITY INVOKER)';

-- ============================================
-- 1.6 v_global_kpis
-- ============================================
DROP VIEW IF EXISTS v_global_kpis CASCADE;

CREATE VIEW v_global_kpis WITH (security_invoker = true) AS
WITH period_calls AS (
    SELECT ac.id,
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
        ac.call_classification,
        ac.call_quality_score,
        ac.sentiment_analysis,
        ac.llm_model,
        ac.tts_provider,
        ac.tts_voice_id,
        ac.stt_provider,
        ac.direction,
        ac.call_status,
        ac.provider,
        CASE
            WHEN (ac.outcome = ANY (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) THEN false
            WHEN (ac.outcome IS NULL) THEN false
            ELSE true
        END AS answered,
        CASE
            WHEN (ac.outcome = 'appointment_scheduled'::text) THEN true
            ELSE false
        END AS appointment_scheduled
    FROM agent_calls ac
), current_period AS (
    SELECT count(*) AS total_calls,
        count(*) FILTER (WHERE period_calls.answered) AS answered_calls,
        count(*) FILTER (WHERE period_calls.appointment_scheduled) AS appointments_scheduled,
        round(avg(period_calls.duration_seconds) FILTER (WHERE (period_calls.duration_seconds > 0)), 0) AS avg_duration,
        sum(period_calls.total_cost) AS total_cost
    FROM period_calls
    WHERE (period_calls.started_at >= (CURRENT_DATE - '30 days'::interval))
), previous_period AS (
    SELECT count(*) AS total_calls,
        count(*) FILTER (WHERE period_calls.answered) AS answered_calls,
        count(*) FILTER (WHERE period_calls.appointment_scheduled) AS appointments_scheduled,
        round(avg(period_calls.duration_seconds) FILTER (WHERE (period_calls.duration_seconds > 0)), 0) AS avg_duration,
        sum(period_calls.total_cost) AS total_cost
    FROM period_calls
    WHERE ((period_calls.started_at >= (CURRENT_DATE - '60 days'::interval)) AND (period_calls.started_at < (CURRENT_DATE - '30 days'::interval)))
)
SELECT jsonb_build_object('total_calls', cp.total_calls, 'answered_calls', cp.answered_calls, 'appointments_scheduled', cp.appointments_scheduled, 'avg_duration', cp.avg_duration, 'total_cost', cp.total_cost) AS current_period,
    jsonb_build_object('total_calls', pp.total_calls, 'answered_calls', pp.answered_calls, 'appointments_scheduled', pp.appointments_scheduled, 'avg_duration', pp.avg_duration, 'total_cost', pp.total_cost) AS previous_period
FROM current_period cp,
    previous_period pp;

GRANT SELECT ON v_global_kpis TO authenticated;
GRANT SELECT ON v_global_kpis TO anon;

COMMENT ON VIEW v_global_kpis IS 'KPIs globaux avec comparaison période actuelle vs précédente (SECURITY INVOKER)';

-- ============================================
-- 1.7 v_global_outcome_distribution
-- ============================================
DROP VIEW IF EXISTS v_global_outcome_distribution CASCADE;

CREATE VIEW v_global_outcome_distribution WITH (security_invoker = true) AS
SELECT COALESCE(outcome, 'unknown'::text) AS outcome,
    count(*) AS count,
    round((((count(*))::numeric * 100.0) / sum(count(*)) OVER ()), 2) AS percentage
FROM agent_calls
GROUP BY outcome
ORDER BY (count(*)) DESC;

GRANT SELECT ON v_global_outcome_distribution TO authenticated;
GRANT SELECT ON v_global_outcome_distribution TO anon;

COMMENT ON VIEW v_global_outcome_distribution IS 'Distribution des outcomes d''appels (SECURITY INVOKER)';

-- ============================================
-- 1.8 v_global_call_volume_by_day
-- ============================================
DROP VIEW IF EXISTS v_global_call_volume_by_day CASCADE;

CREATE VIEW v_global_call_volume_by_day WITH (security_invoker = true) AS
SELECT date(started_at) AS call_date,
    count(*) AS total_calls,
    count(*) FILTER (WHERE ((outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (outcome IS NOT NULL))) AS answered_calls,
    count(*) FILTER (WHERE (outcome = 'appointment_scheduled'::text)) AS appointments_scheduled,
    sum(total_cost) AS total_cost,
    avg(duration_seconds) FILTER (WHERE (duration_seconds > 0)) AS avg_duration
FROM agent_calls
GROUP BY (date(started_at))
ORDER BY (date(started_at)) DESC;

GRANT SELECT ON v_global_call_volume_by_day TO authenticated;
GRANT SELECT ON v_global_call_volume_by_day TO anon;

COMMENT ON VIEW v_global_call_volume_by_day IS 'Volume d''appels par jour (SECURITY INVOKER)';

-- ============================================
-- 1.9 v_global_agent_type_performance
-- ============================================
DROP VIEW IF EXISTS v_global_agent_type_performance CASCADE;

CREATE VIEW v_global_agent_type_performance WITH (security_invoker = true) AS
SELECT at.name AS agent_type_name,
    at.display_name AS agent_type_display_name,
    count(ac.id) AS total_calls,
    count(ac.id) FILTER (WHERE ((ac.outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (ac.outcome IS NOT NULL))) AS answered_calls,
    count(ac.id) FILTER (WHERE (ac.outcome = 'appointment_scheduled'::text)) AS appointments_scheduled,
    sum(ac.total_cost) AS total_cost,
    avg(ac.duration_seconds) FILTER (WHERE (ac.duration_seconds > 0)) AS avg_duration
FROM ((agent_calls ac
    JOIN agent_deployments ad ON ((ac.deployment_id = ad.id)))
    JOIN agent_types at ON ((ad.agent_type_id = at.id)))
GROUP BY at.id, at.name, at.display_name
ORDER BY (count(ac.id)) DESC;

GRANT SELECT ON v_global_agent_type_performance TO authenticated;
GRANT SELECT ON v_global_agent_type_performance TO anon;

COMMENT ON VIEW v_global_agent_type_performance IS 'Performance par type d''agent (SECURITY INVOKER)';

-- ============================================
-- 1.10 v_global_top_clients
-- ============================================
DROP VIEW IF EXISTS v_global_top_clients CASCADE;

CREATE VIEW v_global_top_clients WITH (security_invoker = true) AS
SELECT c.id AS client_id,
    c.name AS client_name,
    count(ac.id) AS total_calls,
    count(ac.id) FILTER (WHERE ((ac.outcome <> ALL (ARRAY['voicemail'::text, 'call_failed'::text, 'no_answer'::text, 'busy'::text, 'invalid_number'::text, 'error'::text, 'canceled'::text, 'rejected'::text])) AND (ac.outcome IS NOT NULL))) AS answered_calls,
    count(ac.id) FILTER (WHERE (ac.outcome = 'appointment_scheduled'::text)) AS appointments_scheduled,
    sum(ac.total_cost) AS total_cost
FROM ((agent_calls ac
    JOIN agent_deployments ad ON ((ac.deployment_id = ad.id)))
    JOIN clients c ON ((ad.client_id = c.id)))
GROUP BY c.id, c.name
ORDER BY (count(ac.id)) DESC;

GRANT SELECT ON v_global_top_clients TO authenticated;
GRANT SELECT ON v_global_top_clients TO anon;

COMMENT ON VIEW v_global_top_clients IS 'Top clients par volume d''appels (SECURITY INVOKER)';

-- ============================================
-- 1.11 v_arthur_next_calls
-- ============================================
DROP VIEW IF EXISTS v_arthur_next_calls CASCADE;

CREATE VIEW v_arthur_next_calls WITH (security_invoker = true) AS
SELECT ps.id AS sequence_id,
    p.id AS prospect_id,
    p.external_deal_id AS pipedrive_deal_id,
    p.external_user_id AS pipedrive_person_id,
    p.first_name,
    p.last_name,
    p.phone_number,
    p.status AS prospect_status,
    ps.deployment_id,
    ps.current_attempt,
    ps.max_attempts,
    ps.next_action_at,
    (p.ai_analysis ->> 'approche_arthur'::text) AS approche_recommandee,
    (p.ai_analysis -> 'points_accroche'::text) AS points_accroche,
    ps.metadata
FROM (agent_arthur_prospect_sequences ps
    JOIN agent_arthur_prospects p ON ((p.id = ps.prospect_id)))
WHERE ((ps.status = 'active'::text) AND (ps.next_action_at IS NOT NULL) AND (ps.next_action_at <= now()))
ORDER BY ps.next_action_at;

GRANT SELECT ON v_arthur_next_calls TO authenticated;
GRANT SELECT ON v_arthur_next_calls TO anon;

COMMENT ON VIEW v_arthur_next_calls IS 'Prochains appels Arthur à effectuer (SECURITY INVOKER)';

-- ============================================
-- 1.12 v_arthur_next_calls_global
-- ============================================
DROP VIEW IF EXISTS v_arthur_next_calls_global CASCADE;

CREATE VIEW v_arthur_next_calls_global WITH (security_invoker = true) AS
SELECT p.id AS prospect_id,
    p.first_name,
    p.last_name,
    p.phone_number,
    p.email,
    p.company_name,
    p.status AS prospect_status,
    ps.id AS sequence_id,
    ps.current_attempt,
    ps.max_attempts,
    ps.next_action_at,
    ps.status AS sequence_status,
    count(ac.id) AS total_calls_count,
    max(ac.started_at) AS last_call_at,
    max(ac.outcome) AS last_call_outcome
FROM ((agent_arthur_prospects p
    JOIN agent_arthur_prospect_sequences ps ON ((p.id = ps.prospect_id)))
    LEFT JOIN agent_calls ac ON (((p.id = ac.prospect_id) AND (ps.id = ac.sequence_id))))
WHERE ((ps.status = 'active'::text) AND (ps.next_action_at > now()))
GROUP BY p.id, p.first_name, p.last_name, p.phone_number, p.email, p.company_name, p.status, ps.id, ps.current_attempt, ps.max_attempts, ps.next_action_at, ps.status
ORDER BY ps.next_action_at;

GRANT SELECT ON v_arthur_next_calls_global TO authenticated;
GRANT SELECT ON v_arthur_next_calls_global TO anon;

COMMENT ON VIEW v_arthur_next_calls_global IS 'Vue globale des prochains appels Arthur (SECURITY INVOKER)';

-- ============================================
-- 1.13 v_arthur_next_call_norloc
-- ============================================
DROP VIEW IF EXISTS v_arthur_next_call_norloc CASCADE;

CREATE VIEW v_arthur_next_call_norloc WITH (security_invoker = true) AS
SELECT ps.id AS sequence_id,
    p.id AS prospect_id,
    p.external_deal_id,
    p.external_user_id,
    p.first_name,
    p.last_name,
    p.phone_number,
    p.email,
    p.status AS prospect_status,
    ps.status AS sequence_status,
    ps.deployment_id,
    ps.current_attempt,
    ps.max_attempts,
    ps.next_action_at,
    (p.ai_analysis ->> 'approche_arthur'::text) AS approche_recommandee,
    (p.ai_analysis -> 'points_accroche'::text) AS points_accroche,
    (p.ai_analysis ->> 'segment_detecte'::text) AS segment,
    (p.ai_analysis ->> 'delai_contact'::text) AS delai_contact,
    (p.ai_analysis ->> 'dernier_interlocuteur'::text) AS dernier_interlocuteur,
    (p.ai_analysis ->> 'historique_resume'::text) AS historique_resume,
    (p.ai_analysis ->> 'comportement_detecte'::text) AS comportement_detecte,
    (p.ai_analysis -> 'objections_probables'::text) AS objections_probables,
    (p.ai_analysis ->> 'recommandation'::text) AS recommandation,
    (p.ai_analysis ->> 'notes_importantes'::text) AS notes_importantes,
    ps.metadata,
    CASE
        WHEN (ps.status = 'callback'::text) THEN 'CALLBACK'::text
        WHEN (ps.status = 'active'::text) THEN 'ACTIVE'::text
        ELSE 'OTHER'::text
    END AS call_type,
    CASE
        WHEN (ps.current_attempt >= ps.max_attempts) THEN true
        ELSE false
    END AS exceeded_max_attempts
FROM (agent_arthur_prospect_sequences ps
    JOIN agent_arthur_prospects p ON ((p.id = ps.prospect_id)))
WHERE ((ps.deployment_id = 'd44a37ed-eed8-45c4-8886-c2b326551ec6'::uuid) AND (ps.status = ANY (ARRAY['active'::text, 'callback'::text])) AND (ps.next_action_at IS NOT NULL) AND (ps.next_action_at <= now()))
ORDER BY
    CASE
        WHEN (ps.status = 'callback'::text) THEN 1
        WHEN (ps.status = 'active'::text) THEN 2
        ELSE 3
    END, ps.next_action_at
LIMIT 1;

GRANT SELECT ON v_arthur_next_call_norloc TO authenticated;
GRANT SELECT ON v_arthur_next_call_norloc TO anon;

COMMENT ON VIEW v_arthur_next_call_norloc IS 'Prochain appel Arthur pour Norloc (SECURITY INVOKER)';

-- ============================================
-- 1.14 v_arthur_next_call_stefanodesign
-- ============================================
DROP VIEW IF EXISTS v_arthur_next_call_stefanodesign CASCADE;

CREATE VIEW v_arthur_next_call_stefanodesign WITH (security_invoker = true) AS
SELECT ps.id AS sequence_id,
    p.id AS prospect_id,
    p.external_deal_id,
    p.external_user_id,
    p.first_name,
    p.last_name,
    p.phone_number,
    p.email,
    p.status AS prospect_status,
    ps.status AS sequence_status,
    ps.deployment_id,
    ps.current_attempt,
    ps.max_attempts,
    ps.next_action_at,
    (p.ai_analysis ->> 'approche_arthur'::text) AS approche_recommandee,
    (p.ai_analysis -> 'points_accroche'::text) AS points_accroche,
    (p.ai_analysis ->> 'segment_detecte'::text) AS segment,
    (p.ai_analysis ->> 'delai_contact'::text) AS delai_contact,
    (p.ai_analysis ->> 'dernier_interlocuteur'::text) AS dernier_interlocuteur,
    (p.ai_analysis ->> 'historique_resume'::text) AS historique_resume,
    (p.ai_analysis ->> 'comportement_detecte'::text) AS comportement_detecte,
    (p.ai_analysis -> 'objections_probables'::text) AS objections_probables,
    (p.ai_analysis ->> 'recommandation'::text) AS recommandation,
    (p.ai_analysis ->> 'notes_importantes'::text) AS notes_importantes,
    ps.metadata,
    CASE
        WHEN (ps.status = 'callback'::text) THEN 'CALLBACK'::text
        WHEN (ps.status = 'active'::text) THEN 'ACTIVE'::text
        ELSE 'OTHER'::text
    END AS call_type,
    CASE
        WHEN (ps.current_attempt >= ps.max_attempts) THEN true
        ELSE false
    END AS exceeded_max_attempts
FROM (agent_arthur_prospect_sequences ps
    JOIN agent_arthur_prospects p ON ((p.id = ps.prospect_id)))
WHERE ((ps.deployment_id = '63ec5a2a-8b8f-49cc-86ca-d76c2caa008e'::uuid) AND (ps.status = ANY (ARRAY['active'::text, 'callback'::text])) AND (ps.next_action_at IS NOT NULL) AND (ps.next_action_at <= now()))
ORDER BY
    CASE
        WHEN (ps.status = 'callback'::text) THEN 1
        WHEN (ps.status = 'active'::text) THEN 2
        ELSE 3
    END, ps.next_action_at
LIMIT 1;

GRANT SELECT ON v_arthur_next_call_stefanodesign TO authenticated;
GRANT SELECT ON v_arthur_next_call_stefanodesign TO anon;

COMMENT ON VIEW v_arthur_next_call_stefanodesign IS 'Prochain appel Arthur pour Stefano Design (SECURITY INVOKER)';

-- ============================================
-- 1.15 v_arthur_next_call_exoticdesign
-- ============================================
DROP VIEW IF EXISTS v_arthur_next_call_exoticdesign CASCADE;

CREATE VIEW v_arthur_next_call_exoticdesign WITH (security_invoker = true) AS
SELECT ps.id AS sequence_id,
    p.id AS prospect_id,
    p.external_deal_id,
    p.external_user_id,
    p.first_name,
    p.last_name,
    p.phone_number,
    p.email,
    p.status AS prospect_status,
    ps.status AS sequence_status,
    ps.deployment_id,
    ps.current_attempt,
    ps.max_attempts,
    ps.next_action_at,
    (p.ai_analysis ->> 'approche_arthur'::text) AS approche_recommandee,
    (p.ai_analysis -> 'points_accroche'::text) AS points_accroche,
    (p.ai_analysis ->> 'segment_detecte'::text) AS segment,
    (p.ai_analysis ->> 'delai_contact'::text) AS delai_contact,
    (p.ai_analysis ->> 'dernier_interlocuteur'::text) AS dernier_interlocuteur,
    (p.ai_analysis ->> 'historique_resume'::text) AS historique_resume,
    (p.ai_analysis ->> 'comportement_detecte'::text) AS comportement_detecte,
    (p.ai_analysis -> 'objections_probables'::text) AS objections_probables,
    (p.ai_analysis ->> 'recommandation'::text) AS recommandation,
    (p.ai_analysis ->> 'notes_importantes'::text) AS notes_importantes,
    ps.metadata,
    CASE
        WHEN (ps.status = 'callback'::text) THEN 'CALLBACK'::text
        WHEN (ps.status = 'active'::text) THEN 'ACTIVE'::text
        ELSE 'OTHER'::text
    END AS call_type,
    CASE
        WHEN (ps.current_attempt >= ps.max_attempts) THEN true
        ELSE false
    END AS exceeded_max_attempts
FROM (agent_arthur_prospect_sequences ps
    JOIN agent_arthur_prospects p ON ((p.id = ps.prospect_id)))
WHERE ((ps.deployment_id = '23494c03-63bb-4fea-a9be-ef6d92ccb292'::uuid) AND (ps.status = ANY (ARRAY['active'::text, 'callback'::text])) AND (ps.next_action_at IS NOT NULL) AND (ps.next_action_at <= now()))
ORDER BY
    CASE
        WHEN (ps.status = 'callback'::text) THEN 1
        WHEN (ps.status = 'active'::text) THEN 2
        ELSE 3
    END, ps.next_action_at
LIMIT 1;

GRANT SELECT ON v_arthur_next_call_exoticdesign TO authenticated;
GRANT SELECT ON v_arthur_next_call_exoticdesign TO anon;

COMMENT ON VIEW v_arthur_next_call_exoticdesign IS 'Prochain appel Arthur pour Exotic Design (SECURITY INVOKER)';

-- ============================================
-- 1.16 v_prospects_attempts_exceeded
-- ============================================
DROP VIEW IF EXISTS v_prospects_attempts_exceeded CASCADE;

CREATE VIEW v_prospects_attempts_exceeded WITH (security_invoker = true) AS
SELECT p.id AS prospect_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone_number,
    p.company_name,
    p.status AS prospect_status,
    p.external_deal_id,
    p.external_source,
    p.client_slug,
    p.deployment_id,
    s.id AS sequence_id,
    s.sequence_number,
    s.current_attempt,
    s.max_attempts,
    (s.current_attempt - s.max_attempts) AS attempts_overflow,
    s.status AS sequence_status,
    s.outcome AS sequence_outcome,
    s.next_action_at,
    s.started_at AS sequence_started_at,
    s.paused_at AS sequence_paused_at,
    p.ai_analysis,
    s.metadata AS sequence_metadata,
    p.created_at AS prospect_created_at,
    p.updated_at AS prospect_updated_at,
    s.created_at AS sequence_created_at,
    s.updated_at AS sequence_updated_at
FROM (agent_arthur_prospects p
    JOIN agent_arthur_prospect_sequences s ON ((p.id = s.prospect_id)))
WHERE ((s.current_attempt > s.max_attempts) AND (s.status <> 'failed'::text) AND (p.status <> ALL (ARRAY['lost'::text, 'failed'::text])))
ORDER BY (s.current_attempt - s.max_attempts) DESC, s.updated_at DESC;

GRANT SELECT ON v_prospects_attempts_exceeded TO authenticated;
GRANT SELECT ON v_prospects_attempts_exceeded TO anon;

COMMENT ON VIEW v_prospects_attempts_exceeded IS 'Prospects ayant dépassé le nombre max de tentatives (SECURITY INVOKER)';

-- ============================================
-- SECTION 2: ADD RLS POLICIES TO ARTHUR TABLES
-- ============================================

-- Fix: Add RLS policies to agent_arthur_prospects and agent_arthur_prospect_sequences
-- Impact: These tables currently have RLS enabled but NO policies → blocking ALL access
-- Risk: LOW (standard pattern used on other tables)

-- ============================================
-- 2.1 agent_arthur_prospects - RLS Policies
-- ============================================

-- Policy 1: Admins see all prospects
DROP POLICY IF EXISTS admin_see_all_prospects ON agent_arthur_prospects;
CREATE POLICY admin_see_all_prospects ON agent_arthur_prospects
  FOR SELECT
  USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

-- Policy 2: Admins manage all prospects
DROP POLICY IF EXISTS admin_manage_all_prospects ON agent_arthur_prospects;
CREATE POLICY admin_manage_all_prospects ON agent_arthur_prospects
  FOR ALL
  USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

-- Policy 3: Clients see own prospects
DROP POLICY IF EXISTS client_see_own_prospects ON agent_arthur_prospects;
CREATE POLICY client_see_own_prospects ON agent_arthur_prospects
  FOR SELECT
  USING (
    deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    )
  );

-- Policy 4: Clients manage own prospects
DROP POLICY IF EXISTS client_manage_own_prospects ON agent_arthur_prospects;
CREATE POLICY client_manage_own_prospects ON agent_arthur_prospects
  FOR ALL
  USING (
    deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    )
  );

COMMENT ON TABLE agent_arthur_prospects IS 'Prospects pour agent Arthur avec RLS (4 policies)';

-- ============================================
-- 2.2 agent_arthur_prospect_sequences - RLS Policies
-- ============================================

-- Policy 1: Admins see all sequences
DROP POLICY IF EXISTS admin_see_all_sequences ON agent_arthur_prospect_sequences;
CREATE POLICY admin_see_all_sequences ON agent_arthur_prospect_sequences
  FOR SELECT
  USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

-- Policy 2: Admins manage all sequences
DROP POLICY IF EXISTS admin_manage_all_sequences ON agent_arthur_prospect_sequences;
CREATE POLICY admin_manage_all_sequences ON agent_arthur_prospect_sequences
  FOR ALL
  USING (((SELECT auth.jwt()) ->> 'role'::text) = 'admin'::text);

-- Policy 3: Clients see own sequences
DROP POLICY IF EXISTS client_see_own_sequences ON agent_arthur_prospect_sequences;
CREATE POLICY client_see_own_sequences ON agent_arthur_prospect_sequences
  FOR SELECT
  USING (
    deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    )
  );

-- Policy 4: Clients manage own sequences
DROP POLICY IF EXISTS client_manage_own_sequences ON agent_arthur_prospect_sequences;
CREATE POLICY client_manage_own_sequences ON agent_arthur_prospect_sequences
  FOR ALL
  USING (
    deployment_id IN (
      SELECT id FROM agent_deployments
      WHERE client_id = (((SELECT auth.jwt()) ->> 'client_id'::text))::uuid
    )
  );

COMMENT ON TABLE agent_arthur_prospect_sequences IS 'Séquences de prospection Arthur avec RLS (4 policies)';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Run these queries to verify the migration succeeded

-- Verify all 16 views were created successfully
SELECT COUNT(*) AS views_created
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN (
    'v_user_accessible_clients', 'v_user_accessible_agents',
    'v_agent_calls_enriched', 'v_arthur_calls_enriched',
    'v_louis_agent_performance', 'v_global_kpis',
    'v_global_outcome_distribution', 'v_global_call_volume_by_day',
    'v_global_agent_type_performance', 'v_global_top_clients',
    'v_arthur_next_calls', 'v_arthur_next_calls_global',
    'v_arthur_next_call_norloc', 'v_arthur_next_call_stefanodesign',
    'v_arthur_next_call_exoticdesign', 'v_prospects_attempts_exceeded'
  );
-- Expected: 16

-- Verify RLS policies were created (4 policies per table = 8 total)
SELECT COUNT(*) AS policies_created
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('agent_arthur_prospects', 'agent_arthur_prospect_sequences');
-- Expected: 8

-- Verify views return data (should not error)
SELECT COUNT(*) FROM v_user_accessible_clients;
SELECT COUNT(*) FROM v_agent_calls_enriched;
SELECT COUNT(*) FROM v_global_kpis;

-- Verify Arthur tables are now accessible (should return data, not error)
SELECT COUNT(*) FROM agent_arthur_prospects;
SELECT COUNT(*) FROM agent_arthur_prospect_sequences;

COMMIT;

-- ============================================
-- POST-MIGRATION ACTIONS
-- ============================================

-- 1. Run VACUUM ANALYZE to update statistics
-- VACUUM ANALYZE;

-- 2. Check Supabase Advisors again (should show 0 CRITICAL errors)
-- Via Supabase Dashboard → Database → Advisors

-- 3. Test dashboard functionality
-- - Dashboard Louis should display correctly
-- - Dashboard Arthur should display correctly
-- - Global dashboard should display correctly

-- ============================================
-- ROLLBACK PROCEDURE (if needed)
-- ============================================

-- To rollback this migration, you need to:
-- 1. Revert views to SECURITY DEFINER (change SECURITY INVOKER to SECURITY DEFINER)
-- 2. Drop the 8 RLS policies created in section 2

-- Example:
-- CREATE OR REPLACE VIEW v_user_accessible_clients SECURITY DEFINER AS ...
-- DROP POLICY admin_see_all_prospects ON agent_arthur_prospects;
-- etc.

-- ============================================
-- END OF MIGRATION 01_security_fixes.sql
-- ============================================
