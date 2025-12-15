-- Migration: Consumption Dashboard View As User Support
-- Date: 2025-12-15
-- Description: Modifie get_consumption_chart_data pour supporter view_as_user
--              et ajoute les données d'historique mensuel à la place de by_client
-- SECURITE: Ne retourne JAMAIS provider_cost, margin, margin_percentage aux utilisateurs

DROP FUNCTION IF EXISTS get_consumption_chart_data(DATE, DATE, UUID);
DROP FUNCTION IF EXISTS get_consumption_chart_data(DATE, DATE, UUID, UUID);

CREATE OR REPLACE FUNCTION get_consumption_chart_data(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_view_as_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_admin BOOLEAN;
  v_effective_user_id UUID;
  v_result JSONB;
  v_daily_consumption JSONB;
  v_by_channel JSONB;
  v_by_agent JSONB;
  v_monthly_history JSONB;
BEGIN
  -- Get current user
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Check if user is admin
  v_is_admin := is_admin();

  -- Determine effective user ID for permissions
  -- If admin and view_as_user_id is provided, use that user's permissions
  IF v_is_admin AND p_view_as_user_id IS NOT NULL THEN
    v_effective_user_id := p_view_as_user_id;
  ELSE
    v_effective_user_id := v_user_id;
  END IF;

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
        -- Admin viewing as self (no view_as_user) sees everything
        (v_is_admin = true AND p_view_as_user_id IS NULL)
        OR
        -- Otherwise filter by effective user's permissions
        EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_effective_user_id
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
      (v_is_admin = true AND p_view_as_user_id IS NULL)
      OR
      EXISTS (
        SELECT 1 FROM user_client_permissions ucp
        WHERE ucp.user_id = v_effective_user_id
          AND ucp.client_id = fm.client_id
      )
    )
    AND (p_client_id IS NULL OR fm.client_id = p_client_id);

  -- =========================================================================
  -- 3. By Agent (for horizontal bar chart - top 10)
  -- Filtered by user's accessible agents
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
        (v_is_admin = true AND p_view_as_user_id IS NULL)
        OR
        EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_effective_user_id
            AND ucp.client_id = fm.client_id
        )
      )
      AND (p_client_id IS NULL OR fm.client_id = p_client_id)
    GROUP BY fm.deployment_id, ad.name, at.name
    ORDER BY SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue) DESC
    LIMIT 10
  ) agent_data;

  -- =========================================================================
  -- 4. Monthly History (last 6 months comparison)
  -- Replaces "by_client" which is not useful for non-admin users
  -- =========================================================================
  SELECT COALESCE(jsonb_agg(month_row ORDER BY month_row->>'month'), '[]'::jsonb)
  INTO v_monthly_history
  FROM (
    SELECT jsonb_build_object(
      'month', TO_CHAR(DATE_TRUNC('month', fm.metric_date::date), 'YYYY-MM'),
      'month_label', TO_CHAR(DATE_TRUNC('month', fm.metric_date::date), 'Mon YYYY'),
      'total_cost', COALESCE(SUM(fm.call_revenue + fm.sms_revenue + fm.email_revenue), 0),
      'call_cost', COALESCE(SUM(fm.call_revenue), 0),
      'sms_cost', COALESCE(SUM(fm.sms_revenue), 0),
      'email_cost', COALESCE(SUM(fm.email_revenue), 0),
      'total_calls', COALESCE(SUM(fm.call_count), 0),
      'total_minutes', COALESCE(SUM(fm.total_duration_seconds) / 60.0, 0),
      'total_sms', COALESCE(SUM(fm.sms_count), 0),
      'total_emails', COALESCE(SUM(fm.email_count), 0)
    ) as month_row
    FROM v_financial_metrics_enriched fm
    WHERE fm.metric_date::date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 months'
      AND fm.metric_date::date <= CURRENT_DATE
      AND (
        (v_is_admin = true AND p_view_as_user_id IS NULL)
        OR
        EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.user_id = v_effective_user_id
            AND ucp.client_id = fm.client_id
        )
      )
      AND (p_client_id IS NULL OR fm.client_id = p_client_id)
    GROUP BY DATE_TRUNC('month', fm.metric_date::date)
  ) month_data;

  -- =========================================================================
  -- Build final result
  -- =========================================================================
  v_result := jsonb_build_object(
    'daily_consumption', v_daily_consumption,
    'by_channel', v_by_channel,
    'by_agent', v_by_agent,
    'monthly_history', v_monthly_history
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_consumption_chart_data(DATE, DATE, UUID, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_consumption_chart_data IS 'Returns consumption chart data for Ma Conso dashboard. Supports view_as_user for admin preview. SECURITY: Never returns provider_cost or margin data.';
