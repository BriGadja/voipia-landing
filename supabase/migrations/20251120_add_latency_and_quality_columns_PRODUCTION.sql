-- =====================================================
-- MIGRATION COMPLÈTE POUR PRODUCTION
-- =====================================================
-- Date: 2025-01-20
-- Author: Claude
-- Risk: LOW (adds columns and indices, no data loss)
--
-- Ce script combine 2 migrations :
-- 1. Ajout des 9 colonnes de latences + backfill + RPC function
-- 2. Ajout de la colonne call_quality_analysis + indices
--
-- IMPORTANT: Exécuter ce script en PRODUCTION via Supabase Dashboard
-- =====================================================

BEGIN;

-- =====================================================
-- PARTIE 1: COLONNES DE LATENCES (9 colonnes)
-- =====================================================

-- Step 1.1: Ajouter les colonnes de latence
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS avg_llm_latency_ms NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS min_llm_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS max_llm_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS avg_tts_latency_ms NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS min_tts_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS max_tts_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS avg_total_latency_ms NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS min_total_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS max_total_latency_ms INTEGER;

-- Step 1.2: Ajouter les commentaires
COMMENT ON COLUMN agent_calls.avg_llm_latency_ms IS 'Average LLM latency in milliseconds (from metadata.latencies.llmLatencies.average)';
COMMENT ON COLUMN agent_calls.min_llm_latency_ms IS 'Minimum LLM latency in milliseconds (from metadata.latencies.llmLatencies.min)';
COMMENT ON COLUMN agent_calls.max_llm_latency_ms IS 'Maximum LLM latency in milliseconds (from metadata.latencies.llmLatencies.max)';
COMMENT ON COLUMN agent_calls.avg_tts_latency_ms IS 'Average TTS latency in milliseconds (from metadata.latencies.ttsLatencies.average)';
COMMENT ON COLUMN agent_calls.min_tts_latency_ms IS 'Minimum TTS latency in milliseconds (from metadata.latencies.ttsLatencies.min)';
COMMENT ON COLUMN agent_calls.max_tts_latency_ms IS 'Maximum TTS latency in milliseconds (from metadata.latencies.ttsLatencies.max)';
COMMENT ON COLUMN agent_calls.avg_total_latency_ms IS 'Average total latency in milliseconds (from metadata.latencies.totalLatencies.average)';
COMMENT ON COLUMN agent_calls.min_total_latency_ms IS 'Minimum total latency in milliseconds (from metadata.latencies.totalLatencies.min)';
COMMENT ON COLUMN agent_calls.max_total_latency_ms IS 'Maximum total latency in milliseconds (from metadata.latencies.totalLatencies.max)';

-- Step 1.3: Backfill depuis metadata.latencies
DO $$
DECLARE
  v_total_calls INTEGER;
  v_calls_with_metadata INTEGER;
  v_backfilled INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_calls FROM agent_calls;
  SELECT COUNT(*) INTO v_calls_with_metadata FROM agent_calls WHERE metadata ? 'latencies';

  RAISE NOTICE '=== BACKFILL LATENCES ===';
  RAISE NOTICE 'Total appels: %', v_total_calls;
  RAISE NOTICE 'Appels avec metadata.latencies: %', v_calls_with_metadata;

  -- Backfill
  UPDATE agent_calls
  SET
    avg_llm_latency_ms = (metadata->'latencies'->'llmLatencies'->>'average')::numeric,
    min_llm_latency_ms = (metadata->'latencies'->'llmLatencies'->>'min')::integer,
    max_llm_latency_ms = (metadata->'latencies'->'llmLatencies'->>'max')::integer,
    avg_tts_latency_ms = (metadata->'latencies'->'ttsLatencies'->>'average')::numeric,
    min_tts_latency_ms = (metadata->'latencies'->'ttsLatencies'->>'min')::integer,
    max_tts_latency_ms = (metadata->'latencies'->'ttsLatencies'->>'max')::integer,
    avg_total_latency_ms = (metadata->'latencies'->'totalLatencies'->>'average')::numeric,
    min_total_latency_ms = (metadata->'latencies'->'totalLatencies'->>'min')::integer,
    max_total_latency_ms = (metadata->'latencies'->'totalLatencies'->>'max')::integer
  WHERE
    metadata ? 'latencies'
    AND avg_llm_latency_ms IS NULL;

  SELECT COUNT(*) INTO v_backfilled FROM agent_calls WHERE avg_llm_latency_ms IS NOT NULL;
  RAISE NOTICE 'Appels avec latences remplies: %', v_backfilled;
