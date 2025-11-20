-- Migration: Add dedicated latency columns to agent_calls
-- Date: 2025-01-20
-- Author: Claude
-- Risk: LOW (adds columns, no data loss)
--
-- Context:
-- Latency data is currently stored in metadata->'latencies' JSONB.
-- Adding dedicated columns improves query performance and simplifies access.
-- We keep metadata.latencies for historical data and flexibility.
--
-- Changes:
-- 1. Add 9 latency columns (LLM: avg/min/max, TTS: avg/min/max, Total: avg/min/max)
-- 2. Backfill columns from metadata.latencies for existing calls
-- 3. Update get_latency_metrics() RPC to use dedicated columns
--
-- Expected Impact:
-- - Faster queries (no JSONB extraction needed)
-- - Simpler SQL (direct column access)
-- - Better indexing capabilities
-- - Metadata preserved for historical reference

BEGIN;

-- =====================================================
-- Step 1: Add latency columns
-- =====================================================

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

-- Add comments for documentation
COMMENT ON COLUMN agent_calls.avg_llm_latency_ms IS 'Average LLM latency in milliseconds (from metadata.latencies.llmLatencies.average)';
COMMENT ON COLUMN agent_calls.min_llm_latency_ms IS 'Minimum LLM latency in milliseconds (from metadata.latencies.llmLatencies.min)';
COMMENT ON COLUMN agent_calls.max_llm_latency_ms IS 'Maximum LLM latency in milliseconds (from metadata.latencies.llmLatencies.max)';
COMMENT ON COLUMN agent_calls.avg_tts_latency_ms IS 'Average TTS latency in milliseconds (from metadata.latencies.ttsLatencies.average)';
COMMENT ON COLUMN agent_calls.min_tts_latency_ms IS 'Minimum TTS latency in milliseconds (from metadata.latencies.ttsLatencies.min)';
COMMENT ON COLUMN agent_calls.max_tts_latency_ms IS 'Maximum TTS latency in milliseconds (from metadata.latencies.ttsLatencies.max)';
COMMENT ON COLUMN agent_calls.avg_total_latency_ms IS 'Average total latency in milliseconds (from metadata.latencies.totalLatencies.average)';
COMMENT ON COLUMN agent_calls.min_total_latency_ms IS 'Minimum total latency in milliseconds (from metadata.latencies.totalLatencies.min)';
COMMENT ON COLUMN agent_calls.max_total_latency_ms IS 'Maximum total latency in milliseconds (from metadata.latencies.totalLatencies.max)';

-- =====================================================
-- Step 2: Backfill latency data from metadata
-- =====================================================

-- Show before statistics
DO $$
DECLARE
  v_total_calls INTEGER;
  v_calls_with_metadata INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_calls FROM agent_calls;
  SELECT COUNT(*) INTO v_calls_with_metadata FROM agent_calls WHERE metadata ? 'latencies';

  RAISE NOTICE '=== BEFORE BACKFILL ===';
  RAISE NOTICE 'Total calls: %', v_total_calls;
  RAISE NOTICE 'Calls with metadata.latencies: %', v_calls_with_metadata;
END $$;

-- Backfill latency columns from metadata.latencies
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
  AND avg_llm_latency_ms IS NULL; -- Only update NULL rows (idempotent)

-- Show after statistics
DO $$
DECLARE
  v_backfilled INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_backfilled FROM agent_calls WHERE avg_llm_latency_ms IS NOT NULL;

  RAISE NOTICE '=== AFTER BACKFILL ===';
  RAISE NOTICE 'Calls with latency columns populated: %', v_backfilled;
END $$;

-- =====================================================
-- Step 3: Add indices for latency columns
-- =====================================================

-- Index for filtering by latency thresholds
CREATE INDEX IF NOT EXISTS idx_agent_calls_avg_llm_latency
  ON agent_calls(avg_llm_latency_ms)
  WHERE avg_llm_latency_ms IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agent_calls_avg_tts_latency
  ON agent_calls(avg_tts_latency_ms)
  WHERE avg_tts_latency_ms IS NOT NULL;

-- Index for date + latency queries (common dashboard query pattern)
CREATE INDEX IF NOT EXISTS idx_agent_calls_started_latency
  ON agent_calls(started_at DESC, deployment_id)
  WHERE avg_llm_latency_ms IS NOT NULL;

-- =====================================================
-- Step 4: Update get_latency_metrics() RPC function
-- =====================================================

