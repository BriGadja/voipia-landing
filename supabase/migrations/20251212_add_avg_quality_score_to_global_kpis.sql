-- Migration: Add avg_quality_score to get_global_kpis
-- Date: 2025-12-12
-- Changes: Add average call_quality_score to the KPIs returned by get_global_kpis

DROP FUNCTION IF EXISTS get_global_kpis(DATE, DATE, UUID[], UUID, TEXT);

CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
        'cost_per_appointment', 0,
        'avg_quality_score', 0
      ),
      'previous_period', JSONB_BUILD_OBJECT(
        'total_calls', 0,
        'answered_calls', 0,
        'appointments_scheduled', 0,
        'answer_rate', 0,
        'conversion_rate', 0,
        'avg_duration', 0,
        'total_cost', 0,
        'cost_per_appointment', 0,
        'avg_quality_score', 0
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
    END,
    'avg_quality_score', ROUND(COALESCE(AVG(call_quality_score) FILTER (WHERE call_quality_score IS NOT NULL), 0), 0)
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
    END,
    'avg_quality_score', ROUND(COALESCE(AVG(call_quality_score) FILTER (WHERE call_quality_score IS NOT NULL), 0), 0)
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

GRANT EXECUTE ON FUNCTION get_global_kpis(DATE, DATE, UUID[], UUID, TEXT) TO authenticated;
