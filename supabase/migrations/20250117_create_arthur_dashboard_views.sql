-- Migration: Create Arthur Dashboard Views
-- Description: Creates 5 views to support the Arthur reactivation agent dashboard
-- Author: Claude Code
-- Date: 2025-01-17

-- ============================================================================
-- View 1: v_arthur_kpis_dashboard
-- Aggregates all KPIs for the dashboard with current and previous periods
-- ============================================================================

CREATE OR REPLACE VIEW v_arthur_kpis_dashboard AS
WITH date_params AS (
  SELECT
    CURRENT_DATE - INTERVAL '30 days' AS current_start,
    CURRENT_DATE AS current_end,
    CURRENT_DATE - INTERVAL '60 days' AS previous_start,
    CURRENT_DATE - INTERVAL '30 days' AS previous_end
),
current_period AS (
  SELECT
    COUNT(DISTINCT aap.id) AS total_prospects,
    COUNT(DISTINCT CASE WHEN aap.status = 'converted' THEN aap.id END) AS conversions,
    COUNT(DISTINCT ac.id) AS total_calls,
    COUNT(DISTINCT CASE WHEN ac.outcome != 'voicemail' THEN ac.id END) AS answered_calls,
    COUNT(DISTINCT CASE WHEN (ac.metadata->>'appointment_scheduled_at') IS NOT NULL THEN ac.id END) AS appointments_scheduled,
    COALESCE(SUM(ac.cost), 0) AS total_cost,
    COALESCE(AVG(ac.duration_seconds), 0) AS avg_duration,
    COALESCE(
      AVG(
        CASE
          WHEN aaps.current_attempt = 1 AND ac.outcome != 'voicemail' THEN 1
          WHEN aaps.current_attempt = 1 THEN 0
          ELSE NULL
        END
      ),
      0
    ) AS answer_rate_attempt_1
  FROM agent_arthur_prospects aap
  LEFT JOIN agent_arthur_prospect_sequences aaps ON aap.id = aaps.prospect_id
  LEFT JOIN agent_calls ac ON aap.id = ac.prospect_id
  CROSS JOIN date_params
  WHERE ac.started_at >= date_params.current_start
    AND ac.started_at <= date_params.current_end
),
previous_period AS (
  SELECT
    COUNT(DISTINCT aap.id) AS total_prospects,
    COUNT(DISTINCT CASE WHEN aap.status = 'converted' THEN aap.id END) AS conversions,
    COUNT(DISTINCT ac.id) AS total_calls,
    COUNT(DISTINCT CASE WHEN ac.outcome != 'voicemail' THEN ac.id END) AS answered_calls,
    COUNT(DISTINCT CASE WHEN (ac.metadata->>'appointment_scheduled_at') IS NOT NULL THEN ac.id END) AS appointments_scheduled,
    COALESCE(SUM(ac.cost), 0) AS total_cost,
    COALESCE(AVG(ac.duration_seconds), 0) AS avg_duration,
    COALESCE(
      AVG(
        CASE
          WHEN aaps.current_attempt = 1 AND ac.outcome != 'voicemail' THEN 1
          WHEN aaps.current_attempt = 1 THEN 0
          ELSE NULL
        END
      ),
      0
    ) AS answer_rate_attempt_1
  FROM agent_arthur_prospects aap
  LEFT JOIN agent_arthur_prospect_sequences aaps ON aap.id = aaps.prospect_id
  LEFT JOIN agent_calls ac ON aap.id = ac.prospect_id
  CROSS JOIN date_params
  WHERE ac.started_at >= date_params.previous_start
    AND ac.started_at < date_params.previous_end
)
SELECT
  jsonb_build_object(
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
  ) AS current_period,
  jsonb_build_object(
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
  ) AS previous_period
FROM current_period cp
CROSS JOIN previous_period pp;

COMMENT ON VIEW v_arthur_kpis_dashboard IS 'Aggregated KPIs for Arthur dashboard with current and previous period comparison';


