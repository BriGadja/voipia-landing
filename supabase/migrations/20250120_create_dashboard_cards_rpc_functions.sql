-- Migration: Create RPC functions for dynamic dashboard cards
-- Description: Functions to fetch client and agent cards data with aggregated metrics
-- Date: 2025-01-20

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
      c.client_id,
      c.name AS client_name,
      c.industry,
      COUNT(DISTINCT ad.deployment_id) AS total_agents,
      COUNT(DISTINCT ad.deployment_id) FILTER (WHERE ad.status = 'active') AS active_agents,
      COUNT(ac.call_id) AS total_calls,
      COUNT(ac.call_id) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(ac.call_id) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(
        ROUND(
          (COUNT(ac.call_id) FILTER (WHERE ac.answered = true)::NUMERIC /
           NULLIF(COUNT(ac.call_id), 0) * 100),
          1
        ),
        0
      ) AS answer_rate,
      COALESCE(
        ROUND(
          (COUNT(ac.call_id) FILTER (WHERE ac.appointment_scheduled = true)::NUMERIC /
           NULLIF(COUNT(ac.call_id) FILTER (WHERE ac.answered = true), 0) * 100),
          1
        ),
        0
      ) AS conversion_rate,
      COALESCE(SUM(ac.cost), 0) AS total_cost,
      MAX(ac.started_at) AS last_call_at,
      ARRAY_AGG(DISTINCT at.name ORDER BY at.name) AS agent_types
    FROM clients c
    INNER JOIN user_accessible_clients uac ON c.client_id = uac.client_id
    LEFT JOIN agent_deployments ad ON c.client_id = ad.client_id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.agent_type_id
    LEFT JOIN agent_calls ac ON ad.deployment_id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    GROUP BY c.client_id, c.name, c.industry
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
  'Fetches client cards with aggregated metrics. Respects RLS - only returns clients the user has access to.';


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
      ad.deployment_id,
      ad.name AS deployment_name,
      ad.slug,
      at.name AS agent_type_name,
      at.display_name AS agent_display_name,
      c.name AS client_name,
      COUNT(ac.call_id) AS total_calls,
      COUNT(ac.call_id) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(ac.call_id) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(
        ROUND(
          (COUNT(ac.call_id) FILTER (WHERE ac.answered = true)::NUMERIC /
           NULLIF(COUNT(ac.call_id), 0) * 100),
          1
        ),
        0
      ) AS answer_rate,
      COALESCE(
        ROUND(
          (COUNT(ac.call_id) FILTER (WHERE ac.appointment_scheduled = true)::NUMERIC /
           NULLIF(COUNT(ac.call_id) FILTER (WHERE ac.answered = true), 0) * 100),
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
    INNER JOIN user_accessible_agents uaa ON ad.deployment_id = uaa.deployment_id
    INNER JOIN agent_types at ON ad.agent_type_id = at.agent_type_id
    INNER JOIN clients c ON ad.client_id = c.client_id
    LEFT JOIN agent_calls ac ON ad.deployment_id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    GROUP BY
      ad.deployment_id,
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
  'Fetches agent cards with aggregated metrics. Respects RLS - only returns agents the user has access to.';
