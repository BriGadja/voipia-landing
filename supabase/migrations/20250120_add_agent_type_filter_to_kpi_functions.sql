-- Migration: Add agent type filtering to KPI and chart functions
-- Description: Ensures Louis dashboard shows ONLY Louis data, Arthur shows ONLY Arthur data
-- Date: 2025-01-20
-- Author: Claude
--
-- Problem: get_kpi_metrics and get_chart_data were returning ALL agents (Louis + Arthur)
-- Solution: Add p_agent_type_name parameter to filter by agent type

-- ==============================================================================
-- STEP 1: DROP EXISTING FUNCTIONS
-- ==============================================================================

DROP FUNCTION IF EXISTS get_kpi_metrics(DATE, DATE, UUID, UUID);
DROP FUNCTION IF EXISTS get_chart_data(DATE, DATE, UUID, UUID);


-- ==============================================================================
-- STEP 2: CREATE get_kpi_metrics WITH AGENT TYPE FILTER
-- ==============================================================================

CREATE FUNCTION get_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_period JSON;
  v_previous_period JSON;
  v_period_days INTEGER;
BEGIN
  -- Calculate period length for comparison
  v_period_days := p_end_date - p_start_date + 1;

  -- ============================================================================
  -- CURRENT PERIOD METRICS
  -- ============================================================================
  WITH current_calls AS (
    SELECT
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments_scheduled,
      COUNT(*) FILTER (WHERE outcome = 'RDV REFUSÉ') AS refused_appointments,
      COUNT(*) FILTER (WHERE outcome = 'CALLBACK' OR metadata ? 'callback_requested') AS callbacks_requested,
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,
      SUM(cost) AS total_cost
    FROM v_agent_calls_enriched ac
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      -- Filter by client if provided
      AND (p_client_id IS NULL OR ac.deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      -- Filter by specific deployment if provided
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      -- CRITICAL: Filter by agent type (louis, arthur, etc.)
      AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
        SELECT ad.id
        FROM agent_deployments ad
        INNER JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE at.name = p_agent_type_name
      ))
  )
  SELECT json_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'appointments_scheduled', COALESCE(appointments_scheduled, 0),
    'refused_appointments', COALESCE(refused_appointments, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),

    -- Answer rate = (answered_calls / total_calls) * 100
    'answer_rate', CASE
      WHEN total_calls > 0 THEN ROUND((answered_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,

    -- Conversion rate = (appointments_scheduled / answered_calls) * 100
    'conversion_rate', CASE
      WHEN answered_calls > 0 THEN ROUND((appointments_scheduled::NUMERIC / answered_calls * 100), 1)
      ELSE 0
    END,

    -- Acceptance rate = appointments / (appointments + refused) * 100
    'acceptance_rate', CASE
      WHEN (appointments_scheduled + refused_appointments) > 0
        THEN ROUND((appointments_scheduled::NUMERIC / (appointments_scheduled + refused_appointments) * 100), 1)
      ELSE 0
    END,

    -- Average duration (only for calls with duration > 0)
    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,

    -- Financial metrics
    'total_cost', COALESCE(total_cost, 0),
    'cost_per_appointment', CASE
      WHEN appointments_scheduled > 0 THEN ROUND(total_cost / appointments_scheduled, 2)
      ELSE 0
    END
  )
  INTO v_current_period
  FROM current_calls;

  -- ============================================================================
  -- PREVIOUS PERIOD METRICS (for comparison)
  -- ============================================================================
  WITH previous_calls AS (
    SELECT
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments_scheduled,
      COUNT(*) FILTER (WHERE outcome = 'RDV REFUSÉ') AS refused_appointments,
      COUNT(*) FILTER (WHERE outcome = 'CALLBACK' OR metadata ? 'callback_requested') AS callbacks_requested,
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,
      SUM(cost) AS total_cost
    FROM v_agent_calls_enriched ac
    WHERE ac.started_at >= (p_start_date - v_period_days * INTERVAL '1 day')
      AND ac.started_at < p_start_date
      AND (p_client_id IS NULL OR ac.deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
        SELECT ad.id
        FROM agent_deployments ad
        INNER JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE at.name = p_agent_type_name
      ))
  )
  SELECT json_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'appointments_scheduled', COALESCE(appointments_scheduled, 0),
    'refused_appointments', COALESCE(refused_appointments, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),

    'answer_rate', CASE
      WHEN total_calls > 0 THEN ROUND((answered_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,

    'conversion_rate', CASE
      WHEN answered_calls > 0 THEN ROUND((appointments_scheduled::NUMERIC / answered_calls * 100), 1)
      ELSE 0
    END,

    'acceptance_rate', CASE
      WHEN (appointments_scheduled + refused_appointments) > 0
        THEN ROUND((appointments_scheduled::NUMERIC / (appointments_scheduled + refused_appointments) * 100), 1)
      ELSE 0
    END,

    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,

    'total_cost', COALESCE(total_cost, 0),
    'cost_per_appointment', CASE
      WHEN appointments_scheduled > 0 THEN ROUND(total_cost / appointments_scheduled, 2)
      ELSE 0
    END
  )
  INTO v_previous_period
  FROM previous_calls;

  -- Return combined result
  RETURN json_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_kpi_metrics(DATE, DATE, UUID, UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION get_kpi_metrics IS
  'Calculate KPI metrics filtered by agent type. Louis dashboard passes ''louis'', Arthur passes ''arthur''.';


-- ==============================================================================
-- STEP 3: CREATE get_chart_data WITH AGENT TYPE FILTER
-- ==============================================================================

CREATE FUNCTION get_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  WITH
  -- Call volume by day
  call_volume AS (
    SELECT json_agg(
      json_build_object(
        'date', call_date::TEXT,
        'total_calls', total_calls,
        'answered_calls', answered_calls,
        'appointments', appointments
      ) ORDER BY call_date
    ) AS data
    FROM (
      SELECT
        DATE(ac.started_at) AS call_date,
        COUNT(*) AS total_calls,
        COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
        COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments
      FROM v_agent_calls_enriched ac
      WHERE ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR ac.deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
          SELECT ad.id
          FROM agent_deployments ad
          INNER JOIN agent_types at ON ad.agent_type_id = at.id
          WHERE at.name = p_agent_type_name
        ))
      GROUP BY DATE(ac.started_at)
      ORDER BY DATE(ac.started_at)
    ) daily_stats
  ),

  -- Outcome distribution
  outcome_dist AS (
    SELECT json_agg(
      json_build_object(
        'outcome', outcome,
        'count', count
      ) ORDER BY count DESC
    ) AS data
    FROM (
      SELECT
        ac.outcome,
        COUNT(*) AS count
      FROM v_agent_calls_enriched ac
      WHERE ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR ac.deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
          SELECT ad.id
          FROM agent_deployments ad
          INNER JOIN agent_types at ON ad.agent_type_id = at.id
          WHERE at.name = p_agent_type_name
        ))
        AND ac.outcome IS NOT NULL
      GROUP BY ac.outcome
      HAVING COUNT(*) > 0
    ) outcomes
  ),

  -- Emotion distribution
  emotion_dist AS (
    SELECT json_agg(
      json_build_object(
        'emotion', emotion,
        'count', count
      ) ORDER BY count DESC
    ) AS data
    FROM (
      SELECT
        COALESCE(ac.emotion, 'unknown') AS emotion,
        COUNT(*) AS count
      FROM v_agent_calls_enriched ac
      WHERE ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR ac.deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        AND (p_agent_type_name IS NULL OR ac.deployment_id IN (
          SELECT ad.id
          FROM agent_deployments ad
          INNER JOIN agent_types at ON ad.agent_type_id = at.id
          WHERE at.name = p_agent_type_name
        ))
      GROUP BY emotion
      HAVING COUNT(*) > 0
    ) emotions
  ),

  -- Voicemail rate by agent (only show agents of the specified type)
  voicemail_by_agent AS (
    SELECT json_agg(
      json_build_object(
        'agent', agent_name,
        'rate', voicemail_rate
      ) ORDER BY voicemail_rate DESC
    ) AS data
    FROM (
      SELECT
        ad.name AS agent_name,
        ROUND(
          (COUNT(*) FILTER (WHERE ac.outcome = 'VOICEMAIL')::NUMERIC /
           NULLIF(COUNT(*), 0) * 100),
          1
        ) AS voicemail_rate
      FROM agent_deployments ad
      INNER JOIN agent_types at ON ad.agent_type_id = at.id
      LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
        AND ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date + INTERVAL '1 day'
      WHERE (p_client_id IS NULL OR ad.client_id = p_client_id)
        AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
        AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      GROUP BY ad.id, ad.name
      HAVING COUNT(*) > 0
    ) agent_stats
  )

  SELECT json_build_object(
    'call_volume_by_day', COALESCE((SELECT data FROM call_volume), '[]'::json),
    'outcome_distribution', COALESCE((SELECT data FROM outcome_dist), '[]'::json),
    'emotion_distribution', COALESCE((SELECT data FROM emotion_dist), '[]'::json),
    'voicemail_by_agent', COALESCE((SELECT data FROM voicemail_by_agent), '[]'::json)
  )
  INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_chart_data(DATE, DATE, UUID, UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION get_chart_data IS
  'Get chart data filtered by agent type. Louis dashboard passes ''louis'', Arthur passes ''arthur''.';


-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Test Louis KPIs (should only show Louis data)
-- SELECT get_kpi_metrics('2025-01-01', '2025-01-20', NULL, NULL, 'louis');

-- Test Arthur KPIs (should only show Arthur data)
-- SELECT get_kpi_metrics('2025-01-01', '2025-01-20', NULL, NULL, 'arthur');

-- Test Louis chart data
-- SELECT get_chart_data('2025-01-01', '2025-01-20', NULL, NULL, 'louis');

-- Verify agent type filtering works
-- SELECT
--   at.name as agent_type,
--   COUNT(*) as call_count
-- FROM v_agent_calls_enriched ac
-- INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
-- INNER JOIN agent_types at ON ad.agent_type_id = at.id
-- GROUP BY at.name;
