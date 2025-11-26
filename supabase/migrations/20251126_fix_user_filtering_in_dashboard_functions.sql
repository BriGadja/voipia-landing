-- Migration: Fix user filtering in dashboard RPC functions
-- Date: 2025-11-26
-- Changes: Add explicit auth.uid() filtering to get_client_cards_data and get_agent_type_cards_data
-- Problem: Functions are SECURITY DEFINER which bypasses RLS, so they return ALL clients/agents
-- Solution: Filter explicitly by auth.uid() in the CTE queries

-- ============================================================================
-- FIX get_client_cards_data - Filter clients by authenticated user
-- ============================================================================
DROP FUNCTION IF EXISTS get_client_cards_data(DATE, DATE);

CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
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
    -- Get clients accessible by the authenticated user
    -- FIXED: Filter explicitly by auth.uid() since SECURITY DEFINER bypasses RLS
    SELECT DISTINCT c.client_id
    FROM v_user_accessible_clients c
    WHERE c.user_id = auth.uid()
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

GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE) TO authenticated;

-- ============================================================================
-- FIX get_agent_type_cards_data - Filter agents by authenticated user
-- ============================================================================
DROP FUNCTION IF EXISTS get_agent_type_cards_data(DATE, DATE, UUID[]);

CREATE OR REPLACE FUNCTION get_agent_type_cards_data(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
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
    -- Get agents accessible by the authenticated user
    -- FIXED: Filter explicitly by auth.uid() since SECURITY DEFINER bypasses RLS
    SELECT DISTINCT a.deployment_id, a.agent_type_name
    FROM v_user_accessible_agents a
    WHERE a.user_id = auth.uid()
      AND (p_client_ids IS NULL OR a.client_id = ANY(p_client_ids))
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

GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(DATE, DATE, UUID[]) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES (run manually to test)
-- ============================================================================
-- Test as Valentin (should only see Exotic Design and Stefano Design):
-- SELECT * FROM get_client_cards_data();
--
-- Test as Brice (should see Exotic Design, Norloc, Stefano Design, Voipia):
-- SELECT * FROM get_client_cards_data();
