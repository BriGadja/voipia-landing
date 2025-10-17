-- Migration: Mettre à jour les fonctions RPC du dashboard Louis pour utiliser agent_calls au lieu de calls
-- ================================================================================

-- DROP les anciennes fonctions
DROP FUNCTION IF EXISTS public.get_kpi_metrics(timestamptz, timestamptz, uuid, uuid);
DROP FUNCTION IF EXISTS public.get_chart_data(timestamptz, timestamptz, uuid, uuid);

-- ================================================================================
-- FONCTION: get_kpi_metrics - VERSION AGENT_CALLS
-- ================================================================================
-- Calcule les KPIs pour le dashboard Louis en utilisant la table agent_calls
-- Filtre automatiquement sur agent_type = 'louis'
CREATE OR REPLACE FUNCTION public.get_kpi_metrics(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  prev_start_date TIMESTAMPTZ;
  prev_end_date TIMESTAMPTZ;
BEGIN
  -- Calculer période précédente de même durée
  prev_end_date := p_start_date - INTERVAL '1 second';
  prev_start_date := prev_end_date - (p_end_date - p_start_date);

  -- Construire le JSON de résultats
  SELECT json_build_object(
    'current_period', (
      SELECT json_build_object(
        'appointments_scheduled', COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL),
        'answer_rate', COALESCE(
          ROUND(
            (COUNT(*) FILTER (WHERE ac.outcome IN ('rdv_pris', 'refus', 'callback_requested', 'not_interested'))::NUMERIC
             / NULLIF(COUNT(*), 0) * 100
            ), 2
          ), 0
        ),
        'avg_duration', COALESCE(ROUND(AVG(ac.duration_seconds)), 0),
        'avg_cost', COALESCE(ROUND(AVG(ac.cost)::NUMERIC, 2), 0),
        'conversion_rate', COALESCE(
          ROUND(
            (COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL)::NUMERIC
             / NULLIF(COUNT(*) FILTER (WHERE ac.outcome IN ('rdv_pris', 'refus', 'callback_requested', 'not_interested')), 0) * 100
            ), 2
          ), 0
        ),
        'total_cost', COALESCE(ROUND(SUM(ac.cost)::NUMERIC, 2), 0),
        'total_calls', COUNT(*),
        'cpa', COALESCE(
          ROUND(
            (SUM(ac.cost) / NULLIF(COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL), 0))::NUMERIC,
            2
          ), 0
        )
      )
      FROM agent_calls ac
      JOIN agent_deployments ad ON ac.deployment_id = ad.id
      JOIN agent_types at ON ad.agent_type_id = at.id
      WHERE ac.started_at >= p_start_date
        AND ac.started_at <= p_end_date
        AND at.name = 'louis'  -- Filtre Louis uniquement
        AND (p_client_id IS NULL OR ad.client_id = p_client_id)
        AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    ),
    'previous_period', (
      SELECT json_build_object(
        'appointments_scheduled', COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL),
        'answer_rate', COALESCE(
          ROUND(
            (COUNT(*) FILTER (WHERE ac.outcome IN ('rdv_pris', 'refus', 'callback_requested', 'not_interested'))::NUMERIC
             / NULLIF(COUNT(*), 0) * 100
            ), 2
          ), 0
        ),
        'avg_duration', COALESCE(ROUND(AVG(ac.duration_seconds)), 0),
        'avg_cost', COALESCE(ROUND(AVG(ac.cost)::NUMERIC, 2), 0),
        'conversion_rate', COALESCE(
          ROUND(
            (COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL)::NUMERIC
             / NULLIF(COUNT(*) FILTER (WHERE ac.outcome IN ('rdv_pris', 'refus', 'callback_requested', 'not_interested')), 0) * 100
            ), 2
          ), 0
        ),
        'total_calls', COUNT(*)
      )
      FROM agent_calls ac
      JOIN agent_deployments ad ON ac.deployment_id = ad.id
      JOIN agent_types at ON ad.agent_type_id = at.id
      WHERE ac.started_at >= prev_start_date
        AND ac.started_at <= prev_end_date
        AND at.name = 'louis'  -- Filtre Louis uniquement
        AND (p_client_id IS NULL OR ad.client_id = p_client_id)
        AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
    )
  )
  INTO result;

  RETURN result;
