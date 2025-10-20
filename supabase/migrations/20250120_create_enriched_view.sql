-- Migration: Create enriched view for agent_calls
-- Description: Creates a view that adds calculated columns without modifying the base table
-- Date: 2025-01-20
-- Author: Claude
--
-- This migration:
-- 1. Creates v_agent_calls_enriched view with calculated answered and appointment_scheduled
-- 2. Does NOT modify the agent_calls table
-- 3. Keeps all data logic in SQL views and functions

-- ==============================================================================
-- VIEW: v_agent_calls_enriched
-- Description: Enriched view of agent_calls with calculated boolean columns
-- Purpose: Add answered and appointment_scheduled without modifying base table
-- ==============================================================================

CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT
  ac.*,

  -- Calculate if call was answered (not voicemail)
  CASE
    -- Explicit answered outcomes
    WHEN ac.outcome IN ('RDV PRIS', 'RDV REFUSÉ', 'CALLBACK', 'NOT_INTERESTED', 'ALREADY_CLIENT', 'TOO_CONF')
      THEN true

    -- Explicit not answered outcomes
    WHEN ac.outcome IN ('VOICEMAIL', 'NO_ANSWER', 'BUSY', 'FAILED', 'INVALID_NUMBER')
      THEN false

    -- For other outcomes, check duration (real conversation > 10 seconds)
    WHEN ac.duration_seconds IS NOT NULL AND ac.duration_seconds > 10
      THEN true

    ELSE false
  END AS answered,

  -- Calculate if appointment was scheduled
  CASE
    -- Explicit outcome
    WHEN ac.outcome = 'RDV PRIS'
      THEN true

    -- Check metadata for Louis agent (contains appointment_scheduled_at)
    WHEN ac.metadata IS NOT NULL AND ac.metadata ? 'appointment_scheduled_at'
      THEN true

    ELSE false
  END AS appointment_scheduled

FROM agent_calls ac;

-- Add comment for documentation
COMMENT ON VIEW v_agent_calls_enriched IS
  'Enriched view of agent_calls with calculated answered and appointment_scheduled columns. Does not modify the base table.';

-- Grant SELECT to authenticated users (same as agent_calls)
GRANT SELECT ON v_agent_calls_enriched TO authenticated;


-- ==============================================================================
-- INDEXES ON BASE TABLE (for performance)
-- ==============================================================================

-- Index on outcome for filtering
CREATE INDEX IF NOT EXISTS idx_agent_calls_outcome
  ON agent_calls(outcome);

-- Index on metadata for JSON queries
CREATE INDEX IF NOT EXISTS idx_agent_calls_metadata_appointment
  ON agent_calls USING GIN ((metadata -> 'appointment_scheduled_at'));

-- Composite index for common queries (deployment + date range)
CREATE INDEX IF NOT EXISTS idx_agent_calls_deployment_started_at
  ON agent_calls(deployment_id, started_at DESC);

COMMENT ON INDEX idx_agent_calls_outcome IS
  'Index for quickly filtering calls by outcome';

COMMENT ON INDEX idx_agent_calls_metadata_appointment IS
  'GIN index for quickly checking appointment_scheduled_at in metadata';

COMMENT ON INDEX idx_agent_calls_deployment_started_at IS
  'Composite index for common dashboard queries filtering by deployment and date';
