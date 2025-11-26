-- ============================================================================
-- ROLLBACK MIGRATION : Restaurer l'état initial de agent_calls
-- Date: 2025-11-13
-- Auteur: Brice @ Voipia
-- 
-- ⚠️ À utiliser UNIQUEMENT si la migration a causé des problèmes
-- Ce script restaure l'état initial de la table et des vues
-- ============================================================================

BEGIN;

-- ============================================================================
-- ÉTAPE 1 : Drop des vues actuelles
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
-- ÉTAPE 2 : Supprimer les nouvelles colonnes
-- ============================================================================

ALTER TABLE agent_calls
  DROP COLUMN IF EXISTS conversation_id,
  DROP COLUMN IF EXISTS call_sid,
  DROP COLUMN IF EXISTS stt_cost,
  DROP COLUMN IF EXISTS tts_cost,
  DROP COLUMN IF EXISTS llm_cost,
  DROP COLUMN IF EXISTS telecom_cost,
  DROP COLUMN IF EXISTS dipler_commission,
  DROP COLUMN IF EXISTS cost_per_minute,
  DROP COLUMN IF EXISTS call_classification,
  DROP COLUMN IF EXISTS call_quality_score,
  DROP COLUMN IF EXISTS sentiment_analysis,
  DROP COLUMN IF EXISTS llm_model,
  DROP COLUMN IF EXISTS tts_provider,
  DROP COLUMN IF EXISTS tts_voice_id,
  DROP COLUMN IF EXISTS stt_provider,
  DROP COLUMN IF EXISTS direction,
  DROP COLUMN IF EXISTS call_status,
  DROP COLUMN IF EXISTS provider;

-- ============================================================================
-- ÉTAPE 3 : Renommer total_cost → cost (restaurer le nom original)
-- ============================================================================

ALTER TABLE agent_calls RENAME COLUMN total_cost TO cost;

-- ============================================================================
-- ÉTAPE 4 : Supprimer les nouveaux index
-- ============================================================================

DROP INDEX IF EXISTS idx_calls_conversation_id;
DROP INDEX IF EXISTS idx_calls_call_sid;
DROP INDEX IF EXISTS idx_calls_classification;
DROP INDEX IF EXISTS idx_calls_quality_score;
DROP INDEX IF EXISTS idx_calls_sentiment;
DROP INDEX IF EXISTS idx_calls_llm_model;
DROP INDEX IF EXISTS idx_calls_direction;

-- ============================================================================
-- ÉTAPE 5 : Recréer les vues ORIGINALES (copier depuis le backup de production)
-- ============================================================================

-- TODO: Copier-coller ici les définitions des vues originales depuis le backup
-- Ou lancer un restore depuis un dump SQL fait avant la migration

-- Exemple pour v_agent_calls_enriched (version originale):
CREATE VIEW v_agent_calls_enriched AS
SELECT 
  id, deployment_id, first_name, last_name, email, phone_number,
  started_at, ended_at, duration_seconds, outcome, emotion, cost,
  transcript, transcript_summary, recording_url, metadata, created_at,
  prospect_id, sequence_id,
  CASE
    WHEN outcome IN ('voicemail', 'call_failed', 'no_answer', 'busy', 
                     'invalid_number', 'error', 'canceled', 'rejected') THEN false
    WHEN outcome IS NULL THEN false
    ELSE true
  END AS answered,
  CASE
    WHEN outcome = 'appointment_scheduled' THEN true
    ELSE false
  END AS appointment_scheduled
FROM agent_calls ac;

-- ... Copier toutes les autres vues originales ici

COMMIT;

-- ============================================================================
-- MESSAGE FINAL
-- ============================================================================
-- SELECT 'Rollback effectué avec succès. État restauré avant migration.' AS status;
