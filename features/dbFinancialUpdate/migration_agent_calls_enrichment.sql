-- ============================================================================
-- MIGRATION : Enrichissement table agent_calls avec données financières Dipler
-- Date: 2025-11-13
-- Auteur: Brice @ Voipia
-- 
-- Ce script fait :
-- 1. Drop des vues dépendantes
-- 2. Renommage cost → total_cost + ajout colonnes analytics
-- 3. Recréation des vues avec nouveau nom de colonne
-- 4. Ajout des index pour performance
--
-- ⚠️ IMPORTANT : Tout est dans une transaction = rollback auto si erreur
-- ============================================================================

BEGIN;

-- ============================================================================
-- ÉTAPE 1 : Drop des vues dépendantes (dans l'ordre des dépendances)
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
-- ÉTAPE 2 : Modification de la table agent_calls
-- ============================================================================

-- 2.1 Renommer la colonne existante
ALTER TABLE agent_calls RENAME COLUMN cost TO total_cost;

-- 2.2 Ajouter identifiants externes
ALTER TABLE agent_calls
  ADD COLUMN conversation_id TEXT UNIQUE,
  ADD COLUMN call_sid TEXT;

-- 2.3 Ajouter breakdown financier
ALTER TABLE agent_calls
  ADD COLUMN stt_cost NUMERIC(10, 6),
  ADD COLUMN tts_cost NUMERIC(10, 6),
  ADD COLUMN llm_cost NUMERIC(10, 6),
  ADD COLUMN telecom_cost NUMERIC(10, 6),
  ADD COLUMN dipler_commission NUMERIC(10, 6),
  ADD COLUMN cost_per_minute NUMERIC(10, 6);

-- 2.4 Ajouter qualité & classification
ALTER TABLE agent_calls
  ADD COLUMN call_classification TEXT,
  ADD COLUMN call_quality_score INTEGER CHECK (call_quality_score BETWEEN 1 AND 10),
  ADD COLUMN sentiment_analysis TEXT CHECK (sentiment_analysis IN ('positive', 'neutral', 'negative'));

-- 2.5 Ajouter stack technique
ALTER TABLE agent_calls
  ADD COLUMN llm_model TEXT,
  ADD COLUMN tts_provider TEXT,
  ADD COLUMN tts_voice_id TEXT,
  ADD COLUMN stt_provider TEXT;

-- 2.6 Ajouter contexte téléphonie
ALTER TABLE agent_calls
  ADD COLUMN direction TEXT CHECK (direction IN ('inbound', 'outbound')),
  ADD COLUMN call_status TEXT,
  ADD COLUMN provider TEXT DEFAULT 'twilio';

-- 2.7 Commentaires
COMMENT ON COLUMN agent_calls.conversation_id IS 'ID unique de conversation Dipler (ex: 01K9Y3RDPR2DHFQQS9SC4XA0TM)';
COMMENT ON COLUMN agent_calls.call_sid IS 'Twilio Call SID (ex: CA83f4c6960b6bb71c6ac80df45ff59a44)';
COMMENT ON COLUMN agent_calls.total_cost IS 'Coût total de l''appel incluant STT+TTS+LLM+telecom+commission';
COMMENT ON COLUMN agent_calls.call_classification IS 'Classification post-appel (callback_requested, appointment_set, not_interested, etc.)';
COMMENT ON COLUMN agent_calls.call_quality_score IS 'Score de qualité de l''appel (1-10) généré par l''analyse post-conversation';
COMMENT ON COLUMN agent_calls.sentiment_analysis IS 'Sentiment détecté dans la conversation (positive, neutral, negative)';

-- ============================================================================
-- ÉTAPE 3 : Recréation des vues avec nouvelle nomenclature
-- ============================================================================

-- 3.1 v_agent_calls_enriched
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

-- 3.2 v_user_accessible_agents
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

-- 3.3 v_global_kpis
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

-- 3.4 v_arthur_calls_enriched
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

-- 3.5 v_global_call_volume_by_day
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

-- 3.6 v_global_outcome_distribution
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

-- 3.7 v_global_agent_type_performance
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

-- 3.8 v_global_top_clients
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

-- 3.9 v_louis_agent_performance
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

-- 3.10 v_arthur_next_calls_global
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
-- ÉTAPE 4 : Ajout des nouveaux index pour performance
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
