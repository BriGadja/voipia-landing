-- Migration: Admin bypass for view-as-user functionality
-- Date: 2025-11-27
-- Changes:
--   1. Modify get_agent_cards_data to allow admin to view any client's data
--   2. Modify get_global_kpis to allow admin to view any client's data
--   3. Modify get_global_chart_data to allow admin to view any client's data
--   4. Modify get_client_cards_data to add p_client_ids param and admin bypass
--
-- Problem: When admin uses "view as user" feature, functions still filter by admin's own
-- permissions instead of using the provided client IDs.
--
-- Solution: If user is admin AND p_client_ids is provided, use those IDs directly
-- without filtering by auth.uid()'s permissions.

-- ============================================================================
-- 1. FUNCTION: get_agent_cards_data (with admin bypass)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_agent_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE(
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
SET search_path TO 'public'
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If no accessible clients, return empty
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH agent_metrics AS (
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
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
      MAX(ac.started_at) AS last_call_at,
      ad.status AS deployment_status
    FROM agent_deployments ad
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN clients c ON ad.client_id = c.id
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids)
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

-- ============================================================================
-- 2. FUNCTION: get_global_kpis (with admin bypass)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_ids UUID[] DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_duration INTERVAL;
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If user has no accessible clients, return empty results
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN JSONB_BUILD_OBJECT(
      'current_period', JSONB_BUILD_OBJECT(
        'total_calls', 0,
        'answered_calls', 0,
        'appointments_scheduled', 0,
        'answer_rate', 0,
        'conversion_rate', 0,
        'avg_duration', 0,
        'total_cost', 0,
        'cost_per_appointment', 0
      ),
      'previous_period', JSONB_BUILD_OBJECT(
        'total_calls', 0,
        'answered_calls', 0,
        'appointments_scheduled', 0,
        'answer_rate', 0,
        'conversion_rate', 0,
        'avg_duration', 0,
        'total_cost', 0,
        'cost_per_appointment', 0
      )
    );
  END IF;

  -- Calculate period duration for comparison
  v_period_duration := p_end_date - p_start_date;

  -- Current period
  SELECT JSONB_BUILD_OBJECT(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL),
    'appointments_scheduled', COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled'),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled')::NUMERIC /
                  COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled') > 0
      THEN ROUND(COALESCE(SUM(total_cost), 0) / COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled'), 2)
      ELSE 0
    END
  ) INTO v_current_period
  FROM agent_calls ac
  INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= p_start_date
    AND ac.started_at <= p_end_date
    AND ad.client_id = ANY(v_accessible_client_ids)
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name);

  -- Previous period
  SELECT JSONB_BUILD_OBJECT(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL),
    'appointments_scheduled', COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled'),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled')::NUMERIC /
                  COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled') > 0
      THEN ROUND(COALESCE(SUM(total_cost), 0) / COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled'), 2)
      ELSE 0
    END
  ) INTO v_previous_period
  FROM agent_calls ac
  INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= (p_start_date - v_period_duration)
    AND ac.started_at < p_start_date
    AND ad.client_id = ANY(v_accessible_client_ids)
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name);

  RETURN JSONB_BUILD_OBJECT(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

-- ============================================================================
-- 3. FUNCTION: get_global_chart_data (with admin bypass)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_global_chart_data(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_ids UUID[] DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If user has no accessible clients, return empty results
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN JSONB_BUILD_OBJECT(
      'call_volume_by_day', '[]'::JSONB,
      'outcome_distribution', '[]'::JSONB,
      'emotion_distribution', '[]'::JSONB
    );
  END IF;

  -- Call volume by day
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'date', date,
      'total_calls', total_calls,
      'answered_calls', answered_calls,
      'appointments', appointments
    ) ORDER BY date
  ) INTO v_call_volume
  FROM (
    SELECT
      DATE(ac.started_at) AS date,
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND outcome IS NOT NULL) AS answered_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled') AS appointments
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY DATE(ac.started_at)
  ) sub;

  -- Outcome distribution
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'outcome', outcome,
      'count', count,
      'percentage', percentage
    ) ORDER BY count DESC
  ) INTO v_outcome_distribution
  FROM (
    SELECT
      COALESCE(ac.outcome, 'unknown') AS outcome,
      COUNT(*) AS count,
      ROUND((COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0)) * 100, 2) AS percentage
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY ac.outcome
  ) sub;

  -- Emotion distribution
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'emotion', emotion,
      'count', count,
      'percentage', percentage
    ) ORDER BY count DESC
  ) INTO v_emotion_distribution
  FROM (
    SELECT
      COALESCE(ac.emotion, 'unknown') AS emotion,
      COUNT(*) AS count,
      ROUND((COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0)) * 100, 2) AS percentage
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY ac.emotion
  ) sub;

  RETURN JSONB_BUILD_OBJECT(
    'call_volume_by_day', COALESCE(v_call_volume, '[]'::JSONB),
    'outcome_distribution', COALESCE(v_outcome_distribution, '[]'::JSONB),
    'emotion_distribution', COALESCE(v_emotion_distribution, '[]'::JSONB)
  );
END;
$$;

