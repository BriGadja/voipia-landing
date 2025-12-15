-- Migration: Louis-Nestenn Dashboard Functions
-- Date: 2025-12-15
-- Description: Create KPI and chart functions for Louis-Nestenn qualification dashboard
--
-- Nestenn is different from standard Louis:
-- - Focus on lead QUALIFICATION, not RDV booking
-- - Main success metric: appointment_requested (transfer to human)
-- - Outcomes: voicemail, appointment_requested, callback_requested, no_answer, null
-- - KPIs: contact_rate, qualification_rate, transfers_requested, cost_per_transfer

-- ============================================================================
-- FUNCTION: get_louis_nestenn_kpis
-- Returns KPI metrics for Louis-Nestenn qualification dashboard
-- ============================================================================

DROP FUNCTION IF EXISTS get_louis_nestenn_kpis(DATE, DATE, UUID, UUID);

CREATE OR REPLACE FUNCTION get_louis_nestenn_kpis(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_current JSONB;
  v_previous JSONB;
  v_period_length INT;
  v_prev_start DATE;
  v_prev_end DATE;
BEGIN
  -- Calculate period length and previous period dates
  v_period_length := p_end_date - p_start_date + 1;
  v_prev_end := p_start_date - INTERVAL '1 day';
  v_prev_start := v_prev_end - (v_period_length - 1) * INTERVAL '1 day';

  -- Current period metrics
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      -- Security: Check user permissions
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  current_metrics AS (
    SELECT
      COUNT(*)::INT AS total_calls,
      COUNT(*) FILTER (WHERE outcome NOT IN ('no_answer', 'voicemail') OR outcome IS NULL AND duration_seconds > 10)::INT AS contacted_calls,
      COUNT(*) FILTER (WHERE duration_seconds > 10)::INT AS answered_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT AS transfers_requested,
      COUNT(*) FILTER (WHERE outcome = 'callback_requested')::INT AS callbacks_requested,
      COUNT(*) FILTER (WHERE outcome = 'voicemail')::INT AS voicemails,
      COUNT(*) FILTER (WHERE outcome = 'no_answer')::INT AS no_answers,
      COUNT(*) FILTER (WHERE outcome = 'not_interested')::INT AS not_interested,
      ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 1)::NUMERIC AS avg_duration,
      ROUND(SUM(COALESCE(total_cost, 0))::NUMERIC, 2) AS sum_cost
    FROM nestenn_calls
  )
  SELECT jsonb_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'contacted_calls', COALESCE(contacted_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'transfers_requested', COALESCE(transfers_requested, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),
    'voicemails', COALESCE(voicemails, 0),
    'no_answers', COALESCE(no_answers, 0),
    'not_interested', COALESCE(not_interested, 0),
    'appointments_scheduled', COALESCE(transfers_requested, 0), -- Alias for compatibility
    'contact_rate', CASE
      WHEN COALESCE(total_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(contacted_calls, 0)::NUMERIC / total_calls * 100), 1)
    END,
    'answer_rate', CASE
      WHEN COALESCE(total_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(answered_calls, 0)::NUMERIC / total_calls * 100), 1)
    END,
    'qualification_rate', CASE
      WHEN COALESCE(answered_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(transfers_requested, 0)::NUMERIC / answered_calls * 100), 1)
    END,
    'conversion_rate', CASE
      WHEN COALESCE(answered_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(transfers_requested, 0)::NUMERIC / answered_calls * 100), 1)
    END,
    'avg_duration', COALESCE(avg_duration, 0),
    'total_cost', COALESCE(sum_cost, 0),
    'cost_per_transfer', CASE
      WHEN COALESCE(transfers_requested, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(sum_cost, 0) / transfers_requested), 2)
    END,
    'cost_per_appointment', CASE
      WHEN COALESCE(transfers_requested, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(sum_cost, 0) / transfers_requested), 2)
    END
  ) INTO v_current
  FROM current_metrics;

  -- Previous period metrics
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN v_prev_start AND v_prev_end
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  previous_metrics AS (
    SELECT
      COUNT(*)::INT AS total_calls,
      COUNT(*) FILTER (WHERE outcome NOT IN ('no_answer', 'voicemail') OR outcome IS NULL AND duration_seconds > 10)::INT AS contacted_calls,
      COUNT(*) FILTER (WHERE duration_seconds > 10)::INT AS answered_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT AS transfers_requested,
      COUNT(*) FILTER (WHERE outcome = 'callback_requested')::INT AS callbacks_requested,
      COUNT(*) FILTER (WHERE outcome = 'voicemail')::INT AS voicemails,
      COUNT(*) FILTER (WHERE outcome = 'no_answer')::INT AS no_answers,
      COUNT(*) FILTER (WHERE outcome = 'not_interested')::INT AS not_interested,
      ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 1)::NUMERIC AS avg_duration,
      ROUND(SUM(COALESCE(total_cost, 0))::NUMERIC, 2) AS sum_cost
    FROM nestenn_calls
  )
  SELECT jsonb_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'contacted_calls', COALESCE(contacted_calls, 0),
    'answered_calls', COALESCE(answered_calls, 0),
    'transfers_requested', COALESCE(transfers_requested, 0),
    'callbacks_requested', COALESCE(callbacks_requested, 0),
    'voicemails', COALESCE(voicemails, 0),
    'no_answers', COALESCE(no_answers, 0),
    'not_interested', COALESCE(not_interested, 0),
    'appointments_scheduled', COALESCE(transfers_requested, 0),
    'contact_rate', CASE
      WHEN COALESCE(total_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(contacted_calls, 0)::NUMERIC / total_calls * 100), 1)
    END,
    'answer_rate', CASE
      WHEN COALESCE(total_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(answered_calls, 0)::NUMERIC / total_calls * 100), 1)
    END,
    'qualification_rate', CASE
      WHEN COALESCE(answered_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(transfers_requested, 0)::NUMERIC / answered_calls * 100), 1)
    END,
    'conversion_rate', CASE
      WHEN COALESCE(answered_calls, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(transfers_requested, 0)::NUMERIC / answered_calls * 100), 1)
    END,
    'avg_duration', COALESCE(avg_duration, 0),
    'total_cost', COALESCE(sum_cost, 0),
    'cost_per_transfer', CASE
      WHEN COALESCE(transfers_requested, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(sum_cost, 0) / transfers_requested), 2)
    END,
    'cost_per_appointment', CASE
      WHEN COALESCE(transfers_requested, 0) = 0 THEN 0
      ELSE ROUND((COALESCE(sum_cost, 0) / transfers_requested), 2)
    END
  ) INTO v_previous
  FROM previous_metrics;

  -- Build result
  v_result := jsonb_build_object(
    'current_period', v_current,
    'previous_period', v_previous
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_louis_nestenn_kpis(DATE, DATE, UUID, UUID) TO authenticated;

-- ============================================================================
-- FUNCTION: get_louis_nestenn_charts
-- Returns chart data for Louis-Nestenn qualification dashboard
-- ============================================================================

DROP FUNCTION IF EXISTS get_louis_nestenn_charts(DATE, DATE, UUID, UUID);

CREATE OR REPLACE FUNCTION get_louis_nestenn_charts(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_call_volume JSONB;
  v_outcome_dist JSONB;
  v_emotion_dist JSONB;
  v_duration_by_outcome JSONB;
  v_funnel JSONB;
  v_by_owner JSONB;
BEGIN
  -- Base CTE for Nestenn calls
  -- Call volume by day
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  daily_volume AS (
    SELECT
      created_at::date AS date,
      COUNT(*)::INT AS total_calls,
      COUNT(*) FILTER (WHERE duration_seconds > 10)::INT AS answered_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT AS appointments,
      COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT AS transfers
    FROM nestenn_calls
    GROUP BY created_at::date
    ORDER BY date
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'date', to_char(date, 'YYYY-MM-DD'),
      'total_calls', total_calls,
      'answered_calls', answered_calls,
      'appointments', appointments,
      'transfers', transfers
    )
  ), '[]'::jsonb) INTO v_call_volume
  FROM daily_volume;

  -- Outcome distribution
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  outcome_counts AS (
    SELECT
      COALESCE(outcome, 'unknown') AS outcome,
      COUNT(*)::INT AS count,
      ROUND(SUM(COALESCE(total_cost, 0))::NUMERIC, 2) AS sum_cost,
      ROUND(AVG(duration_seconds)::NUMERIC, 1) AS avg_duration
    FROM nestenn_calls
    GROUP BY outcome
  ),
  total AS (
    SELECT SUM(count)::INT AS total FROM outcome_counts
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'outcome', oc.outcome,
      'count', oc.count,
      'percentage', CASE WHEN t.total = 0 THEN 0 ELSE ROUND((oc.count::NUMERIC / t.total * 100), 1) END,
      'total_cost', oc.sum_cost,
      'avg_duration', oc.avg_duration
    )
  ), '[]'::jsonb) INTO v_outcome_dist
  FROM outcome_counts oc, total t;

  -- Emotion distribution (only for answered calls)
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND ac.duration_seconds > 10  -- Only answered calls
      AND ac.emotion IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  emotion_counts AS (
    SELECT
      COALESCE(emotion, 'unknown') AS emotion,
      COUNT(*)::INT AS count
    FROM nestenn_calls
    GROUP BY emotion
  ),
  total AS (
    SELECT SUM(count)::INT AS total FROM emotion_counts
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'emotion', ec.emotion,
      'count', ec.count,
      'percentage', CASE WHEN t.total = 0 THEN 0 ELSE ROUND((ec.count::NUMERIC / t.total * 100), 1) END
    )
  ), '[]'::jsonb) INTO v_emotion_dist
  FROM emotion_counts ec, total t;

  -- Duration by outcome (for horizontal bar chart)
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND ac.duration_seconds > 0
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  duration_by_outcome AS (
    SELECT
      COALESCE(outcome, 'unknown') AS outcome,
      ROUND(AVG(duration_seconds)::NUMERIC, 1) AS avg_duration,
      COUNT(*)::INT AS count
    FROM nestenn_calls
    GROUP BY outcome
    ORDER BY avg_duration DESC
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'outcome', outcome,
      'avg_duration', avg_duration,
      'count', count,
      'color', CASE outcome
        WHEN 'appointment_requested' THEN '#10b981'
        WHEN 'callback_requested' THEN '#3b82f6'
        WHEN 'voicemail' THEN '#f59e0b'
        WHEN 'no_answer' THEN '#6b7280'
        WHEN 'not_interested' THEN '#ef4444'
        ELSE '#8b5cf6'
      END
    )
  ), '[]'::jsonb) INTO v_duration_by_outcome
  FROM duration_by_outcome;

  -- Funnel data
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  )
  SELECT jsonb_build_object(
    'total_calls', COUNT(*)::INT,
    'contacted', COUNT(*) FILTER (WHERE outcome NOT IN ('no_answer') OR duration_seconds > 0)::INT,
    'answered', COUNT(*) FILTER (WHERE duration_seconds > 10)::INT,
    'qualified', COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT
  ) INTO v_funnel
  FROM nestenn_calls;

  -- RDV by Owner (agent immobilier) - Uses metadata->>'owner'
  WITH nestenn_calls AS (
    SELECT
      ac.*
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.created_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
      AND EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.client_id = ad.client_id
        AND ucp.user_id = auth.uid()
      )
  ),
  owner_stats AS (
    SELECT
      COALESCE(metadata->>'owner', 'Non assigné') AS owner,
      COUNT(*)::INT AS total_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_requested')::INT AS rdv_count
    FROM nestenn_calls
    WHERE metadata->>'owner' IS NOT NULL
    GROUP BY metadata->>'owner'
    HAVING COUNT(*) FILTER (WHERE outcome = 'appointment_requested') > 0
    ORDER BY rdv_count DESC
    LIMIT 10
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'owner', owner,
      'total_calls', total_calls,
      'rdv_count', rdv_count,
      'conversion_rate', CASE WHEN total_calls = 0 THEN 0 ELSE ROUND((rdv_count::NUMERIC / total_calls * 100), 1) END
    )
  ), '[]'::jsonb) INTO v_by_owner
  FROM owner_stats;

  -- Build result
  v_result := jsonb_build_object(
    'call_volume_by_day', v_call_volume,
    'outcome_distribution', v_outcome_dist,
    'emotion_distribution', v_emotion_dist,
    'duration_by_outcome', v_duration_by_outcome,
    'funnel_data', v_funnel,
    'by_owner', v_by_owner
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_louis_nestenn_charts(DATE, DATE, UUID, UUID) TO authenticated;

-- ============================================================================
-- Verification queries (commented out)
-- ============================================================================

-- Test KPIs:
-- SELECT get_louis_nestenn_kpis('2025-12-01'::date, '2025-12-15'::date, NULL, 'f3ab177f-802c-485d-ae58-403131a5a51d'::uuid);

-- Test Charts:
-- SELECT get_louis_nestenn_charts('2025-12-01'::date, '2025-12-15'::date, NULL, 'f3ab177f-802c-485d-ae58-403131a5a51d'::uuid);