-- ============================================================================
-- View 2: v_arthur_calls_enriched
-- Complete join of all Arthur tables for rich queries
-- ============================================================================

CREATE OR REPLACE VIEW v_arthur_calls_enriched AS
SELECT
  ac.id AS call_id,
  ac.started_at,
  ac.ended_at,
  ac.duration_seconds,
  ac.cost,
  (ac.outcome != 'voicemail') AS answered,
  ac.outcome AS call_outcome,
  (ac.metadata->>'appointment_scheduled_at')::timestamptz AS appointment_scheduled_at,
  ac.recording_url AS call_recording_url,
  ac.transcript,

  -- Prospect info
  aap.id AS prospect_id,
  aap.first_name,
  aap.last_name,
  aap.email,
  aap.phone_number AS phone,
  aap.company_name AS company,
  aap.external_source,
  aap.external_deal_id,
  aap.status AS prospect_status,
  aap.ai_analysis,

  -- Sequence info
  aaps.id AS sequence_id,
  aaps.sequence_number,
  aaps.current_attempt,
  aaps.max_attempts,
  aaps.status AS sequence_status,
  aaps.outcome AS sequence_outcome,
  aaps.next_action_at,

  -- Agent & Client info
  ad.id AS agent_deployment_id,
  ad.agent_type_id,
  ad.client_id,
  at.display_name AS agent_name,
  c.name AS client_name,

  -- Derived fields
  CASE
    WHEN (ac.metadata->>'appointment_scheduled_at') IS NOT NULL THEN 'converted'
    WHEN ac.outcome = 'callback_requested' THEN 'callback'
    WHEN ac.outcome = 'not_interested' THEN 'lost'
    WHEN ac.outcome = 'do_not_call' THEN 'blacklisted'
    ELSE 'in_progress'
  END AS derived_status,

  -- Dynamic attempt label (no hard-coded limit)
  'Tentative ' || aaps.current_attempt AS attempt_label,

  -- AI analysis extracted fields (assuming JSONB structure)
  aap.ai_analysis->>'segment' AS ai_segment,
  aap.ai_analysis->>'score' AS ai_score,
  aap.ai_analysis->>'reason' AS ai_reason

FROM agent_calls ac
INNER JOIN agent_arthur_prospects aap ON ac.prospect_id = aap.id
LEFT JOIN agent_arthur_prospect_sequences aaps ON aap.id = aaps.prospect_id
LEFT JOIN agent_deployments ad ON ac.deployment_id = ad.id
LEFT JOIN agent_types at ON ad.agent_type_id = at.id
LEFT JOIN clients c ON ad.client_id = c.id
WHERE at.name = 'arthur';

COMMENT ON VIEW v_arthur_calls_enriched IS 'Enriched view of Arthur calls with all related prospect, sequence, agent, and client data';


-- ============================================================================
-- View 3: v_arthur_funnel_conversion
-- Calculate conversion rates at each attempt for funnel visualization
-- ============================================================================

