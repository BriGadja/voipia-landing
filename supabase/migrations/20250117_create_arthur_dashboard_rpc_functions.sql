-- Migration: Create Arthur Dashboard RPC Functions
-- Description: Creates 2 RPC functions to fetch KPIs and chart data with dynamic filters
-- Author: Claude Code
-- Date: 2025-01-17

-- ============================================================================
-- RPC Function 1: get_arthur_kpi_metrics
-- Fetches KPI metrics with current and previous period comparison
-- Supports dynamic date ranges and client/agent filters
-- ============================================================================

CREATE OR REPLACE FUNCTION get_arthur_kpi_metrics(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid DEFAULT NULL,
  p_agent_type_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_period_days integer;
BEGIN
  -- Calculate period length in days
  v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

  WITH current_period AS (
    SELECT
      COUNT(DISTINCT prospect_id) AS total_prospects,
      COUNT(DISTINCT CASE WHEN derived_status = 'converted' THEN prospect_id END) AS conversions,
      COUNT(DISTINCT call_id) AS total_calls,
      COUNT(DISTINCT CASE WHEN answered = true THEN call_id END) AS answered_calls,
      COUNT(DISTINCT CASE WHEN appointment_scheduled_at IS NOT NULL THEN call_id END) AS appointments_scheduled,
      COALESCE(SUM(cost), 0) AS total_cost,
      COALESCE(AVG(duration_seconds), 0) AS avg_duration,
      COALESCE(
        AVG(
          CASE
            WHEN current_attempt = 1 AND answered = true THEN 1
            WHEN current_attempt = 1 THEN 0
            ELSE NULL
          END
        ),
        0
      ) AS answer_rate_attempt_1
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
  ),
  previous_period AS (
    SELECT
      COUNT(DISTINCT prospect_id) AS total_prospects,
      COUNT(DISTINCT CASE WHEN derived_status = 'converted' THEN prospect_id END) AS conversions,
      COUNT(DISTINCT call_id) AS total_calls,
      COUNT(DISTINCT CASE WHEN answered = true THEN call_id END) AS answered_calls,
      COUNT(DISTINCT CASE WHEN appointment_scheduled_at IS NOT NULL THEN call_id END) AS appointments_scheduled,
      COALESCE(SUM(cost), 0) AS total_cost,
      COALESCE(AVG(duration_seconds), 0) AS avg_duration,
      COALESCE(
        AVG(
          CASE
            WHEN current_attempt = 1 AND answered = true THEN 1
            WHEN current_attempt = 1 THEN 0
            ELSE NULL
          END
        ),
        0
      ) AS answer_rate_attempt_1
    FROM v_arthur_calls_enriched
    WHERE started_at >= (p_start_date - (v_period_days || ' days')::interval)
      AND started_at < p_start_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
  )
  SELECT jsonb_build_object(
    'current_period', jsonb_build_object(
      'reactivation_rate',
      CASE
        WHEN cp.total_prospects > 0
        THEN ROUND((cp.conversions::numeric / cp.total_prospects::numeric) * 100, 2)
        ELSE 0
      END,
      'cost_per_conversion',
      CASE
        WHEN cp.conversions > 0
        THEN ROUND(cp.total_cost / cp.conversions, 2)
        ELSE 0
      END,
      'avg_duration_per_attempt',
      ROUND(cp.avg_duration, 0),
      'appointments_scheduled',
      cp.appointments_scheduled,
      'answer_rate_attempt_1',
      ROUND(cp.answer_rate_attempt_1 * 100, 2)
    ),
    'previous_period', jsonb_build_object(
      'reactivation_rate',
      CASE
        WHEN pp.total_prospects > 0
        THEN ROUND((pp.conversions::numeric / pp.total_prospects::numeric) * 100, 2)
        ELSE 0
      END,
      'cost_per_conversion',
      CASE
        WHEN pp.conversions > 0
        THEN ROUND(pp.total_cost / pp.conversions, 2)
        ELSE 0
      END,
      'avg_duration_per_attempt',
      ROUND(pp.avg_duration, 0),
      'appointments_scheduled',
      pp.appointments_scheduled,
      'answer_rate_attempt_1',
      ROUND(pp.answer_rate_attempt_1 * 100, 2)
    )
  ) INTO v_result
  FROM current_period cp
  CROSS JOIN previous_period pp;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_arthur_kpi_metrics IS 'Fetches Arthur dashboard KPI metrics with current and previous period comparison. Supports date range and client/agent_type filters.';


-- ============================================================================
-- RPC Function 2: get_arthur_chart_data
-- Fetches data for all 4 dashboard charts with dynamic filters
-- Returns: call_volume_by_day, conversion_funnel, outcome_distribution, segment_performance
-- ============================================================================

CREATE OR REPLACE FUNCTION get_arthur_chart_data(
  p_start_date timestamp with time zone,
  p_end_date timestamp with time zone,
  p_client_id uuid DEFAULT NULL,
  p_agent_type_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  WITH call_volume_by_day AS (
    SELECT
      DATE(started_at) AS day,
      attempt_label,
      COUNT(*) AS count
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
    GROUP BY DATE(started_at), attempt_label, current_attempt
    ORDER BY day, current_attempt
  ),
  conversion_funnel AS (
    SELECT
      attempt_label,
      current_attempt,
      COUNT(*) AS total_calls,
      COUNT(CASE WHEN answered = true THEN 1 END) AS answered_calls,
      COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END) AS conversions,
      ROUND(
        (COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100,
        2
      ) AS conversion_rate
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
    GROUP BY attempt_label, current_attempt
    ORDER BY current_attempt
  ),
  outcome_distribution AS (
    SELECT
      CASE
        WHEN call_outcome = 'appointment_scheduled' OR appointment_scheduled_at IS NOT NULL THEN 'Converti'
        WHEN call_outcome = 'callback_requested' THEN 'Callback'
        WHEN call_outcome = 'not_interested' OR call_outcome = 'appointment_refused' THEN 'Pas intéressé'
        WHEN call_outcome = 'do_not_call' THEN 'Ne pas rappeler'
        WHEN call_outcome = 'voicemail' OR answered = false THEN 'Messagerie'
        ELSE 'Autre'
      END AS outcome,
      COUNT(*) AS count
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
    GROUP BY outcome
    ORDER BY count DESC
  ),
  segment_performance AS (
    SELECT
      COALESCE(ai_segment, 'Non segmenté') AS segment,
      COUNT(*) AS total_calls,
      COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END) AS conversions,
      ROUND(
        (COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100,
        2
      ) AS conversion_rate
    FROM v_arthur_calls_enriched
    WHERE started_at >= p_start_date
      AND started_at <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_id IS NULL OR agent_type_id = p_agent_type_id)
    GROUP BY ai_segment
    ORDER BY conversion_rate DESC NULLS LAST
  )
  SELECT jsonb_build_object(
    'call_volume_by_day', COALESCE((SELECT jsonb_agg(row_to_json(t)) FROM call_volume_by_day t), '[]'::jsonb),
    'conversion_funnel', COALESCE((SELECT jsonb_agg(row_to_json(t)) FROM conversion_funnel t), '[]'::jsonb),
    'outcome_distribution', COALESCE((SELECT jsonb_agg(row_to_json(t)) FROM outcome_distribution t), '[]'::jsonb),
    'segment_performance', COALESCE((SELECT jsonb_agg(row_to_json(t)) FROM segment_performance t), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_arthur_chart_data IS 'Fetches data for Arthur dashboard charts: call volume by day, conversion funnel, outcome distribution, and segment performance. Supports date range and client/agent_type filters.';


-- ============================================================================
-- Grant EXECUTE permissions on RPC functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_arthur_kpi_metrics(timestamp with time zone, timestamp with time zone, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_arthur_chart_data(timestamp with time zone, timestamp with time zone, uuid, uuid) TO authenticated;

-- Optional: Grant to anon role if needed for public dashboards
-- GRANT EXECUTE ON FUNCTION get_arthur_kpi_metrics(timestamp with time zone, timestamp with time zone, uuid, uuid) TO anon;
-- GRANT EXECUTE ON FUNCTION get_arthur_chart_data(timestamp with time zone, timestamp with time zone, uuid, uuid) TO anon;


-- ============================================================================
-- Test queries (comment out in production, or remove after validation)
-- ============================================================================

-- Test get_arthur_kpi_metrics with 30-day period
-- SELECT get_arthur_kpi_metrics(
--   (CURRENT_DATE - INTERVAL '30 days')::timestamptz,
--   CURRENT_DATE::timestamptz,
--   NULL,
--   NULL
-- );

-- Test get_arthur_chart_data with 30-day period
-- SELECT get_arthur_chart_data(
--   (CURRENT_DATE - INTERVAL '30 days')::timestamptz,
--   CURRENT_DATE::timestamptz,
--   NULL,
--   NULL
-- );