-- ============================================================================
-- 4. FUNCTION: get_client_cards_data (with p_client_ids param and admin bypass)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE(
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
SET search_path TO 'public'
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If no accessible clients, return empty
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH client_metrics AS (
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
    LEFT JOIN agent_deployments ad ON c.id = ad.client_id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    WHERE c.id = ANY(v_accessible_client_ids)
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

-- ============================================================================
-- 5. FUNCTION: get_agent_type_cards_data (with admin bypass)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_agent_type_cards_data(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE(
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
SET search_path TO 'public'
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If no accessible clients, return empty
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH agent_type_metrics AS (
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
    LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
    WHERE at.status = 'active'
      AND ad.client_id = ANY(v_accessible_client_ids)
    GROUP BY
      at.name,
      at.display_name
    HAVING COUNT(DISTINCT ad.id) > 0
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

-- ============================================================================
-- 6. FUNCTION: get_top_clients (with admin bypass + security fix)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_top_clients(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_ids UUID[] DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_result JSONB;
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If no accessible clients, return empty
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN '[]'::JSONB;
  END IF;

  SELECT JSONB_AGG(row_data)
  INTO v_result
  FROM (
    SELECT JSONB_BUILD_OBJECT(
      'client_id', c.id,
      'client_name', c.name,
      'industry', c.industry,
      'total_agents', COUNT(DISTINCT ad.id),
      'total_calls', COUNT(ac.id),
      'answered_calls', COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL),
      'appointments', COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled'),
      'conversion_rate', CASE
        WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) > 0
        THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled')::NUMERIC /
                    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC) * 100, 2)
        ELSE 0
      END,
      'total_cost', ROUND(COALESCE(SUM(ac.total_cost), 0), 2),
      'cost_per_appointment', CASE
        WHEN COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') > 0
        THEN ROUND(COALESCE(SUM(ac.total_cost), 0) / COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled'), 2)
        ELSE 0
      END,
      'last_call_at', MAX(ac.started_at)
    ) AS row_data,
    COUNT(ac.id) AS sort_key
    FROM clients c
    LEFT JOIN agent_deployments ad ON c.id = ad.client_id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
    WHERE c.id = ANY(v_accessible_client_ids)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    GROUP BY c.id, c.name, c.industry
    HAVING COUNT(ac.id) > 0
    ORDER BY sort_key DESC
    LIMIT p_limit
  ) sub;

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- ============================================================================
-- 7. FUNCTION: get_agent_type_performance (with admin bypass + security fix)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_agent_type_performance(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_result JSONB;
  v_7d_ago TIMESTAMP WITH TIME ZONE;
  v_is_admin BOOLEAN;
  v_accessible_client_ids UUID[];
BEGIN
  v_7d_ago := NOW() - INTERVAL '7 days';

  -- Check if current user is admin
  SELECT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) INTO v_is_admin;

  -- If admin AND p_client_ids provided, use p_client_ids directly (admin bypass)
  -- Otherwise, filter by auth.uid()'s accessible clients
  IF v_is_admin AND p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := p_client_ids;
  ELSE
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = auth.uid()
      AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));
  END IF;

  -- If no accessible clients, return empty
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN '[]'::JSONB;
  END IF;

  SELECT JSONB_AGG(row_data)
  INTO v_result
  FROM (
    SELECT JSONB_BUILD_OBJECT(
      'agent_type', at.name,
      'display_name', at.display_name,
      'total_deployments', COUNT(DISTINCT ad.id),
      'total_clients', COUNT(DISTINCT ad.client_id),
      'total_calls', COUNT(ac.id),
      'calls_last_7d', COUNT(ac.id) FILTER (WHERE ac.started_at >= v_7d_ago),
      'answer_rate', CASE
        WHEN COUNT(ac.id) > 0
        THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC / COUNT(ac.id)::NUMERIC) * 100, 2)
        ELSE 0
      END,
      'conversion_rate', CASE
        WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) > 0
        THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled')::NUMERIC /
                    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC) * 100, 2)
        ELSE 0
      END,
      'avg_duration', ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0), 0), 0),
      'total_cost', ROUND(COALESCE(SUM(ac.total_cost), 0), 2),
      'cost_per_appointment', CASE
        WHEN COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') > 0
        THEN ROUND(COALESCE(SUM(ac.total_cost), 0) / COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled'), 2)
        ELSE 0
      END
    ) AS row_data,
    COUNT(ac.id) AS sort_key
    FROM agent_types at
    LEFT JOIN agent_deployments ad ON at.id = ad.agent_type_id
      AND ad.client_id = ANY(v_accessible_client_ids)
    LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
    WHERE at.status = 'active'
    GROUP BY at.id, at.name, at.display_name
    HAVING COUNT(DISTINCT ad.id) > 0
    ORDER BY sort_key DESC
  ) sub;

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_agent_cards_data(DATE, DATE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_kpis(TIMESTAMPTZ, TIMESTAMPTZ, UUID[], UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_chart_data(TIMESTAMPTZ, TIMESTAMPTZ, UUID[], UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(DATE, DATE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_clients(TIMESTAMPTZ, TIMESTAMPTZ, UUID[], TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_type_performance(TIMESTAMPTZ, TIMESTAMPTZ, UUID[]) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Test as admin viewing as user:
-- SELECT * FROM get_agent_cards_data('2025-01-01', '2025-12-31', ARRAY['client-uuid-here']::uuid[]);
-- SELECT * FROM get_global_kpis('2025-01-01'::timestamptz, '2025-12-31'::timestamptz, ARRAY['client-uuid-here']::uuid[]);
-- SELECT * FROM get_client_cards_data('2025-01-01', '2025-12-31', ARRAY['client-uuid-here']::uuid[]);
-- SELECT * FROM get_agent_type_cards_data('2025-01-01', '2025-12-31', ARRAY['client-uuid-here']::uuid[]);
