-- ============================================================================
-- Migration: filter_kpis_by_active_agents
-- Date: 2025-12-15
-- Description: Filtrer les appels par agents actifs dans tous les dashboards
-- Impact: Seuls les appels des agents avec status='active' seront comptabilisés
-- ============================================================================

-- ============================================================================
-- PARTIE 1: FONCTIONS RPC PRINCIPALES (KPIs/Charts)
-- ============================================================================

-- 1. get_global_kpis
DROP FUNCTION IF EXISTS get_global_kpis(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]);

CREATE OR REPLACE FUNCTION get_global_kpis(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_accessible_client_ids UUID[];
  v_current_period JSONB;
  v_previous_period JSONB;
  v_period_duration INTERVAL;
  v_previous_start TIMESTAMP WITH TIME ZONE;
  v_previous_end TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculer la durée de la période pour la comparaison
  v_period_duration := p_end_date - p_start_date;
  v_previous_start := p_start_date - v_period_duration;
  v_previous_end := p_start_date;

  -- Récupérer les clients accessibles
  SELECT ARRAY_AGG(DISTINCT client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions
  WHERE user_id = auth.uid();

  -- Si p_client_ids est fourni, filtrer par ces clients
  IF p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := ARRAY(
      SELECT UNNEST(v_accessible_client_ids)
      INTERSECT
      SELECT UNNEST(p_client_ids)
    );
  END IF;

  -- Si aucun client accessible, retourner des valeurs vides
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'current_period', jsonb_build_object(
        'total_calls', 0,
        'answered_calls', 0,
        'appointments_scheduled', 0,
        'answer_rate', 0,
        'conversion_rate', 0,
        'avg_duration', 0,
        'total_cost', 0,
        'cost_per_appointment', 0
      ),
      'previous_period', jsonb_build_object(
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

  -- Période actuelle
  SELECT jsonb_build_object(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL),
    'appointments_scheduled', COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled'),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled')::NUMERIC / COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(ac.total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled') > 0
      THEN ROUND(COALESCE(SUM(ac.total_cost), 0) / COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled'), 2)
      ELSE 0
    END
  )
  INTO v_current_period
  FROM agent_calls ac
  INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
  WHERE ac.started_at >= p_start_date
    AND ac.started_at <= p_end_date
    AND ad.client_id = ANY(v_accessible_client_ids)
    AND ad.status = 'active';  -- FILTRE: Uniquement les agents actifs

  -- Période précédente
  SELECT jsonb_build_object(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL),
    'appointments_scheduled', COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled'),
    'answer_rate', CASE
      WHEN COUNT(*) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'conversion_rate', CASE
      WHEN COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) > 0
      THEN ROUND((COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled')::NUMERIC / COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC) * 100, 2)
      ELSE 0
    END,
    'avg_duration', ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0), 0), 0),
    'total_cost', ROUND(COALESCE(SUM(ac.total_cost), 0), 2),
    'cost_per_appointment', CASE
      WHEN COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled') > 0
      THEN ROUND(COALESCE(SUM(ac.total_cost), 0) / COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled'), 2)
      ELSE 0
    END
  )
  INTO v_previous_period
  FROM agent_calls ac
  INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
  WHERE ac.started_at >= v_previous_start
    AND ac.started_at < v_previous_end
    AND ad.client_id = ANY(v_accessible_client_ids)
    AND ad.status = 'active';  -- FILTRE: Uniquement les agents actifs

  RETURN jsonb_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_global_kpis(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_kpis(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO service_role;


-- 2. get_global_chart_data
DROP FUNCTION IF EXISTS get_global_chart_data(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]);

CREATE OR REPLACE FUNCTION get_global_chart_data(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_accessible_client_ids UUID[];
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
BEGIN
  -- Récupérer les clients accessibles
  SELECT ARRAY_AGG(DISTINCT client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions
  WHERE user_id = auth.uid();

  -- Si p_client_ids est fourni, filtrer par ces clients
  IF p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := ARRAY(
      SELECT UNNEST(v_accessible_client_ids)
      INTERSECT
      SELECT UNNEST(p_client_ids)
    );
  END IF;

  -- Volume d'appels par jour
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'date')), '[]'::jsonb)
  INTO v_call_volume
  FROM (
    SELECT jsonb_build_object(
      'date', DATE(ac.started_at),
      'total_calls', COUNT(*),
      'answered_calls', COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL),
      'appointments', COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled')
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
    GROUP BY DATE(ac.started_at)
  ) sub;

  -- Distribution des outcomes
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'count')::int DESC), '[]'::jsonb)
  INTO v_outcome_distribution
  FROM (
    SELECT jsonb_build_object(
      'outcome', COALESCE(ac.outcome, 'unknown'),
      'count', COUNT(*),
      'percentage', ROUND(COUNT(*)::NUMERIC * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
    GROUP BY ac.outcome
  ) sub;

  -- Distribution des émotions
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'count')::int DESC), '[]'::jsonb)
  INTO v_emotion_distribution
  FROM (
    SELECT jsonb_build_object(
      'emotion', COALESCE(ac.emotion, 'unknown'),
      'count', COUNT(*),
      'percentage', ROUND(COUNT(*)::NUMERIC * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    WHERE ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date
      AND ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
    GROUP BY ac.emotion
  ) sub;

  RETURN jsonb_build_object(
    'call_volume', v_call_volume,
    'outcome_distribution', v_outcome_distribution,
    'emotion_distribution', v_emotion_distribution
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_global_chart_data(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_chart_data(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO service_role;


-- 3. get_kpi_metrics
DROP FUNCTION IF EXISTS get_kpi_metrics(DATE, DATE, UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS TABLE (
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments_scheduled BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  cost_per_appointment NUMERIC,
  prev_total_calls BIGINT,
  prev_answered_calls BIGINT,
  prev_appointments BIGINT,
  prev_answer_rate NUMERIC,
  prev_conversion_rate NUMERIC,
  prev_avg_duration NUMERIC,
  prev_total_cost NUMERIC,
  total_calls_change NUMERIC,
  answered_calls_change NUMERIC,
  appointments_change NUMERIC,
  answer_rate_change NUMERIC,
  conversion_rate_change NUMERIC,
  avg_duration_change NUMERIC,
  cost_change NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_period_duration INTERVAL;
BEGIN
  v_period_duration := p_end_date - p_start_date;

  RETURN QUERY
  WITH accessible_calls AS (
    SELECT
      ac.id,
      ac.duration_seconds,
      ac.total_cost,
      ac.started_at,
      ac.outcome,
      CASE
        WHEN ac.outcome IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') THEN false
        WHEN ac.outcome IS NULL THEN false
        ELSE true
      END AS answered,
      CASE
        WHEN ac.outcome = 'appointment_scheduled' THEN true
        ELSE false
      END AS appointment_scheduled
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  ),
  current_period AS (
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (WHERE answered) AS answered,
      COUNT(*) FILTER (WHERE appointment_scheduled) AS appointments,
      ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0) AS avg_dur,
      COALESCE(SUM(total_cost), 0) AS cost
    FROM accessible_calls
    WHERE started_at >= p_start_date
      AND started_at < p_end_date + INTERVAL '1 day'
  ),
  previous_period AS (
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (WHERE answered) AS answered,
      COUNT(*) FILTER (WHERE appointment_scheduled) AS appointments,
      ROUND(AVG(duration_seconds) FILTER (WHERE duration_seconds > 0), 0) AS avg_dur,
      COALESCE(SUM(total_cost), 0) AS cost
    FROM accessible_calls
    WHERE started_at >= (p_start_date - v_period_duration)
      AND started_at < p_start_date
  )
  SELECT
    cp.total,
    cp.answered,
    cp.appointments,
    CASE WHEN cp.total > 0 THEN ROUND((cp.answered::NUMERIC / cp.total) * 100, 2) ELSE 0 END,
    CASE WHEN cp.answered > 0 THEN ROUND((cp.appointments::NUMERIC / cp.answered) * 100, 2) ELSE 0 END,
    COALESCE(cp.avg_dur, 0),
    ROUND(cp.cost, 2),
    CASE WHEN cp.appointments > 0 THEN ROUND(cp.cost / cp.appointments, 2) ELSE 0 END,
    pp.total,
    pp.answered,
    pp.appointments,
    CASE WHEN pp.total > 0 THEN ROUND((pp.answered::NUMERIC / pp.total) * 100, 2) ELSE 0 END,
    CASE WHEN pp.answered > 0 THEN ROUND((pp.appointments::NUMERIC / pp.answered) * 100, 2) ELSE 0 END,
    COALESCE(pp.avg_dur, 0),
    ROUND(pp.cost, 2),
    CASE WHEN pp.total > 0 THEN ROUND(((cp.total - pp.total)::NUMERIC / pp.total) * 100, 2) ELSE 0 END,
    CASE WHEN pp.answered > 0 THEN ROUND(((cp.answered - pp.answered)::NUMERIC / pp.answered) * 100, 2) ELSE 0 END,
    CASE WHEN pp.appointments > 0 THEN ROUND(((cp.appointments - pp.appointments)::NUMERIC / pp.appointments) * 100, 2) ELSE 0 END,
    CASE WHEN cp.total > 0 THEN ROUND((cp.answered::NUMERIC / cp.total) * 100, 2) ELSE 0 END -
    CASE WHEN pp.total > 0 THEN ROUND((pp.answered::NUMERIC / pp.total) * 100, 2) ELSE 0 END,
    CASE WHEN cp.answered > 0 THEN ROUND((cp.appointments::NUMERIC / cp.answered) * 100, 2) ELSE 0 END -
    CASE WHEN pp.answered > 0 THEN ROUND((pp.appointments::NUMERIC / pp.answered) * 100, 2) ELSE 0 END,
    COALESCE(cp.avg_dur, 0) - COALESCE(pp.avg_dur, 0),
    CASE WHEN pp.cost > 0 THEN ROUND(((cp.cost - pp.cost) / pp.cost) * 100, 2) ELSE 0 END
  FROM current_period cp, previous_period pp;
END;
$$;

GRANT EXECUTE ON FUNCTION get_kpi_metrics(DATE, DATE, UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_kpi_metrics(DATE, DATE, UUID, TEXT, UUID) TO service_role;


-- 4. get_chart_data
DROP FUNCTION IF EXISTS get_chart_data(DATE, DATE, UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION get_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_call_volume JSONB;
  v_outcome_distribution JSONB;
  v_emotion_distribution JSONB;
  v_hourly_distribution JSONB;
BEGIN
  -- Volume d'appels par jour
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'date')), '[]'::jsonb)
  INTO v_call_volume
  FROM (
    SELECT jsonb_build_object(
      'date', DATE(ac.started_at),
      'total_calls', COUNT(*),
      'answered_calls', COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL),
      'appointments', COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled')
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY DATE(ac.started_at)
  ) sub;

  -- Distribution des outcomes
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'count')::int DESC), '[]'::jsonb)
  INTO v_outcome_distribution
  FROM (
    SELECT jsonb_build_object(
      'outcome', COALESCE(ac.outcome, 'unknown'),
      'count', COUNT(*),
      'percentage', ROUND(COUNT(*)::NUMERIC * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY ac.outcome
  ) sub;

  -- Distribution des émotions
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'count')::int DESC), '[]'::jsonb)
  INTO v_emotion_distribution
  FROM (
    SELECT jsonb_build_object(
      'emotion', COALESCE(ac.emotion, 'unknown'),
      'count', COUNT(*),
      'percentage', ROUND(COUNT(*)::NUMERIC * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY ac.emotion
  ) sub;

  -- Distribution horaire
  SELECT COALESCE(jsonb_agg(row_data ORDER BY (row_data->>'hour')::int), '[]'::jsonb)
  INTO v_hourly_distribution
  FROM (
    SELECT jsonb_build_object(
      'hour', EXTRACT(HOUR FROM ac.started_at),
      'count', COUNT(*),
      'answered', COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)
    ) AS row_data
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
    GROUP BY EXTRACT(HOUR FROM ac.started_at)
  ) sub;

  RETURN jsonb_build_object(
    'call_volume', v_call_volume,
    'outcome_distribution', v_outcome_distribution,
    'emotion_distribution', v_emotion_distribution,
    'hourly_distribution', v_hourly_distribution
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_chart_data(DATE, DATE, UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_chart_data(DATE, DATE, UUID, TEXT, UUID) TO service_role;


-- ============================================================================
-- PARTIE 2: FONCTIONS DE CARDS
-- ============================================================================

-- 5. get_client_cards_data (version avec 3 paramètres)
DROP FUNCTION IF EXISTS get_client_cards_data(DATE, DATE, UUID[]);

CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  active_agents BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id AS client_id,
    c.name AS client_name,
    COUNT(ac.id) FILTER (WHERE ad.status = 'active') AS total_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') AS answered_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active') AS appointments,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS answer_rate,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS conversion_rate,
    ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0 AND ad.status = 'active'), 0), 0) AS avg_duration,
    ROUND(COALESCE(SUM(ac.total_cost) FILTER (WHERE ad.status = 'active'), 0), 2) AS total_cost,
    COUNT(DISTINCT ad.id) FILTER (WHERE ad.status = 'active') AS active_agents
  FROM clients c
  INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
  LEFT JOIN agent_deployments ad ON c.id = ad.client_id
  LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
  WHERE ucp.user_id = auth.uid()
    AND (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
  GROUP BY c.id, c.name
  ORDER BY COUNT(ac.id) FILTER (WHERE ad.status = 'active') DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE, UUID[]) TO service_role;


