-- Migration: Create RPC function for agent type cards (global aggregation)
-- Description: Creates a function that aggregates metrics by agent type (louis, arthur, alexandra)
-- Date: 2025-01-20
-- Author: Claude
--
-- This migration:
-- 1. Creates get_agent_type_cards_data() function
-- 2. Aggregates all deployments of the same type (e.g., all Louis, all Arthur)
-- 3. Respects RLS - only includes agents the user has access to

-- ==============================================================================
-- FUNCTION: get_agent_type_cards_data
-- Description: Fetches agent type cards with aggregated metrics across all deployments
-- Returns: Array of agent type card data (one card per agent type: louis, arthur, alexandra)
-- Security: Uses RLS - only returns data for agents the user has access to
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_agent_type_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
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
  last_call_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(DATE, DATE, UUID[]) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_agent_type_cards_data IS
  'Fetches agent type cards with aggregated metrics across all deployments of each type. Respects RLS - only returns agent types the user has access to.';


-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Test the function
-- SELECT * FROM get_agent_type_cards_data('2025-01-01', '2025-01-31', NULL);

-- Compare with individual agent cards
-- SELECT
--   agent_type_name,
--   COUNT(*) as deployment_count,
--   SUM(total_calls) as total_calls
-- FROM get_agent_cards_data('2025-01-01', '2025-01-31', NULL)
-- GROUP BY agent_type_name;
