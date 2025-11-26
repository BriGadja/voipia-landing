-- Migration: Create get_financial_drilldown RPC function
-- Date: 2025-01-16
-- Author: Claude
--
-- Purpose: Multi-level financial drilldown (client → agent type → deployment → channel)
-- Returns: Detailed breakdown of revenue, costs, and margins at requested level
--
-- Parameters:
--   p_start_date: Start date for analysis period (inclusive)
--   p_end_date: End date for analysis period (inclusive)
--   p_level: Drilldown level ('client', 'agent_type', 'deployment', 'channel')
--   p_client_id: Optional filter by specific client
--   p_agent_type_name: Optional filter by agent type
--   p_deployment_id: Optional filter by specific deployment

DROP FUNCTION IF EXISTS get_financial_drilldown(date, date, text, uuid, text, uuid);

CREATE OR REPLACE FUNCTION get_financial_drilldown(
  p_start_date date,
  p_end_date date,
  p_level text DEFAULT 'client',
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
  v_result jsonb;
BEGIN
  -- Validate drilldown level
  IF p_level NOT IN ('client', 'agent_type', 'deployment', 'channel') THEN
    RAISE EXCEPTION 'Invalid drilldown level. Must be: client, agent_type, deployment, or channel';
  END IF;

  -- CLIENT LEVEL DRILLDOWN
  IF p_level = 'client' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'client_id', client_id,
        'client_name', client_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'unique_deployments', unique_deployments,
        'active_days', active_days
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        client_id,
        client_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT deployment_id) as unique_deployments,
        COUNT(DISTINCT metric_date) as active_days
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY client_id, client_name
    ) client_data;

  -- AGENT TYPE LEVEL DRILLDOWN
  ELSIF p_level = 'agent_type' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'agent_type_id', agent_type_id,
        'agent_type_name', agent_type_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'unique_clients', unique_clients,
        'unique_deployments', unique_deployments
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        agent_type_id,
        agent_type_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT client_id) as unique_clients,
        COUNT(DISTINCT deployment_id) as unique_deployments
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY agent_type_id, agent_type_name
    ) agent_data;

  -- DEPLOYMENT LEVEL DRILLDOWN
  ELSIF p_level = 'deployment' THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'deployment_id', deployment_id,
        'client_id', client_id,
        'client_name', client_name,
        'agent_type_id', agent_type_id,
        'agent_type_name', agent_type_name,
        'total_revenue', total_revenue,
        'total_provider_cost', total_provider_cost,
        'total_margin', total_margin,
        'margin_percentage', margin_percentage,
        'call_revenue', call_revenue,
        'sms_revenue', sms_revenue,
        'email_revenue', email_revenue,
        'leasing_revenue', leasing_revenue,
        'call_count', call_count,
        'sms_count', sms_count,
        'email_count', email_count,
        'answered_calls', answered_calls,
        'appointments_scheduled', appointments_scheduled,
        'active_days', active_days
      )
      ORDER BY total_revenue DESC
    )
    INTO v_result
    FROM (
      SELECT
        deployment_id,
        client_id,
        client_name,
        agent_type_id,
        agent_type_name,
        SUM(total_revenue) as total_revenue,
        SUM(total_provider_cost) as total_provider_cost,
        SUM(total_margin) as total_margin,
        CASE
          WHEN SUM(total_revenue) > 0
          THEN (SUM(total_margin) / SUM(total_revenue)) * 100
          ELSE 0
        END as margin_percentage,
        SUM(call_revenue) as call_revenue,
        SUM(sms_revenue) as sms_revenue,
        SUM(email_revenue) as email_revenue,
        SUM(leasing_revenue_daily) as leasing_revenue,
        SUM(call_count) as call_count,
        SUM(sms_count) as sms_count,
        SUM(email_count) as email_count,
        SUM(answered_calls) as answered_calls,
        SUM(appointments_scheduled) as appointments_scheduled,
        COUNT(DISTINCT metric_date) as active_days
      FROM v_financial_metrics_enriched
      WHERE metric_date >= p_start_date
        AND metric_date <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
        AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id)
      GROUP BY deployment_id, client_id, client_name, agent_type_id, agent_type_name
    ) deployment_data;

  -- CHANNEL LEVEL DRILLDOWN
  ELSIF p_level = 'channel' THEN
    SELECT jsonb_build_object(
      'channels', jsonb_build_array(
        jsonb_build_object(
          'channel_name', 'calls',
          'revenue', SUM(call_revenue),
          'provider_cost', SUM(call_provider_cost),
          'margin', SUM(call_revenue) - SUM(call_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(call_revenue) > 0
              THEN ((SUM(call_revenue) - SUM(call_provider_cost)) / SUM(call_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(call_count),
          'answered', SUM(answered_calls)
        ),
        jsonb_build_object(
          'channel_name', 'sms',
          'revenue', SUM(sms_revenue),
          'provider_cost', SUM(sms_provider_cost),
          'margin', SUM(sms_revenue) - SUM(sms_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(sms_revenue) > 0
              THEN ((SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(sms_count),
          'delivered', SUM(sms_delivered)
        ),
        jsonb_build_object(
          'channel_name', 'email',
          'revenue', SUM(email_revenue),
          'provider_cost', SUM(email_provider_cost),
          'margin', SUM(email_revenue) - SUM(email_provider_cost),
          'margin_percentage',
            CASE
              WHEN SUM(email_revenue) > 0
              THEN ((SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_revenue)) * 100
              ELSE 0
            END,
          'volume', SUM(email_count),
          'delivered', SUM(email_delivered)
        ),
        jsonb_build_object(
          'channel_name', 'leasing',
          'revenue', SUM(leasing_revenue_daily),
          'provider_cost', 0,
          'margin', SUM(leasing_revenue_daily),
          'margin_percentage', 100,
          'volume', COUNT(DISTINCT deployment_id),
          'description', 'Monthly subscription fees pro-rated by day'
        )
      )
    )
    INTO v_result
    FROM v_financial_metrics_enriched
    WHERE metric_date >= p_start_date
      AND metric_date <= p_end_date
      AND (p_client_id IS NULL OR client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id);

  END IF;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_financial_drilldown(date, date, text, uuid, text, uuid) TO authenticated;

COMMENT ON FUNCTION get_financial_drilldown IS
'Multi-level financial drilldown supporting client, agent_type, deployment, and channel levels.
Returns detailed breakdown of revenue, costs, margins, and activity metrics.
RLS enforced via user_has_access column in view.';

-- Verification queries (run these to test the function)
/*
-- Test 1: Client-level drilldown
SELECT get_financial_drilldown(
  (CURRENT_DATE - 30)::date,
  CURRENT_DATE::date,
  'client',
  NULL::uuid,
  NULL::text,
  NULL::uuid
);

-- Test 2: Agent type drilldown
SELECT get_financial_drilldown(
  (CURRENT_DATE - 30)::date,
  CURRENT_DATE::date,
  'agent_type',
  NULL::uuid,
  NULL::text,
  NULL::uuid
);

-- Test 3: Deployment drilldown for specific client
SELECT get_financial_drilldown(
  (CURRENT_DATE - 30)::date,
  CURRENT_DATE::date,
  'deployment',
  'your-client-uuid'::uuid,
  NULL::text,
  NULL::uuid
);

-- Test 4: Channel breakdown
SELECT get_financial_drilldown(
  (CURRENT_DATE - 30)::date,
  CURRENT_DATE::date,
  'channel',
  NULL::uuid,
  NULL::text,
  NULL::uuid
);
*/
