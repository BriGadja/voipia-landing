-- Migration: Fix user permissions filtering for dashboard security
-- Date: 2025-11-27
-- Changes:
--   1. Add Yassine (yassine@norloc.co) to Norloc client permissions (READ ONLY)
--   2. Fix get_agent_cards_data to filter by auth.uid()
--   3. Fix get_global_kpis to filter by user-accessible clients
--   4. Fix get_global_chart_data to filter by user-accessible clients
--
-- Problem: Functions were returning data for ALL clients/agents instead of
--          only those accessible by the authenticated user.

-- ============================================================================
-- 1. ADD YASSINE TO NORLOC PERMISSIONS (READ ONLY)
-- ============================================================================

INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES (
  '2c9cc13f-6732-430b-a5c3-5ac52ccaa0f3',  -- Yassine user_id
  'e63beaf9-2e3c-44e9-8f5d-5d063cac82fd',  -- Norloc client_id
  'read'  -- Read only - not admin
)
ON CONFLICT (user_id, client_id) DO UPDATE SET permission_level = 'read';

-- ============================================================================
-- 2. FIX get_agent_cards_data - Add auth.uid() filtering
-- ============================================================================

DROP FUNCTION IF EXISTS get_agent_cards_data(date, date, uuid[]);

CREATE OR REPLACE FUNCTION get_agent_cards_data(
  p_start_date date,
  p_end_date date,
  p_client_ids uuid[] DEFAULT NULL
)
RETURNS TABLE(
  deployment_id uuid,
  deployment_name text,
  slug text,
  agent_type_name text,
  agent_display_name text,
  client_name text,
  total_calls bigint,
  answered_calls bigint,
  appointments_scheduled bigint,
  answer_rate numeric,
  conversion_rate numeric,
  avg_duration numeric,
  total_cost numeric,
  last_call_at timestamptz,
  deployment_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH user_accessible_agents AS (
    -- Get agents accessible by the authenticated user via RLS
    -- FIXED: Filter explicitly by auth.uid() since SECURITY DEFINER bypasses RLS
    SELECT DISTINCT a.deployment_id
    FROM v_user_accessible_agents a
    WHERE a.user_id = auth.uid()
      AND (p_client_ids IS NULL OR a.client_id = ANY(p_client_ids))
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
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
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

GRANT EXECUTE ON FUNCTION get_agent_cards_data(date, date, uuid[]) TO authenticated;

-- ============================================================================
-- 3. FIX get_global_kpis - Add user filtering
-- ============================================================================

DROP FUNCTION IF EXISTS get_global_kpis(timestamptz, timestamptz, uuid[], uuid, text);

CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date timestamptz,
  p_end_date timestamptz,
  p_client_ids uuid[] DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_duration INTERVAL;
  v_accessible_client_ids uuid[];
BEGIN
  -- Get user-accessible client IDs
  -- If p_client_ids is provided, intersect with user's accessible clients
  -- Otherwise, use all user-accessible clients
  SELECT ARRAY_AGG(DISTINCT ucp.client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions ucp
  WHERE ucp.user_id = auth.uid()
    AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));

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

GRANT EXECUTE ON FUNCTION get_global_kpis(timestamptz, timestamptz, uuid[], uuid, text) TO authenticated;

-- ============================================================================
-- 4. FIX get_global_chart_data - Add user filtering
-- ============================================================================

DROP FUNCTION IF EXISTS get_global_chart_data(timestamptz, timestamptz, uuid[], uuid, text);

CREATE OR REPLACE FUNCTION get_global_chart_data(
  p_start_date timestamptz,
  p_end_date timestamptz,
  p_client_ids uuid[] DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
  v_accessible_client_ids uuid[];
BEGIN
  -- Get user-accessible client IDs
  SELECT ARRAY_AGG(DISTINCT ucp.client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions ucp
  WHERE ucp.user_id = auth.uid()
    AND (p_client_ids IS NULL OR ucp.client_id = ANY(p_client_ids));

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

GRANT EXECUTE ON FUNCTION get_global_chart_data(timestamptz, timestamptz, uuid[], uuid, text) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES (run after migration to confirm)
-- ============================================================================

-- Verify Yassine has READ permission:
-- SELECT * FROM user_client_permissions WHERE user_id = '2c9cc13f-6732-430b-a5c3-5ac52ccaa0f3';

-- Test get_agent_cards_data returns only user's agents:
-- SET request.jwt.claims TO '{"sub": "2c9cc13f-6732-430b-a5c3-5ac52ccaa0f3"}';
-- SELECT * FROM get_agent_cards_data(CURRENT_DATE - 30, CURRENT_DATE);