END;
$$;

-- ================================================================================
-- FONCTION: get_chart_data - VERSION AGENT_CALLS
-- ================================================================================
-- Récupère les données pour les 4 charts du dashboard Louis
-- Filtre automatiquement sur agent_type = 'louis'
CREATE OR REPLACE FUNCTION public.get_chart_data(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'call_volume_by_day', (
      SELECT json_agg(row_to_json(t) ORDER BY t.date)
      FROM (
        SELECT
          DATE(ac.started_at) AS date,
          COUNT(*) AS total_calls,
          COUNT(*) FILTER (WHERE ac.outcome IN ('rdv_pris', 'refus', 'not_interested', 'callback_requested')) AS answered_calls,
          COUNT(*) FILTER (WHERE (ac.metadata->>'appointment_scheduled_at') IS NOT NULL) AS appointments
        FROM agent_calls ac
        JOIN agent_deployments ad ON ac.deployment_id = ad.id
        JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date
          AND at.name = 'louis'
          AND (p_client_id IS NULL OR ad.client_id = p_client_id)
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        GROUP BY DATE(ac.started_at)
      ) t
    ),
    'emotion_distribution', (
      SELECT json_agg(row_to_json(t) ORDER BY t.count DESC)
      FROM (
        SELECT COALESCE(ac.emotion, 'unknown') AS emotion, COUNT(*) AS count
        FROM agent_calls ac
        JOIN agent_deployments ad ON ac.deployment_id = ad.id
        JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date
          AND at.name = 'louis'
          AND (p_client_id IS NULL OR ad.client_id = p_client_id)
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        GROUP BY COALESCE(ac.emotion, 'unknown')
      ) t
    ),
    'outcome_distribution', (
      SELECT json_agg(row_to_json(t) ORDER BY t.count DESC)
      FROM (
        SELECT ac.outcome::TEXT AS outcome, COUNT(*) AS count
        FROM agent_calls ac
        JOIN agent_deployments ad ON ac.deployment_id = ad.id
        JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date
          AND at.name = 'louis'
          AND (p_client_id IS NULL OR ad.client_id = p_client_id)
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
          AND ac.outcome IS NOT NULL
        GROUP BY ac.outcome
      ) t
    ),
    'voicemail_by_agent', (
      SELECT json_agg(row_to_json(t) ORDER BY t.rate DESC)
      FROM (
        SELECT
          COALESCE(ad.name, 'Unknown') AS agent,
          COUNT(*) FILTER (WHERE ac.outcome = 'voicemail') AS voicemail_count,
          COUNT(*) AS total_count,
          ROUND(
            (COUNT(*) FILTER (WHERE ac.outcome = 'voicemail')::NUMERIC
             / NULLIF(COUNT(*), 0) * 100)
           , 2
          ) AS rate
        FROM agent_calls ac
        JOIN agent_deployments ad ON ac.deployment_id = ad.id
        JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE ac.started_at >= p_start_date
          AND ac.started_at <= p_end_date
          AND at.name = 'louis'
          AND (p_client_id IS NULL OR ad.client_id = p_client_id)
          AND (p_deployment_id IS NULL OR ac.deployment_id = p_deployment_id)
        GROUP BY COALESCE(ad.name, 'Unknown')
      ) t
    )
  )
  INTO result;

  RETURN result;
END;
$$;

-- ================================================================================
-- COMMENTAIRES
-- ================================================================================
COMMENT ON FUNCTION public.get_kpi_metrics IS 'Calcule les KPIs du dashboard Louis depuis agent_calls (filtre sur agent_type=louis). Paramètre p_deployment_id au lieu de p_agent_id.';
COMMENT ON FUNCTION public.get_chart_data IS 'Récupère les données des charts Louis depuis agent_calls (filtre sur agent_type=louis). Paramètre p_deployment_id au lieu de p_agent_id.';
