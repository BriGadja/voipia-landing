-- ============================================================================
-- MIGRATION COMPLÈTE : Enrichissement agent_calls avec données Dipler
-- Date: 2025-11-13
-- Auteur: Claude (analyse + complétion du script original)
--
-- Ce script fait :
-- 1. Drop des fonctions RPC dépendantes
-- 2. Drop des vues dépendantes
-- 3. Renommage cost → total_cost + ajout colonnes analytics
-- 4. Recréation des vues avec nouveau nom de colonne
-- 5. Recréation des fonctions RPC avec nouveau nom de colonne
-- 6. Ajout des index pour performance
--
-- ⚠️ IMPORTANT : Tout est dans une transaction = rollback auto si erreur
-- ============================================================================

BEGIN;

-- ============================================================================
-- ÉTAPE 1 : Drop des fonctions RPC dépendantes (CRITIQUE - MANQUAIT !)
-- ============================================================================

DROP FUNCTION IF EXISTS get_kpi_metrics(date, date, uuid, uuid, text) CASCADE;
DROP FUNCTION IF EXISTS get_chart_data(date, date, uuid, uuid, text) CASCADE;
DROP FUNCTION IF EXISTS get_global_kpis(timestamp with time zone, timestamp with time zone, uuid, uuid, text) CASCADE;
DROP FUNCTION IF EXISTS get_global_chart_data(timestamp with time zone, timestamp with time zone, uuid, uuid, text) CASCADE;
DROP FUNCTION IF EXISTS get_arthur_kpi_metrics(timestamp with time zone, timestamp with time zone, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS get_agent_cards_data(date, date, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS get_agent_type_cards_data(date, date, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS get_client_cards_data(date, date) CASCADE;

-- ============================================================================
-- ÉTAPE 2 : Drop des vues dépendantes (dans l'ordre des dépendances)
-- ============================================================================

DROP VIEW IF EXISTS v_agent_calls_enriched CASCADE;
DROP VIEW IF EXISTS v_global_kpis CASCADE;
DROP VIEW IF EXISTS v_arthur_calls_enriched CASCADE;
DROP VIEW IF EXISTS v_global_call_volume_by_day CASCADE;
DROP VIEW IF EXISTS v_global_outcome_distribution CASCADE;
DROP VIEW IF EXISTS v_global_agent_type_performance CASCADE;
DROP VIEW IF EXISTS v_global_top_clients CASCADE;
DROP VIEW IF EXISTS v_louis_agent_performance CASCADE;
DROP VIEW IF EXISTS v_user_accessible_agents CASCADE;
DROP VIEW IF EXISTS v_arthur_next_calls_global CASCADE;

-- ============================================================================
-- ÉTAPE 3 : Modification de la table agent_calls
-- ============================================================================

-- 3.1 Renommer la colonne existante
ALTER TABLE agent_calls RENAME COLUMN cost TO total_cost;

-- 3.2 Ajouter identifiants externes
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS conversation_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS call_sid TEXT;

-- 3.3 Ajouter breakdown financier
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS stt_cost NUMERIC(10, 6),
  ADD COLUMN IF NOT EXISTS tts_cost NUMERIC(10, 6),
  ADD COLUMN IF NOT EXISTS llm_cost NUMERIC(10, 6),
  ADD COLUMN IF NOT EXISTS telecom_cost NUMERIC(10, 6),
  ADD COLUMN IF NOT EXISTS dipler_commission NUMERIC(10, 6),
  ADD COLUMN IF NOT EXISTS cost_per_minute NUMERIC(10, 6);

-- 3.4 Ajouter qualité & classification
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS call_classification TEXT,
  ADD COLUMN IF NOT EXISTS call_quality_score INTEGER CHECK (call_quality_score BETWEEN 1 AND 10),
  ADD COLUMN IF NOT EXISTS sentiment_analysis TEXT CHECK (sentiment_analysis IN ('positive', 'neutral', 'negative'));

-- 3.5 Ajouter stack technique
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS llm_model TEXT,
  ADD COLUMN IF NOT EXISTS tts_provider TEXT,
  ADD COLUMN IF NOT EXISTS tts_voice_id TEXT,
  ADD COLUMN IF NOT EXISTS stt_provider TEXT;

-- 3.6 Ajouter contexte téléphonie
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS direction TEXT CHECK (direction IN ('inbound', 'outbound')),
  ADD COLUMN IF NOT EXISTS call_status TEXT,
  ADD COLUMN IF NOT EXISTS provider TEXT DEFAULT 'twilio';

-- 3.7 Commentaires
COMMENT ON COLUMN agent_calls.conversation_id IS 'ID unique de conversation Dipler (ex: 01K9Y3RDPR2DHFQQS9SC4XA0TM)';
COMMENT ON COLUMN agent_calls.call_sid IS 'Twilio Call SID (ex: CA83f4c6960b6bb71c6ac80df45ff59a44)';
COMMENT ON COLUMN agent_calls.total_cost IS 'Coût total de l''appel incluant STT+TTS+LLM+telecom+commission';
COMMENT ON COLUMN agent_calls.call_classification IS 'Classification post-appel (callback_requested, appointment_set, not_interested, etc.)';
COMMENT ON COLUMN agent_calls.call_quality_score IS 'Score de qualité de l''appel (1-10) généré par l''analyse post-conversation';
COMMENT ON COLUMN agent_calls.sentiment_analysis IS 'Sentiment détecté dans la conversation (positive, neutral, negative)';

-- ============================================================================
-- ÉTAPE 4 : Recréation des vues avec nouvelle nomenclature
-- ============================================================================

-- 4.1 v_agent_calls_enriched
CREATE VIEW v_agent_calls_enriched AS
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
  call_classification,
  call_quality_score,
  sentiment_analysis,
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

-- 4.2 v_user_accessible_agents
CREATE VIEW v_user_accessible_agents AS
SELECT
  ad.id AS deployment_id,
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
  MAX(ac.started_at) AS last_call_at,
  COUNT(ac.id) AS total_calls_last_30d
FROM agent_deployments ad
JOIN clients c ON ad.client_id = c.id
JOIN user_client_permissions ucp ON c.id = ucp.client_id
JOIN agent_types at ON ad.agent_type_id = at.id
LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
  AND ac.started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
  ad.id, ad.name, ad.slug, ad.client_id, c.name,
  ad.agent_type_id, at.name, at.display_name, ad.status,
  ucp.user_id, ucp.permission_level
ORDER BY c.name, at.display_name, ad.name;

-- 4.3 v_global_kpis
CREATE VIEW v_global_kpis AS
WITH date_params AS (
  SELECT
    CURRENT_DATE - INTERVAL '30 days' AS current_start,
    CURRENT_DATE AS current_end,
    CURRENT_DATE - INTERVAL '60 days' AS previous_start,
    CURRENT_DATE - INTERVAL '30 days' AS previous_end
),
current_period AS (
  SELECT
    COUNT(*) AS total_calls,
    COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
    COUNT(*) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments_scheduled,
    COALESCE(SUM(ac.total_cost), 0) AS total_cost,
    COALESCE(AVG(ac.duration_seconds), 0) AS avg_duration,
    COUNT(DISTINCT ac.deployment_id) AS active_agents,
    COUNT(DISTINCT ac.deployment_id) FILTER (WHERE ac.started_at >= CURRENT_DATE) AS agents_called_today
  FROM agent_calls ac
  CROSS JOIN date_params
  WHERE ac.started_at >= date_params.current_start
    AND ac.started_at <= date_params.current_end
),
previous_period AS (
  SELECT
    COUNT(*) AS total_calls,
    COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
    COUNT(*) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments_scheduled,
    COALESCE(SUM(ac.total_cost), 0) AS total_cost,
    COALESCE(AVG(ac.duration_seconds), 0) AS avg_duration
  FROM agent_calls ac
  CROSS JOIN date_params
  WHERE ac.started_at >= date_params.previous_start
    AND ac.started_at < date_params.previous_end
)
SELECT
  jsonb_build_object(
    'total_calls', cp.total_calls,
    'answered_calls', cp.answered_calls,
    'appointments_scheduled', cp.appointments_scheduled,
    'answer_rate', CASE WHEN cp.total_calls > 0 THEN ROUND((cp.answered_calls::numeric / cp.total_calls::numeric) * 100, 2) ELSE 0 END,
    'conversion_rate', CASE WHEN cp.answered_calls > 0 THEN ROUND((cp.appointments_scheduled::numeric / cp.answered_calls::numeric) * 100, 2) ELSE 0 END,
    'avg_duration', ROUND(cp.avg_duration, 0),
    'total_cost', ROUND(cp.total_cost, 2),
    'cost_per_appointment', CASE WHEN cp.appointments_scheduled > 0 THEN ROUND(cp.total_cost / cp.appointments_scheduled::numeric, 2) ELSE 0 END,
    'active_agents', cp.active_agents,
    'agents_called_today', cp.agents_called_today
  ) AS current_period,
  jsonb_build_object(
    'total_calls', pp.total_calls,
    'answered_calls', pp.answered_calls,
    'appointments_scheduled', pp.appointments_scheduled,
    'answer_rate', CASE WHEN pp.total_calls > 0 THEN ROUND((pp.answered_calls::numeric / pp.total_calls::numeric) * 100, 2) ELSE 0 END,
    'conversion_rate', CASE WHEN pp.answered_calls > 0 THEN ROUND((pp.appointments_scheduled::numeric / pp.answered_calls::numeric) * 100, 2) ELSE 0 END,
    'avg_duration', ROUND(pp.avg_duration, 0),
    'total_cost', ROUND(pp.total_cost, 2),
    'cost_per_appointment', CASE WHEN pp.appointments_scheduled > 0 THEN ROUND(pp.total_cost / pp.appointments_scheduled::numeric, 2) ELSE 0 END
  ) AS previous_period
FROM current_period cp
CROSS JOIN previous_period pp;

-- 4.4 v_arthur_calls_enriched
CREATE VIEW v_arthur_calls_enriched AS
SELECT
  ac.id AS call_id,
  ac.started_at,
  ac.ended_at,
  ac.duration_seconds,
  ac.total_cost,
  ac.outcome != 'voicemail' AS answered,
  ac.outcome AS call_outcome,
  (ac.metadata->>'appointment_scheduled_at')::timestamptz AS appointment_scheduled_at,
  ac.recording_url AS call_recording_url,
  ac.transcript,
  aap.id AS prospect_id,
  aap.first_name,
  aap.last_name,
  aap.email,
  aap.phone_number AS phone,
  aap.company_name AS company,
  aap.external_source,
  aap.external_deal_id,
  aap.status AS prospect_status,
  aap.ai_analysis,
  aaps.id AS sequence_id,
  aaps.sequence_number,
  aaps.current_attempt,
  aaps.max_attempts,
  aaps.status AS sequence_status,
  aaps.outcome AS sequence_outcome,
  aaps.next_action_at,
  ad.id AS agent_deployment_id,
  ad.agent_type_id,
  ad.client_id,
  at.display_name AS agent_name,
  c.name AS client_name,
  CASE
    WHEN ac.metadata->>'appointment_scheduled_at' IS NOT NULL THEN 'converted'
    WHEN ac.outcome = 'callback_requested' THEN 'callback'
    WHEN ac.outcome = 'not_interested' THEN 'lost'
    WHEN ac.outcome = 'do_not_call' THEN 'blacklisted'
    ELSE 'in_progress'
  END AS derived_status,
  'Tentative ' || aaps.current_attempt AS attempt_label,
  aap.ai_analysis->>'segment' AS ai_segment,
  aap.ai_analysis->>'score' AS ai_score,
  aap.ai_analysis->>'reason' AS ai_reason
FROM agent_calls ac
JOIN agent_arthur_prospects aap ON ac.prospect_id = aap.id
LEFT JOIN agent_arthur_prospect_sequences aaps ON aap.id = aaps.prospect_id
LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
LEFT JOIN agent_types at ON ad.agent_type_id = at.id
LEFT JOIN clients c ON ad.client_id = c.id
WHERE at.name = 'arthur';

-- 4.5 v_global_call_volume_by_day
CREATE VIEW v_global_call_volume_by_day AS
SELECT
  DATE(ac.started_at) AS date,
  COUNT(*) AS total_calls,
  COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
  COUNT(*) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments,
  COUNT(*) FILTER (WHERE ac.outcome = 'voicemail') AS voicemail_calls,
  ROUND(SUM(ac.total_cost), 2) AS total_cost,
  ROUND(AVG(ac.duration_seconds), 0) AS avg_duration,
  COUNT(*) FILTER (WHERE at.name = 'louis') AS louis_calls,
  COUNT(*) FILTER (WHERE at.name = 'arthur') AS arthur_calls,
  COUNT(*) FILTER (WHERE at.name NOT IN ('louis', 'arthur')) AS other_calls
FROM agent_calls ac
LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
LEFT JOIN agent_types at ON ad.agent_type_id = at.id
WHERE ac.started_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(ac.started_at)
ORDER BY DATE(ac.started_at) DESC;

-- 4.6 v_global_outcome_distribution
CREATE VIEW v_global_outcome_distribution AS
SELECT
  COALESCE(outcome, 'unknown') AS outcome,
  COUNT(*) AS count,
  ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage,
  ROUND(SUM(total_cost), 2) AS total_cost,
  ROUND(AVG(duration_seconds), 0) AS avg_duration
FROM agent_calls ac
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY outcome
ORDER BY COUNT(*) DESC;

-- 4.7 v_global_agent_type_performance
CREATE VIEW v_global_agent_type_performance AS
SELECT
  at.name AS agent_type,
  at.display_name,
  COUNT(DISTINCT ad.id) AS total_deployments,
  COUNT(DISTINCT ad.client_id) AS total_clients,
  COUNT(ac.id) AS total_calls,
  COUNT(ac.id) FILTER (WHERE ac.started_at >= CURRENT_DATE - INTERVAL '7 days') AS calls_last_7d,
  COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
  COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments,
  ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy'))::numeric / NULLIF(COUNT(ac.id), 0)::numeric) * 100, 2) AS answer_rate,
  ROUND((COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL)::numeric / NULLIF(COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')), 0)::numeric) * 100, 2) AS conversion_rate,
  ROUND(AVG(ac.duration_seconds), 0) AS avg_duration,
  ROUND(SUM(ac.total_cost), 2) AS total_cost,
  ROUND(SUM(ac.total_cost) / NULLIF(COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL), 0)::numeric, 2) AS cost_per_appointment
FROM agent_types at
LEFT JOIN agent_deployments ad ON at.id = ad.agent_type_id AND ad.status = 'active'
LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id AND ac.started_at >= CURRENT_DATE - INTERVAL '30 days'
WHERE at.status = 'active'
GROUP BY at.id, at.name, at.display_name
ORDER BY COUNT(ac.id) DESC;

-- 4.8 v_global_top_clients
CREATE VIEW v_global_top_clients AS
SELECT
  c.id AS client_id,
  c.name AS client_name,
  c.industry,
  COUNT(DISTINCT ad.id) AS total_agents,
  COUNT(ac.id) AS total_calls,
  COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
  COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments,
  ROUND((COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL)::numeric / NULLIF(COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')), 0)::numeric) * 100, 2) AS conversion_rate,
  ROUND(SUM(ac.total_cost), 2) AS total_cost,
  ROUND(SUM(ac.total_cost) / NULLIF(COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL), 0)::numeric, 2) AS cost_per_appointment,
  MAX(ac.started_at) AS last_call_at
FROM clients c
LEFT JOIN agent_deployments ad ON c.id = ad.client_id AND ad.status = 'active'
LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id AND ac.started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.id, c.name, c.industry
HAVING COUNT(ac.id) > 0
ORDER BY COUNT(ac.id) DESC
LIMIT 20;

-- 4.9 v_louis_agent_performance
CREATE VIEW v_louis_agent_performance AS
SELECT
  ad.id AS deployment_id,
  ad.name AS agent_name,
  ad.slug,
  c.id AS client_id,
  c.name AS client_name,
  COUNT(ac.id) AS total_calls,
  COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
  COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments,
  COUNT(ac.id) FILTER (WHERE ac.outcome = 'voicemail') AS voicemail_calls,
  ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy'))::numeric / NULLIF(COUNT(ac.id), 0)::numeric) * 100, 2) AS answer_rate,
  ROUND((COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL)::numeric / NULLIF(COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy')), 0)::numeric) * 100, 2) AS conversion_rate,
  ROUND(AVG(ac.duration_seconds), 0) AS avg_duration,
  ROUND(SUM(ac.total_cost), 2) AS total_cost,
  ROUND(SUM(ac.total_cost) / NULLIF(COUNT(ac.id) FILTER (WHERE ac.metadata->>'appointment_scheduled_at' IS NOT NULL), 0)::numeric, 2) AS cost_per_appointment,
  MAX(ac.started_at) AS last_call_at
FROM agent_deployments ad
JOIN agent_types at ON ad.agent_type_id = at.id
JOIN clients c ON ad.client_id = c.id
LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id AND ac.started_at >= CURRENT_DATE - INTERVAL '30 days'
WHERE at.name = 'louis' AND ad.status = 'active'
GROUP BY ad.id, ad.name, ad.slug, c.id, c.name
ORDER BY COUNT(ac.id) DESC;

-- 4.10 v_arthur_next_calls_global
CREATE VIEW v_arthur_next_calls_global AS
SELECT
  ps.id AS sequence_id,
  p.id AS prospect_id,
  p.external_deal_id,
  p.external_user_id,
  p.first_name,
  p.last_name,
  p.phone_number,
  p.email,
  p.company_name,
  p.status AS prospect_status,
  ps.status AS sequence_status,
  ps.deployment_id,
  ad.name AS agent_name,
  ad.slug AS agent_slug,
  c.name AS client_name,
  ps.current_attempt,
  ps.max_attempts,
  ps.next_action_at,
  p.ai_analysis->>'segment_detecte' AS segment,
  p.ai_analysis->>'approche_arthur' AS approche_recommandee,
  p.ai_analysis->'points_accroche' AS points_accroche,
  p.ai_analysis->>'delai_contact' AS delai_contact,
  CASE
    WHEN ps.status = 'callback' THEN 'CALLBACK'
    WHEN ps.status = 'active' THEN 'ACTIVE'
    ELSE 'OTHER'
  END AS call_type,
  CASE
    WHEN ps.current_attempt >= ps.max_attempts THEN true
    ELSE false
  END AS exceeded_max_attempts,
  CASE
    WHEN ps.next_action_at < NOW() THEN 'overdue'
    WHEN ps.next_action_at <= NOW() + INTERVAL '1 hour' THEN 'urgent'
    WHEN ps.next_action_at <= NOW() + INTERVAL '24 hours' THEN 'due_today'
    ELSE 'scheduled'
  END AS urgency_status,
  (
    SELECT jsonb_build_object(
      'call_id', lac.id,
      'started_at', lac.started_at,
      'duration', lac.duration_seconds,
      'outcome', lac.outcome,
      'answered', lac.outcome NOT IN ('voicemail', 'no_answer', 'busy')
    )
    FROM agent_calls lac
    WHERE lac.prospect_id = p.id
    ORDER BY lac.started_at DESC
    LIMIT 1
  ) AS last_call_info
FROM agent_arthur_prospect_sequences ps
JOIN agent_arthur_prospects p ON ps.prospect_id = p.id
JOIN agent_deployments ad ON ps.deployment_id = ad.id
JOIN clients c ON ad.client_id = c.id
WHERE ps.status IN ('active', 'callback')
  AND ps.next_action_at IS NOT NULL
  AND ps.next_action_at <= NOW() + INTERVAL '7 days'
  AND ps.current_attempt < ps.max_attempts
ORDER BY
  CASE
    WHEN ps.status = 'callback' THEN 1
    WHEN ps.status = 'active' THEN 2
    ELSE 3
  END,
  ps.next_action_at;

-- ============================================================================
-- ÉTAPE 5 : Recréation des fonctions RPC (MANQUAIT DANS LE SCRIPT ORIGINAL!)
-- ============================================================================

-- 5.1 get_kpi_metrics (utilise v_agent_calls_enriched.total_cost via la vue)
CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_current_period JSON;
  v_previous_period JSON;
  v_period_days INTEGER;
BEGIN
  -- Calculate period length for comparison
  v_period_days := p_end_date - p_start_date + 1;

  -- ============================================================================
  -- CURRENT PERIOD METRICS
  -- ============================================================================
  WITH current_calls AS (
    SELECT
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments_scheduled,
      COUNT(*) FILTER (WHERE outcome = 'RDV REFUSÉ') AS refused_appointments,
      COUNT(*) FILTER (WHERE outcome = 'CALLBACK' OR metadata ? 'callback_requested') AS callbacks_requested,
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,
      SUM(total_cost) AS total_cost
    FROM v_agent_calls_enriched ac
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      -- Filter by client if provided
      AND (p_client_id IS NULL OR ac.deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      -- Filter by specific deployment if provided
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      -- CRITICAL: Filter by agent type (louis, arthur, etc.)
      AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
        SELECT ad.id
        FROM agent_deployments ad
        INNER JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE at.name = p_agent_type_name
      ))
  )
  SELECT json_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'appointments_scheduled', COALESCE(appointments_scheduled, 0),
    'refused_appointments', COALESCE(refused_appointments, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),

    -- Answer rate = (answered_calls / total_calls) * 100
    'answer_rate', CASE
      WHEN total_calls > 0 THEN ROUND((answered_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,

    -- Conversion rate = (appointments_scheduled / answered_calls) * 100
    'conversion_rate', CASE
      WHEN answered_calls > 0 THEN ROUND((appointments_scheduled::NUMERIC / answered_calls * 100), 1)
      ELSE 0
    END,

    -- Acceptance rate = appointments / (appointments + refused) * 100
    'acceptance_rate', CASE
      WHEN (appointments_scheduled + refused_appointments) > 0
        THEN ROUND((appointments_scheduled::NUMERIC / (appointments_scheduled + refused_appointments) * 100), 1)
      ELSE 0
    END,

    -- Average duration (only for calls with duration > 0)
    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,

    -- Financial metrics
    'total_cost', COALESCE(total_cost, 0),
    'cost_per_appointment', CASE
      WHEN appointments_scheduled > 0 THEN ROUND(total_cost / appointments_scheduled, 2)
      ELSE 0
    END
  )
  INTO v_current_period
  FROM current_calls;

  -- ============================================================================
  -- PREVIOUS PERIOD METRICS (for comparison)
  -- ============================================================================
  WITH previous_calls AS (
    SELECT
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments_scheduled,
      COUNT(*) FILTER (WHERE outcome = 'RDV REFUSÉ') AS refused_appointments,
      COUNT(*) FILTER (WHERE outcome = 'CALLBACK' OR metadata ? 'callback_requested') AS callbacks_requested,
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,
      SUM(total_cost) AS total_cost
    FROM v_agent_calls_enriched ac
    WHERE ac.started_at >= (p_start_date - v_period_days * INTERVAL '1 day')
      AND ac.started_at < p_start_date
      AND (p_client_id IS NULL OR ac.deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
        SELECT ad.id
        FROM agent_deployments ad
        INNER JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE at.name = p_agent_type_name
      ))
  )
  SELECT json_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'appointments_scheduled', COALESCE(appointments_scheduled, 0),
    'refused_appointments', COALESCE(refused_appointments, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),

    'answer_rate', CASE
      WHEN total_calls > 0 THEN ROUND((answered_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,

    'conversion_rate', CASE
      WHEN answered_calls > 0 THEN ROUND((appointments_scheduled::NUMERIC / answered_calls * 100), 1)
      ELSE 0
    END,

    'acceptance_rate', CASE
      WHEN (appointments_scheduled + refused_appointments) > 0
        THEN ROUND((appointments_scheduled::NUMERIC / (appointments_scheduled + refused_appointments) * 100), 1)
      ELSE 0
    END,

    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,

    'total_cost', COALESCE(total_cost, 0),
    'cost_per_appointment', CASE
      WHEN appointments_scheduled > 0 THEN ROUND(total_cost / appointments_scheduled, 2)
      ELSE 0
    END
  )
  INTO v_previous_period
  FROM previous_calls;

  -- Return combined result
  RETURN json_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

-- 5.2 get_chart_data (utilise v_agent_calls_enriched.total_cost via la vue)
CREATE OR REPLACE FUNCTION get_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  DECLARE
    v_result JSON;
  BEGIN
    WITH
    -- Call volume by day
    call_volume AS (
      SELECT json_agg(
        json_build_object(
          'date', call_date::TEXT,
          'total_calls', total_calls,
          'answered_calls', answered_calls,
          'appointments', appointments
        ) ORDER BY call_date
      ) AS data
      FROM (
        SELECT
          DATE(ac.started_at) AS call_date,
          COUNT(*) AS total_calls,
          COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
          COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments
        FROM v_agent_calls_enriched ac
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date + INTERVAL '1 day'
          AND (p_client_id IS NULL OR ac.deployment_id IN (
            SELECT id FROM agent_deployments WHERE client_id = p_client_id
          ))
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
            SELECT ad.id
            FROM agent_deployments ad
            INNER JOIN agent_types at ON ad.agent_type_id = at.id
            WHERE at.name = p_agent_type_name
          ))
        GROUP BY DATE(ac.started_at)
        ORDER BY DATE(ac.started_at)
      ) daily_stats
    ),

    -- Outcome distribution
    outcome_dist AS (
      SELECT json_agg(
        json_build_object(
          'outcome', outcome,
          'count', count
        ) ORDER BY count DESC
      ) AS data
      FROM (
        SELECT
          ac.outcome,
          COUNT(*) AS count
        FROM v_agent_calls_enriched ac
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date + INTERVAL '1 day'
          AND (p_client_id IS NULL OR ac.deployment_id IN (
            SELECT id FROM agent_deployments WHERE client_id = p_client_id
          ))
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
            SELECT ad.id
            FROM agent_deployments ad
            INNER JOIN agent_types at ON ad.agent_type_id = at.id
            WHERE at.name = p_agent_type_name
          ))
          AND ac.outcome IS NOT NULL
        GROUP BY ac.outcome
        HAVING COUNT(*) > 0
      ) outcomes
    ),

    -- Emotion distribution (MODIFIED: exclude unanswered calls)
    emotion_dist AS (
      SELECT json_agg(
        json_build_object(
          'emotion', emotion,
          'count', count
        ) ORDER BY count DESC
      ) AS data
      FROM (
        SELECT
          COALESCE(ac.emotion, 'unknown') AS emotion,
          COUNT(*) AS count
        FROM v_agent_calls_enriched ac
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date + INTERVAL '1 day'
          AND (p_client_id IS NULL OR ac.deployment_id IN (
            SELECT id FROM agent_deployments WHERE client_id = p_client_id
          ))
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
            SELECT ad.id
            FROM agent_deployments ad
            INNER JOIN agent_types at ON ad.agent_type_id = at.id
            WHERE at.name = p_agent_type_name
          ))
          AND ac.answered = true  -- ⬅️ NOUVEAU: Exclut les appels non répondus
        GROUP BY emotion
        HAVING COUNT(*) > 0
      ) emotions
    ),

    -- Voicemail rate by agent (only show agents of the specified type)
    voicemail_by_agent AS (
      SELECT json_agg(
        json_build_object(
          'agent', agent_name,
          'rate', voicemail_rate
        ) ORDER BY voicemail_rate DESC
      ) AS data
      FROM (
        SELECT
          ad.name AS agent_name,
          ROUND(
            (COUNT(*) FILTER (WHERE ac.outcome = 'voicemail')::NUMERIC /
             NULLIF(COUNT(*), 0) * 100),
            1
          ) AS voicemail_rate
        FROM agent_deployments ad
        INNER JOIN agent_types at ON ad.agent_type_id = at.id
        LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
          AND ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date + INTERVAL '1 day'
        WHERE (p_client_id IS NULL OR ad.client_id = p_client_id)
          AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
          AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
        GROUP BY ad.id, ad.name
        HAVING COUNT(*) > 0
      ) agent_stats
    )

    SELECT json_build_object(
      'call_volume_by_day', COALESCE((SELECT data FROM call_volume), '[]'::json),
      'outcome_distribution', COALESCE((SELECT data FROM outcome_dist), '[]'::json),
      'emotion_distribution', COALESCE((SELECT data FROM emotion_dist), '[]'::json),
      'voicemail_by_agent', COALESCE((SELECT data FROM voicemail_by_agent), '[]'::json)
    )
    INTO v_result;

    RETURN v_result;
  END;
$$;

-- 5.3 get_global_kpis (utilise ac.total_cost directement)
CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_duration INTERVAL;
BEGIN
  -- Calculer durée période pour comparaison
  v_period_duration := p_end_date - p_start_date;

  -- Période courante
  SELECT JSONB_BUILD_OBJECT(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy')),
    'appointments_scheduled', COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy'))::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy')) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL)::NUMERIC /
                  COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy'))::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(duration_seconds), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL) > 0
      THEN ROUND(COALESCE(SUM(total_cost), 0) / COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL), 2)
      ELSE 0
    END
  ) INTO v_current_period
  FROM agent_calls ac
  LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= p_start_date
    AND ac.started_at <= p_end_date
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name);

  -- Période précédente
  SELECT JSONB_BUILD_OBJECT(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy')),
    'appointments_scheduled', COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy'))::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy')) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL)::NUMERIC /
                  COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy'))::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(duration_seconds), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL) > 0
      THEN ROUND(COALESCE(SUM(total_cost), 0) / COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL), 2)
      ELSE 0
    END
  ) INTO v_previous_period
  FROM agent_calls ac
  LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= (p_start_date - v_period_duration)
    AND ac.started_at < p_start_date
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name);

  RETURN JSONB_BUILD_OBJECT(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

-- 5.4 get_global_chart_data (utilise ac.total_cost directement)
CREATE OR REPLACE FUNCTION get_global_chart_data(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
BEGIN
  -- Volume par jour
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'date', date,
      'total_calls', total_calls,
      'answered_calls', answered_calls,
      'appointments', appointments
    ) ORDER BY date
  ) INTO v_call_volume
  FROM (
    SELECT
      DATE(ac.started_at) AS date,
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy')) AS answered_calls,
      COUNT(*) FILTER (WHERE metadata->>'appointment_scheduled_at' IS NOT NULL) AS appointments
    FROM agent_calls ac
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY DATE(ac.started_at)
  ) sub;

  -- Distribution outcomes
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'outcome', outcome,
      'count', count,
      'percentage', percentage
    ) ORDER BY count DESC
  ) INTO v_outcome_distribution
  FROM (
    SELECT
      COALESCE(ac.outcome, 'unknown') AS outcome,
      COUNT(*) AS count,
      ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage
    FROM agent_calls ac
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY ac.outcome
  ) sub;

  -- Distribution émotions
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'emotion', emotion,
      'count', count,
      'percentage', percentage
    ) ORDER BY count DESC
  ) INTO v_emotion_distribution
  FROM (
    SELECT
      COALESCE(ac.emotion, 'unknown') AS emotion,
      COUNT(*) AS count,
      ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage
    FROM agent_calls ac
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ac.emotion IS NOT NULL
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY ac.emotion
  ) sub;

  RETURN JSONB_BUILD_OBJECT(
    'call_volume_by_day', COALESCE(v_call_volume, '[]'::JSONB),
    'outcome_distribution', COALESCE(v_outcome_distribution, '[]'::JSONB),
    'emotion_distribution', COALESCE(v_emotion_distribution, '[]'::JSONB)
  );
