-- Migration: Performance Dashboard Functions
-- Date: 2025-11-26
-- Description: Updates RPC functions to support array client_ids and creates new functions for Performance page
-- Changes:
--   1. Update get_global_kpis to accept p_client_ids array
--   2. Update get_global_chart_data to accept p_client_ids array
--   3. Create get_top_clients function with date filtering
--   4. Create get_agent_type_performance function with date filtering
--
-- Tested in staging: 2025-11-26 - All functions working correctly

-- ============================================================================
-- 1. UPDATE get_global_kpis - Support array of client IDs
-- ============================================================================
DROP FUNCTION IF EXISTS get_global_kpis(timestamp with time zone, timestamp with time zone, uuid, uuid, text);
DROP FUNCTION IF EXISTS get_global_kpis(timestamp with time zone, timestamp with time zone, uuid[], uuid, text);

CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_duration INTERVAL;
BEGIN
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
  LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= p_start_date
    AND ac.started_at <= p_end_date
    AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
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
  LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at >= (p_start_date - v_period_duration)
    AND ac.started_at < p_start_date
    AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name);

  RETURN JSONB_BUILD_OBJECT(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

-- ============================================================================
-- 2. UPDATE get_global_chart_data - Support array of client IDs
-- ============================================================================
DROP FUNCTION IF EXISTS get_global_chart_data(timestamp with time zone, timestamp with time zone, uuid, uuid, text);
DROP FUNCTION IF EXISTS get_global_chart_data(timestamp with time zone, timestamp with time zone, uuid[], uuid, text);

CREATE OR REPLACE FUNCTION get_global_chart_data(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
BEGIN
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
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
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
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
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
    LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
    LEFT JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
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
-- 3. CREATE get_top_clients - Returns top clients with date filtering
-- ============================================================================
DROP FUNCTION IF EXISTS get_top_clients(timestamp with time zone, timestamp with time zone, uuid[], text, integer);

CREATE OR REPLACE FUNCTION get_top_clients(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
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
    WHERE (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
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
-- 4. CREATE get_agent_type_performance - Returns agent type performance with date filtering
-- ============================================================================
DROP FUNCTION IF EXISTS get_agent_type_performance(timestamp with time zone, timestamp with time zone, uuid[]);

CREATE OR REPLACE FUNCTION get_agent_type_performance(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_7d_ago TIMESTAMP WITH TIME ZONE;
BEGIN
  v_7d_ago := NOW() - INTERVAL '7 days';

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
      AND (p_client_ids IS NULL OR ad.client_id = ANY(p_client_ids))
    LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
    WHERE at.status = 'active'
    GROUP BY at.id, at.name, at.display_name
    ORDER BY sort_key DESC
  ) sub;

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;

-- ============================================================================
-- GRANTS - Allow authenticated users to call these functions
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_global_kpis(timestamp with time zone, timestamp with time zone, uuid[], uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_chart_data(timestamp with time zone, timestamp with time zone, uuid[], uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_clients(timestamp with time zone, timestamp with time zone, uuid[], text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_type_performance(timestamp with time zone, timestamp with time zone, uuid[]) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES (run these to test after migration)
-- ============================================================================
-- SELECT get_global_kpis('2025-01-01'::timestamptz, '2025-12-31'::timestamptz, NULL, NULL, NULL);
-- SELECT get_global_chart_data('2025-01-01'::timestamptz, '2025-12-31'::timestamptz, NULL, NULL, NULL);
-- SELECT get_top_clients('2025-01-01'::timestamptz, '2025-12-31'::timestamptz, NULL, NULL, 10);
-- SELECT get_agent_type_performance('2025-01-01'::timestamptz, '2025-12-31'::timestamptz, NULL);
