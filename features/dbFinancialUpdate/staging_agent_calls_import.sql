CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
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
      SUM(total_cost) AS total_cost
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
      SUM(total_cost) AS total_cost
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
