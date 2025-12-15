-- Migration: Louis Nestenn Dashboard KPIs
-- Date: 2025-12-15
-- Description: Fonction specifique pour les KPIs Louis-Nestenn (qualification de leads, pas de RDV)
--
-- Context:
-- Louis pour Nestenn est un agent de qualification qui demande des TRANSFERTS vers le negociateur
-- Il ne prend PAS de RDV directement. Les outcomes pertinents sont:
-- - appointment_scheduled → TRANSFERT DEMANDE (succes principal)
-- - callback_requested → rappel planifie
-- - voicemail → messagerie vocale
-- - no_answer → pas de reponse

-- ============================================================================
-- Fonction: get_louis_nestenn_kpis()
-- Retourne les KPIs specifiques pour Louis-Nestenn
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
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_days INTEGER;
BEGIN
  -- Calculate period length for comparison
  v_period_days := p_end_date - p_start_date + 1;

  -- ============================================================================
  -- CURRENT PERIOD METRICS
  -- ============================================================================
  WITH current_calls AS (
    SELECT
      -- Volumes
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE call_status IN ('ok', 'voicemail')) AS contacted_calls,
      COUNT(*) FILTER (WHERE call_status = 'ok') AS answered_calls,

      -- Outcomes specifiques Nestenn
      COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled') AS transfers_requested,  -- Transfert vers owner
      COUNT(*) FILTER (WHERE outcome = 'callback_requested') AS callbacks_requested,
      COUNT(*) FILTER (WHERE outcome = 'voicemail') AS voicemails,
      COUNT(*) FILTER (WHERE outcome = 'no_answer') AS no_answers,
      COUNT(*) FILTER (WHERE outcome = 'not_interested') AS not_interested,
      -- FIX: qualified_leads only counts if call_status = 'ok' (answered)
      COUNT(*) FILTER (WHERE call_status = 'ok' AND outcome IN ('appointment_scheduled', 'callback_requested')) AS qualified_leads,

      -- Durees
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,

      -- Couts
      SUM(total_cost) AS total_cost

    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND ad.status = 'active'
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  )
  SELECT jsonb_build_object(
    -- KPI 1: Total Appels
    'total_calls', COALESCE(total_calls, 0),

    -- KPI 2: Taux de Contact = (contacted / total) * 100
    'contact_rate', CASE
      WHEN total_calls > 0 THEN ROUND((contacted_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,

    -- KPI 3: Transferts Demandes (succes principal)
    'transfers_requested', COALESCE(transfers_requested, 0),

    -- KPI 4: Taux de Qualification = (qualified / answered) * 100, capped at 100%
    'qualification_rate', CASE
      WHEN answered_calls > 0 THEN LEAST(ROUND((qualified_leads::NUMERIC / answered_calls * 100), 1), 100)
      ELSE 0
    END,

    -- KPI 5: Rappels Planifies
    'callbacks_requested', COALESCE(callbacks_requested, 0),

    -- KPI 6: SMS Envoyes (sera calcule separement via agent_sms)
    'sms_sent', 0,  -- Placeholder, sera enrichi par une autre requete

    -- Donnees additionnelles pour les charts
    'answered_calls', COALESCE(answered_calls, 0),
    'contacted_calls', COALESCE(contacted_calls, 0),
    'qualified_leads', COALESCE(qualified_leads, 0),
    'voicemails', COALESCE(voicemails, 0),
    'no_answers', COALESCE(no_answers, 0),
    'not_interested', COALESCE(not_interested, 0),

    -- Duree moyenne
    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,

    -- Couts
    'total_cost', COALESCE(total_cost, 0),
    'cost_per_transfer', CASE
      WHEN transfers_requested > 0 THEN ROUND(total_cost / transfers_requested, 2)
      ELSE 0
    END
  )
  INTO v_current_period
  FROM current_calls;

  -- ============================================================================
  -- PREVIOUS PERIOD METRICS (pour comparaison)
  -- ============================================================================
  WITH previous_calls AS (
    SELECT
      COUNT(*) AS total_calls,
      COUNT(*) FILTER (WHERE call_status IN ('ok', 'voicemail')) AS contacted_calls,
      COUNT(*) FILTER (WHERE call_status = 'ok') AS answered_calls,
      COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled') AS transfers_requested,
      COUNT(*) FILTER (WHERE outcome = 'callback_requested') AS callbacks_requested,
      COUNT(*) FILTER (WHERE outcome = 'voicemail') AS voicemails,
      COUNT(*) FILTER (WHERE outcome = 'no_answer') AS no_answers,
      COUNT(*) FILTER (WHERE outcome = 'not_interested') AS not_interested,
      -- FIX: qualified_leads only counts if call_status = 'ok' (answered)
      COUNT(*) FILTER (WHERE call_status = 'ok' AND outcome IN ('appointment_scheduled', 'callback_requested')) AS qualified_leads,
      SUM(duration_seconds) FILTER (WHERE duration_seconds > 0) AS total_duration,
      COUNT(*) FILTER (WHERE duration_seconds > 0) AS calls_with_duration,
      SUM(total_cost) AS total_cost
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= (p_start_date - v_period_days * INTERVAL '1 day')
      AND ac.started_at < p_start_date
      AND ad.status = 'active'
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  )
  SELECT jsonb_build_object(
    'total_calls', COALESCE(total_calls, 0),
    'contact_rate', CASE
      WHEN total_calls > 0 THEN ROUND((contacted_calls::NUMERIC / total_calls * 100), 1)
      ELSE 0
    END,
    'transfers_requested', COALESCE(transfers_requested, 0),
    'qualification_rate', CASE
      WHEN answered_calls > 0 THEN ROUND((qualified_leads::NUMERIC / answered_calls * 100), 1)
      ELSE 0
    END,
    'callbacks_requested', COALESCE(callbacks_requested, 0),
    'sms_sent', 0,
    'answered_calls', COALESCE(answered_calls, 0),
    'contacted_calls', COALESCE(contacted_calls, 0),
    'qualified_leads', COALESCE(qualified_leads, 0),
    'voicemails', COALESCE(voicemails, 0),
    'no_answers', COALESCE(no_answers, 0),
    'not_interested', COALESCE(not_interested, 0),
    'avg_duration', CASE
      WHEN calls_with_duration > 0 THEN ROUND(total_duration::NUMERIC / calls_with_duration, 0)
      ELSE 0
    END,
    'total_cost', COALESCE(total_cost, 0),
    'cost_per_transfer', CASE
      WHEN transfers_requested > 0 THEN ROUND(total_cost / transfers_requested, 2)
      ELSE 0
    END
  )
  INTO v_previous_period
  FROM previous_calls;

  -- Return combined result
  RETURN jsonb_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_louis_nestenn_kpis(DATE, DATE, UUID, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_louis_nestenn_kpis IS 'Returns KPIs for Louis-Nestenn dashboard (lead qualification, not appointment booking). Main success metric is transfers_requested.';


-- ============================================================================
-- Fonction: get_louis_nestenn_charts()
-- Retourne les donnees pour les charts specifiques Louis-Nestenn
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
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
  v_duration_by_outcome JSONB;
  v_funnel_data JSONB;
BEGIN

  -- =========================================================================
  -- 1. Call Volume by Day (inchange)
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(day_row ORDER BY day_row->>'date'), '[]'::jsonb)
  INTO v_call_volume
  FROM (
    SELECT jsonb_build_object(
      'date', DATE(ac.started_at)::TEXT,
      'total_calls', COUNT(*),
      'answered_calls', COUNT(*) FILTER (WHERE call_status = 'ok'),
      'transfers', COUNT(*) FILTER (WHERE outcome = 'appointment_scheduled')
    ) as day_row
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND ad.status = 'active'
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY DATE(ac.started_at)
  ) daily_stats;

  -- =========================================================================
  -- 2. Outcome Distribution (pour donut chart)
  -- Mapping Nestenn: appointment_scheduled = Transfert demande
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(outcome_row ORDER BY (outcome_row->>'count')::int DESC), '[]'::jsonb)
  INTO v_outcome_distribution
  FROM (
    SELECT jsonb_build_object(
      'outcome', CASE ac.outcome
        WHEN 'appointment_scheduled' THEN 'Transfert demandé'
        WHEN 'callback_requested' THEN 'Rappel planifié'
        WHEN 'voicemail' THEN 'Messagerie'
        WHEN 'no_answer' THEN 'Pas de réponse'
        WHEN 'not_interested' THEN 'Non intéressé'
        WHEN 'too_short' THEN 'Trop court'
        WHEN 'call_failed' THEN 'Échec appel'
        ELSE COALESCE(ac.outcome, 'Autre')
      END,
      'count', COUNT(*),
      'color', CASE ac.outcome
        WHEN 'appointment_scheduled' THEN '#22c55e'  -- green (succes)
        WHEN 'callback_requested' THEN '#3b82f6'    -- blue
        WHEN 'voicemail' THEN '#eab308'             -- yellow
        WHEN 'no_answer' THEN '#ef4444'             -- red
        WHEN 'not_interested' THEN '#f97316'        -- orange
        ELSE '#6b7280'                              -- gray
      END
    ) as outcome_row
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND ad.status = 'active'
      AND ac.outcome IS NOT NULL
      AND ac.outcome != ''
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY ac.outcome
    HAVING COUNT(*) > 0
  ) outcomes;

  -- =========================================================================
  -- 3. Emotion Distribution (filtre sur call_status = 'ok' uniquement)
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(emotion_row ORDER BY (emotion_row->>'count')::int DESC), '[]'::jsonb)
  INTO v_emotion_distribution
  FROM (
    SELECT jsonb_build_object(
      'emotion', COALESCE(ac.emotion, 'unknown'),
      'count', COUNT(*)
    ) as emotion_row
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND ad.status = 'active'
      AND ac.call_status = 'ok'  -- IMPORTANT: uniquement appels decroches
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY ac.emotion
    HAVING COUNT(*) > 0
  ) emotions;

  -- =========================================================================
  -- 4. Duration by Outcome (bar chart horizontal)
  -- Montre la correlation duree/succes
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(duration_row ORDER BY (duration_row->>'avg_duration')::numeric DESC), '[]'::jsonb)
  INTO v_duration_by_outcome
  FROM (
    SELECT jsonb_build_object(
      'outcome', CASE ac.outcome
        WHEN 'appointment_scheduled' THEN 'Transfert demandé'
        WHEN 'callback_requested' THEN 'Rappel planifié'
        WHEN 'voicemail' THEN 'Messagerie'
        WHEN 'no_answer' THEN 'Pas de réponse'
        WHEN 'not_interested' THEN 'Non intéressé'
        ELSE COALESCE(ac.outcome, 'Autre')
      END,
      'avg_duration', ROUND(AVG(ac.duration_seconds), 0),
      'count', COUNT(*),
      'color', CASE ac.outcome
        WHEN 'appointment_scheduled' THEN '#22c55e'
        WHEN 'callback_requested' THEN '#3b82f6'
        WHEN 'voicemail' THEN '#eab308'
        WHEN 'no_answer' THEN '#ef4444'
        WHEN 'not_interested' THEN '#f97316'
        ELSE '#6b7280'
      END
    ) as duration_row
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE at.name = 'louis'
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND ad.status = 'active'
      AND ac.duration_seconds > 0
      AND ac.outcome IS NOT NULL
      AND ac.outcome != ''
      AND (p_client_id IS NULL OR ad.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY ac.outcome
    HAVING COUNT(*) > 0
  ) durations;

  -- =========================================================================
  -- 5. Funnel Data (pour funnel chart)
  -- Total → Contactes → Decroches → Qualifies
  -- =========================================================================
  SELECT jsonb_build_object(
    'total_calls', COUNT(*),
    'contacted', COUNT(*) FILTER (WHERE call_status IN ('ok', 'voicemail')),
    'answered', COUNT(*) FILTER (WHERE call_status = 'ok'),
    'qualified', COUNT(*) FILTER (WHERE outcome IN ('appointment_scheduled', 'callback_requested'))
  )
  INTO v_funnel_data
  FROM agent_calls ac
  INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
  INNER JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE at.name = 'louis'
    AND ac.started_at >= p_start_date
    AND ac.started_at <= p_end_date + INTERVAL '1 day'
    AND ad.status = 'active'
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_deployment_id IS NULL OR ad.id = p_deployment_id);

  -- =========================================================================
  -- Build final result
  -- =========================================================================
  v_result := jsonb_build_object(
    'call_volume_by_day', v_call_volume,
    'outcome_distribution', v_outcome_distribution,
    'emotion_distribution', v_emotion_distribution,
    'duration_by_outcome', v_duration_by_outcome,
    'funnel_data', v_funnel_data
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_louis_nestenn_charts(DATE, DATE, UUID, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_louis_nestenn_charts IS 'Returns chart data for Louis-Nestenn dashboard including funnel, outcome distribution, emotion distribution, and duration by outcome.';

-- ============================================================================
-- Verification queries (commented out for production)
-- ============================================================================
-- SELECT get_louis_nestenn_kpis('2025-11-01'::date, '2025-11-30'::date, NULL, NULL);
-- SELECT get_louis_nestenn_charts('2025-11-01'::date, '2025-11-30'::date, NULL, NULL);