END;
$$;

-- 5.5 get_arthur_kpi_metrics (utilise total_cost via v_arthur_calls_enriched)
CREATE OR REPLACE FUNCTION get_arthur_kpi_metrics(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_id UUID DEFAULT NULL
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
  -- Calculate period length in days
  v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

  WITH current_period AS (
    SELECT
      COUNT(DISTINCT prospect_id) AS total_prospects,
      COUNT(DISTINCT CASE WHEN derived_status = 'converted' THEN prospect_id END) AS conversions,
      COUNT(DISTINCT call_id) AS total_calls,
      COUNT(DISTINCT CASE WHEN answered = true THEN call_id END) AS answered_calls,
      COUNT(DISTINCT CASE WHEN appointment_scheduled_at IS NOT NULL THEN call_id END) AS appointments_scheduled,
      COALESCE(SUM(total_cost), 0) AS total_cost,
      COALESCE(AVG(duration_seconds), 0) AS avg_duration,
      COALESCE(
        AVG(
          CASE
            WHEN current_attempt = 1 AND answered = true THEN 1
            WHEN current_attempt = 1 THEN 0
            ELSE NULL
          END
        ),
        0
      ) AS answer_rate_attempt_1
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
  ),
  previous_period AS (
    SELECT
      COUNT(DISTINCT prospect_id) AS total_prospects,
      COUNT(DISTINCT CASE WHEN derived_status = 'converted' THEN prospect_id END) AS conversions,
      COUNT(DISTINCT call_id) AS total_calls,
      COUNT(DISTINCT CASE WHEN answered = true THEN call_id END) AS answered_calls,
      COUNT(DISTINCT CASE WHEN appointment_scheduled_at IS NOT NULL THEN call_id END) AS appointments_scheduled,
      COALESCE(SUM(total_cost), 0) AS total_cost,
      COALESCE(AVG(duration_seconds), 0) AS avg_duration,
      COALESCE(
        AVG(
          CASE
            WHEN current_attempt = 1 AND answered = true THEN 1
            WHEN current_attempt = 1 THEN 0
            ELSE NULL
          END
        ),
        0
      ) AS answer_rate_attempt_1
    FROM v_arthur_calls_enriched
    WHERE started_at >= (p_start_date - (v_period_days || ' days')::interval)
      AND started_at < p_start_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
  )
  SELECT jsonb_build_object(
    'current_period', jsonb_build_object(
      'reactivation_rate',
      CASE
        WHEN cp.total_prospects > 0
        THEN ROUND((cp.conversions::numeric / cp.total_prospects::numeric) * 100, 2)
        ELSE 0
      END,
      'cost_per_conversion',
      CASE
        WHEN cp.conversions > 0
        THEN ROUND(cp.total_cost / cp.conversions, 2)
        ELSE 0
      END,
      'avg_duration_per_attempt',
      ROUND(cp.avg_duration, 0),
      'appointments_scheduled',
      cp.appointments_scheduled,
      'answer_rate_attempt_1',
      ROUND(cp.answer_rate_attempt_1 * 100, 2)
    ),
    'previous_period', jsonb_build_object(
      'reactivation_rate',
      CASE
        WHEN pp.total_prospects > 0
        THEN ROUND((pp.conversions::numeric / pp.total_prospects::numeric) * 100, 2)
        ELSE 0
      END,
      'cost_per_conversion',
      CASE
        WHEN pp.conversions > 0
        THEN ROUND(pp.total_cost / pp.conversions, 2)
        ELSE 0
      END,
      'avg_duration_per_attempt',
      ROUND(pp.avg_duration, 0),
      'appointments_scheduled',
      pp.appointments_scheduled,
      'answer_rate_attempt_1',
      ROUND(pp.answer_rate_attempt_1 * 100, 2)
    )
  ) INTO v_result
  FROM current_period cp
  CROSS JOIN previous_period pp;

  RETURN v_result;
END;
$$;

-- 5.6 get_agent_cards_data (utilise ac.total_cost via v_agent_calls_enriched)
CREATE OR REPLACE FUNCTION get_agent_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE(
  deployment_id UUID,
  deployment_name TEXT,
  slug TEXT,
  agent_type_name TEXT,
  agent_display_name TEXT,
  client_name TEXT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments_scheduled BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  last_call_at TIMESTAMP WITH TIME ZONE,
  deployment_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH user_accessible_agents AS (
    -- Get agents accessible by the authenticated user via RLS
    SELECT DISTINCT a.deployment_id
    FROM v_user_accessible_agents a
    WHERE (p_client_ids IS NULL OR a.client_id = ANY(p_client_ids))
  ),
  agent_metrics AS (
    SELECT
      ad.id AS deployment_id,
      ad.name AS deployment_name,
      ad.slug,
      at.name AS agent_type_name,
      at.display_name AS agent_display_name,
      c.name AS client_name,
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.answered = true)::NUMERIC /
           NULLIF(COUNT(ac.id), 0) * 100),
          1
        ),
        0
      ) AS answer_rate,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true)::NUMERIC /
           NULLIF(COUNT(ac.id) FILTER (WHERE ac.answered = true), 0) * 100),
          1
        ),
        0
      ) AS conversion_rate,
      COALESCE(
        ROUND(
          AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0),
          0
        ),
        0
      ) AS avg_duration,
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
      MAX(ac.started_at) AS last_call_at,
      ad.status AS deployment_status
    FROM agent_deployments ad
    INNER JOIN user_accessible_agents uaa ON ad.id = uaa.deployment_id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN clients c ON ad.client_id = c.id
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    GROUP BY
      ad.id,
      ad.name,
      ad.slug,
      at.name,
      at.display_name,
      c.name,
      ad.status
  )
  SELECT
    am.deployment_id,
    am.deployment_name,
    am.slug,
    am.agent_type_name,
    am.agent_display_name,
    am.client_name,
    am.total_calls,
    am.answered_calls,
    am.appointments_scheduled,
    am.answer_rate,
    am.conversion_rate,
    am.avg_duration,
    am.total_cost,
    am.last_call_at,
    am.deployment_status
  FROM agent_metrics am
  ORDER BY am.total_calls DESC, am.deployment_name;