CREATE OR REPLACE VIEW v_arthur_funnel_conversion AS
SELECT
  current_attempt,
  COUNT(*) AS total_calls,
  COUNT(CASE WHEN answered = true THEN 1 END) AS answered_calls,
  COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END) AS conversions,
  ROUND(
    (COUNT(CASE WHEN answered = true THEN 1 END)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100,
    2
  ) AS answer_rate,
  ROUND(
    (COUNT(CASE WHEN appointment_scheduled_at IS NOT NULL THEN 1 END)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100,
    2
  ) AS conversion_rate
FROM v_arthur_calls_enriched
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY current_attempt
ORDER BY current_attempt;

COMMENT ON VIEW v_arthur_funnel_conversion IS 'Conversion funnel by attempt number for Arthur reactivation sequences';


-- ============================================================================
-- View 4: v_arthur_sequences_actives
-- Monitor active sequences and their next actions
-- ============================================================================

CREATE OR REPLACE VIEW v_arthur_sequences_actives AS
SELECT
  aaps.id,
  aaps.prospect_id,
  aap.first_name,
  aap.last_name,
  aap.email,
  aap.phone_number AS phone,
  aap.company_name AS company,
  aaps.sequence_number,
  aaps.current_attempt,
  aaps.max_attempts,
  aaps.status,
  aaps.next_action_at,
  aaps.created_at,
  aaps.updated_at,

  -- Derived fields
  aaps.max_attempts - aaps.current_attempt AS remaining_attempts,
  CASE
    WHEN aaps.next_action_at < NOW() THEN 'overdue'
    WHEN aaps.next_action_at BETWEEN NOW() AND NOW() + INTERVAL '24 hours' THEN 'due_today'
    WHEN aaps.next_action_at BETWEEN NOW() + INTERVAL '24 hours' AND NOW() + INTERVAL '7 days' THEN 'due_this_week'
    ELSE 'scheduled'
  END AS urgency_status,

  -- Last call info
  (
    SELECT jsonb_build_object(
      'call_id', ac.id,
      'started_at', ac.started_at,
      'duration', ac.duration_seconds,
      'outcome', ac.outcome,
      'answered', (ac.outcome != 'voicemail')
    )
    FROM agent_calls ac
    WHERE ac.prospect_id = aaps.prospect_id
    ORDER BY ac.started_at DESC
    LIMIT 1
  ) AS last_call_info

FROM agent_arthur_prospect_sequences aaps
INNER JOIN agent_arthur_prospects aap ON aaps.prospect_id = aap.id
WHERE aaps.status IN ('active', 'callback')
  AND aaps.current_attempt < aaps.max_attempts
ORDER BY aaps.next_action_at ASC;

COMMENT ON VIEW v_arthur_sequences_actives IS 'Active Arthur sequences with urgency status and last call information';


-- ============================================================================
-- View 5: v_arthur_outcome_analysis
-- Detailed distribution of call outcomes for donut chart
-- ============================================================================

CREATE OR REPLACE VIEW v_arthur_outcome_analysis AS
SELECT
  CASE
    WHEN call_outcome = 'appointment_scheduled' OR appointment_scheduled_at IS NOT NULL THEN 'Converti'
    WHEN call_outcome = 'callback_requested' THEN 'Callback'
    WHEN call_outcome = 'not_interested' OR call_outcome = 'appointment_refused' THEN 'Pas intéressé'
    WHEN call_outcome = 'do_not_call' THEN 'Ne pas rappeler'
    WHEN call_outcome = 'voicemail' OR answered = false THEN 'Messagerie'
    ELSE 'Autre'
  END AS outcome_label,
  COUNT(*) AS count,
  ROUND(
    (COUNT(*)::numeric / (
      SELECT COUNT(*)
      FROM v_arthur_calls_enriched
      WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
    )::numeric) * 100,
    2
  ) AS percentage
FROM v_arthur_calls_enriched
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY outcome_label
ORDER BY count DESC;

COMMENT ON VIEW v_arthur_outcome_analysis IS 'Distribution of call outcomes for Arthur dashboard donut chart';


-- ============================================================================
-- Grant permissions (adjust based on your RLS setup)
-- ============================================================================

-- Grant SELECT on all views to authenticated users
GRANT SELECT ON v_arthur_kpis_dashboard TO authenticated;
GRANT SELECT ON v_arthur_calls_enriched TO authenticated;
GRANT SELECT ON v_arthur_funnel_conversion TO authenticated;
GRANT SELECT ON v_arthur_sequences_actives TO authenticated;
GRANT SELECT ON v_arthur_outcome_analysis TO authenticated;

-- Optional: Grant to anon role if needed for public dashboards
-- GRANT SELECT ON v_arthur_kpis_dashboard TO anon;
-- GRANT SELECT ON v_arthur_calls_enriched TO anon;
-- GRANT SELECT ON v_arthur_funnel_conversion TO anon;
-- GRANT SELECT ON v_arthur_sequences_actives TO anon;
-- GRANT SELECT ON v_arthur_outcome_analysis TO anon;
