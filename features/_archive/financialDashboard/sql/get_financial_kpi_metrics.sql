-- Migration: Create get_financial_kpi_metrics RPC function
-- Date: 2025-01-16
-- Author: Claude
--
-- Purpose: Retrieve global financial KPIs with period comparison
-- Returns: Total revenue, costs, margins with current vs previous period comparison
--
-- Parameters:
--   p_start_date: Start date for current period (inclusive)
--   p_end_date: End date for current period (inclusive)
--   p_client_id: Optional filter by specific client (NULL = all clients)
--   p_agent_type_name: Optional filter by agent type (NULL = all types)
--   p_deployment_id: Optional filter by specific deployment (NULL = all deployments)

DROP FUNCTION IF EXISTS get_financial_kpi_metrics(date, date, uuid, text, uuid);

CREATE OR REPLACE FUNCTION get_financial_kpi_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_period jsonb;
  v_previous_period jsonb;
  v_period_duration int;
  v_previous_start date;
  v_previous_end date;
BEGIN
  -- Calculate period duration in days
  v_period_duration := p_end_date - p_start_date + 1;

  -- Calculate previous period dates
  v_previous_end := p_start_date - 1;
  v_previous_start := v_previous_end - v_period_duration + 1;

  -- Get current period metrics
  SELECT jsonb_build_object(
    'total_revenue', COALESCE(SUM(total_revenue), 0),
    'total_provider_cost', COALESCE(SUM(total_provider_cost), 0),
    'total_margin', COALESCE(SUM(total_margin), 0),
    'margin_percentage',
      CASE
        WHEN SUM(total_revenue) > 0
        THEN (SUM(total_margin) / SUM(total_revenue)) * 100
        ELSE 0
      END,
    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'call_count', COALESCE(SUM(call_count), 0),
    'answered_calls', COALESCE(SUM(answered_calls), 0),
    'appointments_scheduled', COALESCE(SUM(appointments_scheduled), 0),
    'sms_count', COALESCE(SUM(sms_count), 0),
    'email_count', COALESCE(SUM(email_count), 0),
    'unique_clients', COUNT(DISTINCT client_id),
    'unique_deployments', COUNT(DISTINCT deployment_id),
    'avg_revenue_per_client',
      CASE
        WHEN COUNT(DISTINCT client_id) > 0
        THEN SUM(total_revenue) / COUNT(DISTINCT client_id)
        ELSE 0
      END,
    'avg_margin_per_client',
      CASE
        WHEN COUNT(DISTINCT client_id) > 0
        THEN SUM(total_margin) / COUNT(DISTINCT client_id)
        ELSE 0
      END
  )
  INTO v_current_period
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
    AND user_has_access = true;  -- RLS enforcement

  -- Get previous period metrics
  SELECT jsonb_build_object(
    'total_revenue', COALESCE(SUM(total_revenue), 0),
    'total_provider_cost', COALESCE(SUM(total_provider_cost), 0),
    'total_margin', COALESCE(SUM(total_margin), 0),
    'margin_percentage',
      CASE
        WHEN SUM(total_revenue) > 0
        THEN (SUM(total_margin) / SUM(total_revenue)) * 100
        ELSE 0
      END
  )
  INTO v_previous_period
  FROM v_financial_metrics_enriched
  WHERE metric_date >= v_previous_start
    AND metric_date <= v_previous_end
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
    AND user_has_access = true;  -- RLS enforcement

  -- Return combined result with period comparison
  RETURN jsonb_build_object(
    'current_period', v_current_period,
    'previous_period', v_previous_period,
    'period_info', jsonb_build_object(
      'start_date', p_start_date,
      'end_date', p_end_date,
      'duration_days', v_period_duration,
      'previous_start_date', v_previous_start,
      'previous_end_date', v_previous_end
    ),
    'comparison', jsonb_build_object(
      'revenue_change',
        (v_current_period->>'total_revenue')::numeric - (v_previous_period->>'total_revenue')::numeric,
      'revenue_change_percentage',
        CASE
          WHEN (v_previous_period->>'total_revenue')::numeric > 0
          THEN ((v_current_period->>'total_revenue')::numeric - (v_previous_period->>'total_revenue')::numeric) / (v_previous_period->>'total_revenue')::numeric * 100
          ELSE 0
        END,
      'margin_change',
        (v_current_period->>'total_margin')::numeric - (v_previous_period->>'total_margin')::numeric,
      'margin_change_percentage',
        CASE
          WHEN (v_previous_period->>'total_margin')::numeric > 0
          THEN ((v_current_period->>'total_margin')::numeric - (v_previous_period->>'total_margin')::numeric) / (v_previous_period->>'total_margin')::numeric * 100
          ELSE 0
        END
    )
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_financial_kpi_metrics(date, date, uuid, text, uuid) TO authenticated;

COMMENT ON FUNCTION get_financial_kpi_metrics IS
'Retrieves global financial KPIs with period comparison.
Returns revenue, costs, margins for current period vs previous period.
Supports filtering by client, agent type, and deployment.
RLS enforced via user_has_access column in view.';

-- Verification queries (run these to test the function)
/*
-- Test 1: Get KPIs for last 30 days (no filters)
SELECT get_financial_kpi_metrics(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  NULL,
  NULL,
  NULL
);

-- Test 2: Get KPIs for specific client
SELECT get_financial_kpi_metrics(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  'your-client-uuid-here'::uuid,
  NULL,
  NULL
);

-- Test 3: Get KPIs for Louis agent only
SELECT get_financial_kpi_metrics(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  NULL,
  'louis',
  NULL
);

-- Test 4: Get KPIs for specific date range
SELECT get_financial_kpi_metrics(
  '2025-01-01'::date,
  '2025-01-31'::date,
  NULL,
  NULL,
  NULL
);
*/