END;
$$;

-- 5.7 get_agent_type_cards_data
CREATE OR REPLACE FUNCTION get_agent_type_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE(
  agent_type_name TEXT,
  agent_display_name TEXT,
  total_deployments BIGINT,
  active_deployments BIGINT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments_scheduled BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  last_call_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH user_accessible_agents AS (
    -- Get agents accessible by the authenticated user via RLS
    SELECT DISTINCT a.deployment_id, a.agent_type_name
    FROM v_user_accessible_agents a
    WHERE (p_client_ids IS NULL OR a.client_id = ANY(p_client_ids))
  ),
  agent_type_metrics AS (
    SELECT
      at.name AS agent_type_name,
      at.display_name AS agent_display_name,
      COUNT(DISTINCT ad.id) AS total_deployments,
      COUNT(DISTINCT ad.id) FILTER (WHERE ad.status = 'active') AS active_deployments,
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.answered = true)::NUMERIC /
           NULLIF(COUNT(ac.id), 0) * 100),
          1
        ),
        0
      ) AS answer_rate,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true)::NUMERIC /
           NULLIF(COUNT(ac.id) FILTER (WHERE ac.answered = true), 0) * 100),
          1
        ),
        0
      ) AS conversion_rate,
      COALESCE(
        ROUND(
          AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0),
          0
        ),
        0
      ) AS avg_duration,
      MAX(ac.started_at) AS last_call_at
    FROM agent_types at
    INNER JOIN agent_deployments ad ON at.id = ad.agent_type_id
    INNER JOIN user_accessible_agents uaa ON ad.id = uaa.deployment_id
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    WHERE at.status = 'active'
    GROUP BY
      at.name,
      at.display_name
    HAVING COUNT(DISTINCT ad.id) > 0  -- Only include agent types with at least 1 deployment
  )
  SELECT
    atm.agent_type_name,
    atm.agent_display_name,
    atm.total_deployments,
    atm.active_deployments,
    atm.total_calls,
    atm.answered_calls,
    atm.appointments_scheduled,
    atm.answer_rate,
    atm.conversion_rate,
    atm.avg_duration,
    atm.last_call_at
  FROM agent_type_metrics atm
  ORDER BY atm.total_calls DESC, atm.agent_type_name;
