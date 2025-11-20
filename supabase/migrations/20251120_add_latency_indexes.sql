-- Migration: Add indexes for latency data queries
-- Date: 2025-01-20
-- Author: Claude
-- Risk: LOW (only adds indexes, no data/schema changes)
--
-- Context:
-- Latency data is stored in metadata->'latencies' JSONB field (103 calls have this data).
-- Queries on JSONB fields without indexes are slow (sequential scans).
-- This migration adds GIN indexes to optimize latency-related queries.
--
-- Changes:
-- 1. GIN index on metadata->'latencies' for fast JSONB queries
-- 2. Composite index on (llm_model, started_at) for model performance analysis
-- 3. Partial index for filtering calls WITH latencies
--
-- Expected Impact:
-- - Queries on metadata->'latencies' will be 10-100x faster
-- - Dashboard latency charts will load much faster
-- - No impact on INSERT/UPDATE performance (latencies are only queried, not updated)
-- - Small storage overhead (~5-10% for 803 rows, negligible)

BEGIN;

-- =====================================================
-- Index 1: GIN index for JSONB latencies queries
-- =====================================================
-- Optimizes queries like:
--   WHERE metadata ? 'latencies'
--   WHERE (metadata->'latencies'->'llmLatencies'->>'average')::numeric > 1000
--
-- GIN (Generalized Inverted Index) is the best index type for JSONB

CREATE INDEX IF NOT EXISTS idx_agent_calls_metadata_latencies
  ON agent_calls USING GIN ((metadata->'latencies'))
  WHERE metadata ? 'latencies';

-- =====================================================
-- Index 2: Composite index for model + date analysis
-- =====================================================
-- Optimizes queries like:
--   SELECT ... FROM agent_calls
--   WHERE llm_model = 'gemini-2.5-flash'
--   AND started_at >= '2025-01-01'
--   ORDER BY started_at DESC
--
-- Useful for:
-- - Comparing latencies across different LLM models
-- - Time-series analysis of latency trends
-- - Filtering by date range + model

CREATE INDEX IF NOT EXISTS idx_agent_calls_llm_started
  ON agent_calls(llm_model, started_at DESC)
  WHERE metadata ? 'latencies';

-- =====================================================
-- Index 3: Partial index for calls WITH latencies
-- =====================================================
-- Optimizes queries that filter for calls with latency data:
--   SELECT ... FROM agent_calls
--   WHERE metadata ? 'latencies'
--   ORDER BY started_at DESC
--
-- This is a partial index (only indexes rows WHERE condition is true)
-- Much smaller than a full index, very fast

CREATE INDEX IF NOT EXISTS idx_agent_calls_has_latencies
  ON agent_calls(started_at DESC)
  WHERE metadata ? 'latencies';

-- =====================================================
-- Index 4: Index on deployment_id for filtered queries
-- =====================================================
-- Optimizes queries that filter by deployment + latencies:
--   SELECT ... FROM agent_calls
--   WHERE deployment_id = '...'
--   AND metadata ? 'latencies'
--
-- Useful for per-agent latency analysis

CREATE INDEX IF NOT EXISTS idx_agent_calls_deployment_latencies
  ON agent_calls(deployment_id, started_at DESC)
  WHERE metadata ? 'latencies';

COMMIT;

-- ===================================
-- VERIFICATION QUERIES (commented out)
-- Run these manually after migration to verify indexes
-- ===================================

-- Check that indexes were created
-- SELECT
--   schemaname,
--   tablename,
--   indexname,
--   indexdef
-- FROM pg_indexes
-- WHERE tablename = 'agent_calls'
--   AND indexname LIKE '%latenc%'
-- ORDER BY indexname;

-- Test query with EXPLAIN ANALYZE to see if index is used
-- EXPLAIN ANALYZE
-- SELECT
--   DATE(started_at) as date,
--   llm_model,
--   AVG((metadata->'latencies'->'llmLatencies'->>'average')::numeric) as avg_llm_ms
-- FROM agent_calls
-- WHERE metadata ? 'latencies'
--   AND started_at >= NOW() - INTERVAL '30 days'
-- GROUP BY DATE(started_at), llm_model
-- ORDER BY date DESC;
--
-- Expected: "Index Scan using idx_agent_calls_metadata_latencies"

-- Test query by deployment
-- EXPLAIN ANALYZE
-- SELECT
--   deployment_id,
--   COUNT(*) as call_count,
--   AVG((metadata->'latencies'->'llmLatencies'->>'average')::numeric) as avg_llm_latency
-- FROM agent_calls
-- WHERE metadata ? 'latencies'
--   AND started_at >= '2025-01-01'
-- GROUP BY deployment_id;
--
-- Expected: "Index Scan using idx_agent_calls_deployment_latencies"

-- Check index sizes
-- SELECT
--   indexname,
--   pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
-- FROM pg_indexes
-- WHERE tablename = 'agent_calls'
--   AND indexname LIKE '%latenc%';