-- 6. get_client_cards_data (version avec 4 paramètres)
DROP FUNCTION IF EXISTS get_client_cards_data(DATE, DATE, TEXT, UUID[]);

CREATE OR REPLACE FUNCTION get_client_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_agent_type_name TEXT DEFAULT NULL,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  active_agents BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id AS client_id,
    c.name AS client_name,
    COUNT(ac.id) FILTER (WHERE ad.status = 'active') AS total_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') AS answered_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active') AS appointments,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS answer_rate,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS conversion_rate,
    ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0 AND ad.status = 'active'), 0), 0) AS avg_duration,
    ROUND(COALESCE(SUM(ac.total_cost) FILTER (WHERE ad.status = 'active'), 0), 2) AS total_cost,
    COUNT(DISTINCT ad.id) FILTER (WHERE ad.status = 'active') AS active_agents
  FROM clients c
  INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
  LEFT JOIN agent_deployments ad ON c.id = ad.client_id
  LEFT JOIN agent_types at ON ad.agent_type_id = at.id
  LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
  WHERE ucp.user_id = auth.uid()
    AND (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
  GROUP BY c.id, c.name
  ORDER BY COUNT(ac.id) FILTER (WHERE ad.status = 'active') DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE, TEXT, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_client_cards_data(DATE, DATE, TEXT, UUID[]) TO service_role;


-- 7. get_agent_type_cards_data
DROP FUNCTION IF EXISTS get_agent_type_cards_data(DATE, DATE, UUID[]);

CREATE OR REPLACE FUNCTION get_agent_type_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
  agent_type_id UUID,
  agent_type_name TEXT,
  display_name TEXT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  active_deployments BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_accessible_client_ids UUID[];
BEGIN
  -- Récupérer les clients accessibles
  SELECT ARRAY_AGG(DISTINCT client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions
  WHERE user_id = auth.uid();

  -- Si p_client_ids est fourni, filtrer
  IF p_client_ids IS NOT NULL THEN
    v_accessible_client_ids := ARRAY(
      SELECT UNNEST(v_accessible_client_ids)
      INTERSECT
      SELECT UNNEST(p_client_ids)
    );
  END IF;

  RETURN QUERY
  SELECT
    at.id AS agent_type_id,
    at.name AS agent_type_name,
    at.display_name,
    COUNT(ac.id) FILTER (WHERE ad.status = 'active') AS total_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') AS answered_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active') AS appointments,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS answer_rate,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active') > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled' AND ad.status = 'active')::NUMERIC / COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL AND ad.status = 'active')::NUMERIC) * 100, 2)
      ELSE 0
    END AS conversion_rate,
    ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0 AND ad.status = 'active'), 0), 0) AS avg_duration,
    ROUND(COALESCE(SUM(ac.total_cost) FILTER (WHERE ad.status = 'active'), 0), 2) AS total_cost,
    COUNT(DISTINCT ad.id) FILTER (WHERE ad.status = 'active') AS active_deployments
  FROM agent_types at
  LEFT JOIN agent_deployments ad ON at.id = ad.agent_type_id
    AND ad.client_id = ANY(v_accessible_client_ids)
  LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
  WHERE at.status = 'active'
  GROUP BY at.id, at.name, at.display_name
  ORDER BY COUNT(ac.id) FILTER (WHERE ad.status = 'active') DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(DATE, DATE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(DATE, DATE, UUID[]) TO service_role;


-- 8. get_agent_cards_data
DROP FUNCTION IF EXISTS get_agent_cards_data(DATE, DATE, UUID, TEXT);

CREATE OR REPLACE FUNCTION get_agent_cards_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  deployment_id UUID,
  deployment_name TEXT,
  client_id UUID,
  client_name TEXT,
  agent_type_name TEXT,
  agent_display_name TEXT,
  total_calls BIGINT,
  answered_calls BIGINT,
  appointments BIGINT,
  answer_rate NUMERIC,
  conversion_rate NUMERIC,
  avg_duration NUMERIC,
  total_cost NUMERIC,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_accessible_client_ids UUID[];
BEGIN
  -- Récupérer les clients accessibles
  SELECT ARRAY_AGG(DISTINCT client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions
  WHERE user_id = auth.uid();

  RETURN QUERY
  SELECT
    ad.id AS deployment_id,
    ad.name AS deployment_name,
    c.id AS client_id,
    c.name AS client_name,
    at.name AS agent_type_name,
    at.display_name AS agent_display_name,
    COUNT(ac.id) AS total_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) AS answered_calls,
    COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments,
    CASE
      WHEN COUNT(ac.id) > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC / COUNT(ac.id)::NUMERIC) * 100, 2)
      ELSE 0
    END AS answer_rate,
    CASE
      WHEN COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) > 0
      THEN ROUND((COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled')::NUMERIC / COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL)::NUMERIC) * 100, 2)
      ELSE 0
    END AS conversion_rate,
    ROUND(COALESCE(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0), 0), 0) AS avg_duration,
    ROUND(COALESCE(SUM(ac.total_cost), 0), 2) AS total_cost,
    ad.status
  FROM agent_deployments ad
  INNER JOIN clients c ON ad.client_id = c.id
  INNER JOIN agent_types at ON ad.agent_type_id = at.id
  LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
  WHERE ad.client_id = ANY(v_accessible_client_ids)
    AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
    AND (p_client_id IS NULL OR c.id = p_client_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
  GROUP BY ad.id, ad.name, c.id, c.name, at.name, at.display_name, ad.status
  ORDER BY COUNT(ac.id) DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_agent_cards_data(DATE, DATE, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_cards_data(DATE, DATE, UUID, TEXT) TO service_role;


-- ============================================================================
-- PARTIE 3: FONCTIONS PERFORMANCE/ANALYTICS
-- ============================================================================

-- 9. get_agent_type_performance
DROP FUNCTION IF EXISTS get_agent_type_performance(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]);

CREATE OR REPLACE FUNCTION get_agent_type_performance(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
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

GRANT EXECUTE ON FUNCTION get_agent_type_performance(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_agent_type_performance(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[]) TO service_role;


-- 10. get_top_clients
DROP FUNCTION IF EXISTS get_top_clients(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[], TEXT, INT);

CREATE OR REPLACE FUNCTION get_top_clients(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_ids UUID[] DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_limit INT DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
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

GRANT EXECUTE ON FUNCTION get_top_clients(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[], TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_clients(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID[], TEXT, INT) TO service_role;


-- 11. get_latency_metrics
DROP FUNCTION IF EXISTS get_latency_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION get_latency_metrics(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_deployment_id UUID DEFAULT NULL,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  date DATE,
  deployment_id UUID,
  deployment_name TEXT,
  client_id UUID,
  client_name TEXT,
  agent_type_name TEXT,
  llm_model TEXT,
  avg_llm_latency_ms NUMERIC,
  min_llm_latency_ms NUMERIC,
  max_llm_latency_ms NUMERIC,
  avg_tts_latency_ms NUMERIC,
  min_tts_latency_ms NUMERIC,
  max_tts_latency_ms NUMERIC,
  avg_total_latency_ms NUMERIC,
  min_total_latency_ms NUMERIC,
  max_total_latency_ms NUMERIC,
  call_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH accessible_calls AS (
    SELECT
      ac.id,
      ac.deployment_id,
      ac.started_at,
      ac.llm_model,
      ac.avg_llm_latency_ms,
      ac.min_llm_latency_ms,
      ac.max_llm_latency_ms,
      ac.avg_tts_latency_ms,
      ac.min_tts_latency_ms,
      ac.max_tts_latency_ms,
      ac.avg_total_latency_ms,
      ac.min_total_latency_ms,
      ac.max_total_latency_ms,
      ad.name AS deployment_name,
      ad.client_id,
      c.name AS client_name,
      at.name AS agent_type_name
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN clients c ON ad.client_id = c.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.user_id = auth.uid()
        AND ucp.client_id = ad.client_id
    )
    AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
    AND ac.avg_llm_latency_ms IS NOT NULL
    AND ac.started_at >= p_start_date
    AND ac.started_at < p_end_date + INTERVAL '1 day'
    AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
  )
  SELECT
    DATE(ac.started_at) AS date,
    ac.deployment_id,
    ac.deployment_name,
    ac.client_id,
    ac.client_name,
    ac.agent_type_name,
    ac.llm_model,
    ROUND(AVG(ac.avg_llm_latency_ms), 2) AS avg_llm_latency_ms,
    MIN(ac.min_llm_latency_ms) AS min_llm_latency_ms,
    MAX(ac.max_llm_latency_ms) AS max_llm_latency_ms,
    ROUND(AVG(ac.avg_tts_latency_ms), 2) AS avg_tts_latency_ms,
    MIN(ac.min_tts_latency_ms) AS min_tts_latency_ms,
    MAX(ac.max_tts_latency_ms) AS max_tts_latency_ms,
    ROUND(AVG(ac.avg_total_latency_ms), 2) AS avg_total_latency_ms,
    MIN(ac.min_total_latency_ms) AS min_total_latency_ms,
    MAX(ac.max_total_latency_ms) AS max_total_latency_ms,
    COUNT(*)::INTEGER AS call_count
  FROM accessible_calls ac
  GROUP BY
    DATE(ac.started_at),
    ac.deployment_id,
    ac.deployment_name,
    ac.client_id,
    ac.client_name,
    ac.agent_type_name,
    ac.llm_model
  ORDER BY
    date DESC,
    deployment_name,
    llm_model;
END;
$$;

GRANT EXECUTE ON FUNCTION get_latency_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_latency_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO service_role;


-- 12. get_cost_breakdown
DROP FUNCTION IF EXISTS get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION get_cost_breakdown(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  WITH call_costs AS (
    SELECT
      COALESCE(SUM(ac.stt_cost), 0) AS stt_cost,
      COALESCE(SUM(ac.tts_cost), 0) AS tts_cost,
      COALESCE(SUM(ac.llm_cost), 0) AS llm_cost,
      COALESCE(SUM(ac.telecom_cost), 0) AS telecom_cost,
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
      COUNT(ac.id) AS call_count
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  ),
  sms_costs AS (
    SELECT
      COALESCE(SUM(s.provider_cost), 0) AS total_cost,
      COUNT(s.id) AS sms_count
    FROM agent_sms s
    INNER JOIN agent_deployments ad ON s.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND s.sent_at >= p_start_date
      AND s.sent_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  ),
  email_costs AS (
    SELECT
      COALESCE(SUM(e.provider_cost), 0) AS total_cost,
      COUNT(e.id) AS email_count
    FROM agent_emails e
    INNER JOIN agent_deployments ad ON e.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND e.sent_at >= p_start_date
      AND e.sent_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  )
  SELECT JSONB_BUILD_OBJECT(
    'call_costs', JSONB_BUILD_OBJECT(
      'stt', (SELECT stt_cost FROM call_costs),
      'tts', (SELECT tts_cost FROM call_costs),
      'llm', (SELECT llm_cost FROM call_costs),
      'telecom', (SELECT telecom_cost FROM call_costs),
      'dipler_commission', 0,
      'total', (SELECT total_cost FROM call_costs)
    ),
    'sms_costs', JSONB_BUILD_OBJECT(
      'total', (SELECT total_cost FROM sms_costs)
    ),
    'email_costs', JSONB_BUILD_OBJECT(
      'total', (SELECT total_cost FROM email_costs)
    ),
    'total_costs', JSONB_BUILD_OBJECT(
      'provider_cost', (
        (SELECT total_cost FROM call_costs) +
        (SELECT total_cost FROM sms_costs) +
        (SELECT total_cost FROM email_costs)
      ),
      'all_channels', (
        (SELECT total_cost FROM call_costs) +
        (SELECT total_cost FROM sms_costs) +
        (SELECT total_cost FROM email_costs)
      )
    ),
    'volume', JSONB_BUILD_OBJECT(
      'calls', (SELECT call_count FROM call_costs),
      'sms', (SELECT sms_count FROM sms_costs),
      'emails', (SELECT email_count FROM email_costs)
    ),
    'revenue', JSONB_BUILD_OBJECT(
      'call_revenue', 0,
      'sms_revenue', 0,
      'email_revenue', 0,
      'total_revenue', 0
    )
  ) INTO v_result;

  RETURN COALESCE(v_result, '{}'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_cost_breakdown: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID) TO service_role;


-- 13. get_sms_metrics
DROP FUNCTION IF EXISTS get_sms_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION get_sms_metrics(
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  total_sms BIGINT,
  total_segments BIGINT,
  delivered_sms BIGINT,
  failed_sms BIGINT,
  pending_sms BIGINT,
  delivery_rate NUMERIC,
  total_revenue NUMERIC,
  total_cost NUMERIC,
  total_margin NUMERIC,
  margin_percentage NUMERIC,
  avg_cost NUMERIC,
  avg_revenue NUMERIC,
  avg_segments NUMERIC,
  prev_total_sms BIGINT,
  prev_delivered_sms BIGINT,
  prev_revenue NUMERIC,
  prev_cost NUMERIC,
  prev_margin NUMERIC,
  total_change NUMERIC,
  delivered_change NUMERIC,
  revenue_change NUMERIC,
  margin_change NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_period_duration INTERVAL;
BEGIN
  v_period_duration := p_end_date - p_start_date;

  RETURN QUERY
  WITH current_period AS (
    SELECT
      COUNT(*) AS total,
      SUM(sms.num_segments) AS segments,
      COUNT(*) FILTER (WHERE sms.status = 'delivered') AS delivered,
      COUNT(*) FILTER (WHERE sms.status = 'failed') AS failed,
      COUNT(*) FILTER (WHERE sms.status = 'sent') AS pending,
      COALESCE(SUM(sms.billed_cost), 0) AS revenue,
      COALESCE(SUM(sms.provider_cost), 0) AS cost,
      COALESCE(SUM(sms.margin), 0) AS margin,
      COALESCE(AVG(sms.provider_cost), 0) AS avg_cost,
      COALESCE(AVG(sms.billed_cost), 0) AS avg_revenue,
      COALESCE(AVG(sms.num_segments), 0) AS avg_segments
    FROM public.v_agent_sms_enriched sms
    INNER JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
    WHERE sms.sent_at >= p_start_date
      AND sms.sent_at < p_end_date
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND (p_client_id IS NULL OR sms.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR sms.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR sms.agent_type_name = p_agent_type_name)
  ),
  previous_period AS (
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (WHERE sms.status = 'delivered') AS delivered,
      COALESCE(SUM(sms.billed_cost), 0) AS revenue,
      COALESCE(SUM(sms.provider_cost), 0) AS cost,
      COALESCE(SUM(sms.margin), 0) AS margin
    FROM public.v_agent_sms_enriched sms
    INNER JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
    WHERE sms.sent_at >= (p_start_date - v_period_duration)
      AND sms.sent_at < p_start_date
      AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
      AND (p_client_id IS NULL OR sms.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR sms.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR sms.agent_type_name = p_agent_type_name)
  )
  SELECT
    cp.total::BIGINT,
    cp.segments::BIGINT,
    cp.delivered::BIGINT,
    cp.failed::BIGINT,
    cp.pending::BIGINT,
    CASE WHEN cp.total > 0 THEN ROUND((cp.delivered::NUMERIC / cp.total) * 100, 2) ELSE 0 END,
    ROUND(cp.revenue, 2),
    ROUND(cp.cost, 2),
    ROUND(cp.margin, 2),
    CASE WHEN cp.revenue > 0 THEN ROUND((cp.margin / cp.revenue) * 100, 2) ELSE 0 END,
    ROUND(cp.avg_cost, 4),
    ROUND(cp.avg_revenue, 4),
    ROUND(cp.avg_segments, 2),
    pp.total::BIGINT,
    pp.delivered::BIGINT,
    ROUND(pp.revenue, 2),
    ROUND(pp.cost, 2),
    ROUND(pp.margin, 2),
    CASE WHEN pp.total > 0 THEN ROUND(((cp.total - pp.total)::NUMERIC / pp.total) * 100, 2) ELSE 0 END,
    CASE WHEN pp.delivered > 0 THEN ROUND(((cp.delivered - pp.delivered)::NUMERIC / pp.delivered) * 100, 2) ELSE 0 END,
    CASE WHEN pp.revenue > 0 THEN ROUND(((cp.revenue - pp.revenue) / pp.revenue) * 100, 2) ELSE 0 END,
    CASE WHEN pp.margin > 0 THEN ROUND(((cp.margin - pp.margin) / pp.margin) * 100, 2) ELSE 0 END
  FROM current_period cp, previous_period pp;
END;
$$;

GRANT EXECUTE ON FUNCTION get_sms_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_sms_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO service_role;


-- 14. get_email_metrics
DROP FUNCTION IF EXISTS get_email_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION get_email_metrics(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_client_id UUID DEFAULT NULL,
    p_deployment_id UUID DEFAULT NULL,
    p_agent_type_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_period_duration INTERVAL;
    v_previous_start_date TIMESTAMP WITH TIME ZONE;
    v_previous_end_date TIMESTAMP WITH TIME ZONE;
    v_current_metrics JSONB;
    v_previous_metrics JSONB;
    v_comparison JSONB;
BEGIN
    v_period_duration := p_end_date - p_start_date;
    v_previous_start_date := p_start_date - v_period_duration;
    v_previous_end_date := p_start_date;

    -- Get current period metrics
    WITH current_period AS (
        SELECT
            COUNT(*) AS total_emails,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_emails,
            COUNT(*) FILTER (WHERE status = 'failed') AS failed_emails,
            COUNT(*) FILTER (WHERE status = 'queued') AS queued_emails,
            CASE
                WHEN COUNT(*) > 0 THEN
                    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
                ELSE 0
            END AS delivery_rate,
            COALESCE(SUM(provider_cost), 0) AS total_provider_cost,
            COALESCE(SUM(billed_cost), 0) AS total_revenue,
            COALESCE(SUM(margin), 0) AS total_margin,
            CASE
                WHEN SUM(billed_cost) > 0 THEN
                    ROUND((SUM(margin) / SUM(billed_cost)) * 100, 2)
                ELSE 0
            END AS margin_percentage,
            ROUND(COALESCE(AVG(provider_cost), 0), 4) AS avg_provider_cost,
            ROUND(COALESCE(AVG(billed_cost), 0), 4) AS avg_billed_cost,
            ROUND(COALESCE(AVG(margin), 0), 4) AS avg_margin,
            ROUND(COALESCE(AVG(word_count), 0), 2) AS avg_word_count,
            ROUND(COALESCE(AVG(html_size_bytes), 0), 2) AS avg_html_size_bytes,
            ROUND(COALESCE(AVG(html_size_bytes) / 1024.0, 0), 2) AS avg_html_size_kb,
            COUNT(DISTINCT email_address) AS unique_recipients,
            COUNT(*) FILTER (WHERE has_attachments = TRUE) AS emails_with_attachments,
            COUNT(*) FILTER (WHERE call_id IS NOT NULL) AS emails_linked_to_calls,
            COUNT(*) FILTER (WHERE prospect_id IS NOT NULL) AS emails_linked_to_prospects,
            COUNT(*) FILTER (WHERE sequence_id IS NOT NULL) AS emails_in_sequences,
            COUNT(*) FILTER (WHERE opened_at IS NOT NULL) AS opened_emails,
            COUNT(*) FILTER (WHERE first_clicked_at IS NOT NULL) AS clicked_emails,
            COUNT(*) FILTER (WHERE bounce_type IS NOT NULL) AS bounced_emails
        FROM public.agent_emails em
        WHERE em.sent_at >= p_start_date
            AND em.sent_at < p_end_date
            AND em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
                  AND (p_client_id IS NULL OR ad.client_id = p_client_id)
            )
            AND (p_deployment_id IS NULL OR em.deployment_id = p_deployment_id)
            AND (p_agent_type_name IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                JOIN public.agent_types at ON ad.agent_type_id = at.id
                WHERE at.name = p_agent_type_name
                  AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
            ))
    )
    SELECT JSONB_BUILD_OBJECT(
        'total_emails', cp.total_emails,
        'sent_emails', cp.sent_emails,
        'failed_emails', cp.failed_emails,
        'queued_emails', cp.queued_emails,
        'delivery_rate', cp.delivery_rate,
        'total_provider_cost', cp.total_provider_cost,
        'total_revenue', cp.total_revenue,
        'total_margin', cp.total_margin,
        'margin_percentage', cp.margin_percentage,
        'avg_provider_cost', cp.avg_provider_cost,
        'avg_billed_cost', cp.avg_billed_cost,
        'avg_margin', cp.avg_margin,
        'avg_word_count', cp.avg_word_count,
        'avg_html_size_bytes', cp.avg_html_size_bytes,
        'avg_html_size_kb', cp.avg_html_size_kb,
        'unique_recipients', cp.unique_recipients,
        'emails_with_attachments', cp.emails_with_attachments,
        'emails_linked_to_calls', cp.emails_linked_to_calls,
        'emails_linked_to_prospects', cp.emails_linked_to_prospects,
        'emails_in_sequences', cp.emails_in_sequences,
        'opened_emails', cp.opened_emails,
        'clicked_emails', cp.clicked_emails,
        'bounced_emails', cp.bounced_emails,
        'open_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.opened_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END,
        'click_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.clicked_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END,
        'bounce_rate', CASE
            WHEN cp.sent_emails > 0 THEN
                ROUND((cp.bounced_emails::NUMERIC / cp.sent_emails::NUMERIC) * 100, 2)
            ELSE 0
        END
    ) INTO v_current_metrics
    FROM current_period cp;

    -- Get previous period metrics
    WITH previous_period AS (
        SELECT
            COUNT(*) AS total_emails,
            COUNT(*) FILTER (WHERE status = 'sent') AS sent_emails,
            CASE
                WHEN COUNT(*) > 0 THEN
                    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
                ELSE 0
            END AS delivery_rate,
            COALESCE(SUM(provider_cost), 0) AS total_provider_cost,
            COALESCE(SUM(billed_cost), 0) AS total_revenue,
            COALESCE(SUM(margin), 0) AS total_margin
        FROM public.agent_emails em
        WHERE em.sent_at >= v_previous_start_date
            AND em.sent_at < v_previous_end_date
            AND em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
                  AND (p_client_id IS NULL OR ad.client_id = p_client_id)
            )
            AND (p_deployment_id IS NULL OR em.deployment_id = p_deployment_id)
            AND (p_agent_type_name IS NULL OR em.deployment_id IN (
                SELECT ad.id FROM public.agent_deployments ad
                JOIN public.agent_types at ON ad.agent_type_id = at.id
                WHERE at.name = p_agent_type_name
                  AND ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
            ))
    )
    SELECT JSONB_BUILD_OBJECT(
        'total_emails', pp.total_emails,
        'sent_emails', pp.sent_emails,
        'delivery_rate', pp.delivery_rate,
        'total_provider_cost', pp.total_provider_cost,
        'total_revenue', pp.total_revenue,
        'total_margin', pp.total_margin
    ) INTO v_previous_metrics
    FROM previous_period pp;

    -- Calculate comparison
    v_comparison := JSONB_BUILD_OBJECT(
        'total_emails_change', CASE
            WHEN (v_previous_metrics->>'total_emails')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_emails')::NUMERIC - (v_previous_metrics->>'total_emails')::NUMERIC) / (v_previous_metrics->>'total_emails')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'sent_emails_change', CASE
            WHEN (v_previous_metrics->>'sent_emails')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'sent_emails')::NUMERIC - (v_previous_metrics->>'sent_emails')::NUMERIC) / (v_previous_metrics->>'sent_emails')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'delivery_rate_change', (v_current_metrics->>'delivery_rate')::NUMERIC - (v_previous_metrics->>'delivery_rate')::NUMERIC,
        'total_provider_cost_change', CASE
            WHEN (v_previous_metrics->>'total_provider_cost')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_provider_cost')::NUMERIC - (v_previous_metrics->>'total_provider_cost')::NUMERIC) / (v_previous_metrics->>'total_provider_cost')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'total_revenue_change', CASE
            WHEN (v_previous_metrics->>'total_revenue')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_revenue')::NUMERIC - (v_previous_metrics->>'total_revenue')::NUMERIC) / (v_previous_metrics->>'total_revenue')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'total_margin_change', CASE
            WHEN (v_previous_metrics->>'total_margin')::NUMERIC > 0 THEN
                ROUND(((v_current_metrics->>'total_margin')::NUMERIC - (v_previous_metrics->>'total_margin')::NUMERIC) / (v_previous_metrics->>'total_margin')::NUMERIC * 100, 2)
            ELSE NULL
        END,
        'margin_percentage_change', (v_current_metrics->>'margin_percentage')::NUMERIC - (v_previous_metrics->>'margin_percentage')::NUMERIC
    );

    RETURN JSONB_BUILD_OBJECT(
        'current_period', v_current_metrics,
        'previous_period', v_previous_metrics,
        'comparison', v_comparison,
        'period_info', JSONB_BUILD_OBJECT(
            'start_date', p_start_date,
            'end_date', p_end_date,
            'previous_start_date', v_previous_start_date,
            'previous_end_date', v_previous_end_date
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION get_email_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_email_metrics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, UUID, UUID, TEXT) TO service_role;


-- ============================================================================
-- PARTIE 4: VUES
-- ============================================================================

-- 15. v_financial_metrics_enriched
DROP VIEW IF EXISTS v_financial_metrics_enriched;

CREATE OR REPLACE VIEW v_financial_metrics_enriched AS
WITH deployment_base AS (
    SELECT
        d.id AS deployment_id,
        d.client_id,
        d.agent_type_id,
        at.name AS agent_type_name,
        c.name AS client_name,
        d.leasing,
        d.cost_per_min,
        d.cost_per_sms,
        d.cost_per_email,
        d.created_at AS deployment_start_date,
        d.status AS deployment_status,
        (EXISTS (
            SELECT 1
            FROM user_client_permissions ucp
            WHERE ucp.client_id = d.client_id AND ucp.user_id = auth.uid()
        )) AS user_has_access
    FROM agent_deployments d
    JOIN agent_types at ON d.agent_type_id = at.id
    JOIN clients c ON d.client_id = c.id
    WHERE d.status = 'active'  -- FILTRE: Uniquement les agents actifs
),
call_metrics AS (
    SELECT
        ac.deployment_id,
        date_trunc('day', ac.created_at) AS metric_date,
        count(*) AS call_count,
        count(*) FILTER (WHERE ac.answered = true) AS answered_calls,
        count(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
        sum(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS total_duration_seconds,
        avg(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS avg_duration_seconds,
        sum(ac.duration_seconds::numeric / 60.0 * db.cost_per_min) AS call_revenue,
        sum(COALESCE(ac.total_cost, 0::numeric)) AS call_provider_cost
    FROM v_agent_calls_enriched ac
    JOIN deployment_base db ON ac.deployment_id = db.deployment_id
    WHERE ac.created_at IS NOT NULL
    GROUP BY ac.deployment_id, date_trunc('day', ac.created_at)
),
sms_metrics AS (
    SELECT
        asms.deployment_id,
        date_trunc('day', asms.sent_at) AS metric_date,
        count(*) AS sms_count,
        count(*) FILTER (WHERE asms.delivered_at IS NOT NULL) AS sms_delivered,
        sum(COALESCE(asms.billed_cost, 0::numeric)) AS sms_revenue,
        sum(COALESCE(asms.provider_cost, 0::numeric)) AS sms_provider_cost
    FROM agent_sms asms
    JOIN deployment_base db ON asms.deployment_id = db.deployment_id
    WHERE asms.sent_at IS NOT NULL
    GROUP BY asms.deployment_id, date_trunc('day', asms.sent_at)
),
email_metrics AS (
    SELECT
        ae.deployment_id,
        date_trunc('day', ae.sent_at) AS metric_date,
        count(*) AS email_count,
        count(*) FILTER (WHERE ae.sent_at IS NOT NULL AND ae.failed_at IS NULL) AS email_delivered,
        sum(COALESCE(ae.billed_cost, 0::numeric)) AS email_revenue,
        sum(COALESCE(ae.provider_cost, 0::numeric)) AS email_provider_cost
    FROM agent_emails ae
    JOIN deployment_base db ON ae.deployment_id = db.deployment_id
    WHERE ae.sent_at IS NOT NULL
    GROUP BY ae.deployment_id, date_trunc('day', ae.sent_at)
),
all_metric_dates AS (
    SELECT DISTINCT combined_dates.deployment_id, combined_dates.metric_date
    FROM (
        SELECT deployment_id, metric_date FROM call_metrics
        UNION
        SELECT deployment_id, metric_date FROM sms_metrics
        UNION
        SELECT deployment_id, metric_date FROM email_metrics
    ) combined_dates
),
combined_metrics AS (
    SELECT
        amd.deployment_id,
        amd.metric_date,
        db.client_id,
        db.client_name,
        db.agent_type_id,
        db.agent_type_name,
        db.deployment_status,
        db.user_has_access,
        COALESCE(cm.call_count, 0::bigint) AS call_count,
        COALESCE(cm.answered_calls, 0::bigint) AS answered_calls,
        COALESCE(cm.appointments_scheduled, 0::bigint) AS appointments_scheduled,
        COALESCE(cm.total_duration_seconds, 0::bigint) AS total_duration_seconds,
        COALESCE(cm.avg_duration_seconds, 0::numeric) AS avg_duration_seconds,
        COALESCE(cm.call_revenue, 0::numeric) AS call_revenue,
        COALESCE(cm.call_provider_cost, 0::numeric) AS call_provider_cost,
        COALESCE(sm.sms_count, 0::bigint) AS sms_count,
        COALESCE(sm.sms_delivered, 0::bigint) AS sms_delivered,
        COALESCE(sm.sms_revenue, 0::numeric) AS sms_revenue,
        COALESCE(sm.sms_provider_cost, 0::numeric) AS sms_provider_cost,
        COALESCE(em.email_count, 0::bigint) AS email_count,
        COALESCE(em.email_delivered, 0::bigint) AS email_delivered,
        COALESCE(em.email_revenue, 0::numeric) AS email_revenue,
        COALESCE(em.email_provider_cost, 0::numeric) AS email_provider_cost,
        COALESCE(db.leasing / 30.0, 0::numeric) AS leasing_revenue_daily,
        COALESCE(cm.call_revenue, 0::numeric) + COALESCE(sm.sms_revenue, 0::numeric) + COALESCE(em.email_revenue, 0::numeric) + COALESCE(db.leasing / 30.0, 0::numeric) AS total_revenue,
        COALESCE(cm.call_provider_cost, 0::numeric) + COALESCE(sm.sms_provider_cost, 0::numeric) + COALESCE(em.email_provider_cost, 0::numeric) AS total_provider_cost,
        COALESCE(cm.call_revenue, 0::numeric) + COALESCE(sm.sms_revenue, 0::numeric) + COALESCE(em.email_revenue, 0::numeric) + COALESCE(db.leasing / 30.0, 0::numeric) - (COALESCE(cm.call_provider_cost, 0::numeric) + COALESCE(sm.sms_provider_cost, 0::numeric) + COALESCE(em.email_provider_cost, 0::numeric)) AS total_margin
    FROM all_metric_dates amd
    JOIN deployment_base db ON amd.deployment_id = db.deployment_id
    LEFT JOIN call_metrics cm ON amd.deployment_id = cm.deployment_id AND amd.metric_date = cm.metric_date
    LEFT JOIN sms_metrics sm ON amd.deployment_id = sm.deployment_id AND amd.metric_date = sm.metric_date
    LEFT JOIN email_metrics em ON amd.deployment_id = em.deployment_id AND amd.metric_date = em.metric_date
)
SELECT
    deployment_id,
    metric_date,
    client_id,
    client_name,
    agent_type_id,
    agent_type_name,
    deployment_status,
    user_has_access,
    call_count,
    answered_calls,
    appointments_scheduled,
    total_duration_seconds,
    avg_duration_seconds,
    call_revenue,
    call_provider_cost,
    sms_count,
    sms_delivered,
    sms_revenue,
    sms_provider_cost,
    email_count,
    email_delivered,
    email_revenue,
    email_provider_cost,
    leasing_revenue_daily,
    total_revenue,
    total_provider_cost,
    total_margin,
    CASE
        WHEN total_revenue > 0::numeric THEN total_margin / total_revenue * 100::numeric
        ELSE 0::numeric
    END AS margin_percentage
FROM combined_metrics;

GRANT SELECT ON v_financial_metrics_enriched TO authenticated;
GRANT SELECT ON v_financial_metrics_enriched TO service_role;


-- 16. v_global_kpis
DROP VIEW IF EXISTS v_global_kpis;

CREATE OR REPLACE VIEW v_global_kpis AS
WITH period_calls AS (
    SELECT
        ac.id,
        ac.deployment_id,
        ac.first_name,
        ac.last_name,
        ac.email,
        ac.phone_number,
        ac.started_at,
        ac.ended_at,
        ac.duration_seconds,
        ac.outcome,
        ac.emotion,
        ac.total_cost,
        ac.transcript,
        ac.transcript_summary,
        ac.recording_url,
        ac.metadata,
        ac.created_at,
        ac.prospect_id,
        ac.sequence_id,
        ac.conversation_id,
        ac.call_sid,
        ac.stt_cost,
        ac.tts_cost,
        ac.llm_cost,
        ac.telecom_cost,
        ac.dipler_commission,
        ac.cost_per_minute,
        ac.call_quality_score,
        ac.sentiment_analysis,
        ac.llm_model,
        ac.tts_provider,
        ac.tts_voice_id,
        ac.stt_provider,
        ac.direction,
        ac.call_status,
        ac.provider,
        CASE
            WHEN ac.outcome = ANY (ARRAY['voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected']) THEN false
            WHEN ac.outcome IS NULL THEN false
            ELSE true
        END AS answered,
        CASE
            WHEN ac.outcome = 'appointment_scheduled' THEN true
            ELSE false
        END AS appointment_scheduled
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
),
current_period AS (
    SELECT
        count(*) AS total_calls,
        count(*) FILTER (WHERE period_calls.answered) AS answered_calls,
        count(*) FILTER (WHERE period_calls.appointment_scheduled) AS appointments_scheduled,
        round(avg(period_calls.duration_seconds) FILTER (WHERE period_calls.duration_seconds > 0), 0) AS avg_duration,
        sum(period_calls.total_cost) AS total_cost
    FROM period_calls
    WHERE period_calls.started_at >= (CURRENT_DATE - '30 days'::interval)
),
previous_period AS (
    SELECT
        count(*) AS total_calls,
        count(*) FILTER (WHERE period_calls.answered) AS answered_calls,
        count(*) FILTER (WHERE period_calls.appointment_scheduled) AS appointments_scheduled,
        round(avg(period_calls.duration_seconds) FILTER (WHERE period_calls.duration_seconds > 0), 0) AS avg_duration,
        sum(period_calls.total_cost) AS total_cost
    FROM period_calls
    WHERE period_calls.started_at >= (CURRENT_DATE - '60 days'::interval)
      AND period_calls.started_at < (CURRENT_DATE - '30 days'::interval)
)
SELECT
    jsonb_build_object(
        'total_calls', cp.total_calls,
        'answered_calls', cp.answered_calls,
        'appointments_scheduled', cp.appointments_scheduled,
        'avg_duration', cp.avg_duration,
        'total_cost', cp.total_cost
    ) AS current_period,
    jsonb_build_object(
        'total_calls', pp.total_calls,
        'answered_calls', pp.answered_calls,
        'appointments_scheduled', pp.appointments_scheduled,
        'avg_duration', pp.avg_duration,
        'total_cost', pp.total_cost
    ) AS previous_period
FROM current_period cp, previous_period pp;

GRANT SELECT ON v_global_kpis TO authenticated;
GRANT SELECT ON v_global_kpis TO service_role;


-- 17. v_global_call_volume_by_day
DROP VIEW IF EXISTS v_global_call_volume_by_day;

CREATE OR REPLACE VIEW v_global_call_volume_by_day AS
SELECT
    date(ac.started_at) AS call_date,
    count(*) AS total_calls,
    count(*) FILTER (WHERE (ac.outcome <> ALL (ARRAY['voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected'])) AND ac.outcome IS NOT NULL) AS answered_calls,
    count(*) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,
    sum(ac.total_cost) AS total_cost,
    avg(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS avg_duration
FROM agent_calls ac
INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
GROUP BY date(ac.started_at)
ORDER BY date(ac.started_at) DESC;

GRANT SELECT ON v_global_call_volume_by_day TO authenticated;
GRANT SELECT ON v_global_call_volume_by_day TO service_role;


-- 18. v_global_outcome_distribution
DROP VIEW IF EXISTS v_global_outcome_distribution;

CREATE OR REPLACE VIEW v_global_outcome_distribution AS
SELECT
    COALESCE(ac.outcome, 'unknown') AS outcome,
    count(*) AS count,
    round(count(*)::numeric * 100.0 / sum(count(*)) OVER (), 2) AS percentage
FROM agent_calls ac
INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
GROUP BY ac.outcome
ORDER BY count(*) DESC;

GRANT SELECT ON v_global_outcome_distribution TO authenticated;
GRANT SELECT ON v_global_outcome_distribution TO service_role;


-- 19. v_global_top_clients
DROP VIEW IF EXISTS v_global_top_clients;

CREATE OR REPLACE VIEW v_global_top_clients AS
SELECT
    c.id AS client_id,
    c.name AS client_name,
    count(ac.id) AS total_calls,
    count(ac.id) FILTER (WHERE (ac.outcome <> ALL (ARRAY['voicemail', 'call_failed', 'no_answer', 'busy', 'invalid_number', 'error', 'canceled', 'rejected'])) AND ac.outcome IS NOT NULL) AS answered_calls,
    count(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,
    sum(ac.total_cost) AS total_cost
FROM agent_calls ac
JOIN agent_deployments ad ON ac.deployment_id = ad.id
JOIN clients c ON ad.client_id = c.id
WHERE ad.status = 'active'  -- FILTRE: Uniquement les agents actifs
GROUP BY c.id, c.name
ORDER BY count(ac.id) DESC;

GRANT SELECT ON v_global_top_clients TO authenticated;
GRANT SELECT ON v_global_top_clients TO service_role;


-- ============================================================================
-- PARTIE 5: TRAÇABILITÉ MIGRATION
-- ============================================================================

-- Insérer l'entrée de migration pour traçabilité
-- Note: La table schema_migrations a les colonnes: version, name, statements, created_by, idempotency_key, rollback
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('20251215120000', 'filter_kpis_by_active_agents')
ON CONFLICT (version) DO NOTHING;


-- ============================================================================
-- FIN DE LA MIGRATION
-- ============================================================================

-- Vérification (à exécuter après la migration):
-- SELECT COUNT(*) as total_calls,
--        COUNT(*) FILTER (WHERE ad.status = 'active') as active_agent_calls,
--        COUNT(*) FILTER (WHERE ad.status != 'active') as inactive_agent_calls
-- FROM agent_calls ac
-- JOIN agent_deployments ad ON ac.deployment_id = ad.id;