END $$;

-- Step 1.4: Indices pour les latences
CREATE INDEX IF NOT EXISTS idx_agent_calls_avg_llm_latency
  ON agent_calls(avg_llm_latency_ms)
  WHERE avg_llm_latency_ms IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agent_calls_avg_tts_latency
  ON agent_calls(avg_tts_latency_ms)
  WHERE avg_tts_latency_ms IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agent_calls_started_latency
  ON agent_calls(started_at DESC, deployment_id)
  WHERE avg_llm_latency_ms IS NOT NULL;

-- Step 1.5: Fonction RPC get_latency_metrics()
DROP FUNCTION IF EXISTS get_latency_metrics(DATE, DATE, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION get_latency_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_deployment_id UUID DEFAULT NULL,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  date DATE,
  deployment_id UUID,
  deployment_name TEXT,
  client_id UUID,
  client_name TEXT,
  agent_type_name TEXT,
  llm_model TEXT,
  avg_llm_latency_ms NUMERIC,
  min_llm_latency_ms INTEGER,
  max_llm_latency_ms INTEGER,
  avg_tts_latency_ms NUMERIC,
  min_tts_latency_ms INTEGER,
  max_tts_latency_ms INTEGER,
  avg_total_latency_ms NUMERIC,
  min_total_latency_ms INTEGER,
  max_total_latency_ms INTEGER,
  call_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH accessible_calls AS (
    SELECT
      ac.id,
      ac.deployment_id,
      ac.started_at,
      ac.llm_model,
      ac.avg_llm_latency_ms,
      ac.min_llm_latency_ms,
      ac.max_llm_latency_ms,
      ac.avg_tts_latency_ms,
      ac.min_tts_latency_ms,
      ac.max_tts_latency_ms,
      ac.avg_total_latency_ms,
      ac.min_total_latency_ms,
      ac.max_total_latency_ms,
      ad.name AS deployment_name,
      ad.client_id,
      c.name AS client_name,
      at.name AS agent_type_name
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN clients c ON ad.client_id = c.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.user_id = auth.uid()
        AND ucp.client_id = ad.client_id
    )
    AND ac.avg_llm_latency_ms IS NOT NULL
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
  )
  SELECT
    DATE(ac.started_at) AS date,
    ac.deployment_id,
    ac.deployment_name,
    ac.client_id,
    ac.client_name,
    ac.agent_type_name,
    ac.llm_model,
    ROUND(AVG(ac.avg_llm_latency_ms), 2) AS avg_llm_latency_ms,
    MIN(ac.min_llm_latency_ms) AS min_llm_latency_ms,
    MAX(ac.max_llm_latency_ms) AS max_llm_latency_ms,
    ROUND(AVG(ac.avg_tts_latency_ms), 2) AS avg_tts_latency_ms,
    MIN(ac.min_tts_latency_ms) AS min_tts_latency_ms,
    MAX(ac.max_tts_latency_ms) AS max_tts_latency_ms,
    ROUND(AVG(ac.avg_total_latency_ms), 2) AS avg_total_latency_ms,
    MIN(ac.min_total_latency_ms) AS min_total_latency_ms,
    MAX(ac.max_total_latency_ms) AS max_total_latency_ms,
    COUNT(*)::INTEGER AS call_count
  FROM accessible_calls ac
  GROUP BY
    DATE(ac.started_at),
    ac.deployment_id,
    ac.deployment_name,
    ac.client_id,
    ac.client_name,
    ac.agent_type_name,
    ac.llm_model
  ORDER BY
    date DESC,
    deployment_name,
    llm_model;
END;
$$;

