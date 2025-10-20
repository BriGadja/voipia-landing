-- Migration: Fix KPI logic and calculations
-- Description: Corrects the definition of "answered" calls and KPI calculation formulas
-- Date: 2025-01-20
-- Author: Claude
--
-- Issues fixed:
-- 1. "Answered" definition: Should be total_calls - (voicemails + errors)
-- 2. Conversion rate > 100%: Fixed formula to use answered_calls as denominator
-- 3. RDV pris > Appels répondus: Fixed by correcting answered definition
-- 4. Answer rate too low: Fixed by using correct outcome categories

-- ==============================================================================
-- VIEW: v_agent_calls_enriched (CORRECTED)
-- Description: Fixed logic for determining answered calls
-- ==============================================================================

CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT
  ac.*,

  -- Calculate if call was answered
  -- Answered = person picked up (NOT voicemail, NOT error)
  -- Logic: If outcome is NOT one of the "not answered" outcomes, then it was answered
  CASE
    -- Explicit NOT answered outcomes (voicemail, errors, no answer)
    WHEN ac.outcome IN (
      'VOICEMAIL',           -- Messagerie
      'NO_ANSWER',           -- Pas de réponse
      'BUSY',                -- Occupé
      'FAILED',              -- Échec
      'INVALID_NUMBER',      -- Numéro invalide
      'ERROR',               -- Erreur
      'CANCELED',            -- Annulé
      'REJECTED'             -- Rejeté
    ) THEN false

    -- All other outcomes mean the call was answered
    -- (RDV PRIS, RDV REFUSÉ, CALLBACK, NOT_INTERESTED, ALREADY_CLIENT, TOO_CONF, etc.)
    ELSE true
  END AS answered,

  -- Calculate if appointment was scheduled
  CASE
    -- Explicit outcome
    WHEN ac.outcome = 'RDV PRIS'
      THEN true

    -- Check metadata for appointment_scheduled_at
    WHEN ac.metadata IS NOT NULL AND ac.metadata ? 'appointment_scheduled_at'
      THEN true

    ELSE false
  END AS appointment_scheduled

FROM agent_calls ac;

-- Add comment for documentation
COMMENT ON VIEW v_agent_calls_enriched IS
  'Enriched view of agent_calls with corrected answered logic. Answered = NOT (voicemail or error). Does not modify the base table.';

-- Grant SELECT to authenticated users
GRANT SELECT ON v_agent_calls_enriched TO authenticated;


-- ==============================================================================
-- FUNCTION: get_kpi_metrics
-- Description: Calculate KPI metrics with correct formulas
-- Returns: Current period and previous period comparison
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
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
    FROM v_agent_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
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
    -- NOT divided by total_calls! This was the bug causing >100% conversion
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
    FROM v_agent_calls_enriched
    WHERE started_at >= (p_start_date - v_period_days * INTERVAL '1 day')
      AND started_at < p_start_date
      AND (p_client_id IS NULL OR deployment_id IN (
        SELECT id FROM agent_deployments WHERE client_id = p_client_id
      ))
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_kpi_metrics(DATE, DATE, UUID, UUID) TO authenticated;

COMMENT ON FUNCTION get_kpi_metrics IS
  'Calculate KPI metrics with corrected formulas. Conversion rate = appointments/answered_calls (not total_calls).';


-- ==============================================================================
-- FUNCTION: get_chart_data
-- Description: Get chart data for dashboard with corrected logic
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
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
        DATE(started_at) AS call_date,
        COUNT(*) AS total_calls,
        COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
        COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments
      FROM v_agent_calls_enriched
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY DATE(started_at)
      ORDER BY DATE(started_at)
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
        outcome,
        COUNT(*) AS count
      FROM v_agent_calls_enriched
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
        AND outcome IS NOT NULL
      GROUP BY outcome
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
        COALESCE(emotion, 'unknown') AS emotion,
        COUNT(*) AS count
      FROM v_agent_calls_enriched
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date + INTERVAL '1 day'
        AND (p_client_id IS NULL OR deployment_id IN (
          SELECT id FROM agent_deployments WHERE client_id = p_client_id
        ))
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY emotion
      HAVING COUNT(*) > 0
    ) emotions
  ),

  -- Voicemail rate by agent
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
      LEFT JOIN v_agent_calls_enriched ac ON ad.id = ac.deployment_id
        AND ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date + INTERVAL '1 day'
      WHERE (p_client_id IS NULL OR ad.client_id = p_client_id)
        AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_chart_data(DATE, DATE, UUID, UUID) TO authenticated;

COMMENT ON FUNCTION get_chart_data IS
  'Get chart data for dashboard with corrected answered call logic and KPI calculations.';


-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Check the distribution of answered vs not answered
-- SELECT
--   answered,
--   COUNT(*) as count,
--   ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) as percentage
-- FROM v_agent_calls_enriched
-- GROUP BY answered;

-- Check outcomes that are considered "not answered"
-- SELECT
--   outcome,
--   COUNT(*) as count,
--   answered
-- FROM v_agent_calls_enriched
-- WHERE outcome IN ('VOICEMAIL', 'NO_ANSWER', 'BUSY', 'FAILED', 'INVALID_NUMBER')
-- GROUP BY outcome, answered
-- ORDER BY outcome;

-- Test KPI calculation for a specific period
-- SELECT get_kpi_metrics('2025-01-01', '2025-01-20', NULL, NULL);

-- Test chart data for a specific period
-- SELECT get_chart_data('2025-01-01', '2025-01-20', NULL, NULL);
