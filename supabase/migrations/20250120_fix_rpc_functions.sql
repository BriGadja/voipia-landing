-- Migration: Create/Fix RPC functions for dashboard cards
-- Description: Creates RPC functions using the enriched view (no table modification)
-- Date: 2025-01-20
-- Author: Claude
--
-- This migration:
-- 1. Uses v_agent_calls_enriched view for calculated columns
-- 2. Does NOT modify agent_calls table
-- 3. Fixes column references (id instead of call_id, etc.)

-- ==============================================================================
-- FUNCTION: get_client_cards_data
-- Description: Fetches client cards with aggregated metrics for the dashboard
-- Returns: Array of client card data with metrics for the specified date range
-- Security: Uses RLS - only returns data for clients the user has access to
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
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
  last_call_at TIMESTAMPTZ,
  agent_types TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
      COALESCE(SUM(ac.cost), 0) AS total_cost,
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_client_cards_data IS
  'Fetches client cards with aggregated metrics. Uses v_agent_calls_enriched view. Respects RLS - only returns clients the user has access to.';


-- ==============================================================================
-- FUNCTION: get_agent_cards_data
-- Description: Fetches agent cards with aggregated metrics for the dashboard
-- Returns: Array of agent card data with metrics for the specified date range
-- Security: Uses RLS - only returns data for agents the user has access to
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_agent_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
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
  last_call_at TIMESTAMPTZ,
  deployment_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
      COALESCE(SUM(ac.cost), 0) AS total_cost,
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_agent_cards_data(DATE, DATE, UUID[]) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_agent_cards_data IS
  'Fetches agent cards with aggregated metrics. Uses v_agent_calls_enriched view. Respects RLS - only returns agents the user has access to.';


-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Test the enriched view
-- SELECT * FROM v_agent_calls_enriched LIMIT 10;

-- Test get_client_cards_data with a date range
-- SELECT * FROM get_client_cards_data('2025-01-01', '2025-01-31');

-- Test get_agent_cards_data with a date range
-- SELECT * FROM get_agent_cards_data('2025-01-01', '2025-01-31', NULL);

-- Check calculated columns distribution
-- SELECT
--   answered,
--   appointment_scheduled,
--   COUNT(*) as count
-- FROM v_agent_calls_enriched
-- GROUP BY answered, appointment_scheduled;
