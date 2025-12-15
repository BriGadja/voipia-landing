-- Migration: Consumption Dashboard Charts Data
-- Date: 2025-12-15
-- Description: Ajoute la fonction get_consumption_chart_data() pour le nouveau dashboard Ma Conso
-- SECURITE: Ne retourne JAMAIS provider_cost, margin, margin_percentage aux utilisateurs

-- ============================================================================
-- Fonction: get_consumption_chart_data()
-- Retourne les donnees pour les graphiques du dashboard consommation
-- ============================================================================

DROP FUNCTION IF EXISTS get_consumption_chart_data(DATE, DATE, UUID);

CREATE OR REPLACE FUNCTION get_consumption_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_admin BOOLEAN;
  v_result JSONB;
  v_daily_consumption JSONB;
  v_by_channel JSONB;
  v_by_agent JSONB;
  v_by_client JSONB;
BEGIN
  -- Get current user
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Check if user is admin (using existing is_admin() function)
  v_is_admin := is_admin();

  -- =========================================================================
  -- 1. Daily Consumption (for time series chart)
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(daily_row ORDER BY daily_row->>'date'), '[]'::jsonb)
  INTO v_daily_consumption
  FROM (
    SELECT jsonb_build_object(
      'date', (fm.metric_date::date)::text,
      'call_cost', COALESCE(SUM(fm.call_revenue), 0),
      'sms_cost', COALESCE(SUM(fm.sms_revenue), 0),
      'email_cost', COALESCE(SUM(fm.email_revenue), 0),
      'total_minutes', COALESCE(SUM(fm.total_duration_seconds) / 60.0, 0),
      'total_sms', COALESCE(SUM(fm.sms_count), 0),
      'total_emails', COALESCE(SUM(fm.email_count), 0)
    ) as daily_row
    FROM v_financial_metrics_enriched fm
    WHERE fm.metric_date::date BETWEEN p_start_date AND p_end_date
      AND (
        v_is_admin = true
        OR EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_user_id
            AND ucp.client_id = fm.client_id
        )
      )
      AND (p_client_id IS NULL OR fm.client_id = p_client_id)
    GROUP BY fm.metric_date::date
  ) daily_data;

  -- =========================================================================
  -- 2. Channel Breakdown (for donut chart)
  -- =========================================================================
  SELECT jsonb_build_object(
    'calls', jsonb_build_object(
      'volume', COALESCE(SUM(fm.call_count), 0),
      'cost', COALESCE(SUM(fm.call_revenue), 0)
    ),
    'sms', jsonb_build_object(
      'volume', COALESCE(SUM(fm.sms_count), 0),
      'cost', COALESCE(SUM(fm.sms_revenue), 0)
    ),
    'emails', jsonb_build_object(
      'volume', COALESCE(SUM(fm.email_count), 0),
      'cost', COALESCE(SUM(fm.email_revenue), 0)
    )
  )
  INTO v_by_channel
  FROM v_financial_metrics_enriched fm
  WHERE fm.metric_date::date BETWEEN p_start_date AND p_end_date
    AND (
      v_is_admin = true
      OR EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.user_id = v_user_id
          AND ucp.client_id = fm.client_id
      )
    )
    AND (p_client_id IS NULL OR fm.client_id = p_client_id);

  -- =========================================================================
  -- 3. By Agent (for horizontal bar chart - top 10)
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(agent_row), '[]'::jsonb)
  INTO v_by_agent
  FROM (
    SELECT jsonb_build_object(
      'deployment_id', fm.deployment_id::text,
      'deployment_name', COALESCE(ad.name, 'Unknown'),
      'agent_type', COALESCE(at.name, 'unknown'),
      'total_cost', COALESCE(SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue), 0),
      'total_minutes', COALESCE(SUM(fm.total_duration_seconds) / 60.0, 0),
      'total_sms', COALESCE(SUM(fm.sms_count), 0),
      'total_emails', COALESCE(SUM(fm.email_count), 0)
    ) as agent_row
    FROM v_financial_metrics_enriched fm
    LEFT JOIN agent_deployments ad ON ad.id = fm.deployment_id
    LEFT JOIN agent_types at ON at.id = ad.agent_type_id
    WHERE fm.metric_date::date BETWEEN p_start_date AND p_end_date
      AND (
        v_is_admin = true
        OR EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_user_id
            AND ucp.client_id = fm.client_id
        )
      )
      AND (p_client_id IS NULL OR fm.client_id = p_client_id)
    GROUP BY fm.deployment_id, ad.name, at.name
    ORDER BY SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue) DESC
    LIMIT 10
  ) agent_data;

  -- =========================================================================
  -- 4. By Client (for horizontal bar chart - top 10)
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(client_row), '[]'::jsonb)
  INTO v_by_client
  FROM (
    SELECT jsonb_build_object(
      'client_id', fm.client_id::text,
      'client_name', COALESCE(fm.client_name, 'Unknown'),
      'total_cost', COALESCE(SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue), 0)
    ) as client_row
    FROM v_financial_metrics_enriched fm
    WHERE fm.metric_date::date BETWEEN p_start_date AND p_end_date
      AND (
        v_is_admin = true
        OR EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_user_id
            AND ucp.client_id = fm.client_id
        )
      )
      AND (p_client_id IS NULL OR fm.client_id = p_client_id)
    GROUP BY fm.client_id, fm.client_name
    ORDER BY SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue) DESC
    LIMIT 10
  ) client_data;

  -- =========================================================================
  -- Build final result
  -- =========================================================================
  v_result := jsonb_build_object(
    'daily_consumption', v_daily_consumption,
    'by_channel', v_by_channel,
    'by_agent', v_by_agent,
    'by_client', v_by_client
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_consumption_chart_data(DATE, DATE, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_consumption_chart_data IS 'Returns consumption chart data for Ma Conso dashboard. SECURITY: Never returns provider_cost or margin data.';

-- ============================================================================
-- Verification query (commented out for production)
-- ============================================================================
-- SELECT get_consumption_chart_data('2025-11-01'::date, '2025-11-30'::date, NULL);
