-- ============================================================================
-- Function: get_deployment_channels_breakdown
-- Description: Returns financial breakdown by channel for a specific deployment
-- Author: Claude
-- Date: 2025-01-17
-- Version: 1.0
-- ============================================================================
--
-- Purpose: Drill down from deployment level to channel level (Calls, SMS, Email, Leasing)
-- Returns: JSONB array with channel financial metrics
--
-- Usage:
--   SELECT get_deployment_channels_breakdown(
--     'deployment-uuid'::uuid,
--     '2024-12-01',
--     '2025-01-17'
--   );
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_deployment_channels_breakdown(
  p_deployment_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_duration_days INTEGER;
  v_deployment RECORD;
BEGIN
  -- Calculate period duration for leasing pro-rating
  v_duration_days := p_end_date - p_start_date + 1;

  -- Get deployment info for pricing model and margins
  SELECT
    d.pricing_model,
    d.leasing_monthly_price,
    d.voipia_margin_percentage,
    d.voipia_margin_percentage_sms,
    d.voipia_margin_percentage_email
  INTO v_deployment
  FROM agent_deployments d
  WHERE d.id = p_deployment_id
    AND d.user_has_access = true;

  -- If deployment not found, return empty array
  IF NOT FOUND THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Build result with channel breakdown
  WITH channel_data AS (
    -- Calls channel
    SELECT
      'calls' AS channel_name,
      'Appels' AS channel_label,
      '📞' AS channel_icon,
      -- Revenue
      SUM(
        CASE
          WHEN v_deployment.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS revenue,
      -- Provider cost
      SUM(COALESCE(ac.vapi_cost_eur, 0)) AS provider_cost,
      -- Margin
      SUM(
        CASE
          WHEN v_deployment.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS margin,
      -- Volume
      COUNT(*) AS volume,
      COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments,
      -- Averages
      ROUND(AVG(ac.duration_seconds) FILTER (WHERE ac.answered = true), 2) AS avg_duration,
      -- Rates
      CASE
        WHEN COUNT(*) > 0
        THEN ROUND((COUNT(*) FILTER (WHERE ac.answered = true)::numeric / COUNT(*) * 100), 2)
        ELSE 0
      END AS answer_rate,
      1 AS sort_order
    FROM v_agent_calls_enriched ac
    WHERE ac.deployment_id = p_deployment_id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
      AND ac.user_has_access = true
    HAVING COUNT(*) > 0

    UNION ALL

    -- SMS channel
    SELECT
      'sms' AS channel_name,
      'SMS' AS channel_label,
      '💬' AS channel_icon,
      SUM(COALESCE(ac.sms_count, 0) * COALESCE(ac.sms_cost_eur, 0) / NULLIF(ac.sms_count, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage_sms, 0) / 100.0)) AS revenue,
      SUM(COALESCE(ac.sms_cost_eur, 0)) AS provider_cost,
      SUM(COALESCE(ac.sms_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage_sms, 0) / 100.0)) AS margin,
      SUM(COALESCE(ac.sms_count, 0)) AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,
      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,
      2 AS sort_order
    FROM v_agent_calls_enriched ac
    WHERE ac.deployment_id = p_deployment_id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
      AND ac.user_has_access = true
      AND ac.sms_count > 0

    UNION ALL

    -- Email channel
    SELECT
      'email' AS channel_name,
      'Emails' AS channel_label,
      '📧' AS channel_icon,
      SUM(COALESCE(ac.email_count, 0) * COALESCE(ac.email_cost_eur, 0) / NULLIF(ac.email_count, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage_email, 0) / 100.0)) AS revenue,
      SUM(COALESCE(ac.email_cost_eur, 0)) AS provider_cost,
      SUM(COALESCE(ac.email_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage_email, 0) / 100.0)) AS margin,
      SUM(COALESCE(ac.email_count, 0)) AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,
      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,
      3 AS sort_order
    FROM v_agent_calls_enriched ac
    WHERE ac.deployment_id = p_deployment_id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
      AND ac.user_has_access = true
      AND ac.email_count > 0

    UNION ALL

    -- Leasing channel (only if leasing pricing model)
    SELECT
      'leasing' AS channel_name,
      'Leasing' AS channel_label,
      '💰' AS channel_icon,
      (COALESCE(v_deployment.leasing_monthly_price, 0) / 30.0) * v_duration_days AS revenue,
      0 AS provider_cost,
      (COALESCE(v_deployment.leasing_monthly_price, 0) / 30.0) * v_duration_days AS margin,
      v_duration_days AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,
      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,
      4 AS sort_order
    WHERE v_deployment.pricing_model = 'leasing'
      AND v_deployment.leasing_monthly_price > 0
  )
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'channel_name', channel_name,
      'channel_label', channel_label,
      'channel_icon', channel_icon,
      'revenue', COALESCE(revenue, 0),
      'provider_cost', COALESCE(provider_cost, 0),
      'margin', COALESCE(margin, 0),
      'margin_percentage', CASE
        WHEN COALESCE(revenue, 0) > 0
        THEN ROUND((COALESCE(margin, 0) / revenue * 100)::numeric, 2)
        ELSE 0
      END,
      'volume', COALESCE(volume, 0),
      'answered_calls', answered_calls,
      'appointments', appointments,
      'avg_duration', avg_duration,
      'answer_rate', answer_rate,
      'cost_per_item', CASE
        WHEN COALESCE(volume, 0) > 0
        THEN ROUND((COALESCE(provider_cost, 0) / volume), 4)
        ELSE 0
      END,
      'revenue_per_item', CASE
        WHEN COALESCE(volume, 0) > 0
        THEN ROUND((COALESCE(revenue, 0) / volume), 4)
        ELSE 0
      END
    ) ORDER BY sort_order
  ) INTO v_result
  FROM channel_data;

  -- Return result or empty array
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_deployment_channels_breakdown: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_deployment_channels_breakdown(UUID, DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_deployment_channels_breakdown IS
  'Returns financial breakdown by channel (Calls, SMS, Email, Leasing) for a specific deployment. Used for drill-down from deployment to channel level.';

-- ============================================================================
-- Verification Queries (run after applying migration)
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames
-- FROM pg_proc
-- WHERE proname = 'get_deployment_channels_breakdown';

-- Test 2: Execute for a deployment (replace with actual deployment_id)
-- SELECT jsonb_pretty(
--   get_deployment_channels_breakdown(
--     'DEPLOYMENT_ID_HERE'::uuid,
--     '2024-12-01',
--     '2025-01-17'
--   )
-- );

-- Test 3: Verify channel data matches aggregate
-- SELECT
--   d.name AS deployment_name,
--   COUNT(ac.id) AS total_calls,
--   SUM(ac.sms_count) AS total_sms,
--   SUM(ac.email_count) AS total_emails
-- FROM agent_deployments d
-- LEFT JOIN v_agent_calls_enriched ac ON ac.deployment_id = d.id
-- WHERE d.id = 'DEPLOYMENT_ID_HERE'::uuid
-- GROUP BY d.id, d.name;