GRANT EXECUTE ON FUNCTION get_latency_metrics(DATE, DATE, UUID, UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION get_latency_metrics IS
'Returns aggregated latency metrics using dedicated columns.
Supports filtering by date range, deployment, client, and agent type.
Enforces RLS based on user_client_permissions.';

-- =====================================================
-- PARTIE 2: COLONNE CALL_QUALITY_ANALYSIS
-- =====================================================

-- Step 2.1: Ajouter la colonne
ALTER TABLE agent_calls
  ADD COLUMN IF NOT EXISTS call_quality_analysis TEXT;

-- Step 2.2: Ajouter le commentaire
COMMENT ON COLUMN agent_calls.call_quality_analysis IS
  'Detailed analysis for call_quality_score (0-100).
  Generated by Dipler post-conversation analysis (field: callQualityAnalysis).
  Format: DÉTAIL DES POINTS / POINTS FORTS / AXES D''AMÉLIORATION.
  Example: "Durée: 95s → 25/25 pts | Sentiment: positif → 30/30 pts..."';

-- Step 2.3: Indices pour recherche full-text
CREATE INDEX IF NOT EXISTS idx_agent_calls_quality_analysis_fts
  ON agent_calls USING gin(to_tsvector('french', call_quality_analysis))
  WHERE call_quality_analysis IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agent_calls_has_analysis
  ON agent_calls(started_at DESC)
  WHERE call_quality_analysis IS NOT NULL;

-- =====================================================
-- STATISTIQUES FINALES
-- =====================================================

DO $$
DECLARE
  v_total_calls INTEGER;
  v_calls_with_latency INTEGER;
  v_calls_with_score INTEGER;
  v_calls_with_analysis INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_calls FROM agent_calls;
  SELECT COUNT(*) INTO v_calls_with_latency FROM agent_calls WHERE avg_llm_latency_ms IS NOT NULL;
  SELECT COUNT(*) INTO v_calls_with_score FROM agent_calls WHERE call_quality_score IS NOT NULL;
  SELECT COUNT(*) INTO v_calls_with_analysis FROM agent_calls WHERE call_quality_analysis IS NOT NULL;

  RAISE NOTICE '=== MIGRATION TERMINÉE ===';
  RAISE NOTICE 'Total appels: %', v_total_calls;
  RAISE NOTICE 'Appels avec latences: % (%.1f%%)',
    v_calls_with_latency,
    CASE WHEN v_total_calls > 0 THEN (v_calls_with_latency::numeric / v_total_calls * 100) ELSE 0 END;
  RAISE NOTICE 'Appels avec quality score: % (%.1f%%)',
    v_calls_with_score,
    CASE WHEN v_total_calls > 0 THEN (v_calls_with_score::numeric / v_total_calls * 100) ELSE 0 END;
  RAISE NOTICE 'Appels avec quality analysis: % (%.1f%%)',
    v_calls_with_analysis,
    CASE WHEN v_total_calls > 0 THEN (v_calls_with_analysis::numeric / v_total_calls * 100) ELSE 0 END;
  RAISE NOTICE '========================';
END $$;

COMMIT;

-- ===================================
-- VÉRIFICATIONS POST-MIGRATION
-- ===================================

-- Vérification 1: Colonnes créées
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'agent_calls'
--   AND (column_name LIKE '%latency%' OR column_name LIKE '%quality%')
-- ORDER BY column_name;

-- Vérification 2: Indices créés
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'agent_calls'
--   AND (indexname LIKE '%latency%' OR indexname LIKE '%quality%')
-- ORDER BY indexname;

-- Vérification 3: Fonction RPC existe
-- SELECT proname, prosrc
-- FROM pg_proc
-- WHERE proname = 'get_latency_metrics';

-- Vérification 4: Données backfillées
-- SELECT
--   COUNT(*) as total,
--   COUNT(avg_llm_latency_ms) as with_llm,
--   COUNT(avg_tts_latency_ms) as with_tts,
--   COUNT(call_quality_score) as with_score,
--   COUNT(call_quality_analysis) as with_analysis
-- FROM agent_calls;

-- Vérification 5: Test RPC function
-- SELECT *
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   NULL, NULL, 'louis'
-- )
-- LIMIT 5;
