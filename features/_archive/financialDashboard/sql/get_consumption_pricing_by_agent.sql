-- ============================================================================
-- Function: get_consumption_pricing_by_agent
-- Description: Returns unit pricing metrics (cost, price, margin) for each agent deployment
-- Author: Claude
-- Date: 2025-01-18
-- Version: 1.0
-- ============================================================================
--
-- Purpose: Calculate consumption pricing by individual agent (deployment level)
-- Returns: JSONB array with unit pricing for calls, SMS, emails per agent
--
-- Usage:
--   SELECT get_consumption_pricing_by_agent(
--     '2024-12-01',
--     '2025-01-18'
--   );
--
--   -- Optional: filter by client
--   SELECT get_consumption_pricing_by_agent(
--     '2024-12-01',
--     '2025-01-18',
--     'e63beaf9-2e3c-44e9-8f5d-5d063cac82fd'::uuid
--   );
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_consumption_pricing_by_agent(
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
  v_result JSONB;
BEGIN
  -- Build result with agent-level unit pricing
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      -- Identification
      'deployment_id', deployment_id,
      'deployment_name', deployment_name,
      'client_name', client_name,
      'agent_type_name', agent_type_name,
      'agent_type_label', agent_type_label,
      'status', status,

      -- CALL METRICS
      'call_metrics', JSONB_BUILD_OBJECT(
        -- Volumes
        'total_calls', COALESCE(total_calls, 0),
        'answered_calls', COALESCE(answered_calls, 0),
        'total_minutes', COALESCE(total_minutes, 0),

        -- Unit costs (provider)
        'cost_per_minute_provider', CASE
          WHEN COALESCE(total_minutes, 0) > 0
          THEN ROUND((COALESCE(call_provider_cost, 0) / total_minutes)::numeric, 4)
          ELSE 0
        END,

        -- Unit prices (charged to client)
        'price_per_minute_charged', COALESCE(price_per_minute, 0),

        -- Unit margin
        'margin_per_minute', CASE
          WHEN COALESCE(total_minutes, 0) > 0
          THEN ROUND((COALESCE(price_per_minute, 0) - (COALESCE(call_provider_cost, 0) / total_minutes))::numeric, 4)
          ELSE 0
        END,

        -- Margin percentage
        'margin_pct_calls', CASE
          WHEN COALESCE(call_revenue, 0) > 0
          THEN ROUND(((call_revenue - call_provider_cost) / call_revenue * 100)::numeric, 2)
          ELSE 0
        END,

        -- Totals
        'total_call_revenue', COALESCE(call_revenue, 0),
        'total_call_cost', COALESCE(call_provider_cost, 0),
        'total_call_margin', COALESCE(call_revenue - call_provider_cost, 0)
      ),

      -- SMS METRICS
      'sms_metrics', JSONB_BUILD_OBJECT(
        -- Volumes
        'total_sms_sent', COALESCE(total_sms, 0),
        'sms_delivered', COALESCE(sms_delivered, 0),

        -- Unit costs (provider)
        'cost_per_sms_provider', CASE
          WHEN COALESCE(total_sms, 0) > 0
          THEN ROUND((COALESCE(sms_provider_cost, 0) / total_sms)::numeric, 4)
          ELSE 0
        END,

        -- Unit prices (charged to client)
        'price_per_sms_charged', COALESCE(price_per_sms, 0),

        -- Unit margin
        'margin_per_sms', CASE
          WHEN COALESCE(total_sms, 0) > 0
          THEN ROUND((COALESCE(price_per_sms, 0) - (COALESCE(sms_provider_cost, 0) / total_sms))::numeric, 4)
          ELSE 0
        END,

        -- Margin percentage
        'margin_pct_sms', CASE
          WHEN COALESCE(sms_revenue, 0) > 0
          THEN ROUND(((sms_revenue - sms_provider_cost) / sms_revenue * 100)::numeric, 2)
          ELSE 0
        END,

        -- Totals
        'total_sms_revenue', COALESCE(sms_revenue, 0),
        'total_sms_cost', COALESCE(sms_provider_cost, 0),
        'total_sms_margin', COALESCE(sms_revenue - sms_provider_cost, 0)
      ),

      -- EMAIL METRICS
      'email_metrics', JSONB_BUILD_OBJECT(
        -- Volumes
        'total_emails_sent', COALESCE(total_emails, 0),
        'emails_delivered', COALESCE(emails_delivered, 0),

        -- Unit costs (provider)
        'cost_per_email_provider', CASE
          WHEN COALESCE(total_emails, 0) > 0
          THEN ROUND((COALESCE(email_provider_cost, 0) / total_emails)::numeric, 4)
          ELSE 0
        END,

        -- Unit prices (charged to client)
        'price_per_email_charged', COALESCE(price_per_email, 0),

        -- Unit margin
        'margin_per_email', CASE
          WHEN COALESCE(total_emails, 0) > 0
          THEN ROUND((COALESCE(price_per_email, 0) - (COALESCE(email_provider_cost, 0) / total_emails))::numeric, 4)
          ELSE 0
        END,

        -- Margin percentage
        'margin_pct_emails', CASE
          WHEN COALESCE(email_revenue, 0) > 0
          THEN ROUND(((email_revenue - email_provider_cost) / email_revenue * 100)::numeric, 2)
          ELSE 0
        END,

        -- Totals
        'total_email_revenue', COALESCE(email_revenue, 0),
        'total_email_cost', COALESCE(email_provider_cost, 0),
        'total_email_margin', COALESCE(email_revenue - email_provider_cost, 0)
      ),

      -- TOTAL CONSUMPTION METRICS (excluding leasing)
      'total_consumption', JSONB_BUILD_OBJECT(
        'total_consumption_revenue', COALESCE(call_revenue + sms_revenue + email_revenue, 0),
        'total_consumption_cost', COALESCE(call_provider_cost + sms_provider_cost + email_provider_cost, 0),
        'total_consumption_margin', COALESCE(
          (call_revenue + sms_revenue + email_revenue) -
          (call_provider_cost + sms_provider_cost + email_provider_cost),
          0
        ),
        'consumption_margin_pct', CASE
          WHEN COALESCE(call_revenue + sms_revenue + email_revenue, 0) > 0
          THEN ROUND((
            ((call_revenue + sms_revenue + email_revenue) -
             (call_provider_cost + sms_provider_cost + email_provider_cost)) /
            (call_revenue + sms_revenue + email_revenue) * 100
          )::numeric, 2)
          ELSE 0
        END
      )
    )
  ) INTO v_result
  FROM (
    SELECT
      d.id AS deployment_id,
      d.name AS deployment_name,
      c.name AS client_name,
      at.name AS agent_type_name,
      at.display_name AS agent_type_label,
      d.status,

      -- Pricing configuration from deployment
      d.cost_per_min AS price_per_minute,
      d.cost_per_sms AS price_per_sms,
      d.cost_per_email AS price_per_email,

      -- CALL AGGREGATES
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.answered = true) AS answered_calls,
      ROUND((SUM(ac.duration_seconds) / 60.0)::numeric, 2) AS total_minutes,
      SUM((ac.duration_seconds / 60.0) * d.cost_per_min) AS call_revenue,
      SUM(COALESCE(ac.vapi_cost_usd * 0.92, 0)) AS call_provider_cost,

      -- SMS AGGREGATES
      SUM(ac.sms_count) AS total_sms,
      -- Note: We approximate delivered count from agent_calls.sms_count
      -- For exact count, would need to join agent_sms table
      SUM(ac.sms_count) AS sms_delivered,
      SUM(ac.sms_count * d.cost_per_sms) AS sms_revenue,
      SUM(
        COALESCE(
          (SELECT SUM(asms.billed_cost)
           FROM agent_sms asms
           WHERE asms.deployment_id = d.id
             AND asms.sent_at::date >= p_start_date
             AND asms.sent_at::date <= p_end_date),
          0
        )
      ) AS sms_provider_cost,

      -- EMAIL AGGREGATES
      SUM(ac.email_count) AS total_emails,
      SUM(ac.email_count) AS emails_delivered,
      SUM(ac.email_count * d.cost_per_email) AS email_revenue,
      SUM(
        COALESCE(
          (SELECT SUM(ae.billed_cost)
           FROM agent_emails ae
           WHERE ae.deployment_id = d.id
             AND ae.sent_at::date >= p_start_date
             AND ae.sent_at::date <= p_end_date),
          0
        )
      ) AS email_provider_cost

    FROM agent_deployments d
    INNER JOIN agent_types at ON d.agent_type_id = at.id
    INNER JOIN clients c ON d.client_id = c.id
    LEFT JOIN agent_calls ac ON ac.deployment_id = d.id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
    WHERE
      -- RLS filtering (user must have access to client)
      EXISTS (
        SELECT 1
        FROM user_client_permissions ucp
        WHERE ucp.client_id = d.client_id
          AND ucp.user_id = auth.uid()
      )
      -- Optional client filter
      AND (p_client_id IS NULL OR d.client_id = p_client_id)
    GROUP BY
      d.id,
      d.name,
      c.name,
      at.name,
      at.display_name,
      d.status,
      d.cost_per_min,
      d.cost_per_sms,
      d.cost_per_email
    HAVING
      -- Only include agents with actual consumption activity
      COUNT(ac.id) > 0
      OR SUM(ac.sms_count) > 0
      OR SUM(ac.email_count) > 0
    ORDER BY
      (SUM((ac.duration_seconds / 60.0) * d.cost_per_min) +
       SUM(ac.sms_count * d.cost_per_sms) +
       SUM(ac.email_count * d.cost_per_email)) DESC
  ) sub;

  -- Return result or empty array
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_consumption_pricing_by_agent: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_consumption_pricing_by_agent(DATE, DATE, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_consumption_pricing_by_agent(DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_consumption_pricing_by_agent IS
  'Returns unit pricing metrics (cost per unit, price per unit, margin per unit) for calls, SMS, and emails by individual agent deployment. Used for consumption pricing analysis.';

-- ============================================================================
-- Verification Queries (run after applying migration)
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames
-- FROM pg_proc
-- WHERE proname = 'get_consumption_pricing_by_agent';

-- Test 2: Get pricing for all agents (last 30 days)
-- SELECT get_consumption_pricing_by_agent(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE
-- );

-- Test 3: Get pricing for specific client
-- SELECT get_consumption_pricing_by_agent(
--   CURRENT_DATE - INTERVAL '30 days',
--   CURRENT_DATE,
--   'e63beaf9-2e3c-44e9-8f5d-5d063cac82fd'::uuid
-- );

-- Test 4: Extract and format results
-- SELECT
--   result->>'deployment_name' as agent,
--   result->>'client_name' as client,
--   (result->'call_metrics'->>'cost_per_minute_provider')::numeric as call_cost,
--   (result->'call_metrics'->>'price_per_minute_charged')::numeric as call_price,
--   (result->'call_metrics'->>'margin_per_minute')::numeric as call_margin,
--   (result->'sms_metrics'->>'cost_per_sms_provider')::numeric as sms_cost,
--   (result->'sms_metrics'->>'price_per_sms_charged')::numeric as sms_price,
--   (result->'sms_metrics'->>'margin_per_sms')::numeric as sms_margin
-- FROM JSONB_ARRAY_ELEMENTS(
--   get_consumption_pricing_by_agent(CURRENT_DATE - 30, CURRENT_DATE)
-- ) as result;