END;
$$;

-- 5.8 get_client_cards_data
CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  client_id UUID,
  client_name TEXT,
  industry TEXT,
  total_agents BIGINT,
  active_agents BIGINT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments_scheduled BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  total_cost NUMERIC,
  last_call_at TIMESTAMP WITH TIME ZONE,
  agent_types TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH user_accessible_clients AS (
    -- Get clients accessible by the authenticated user via RLS
    SELECT DISTINCT c.client_id
    FROM v_user_accessible_clients c
  ),
  client_metrics AS (
    SELECT
      c.id AS client_id,
      c.name AS client_name,
      c.industry,
      COUNT(DISTINCT ad.id) AS total_agents,
      COUNT(DISTINCT ad.id) FILTER (WHERE ad.status = 'active') AS active_agents,
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.answered = true)::NUMERIC /
           NULLIF(COUNT(ac.id), 0) * 100),
          1
        ),
        0
      ) AS answer_rate,
      COALESCE(
        ROUND(
          (COUNT(ac.id) FILTER (WHERE ac.appointment_scheduled = true)::NUMERIC /
           NULLIF(COUNT(ac.id) FILTER (WHERE ac.answered = true), 0) * 100),
          1
        ),
        0
      ) AS conversion_rate,
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
      MAX(ac.started_at) AS last_call_at,
      ARRAY_AGG(DISTINCT at.name ORDER BY at.name) FILTER (WHERE at.name IS NOT NULL) AS agent_types
    FROM clients c
    INNER JOIN user_accessible_clients uac ON c.id = uac.client_id
    LEFT JOIN agent_deployments ad ON c.id = ad.client_id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    GROUP BY c.id, c.name, c.industry
  )
  SELECT
    cm.client_id,
    cm.client_name,
    cm.industry,
    cm.total_agents,
    cm.active_agents,
    cm.total_calls,
    cm.answered_calls,
    cm.appointments_scheduled,
    cm.answer_rate,
    cm.conversion_rate,
    cm.total_cost,
    cm.last_call_at,
    cm.agent_types
  FROM client_metrics cm
  ORDER BY cm.total_calls DESC, cm.client_name;
