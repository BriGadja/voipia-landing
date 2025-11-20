-- Migration: Create RPC function for latency metrics
-- Date: 2025-01-20
-- Author: Claude
-- Risk: LOW (only adds function, no data/schema changes)
--
-- Context:
-- Dashboard needs to query latency data stored in metadata->'latencies' JSONB.
-- This RPC function provides a clean API to fetch latency metrics with filtering.
--
-- Changes:
-- 1. Create get_latency_metrics() function
-- 2. Returns aggregated latency data by date, deployment, model
-- 3. Supports filtering by date range, deployment, client, agent type
-- 4. Grant EXECUTE permission to authenticated users
--
-- Expected Impact:
-- - Dashboard can easily fetch latency metrics via supabase.rpc('get_latency_metrics', {...})
-- - Consistent API with other dashboard RPC functions
-- - Row-level security enforced via user_client_permissions

BEGIN;

-- Drop function if exists (for idempotent migrations)
DROP FUNCTION IF EXISTS get_latency_metrics(DATE, DATE, UUID, UUID, TEXT);

-- =====================================================
-- Function: get_latency_metrics
-- =====================================================
-- Returns aggregated latency metrics for dashboard charts
--
-- Parameters:
--   p_start_date: Filter start date (inclusive)
--   p_end_date: Filter end date (inclusive)
--   p_deployment_id: Optional filter by specific deployment
--   p_client_id: Optional filter by client
--   p_agent_type_name: Optional filter by agent type (louis, arthur, alexandra)
--
-- Returns:
--   Table with daily latency metrics aggregated by deployment and model

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
  -- Return latency metrics aggregated by date, deployment, model
  RETURN QUERY
  WITH accessible_calls AS (
    -- Apply RLS: only return data for clients the user has access to
    SELECT
      ac.id,
      ac.deployment_id,
      ac.started_at,
      ac.llm_model,
      ac.metadata,
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
    AND ac.metadata ? 'latencies'
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
    -- LLM Latencies
    ROUND(AVG((ac.metadata->'latencies'->'llmLatencies'->>'average')::numeric), 2) AS avg_llm_latency_ms,
    MIN((ac.metadata->'latencies'->'llmLatencies'->>'min')::integer) AS min_llm_latency_ms,
    MAX((ac.metadata->'latencies'->'llmLatencies'->>'max')::integer) AS max_llm_latency_ms,
    -- TTS Latencies
    ROUND(AVG((ac.metadata->'latencies'->'ttsLatencies'->>'average')::numeric), 2) AS avg_tts_latency_ms,
    MIN((ac.metadata->'latencies'->'ttsLatencies'->>'min')::integer) AS min_tts_latency_ms,
    MAX((ac.metadata->'latencies'->'ttsLatencies'->>'max')::integer) AS max_tts_latency_ms,
    -- Total Latencies
    ROUND(AVG((ac.metadata->'latencies'->'totalLatencies'->>'average')::numeric), 2) AS avg_total_latency_ms,
    MIN((ac.metadata->'latencies'->'totalLatencies'->>'min')::integer) AS min_total_latency_ms,
    MAX((ac.metadata->'latencies'->'totalLatencies'->>'max')::integer) AS max_total_latency_ms,
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

-- Grant EXECUTE permission to authenticated users
GRANT EXECUTE ON FUNCTION get_latency_metrics(DATE, DATE, UUID, UUID, TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_latency_metrics IS
'Returns aggregated latency metrics (LLM, TTS, total) for dashboard charts.
Supports filtering by date range, deployment, client, and agent type.
Enforces RLS based on user_client_permissions.';

COMMIT;

-- ===================================
-- VERIFICATION QUERIES (commented out)
-- Run these manually after migration to test function
-- ===================================

-- Test 1: Get all latencies for last 30 days
-- SELECT *
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   NULL, -- all deployments
--   NULL, -- all clients
--   NULL  -- all agent types
-- )
-- LIMIT 10;

-- Test 2: Get Louis latencies only
-- SELECT *
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '7 days',
--   CURRENT_DATE,
--   NULL,
--   NULL,
--   'louis' -- filter by Louis agent
-- )
-- ORDER BY date DESC;

-- Test 3: Get latencies for specific deployment
-- SELECT *
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '7 days',
--   CURRENT_DATE,
--   '348cc94d-b4e8-4281-b33a-bc9378fecffc'::UUID, -- specific deployment
--   NULL,
--   NULL
-- );

-- Test 4: Check average latencies by model
-- SELECT
--   llm_model,
--   ROUND(AVG(avg_llm_latency_ms), 2) as overall_avg_llm_ms,
--   ROUND(AVG(avg_tts_latency_ms), 2) as overall_avg_tts_ms,
--   SUM(call_count) as total_calls
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   NULL, NULL, NULL
-- )
-- GROUP BY llm_model
-- ORDER BY total_calls DESC;

-- Test 5: Verify RLS works (should only return accessible clients)
-- SELECT DISTINCT
--   client_id,
--   client_name
-- FROM get_latency_metrics(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   NULL, NULL, NULL
-- );
-- -- Should match clients from user_client_permissions for current user