-- Drop existing function
DROP FUNCTION IF EXISTS get_latency_metrics(DATE, DATE, UUID, UUID, TEXT);

-- Recreate function using dedicated columns (much faster!)
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
  -- LLM Latencies (milliseconds)
  avg_llm_latency_ms NUMERIC,
  min_llm_latency_ms INTEGER,
  max_llm_latency_ms INTEGER,
  -- TTS Latencies (milliseconds)
  avg_tts_latency_ms NUMERIC,
  min_tts_latency_ms INTEGER,
  max_tts_latency_ms INTEGER,
  -- Total Latencies (milliseconds)
  avg_total_latency_ms NUMERIC,
  min_total_latency_ms INTEGER,
  max_total_latency_ms INTEGER,
  -- Call count
  call_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH accessible_calls AS (
    -- Apply RLS: only return data for clients the user has access to
    SELECT
      ac.id,
      ac.deployment_id,
      ac.started_at,
      ac.llm_model,
      -- Use dedicated columns instead of JSONB extraction (faster!)
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
    -- RLS: Check user has permission to view this client's data
    WHERE EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.user_id = auth.uid()
        AND ucp.client_id = ad.client_id
    )
    -- Filter: Only calls with latency data
    AND ac.avg_llm_latency_ms IS NOT NULL
    -- Filter: Date range
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
    -- Filter: Deployment (optional)
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    -- Filter: Client (optional)
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    -- Filter: Agent type (optional)
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
    -- LLM Latencies (direct column access - no JSONB extraction!)
    ROUND(AVG(ac.avg_llm_latency_ms), 2) AS avg_llm_latency_ms,
    MIN(ac.min_llm_latency_ms) AS min_llm_latency_ms,
    MAX(ac.max_llm_latency_ms) AS max_llm_latency_ms,
    -- TTS Latencies
    ROUND(AVG(ac.avg_tts_latency_ms), 2) AS avg_tts_latency_ms,
    MIN(ac.min_tts_latency_ms) AS min_tts_latency_ms,
    MAX(ac.max_tts_latency_ms) AS max_tts_latency_ms,
    -- Total Latencies
    ROUND(AVG(ac.avg_total_latency_ms), 2) AS avg_total_latency_ms,
    MIN(ac.min_total_latency_ms) AS min_total_latency_ms,
    MAX(ac.max_total_latency_ms) AS max_total_latency_ms,
    -- Call count
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

-- Grant EXECUTE permission
GRANT EXECUTE ON FUNCTION get_latency_metrics(DATE, DATE, UUID, UUID, TEXT) TO authenticated;

-- Update comment
COMMENT ON FUNCTION get_latency_metrics IS
'Returns aggregated latency metrics using dedicated columns (faster than JSONB extraction).
Supports filtering by date range, deployment, client, and agent type.
Enforces RLS based on user_client_permissions.';

COMMIT;

-- ===================================
-- VERIFICATION QUERIES (commented out)
-- ===================================

-- Test 1: Check columns are populated
-- SELECT
--   COUNT(*) as total_calls,
--   COUNT(avg_llm_latency_ms) as calls_with_llm_latency,
--   COUNT(avg_tts_latency_ms) as calls_with_tts_latency,
--   COUNT(avg_total_latency_ms) as calls_with_total_latency
-- FROM agent_calls;

-- Test 2: Compare old (metadata) vs new (columns) for same call
-- SELECT
--   id,
--   -- Old way (JSONB)
--   (metadata->'latencies'->'llmLatencies'->>'average')::numeric as metadata_llm_avg,
--   (metadata->'latencies'->'ttsLatencies'->>'average')::numeric as metadata_tts_avg,
--   -- New way (columns)
--   avg_llm_latency_ms as column_llm_avg,
--   avg_tts_latency_ms as column_tts_avg
-- FROM agent_calls
-- WHERE metadata ? 'latencies'
-- LIMIT 10;

-- Test 3: Test RPC function with new columns
-- SELECT *
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   NULL, NULL, 'louis'
-- )
-- LIMIT 10;

-- Test 4: Performance comparison (should be faster now!)
-- EXPLAIN ANALYZE
-- SELECT
--   deployment_id,
--   AVG(avg_llm_latency_ms) as avg_llm,
--   AVG(avg_tts_latency_ms) as avg_tts
-- FROM agent_calls
-- WHERE avg_llm_latency_ms IS NOT NULL
--   AND started_at >= CURRENT_DATE - INTERVAL '30 days'
-- GROUP BY deployment_id;