END;
$$;

-- ============================================================================
-- ÉTAPE 6 : Ajout des nouveaux index pour performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_calls_conversation_id ON agent_calls(conversation_id);
CREATE INDEX IF NOT EXISTS idx_calls_call_sid ON agent_calls(call_sid);
CREATE INDEX IF NOT EXISTS idx_calls_classification ON agent_calls(call_classification) WHERE call_classification IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calls_quality_score ON agent_calls(call_quality_score) WHERE call_quality_score IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calls_sentiment ON agent_calls(sentiment_analysis) WHERE sentiment_analysis IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calls_llm_model ON agent_calls(llm_model) WHERE llm_model IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calls_direction ON agent_calls(direction);

-- ============================================================================
-- COMMIT : Si tout s'est bien passé, on commit. Sinon rollback automatique.
-- ============================================================================

COMMIT;

-- ============================================================================
-- VÉRIFICATIONS POST-MIGRATION (à exécuter séparément)
-- ============================================================================
-- SELECT COUNT(*) FROM agent_calls;
-- SELECT COUNT(*) FROM agent_calls WHERE total_cost IS NOT NULL;
-- SELECT * FROM v_global_kpis;
-- SELECT * FROM v_agent_calls_enriched LIMIT 5;
-- SELECT get_kpi_metrics('2025-01-01', '2025-12-31', NULL, NULL, 'louis');
