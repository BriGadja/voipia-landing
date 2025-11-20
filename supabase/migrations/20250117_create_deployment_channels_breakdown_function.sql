-- ============================================================================
-- Migration: Create get_deployment_channels_breakdown function
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 4 (Drill Down Level 2)
-- ============================================================================
--
-- Purpose: Drill down from deployment level to channel level
-- Returns: JSONB array with channel financial metrics (Calls, SMS, Email, Leasing)
--
-- Changes:
-- 1. Create function get_deployment_channels_breakdown
-- 2. Returns financial breakdown by channel for a specific deployment
-- 3. Calculates revenue, costs, margin per channel
-- 4. Includes volume metrics and rates per channel
-- 5. Respects RLS with user_has_access filtering
--
-- Usage Example:
--   SELECT get_deployment_channels_breakdown(
--     'deployment-uuid'::uuid,
--     '2024-12-01',
--     '2025-01-17'
--   );
-- ============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_deployment_channels_breakdown(UUID, DATE, DATE);

-- Create the function
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

  -- If deployment not found or no access, return empty array
  IF NOT FOUND THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Build result with channel breakdown
  WITH channel_data AS (
    -- ========================================================================
    -- CALLS CHANNEL
    -- ========================================================================
    SELECT
      'calls' AS channel_name,
      'Appels' AS channel_label,
      '📞' AS channel_icon,

      -- Revenue calculation (with Voipia margin if consumption/hybrid)
      SUM(
        CASE
          WHEN v_deployment.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS revenue,

      -- Provider cost (actual VAPI cost)
      SUM(COALESCE(ac.vapi_cost_eur, 0)) AS provider_cost,

      -- Margin (Voipia profit on calls)
      SUM(
        CASE
          WHEN v_deployment.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS margin,

      -- Volume metrics
      COUNT(*) AS volume,
      COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments,

      -- Performance metrics
      ROUND(AVG(ac.duration_seconds) FILTER (WHERE ac.answered = true), 2) AS avg_duration,
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

    -- ========================================================================
    -- SMS CHANNEL
    -- ========================================================================
    SELECT
      'sms' AS channel_name,
      'SMS' AS channel_label,
      '💬' AS channel_icon,

      -- Revenue (SMS cost + Voipia margin)
      SUM(COALESCE(ac.sms_cost_eur, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage_sms, 0) / 100.0)) AS revenue,

      -- Provider cost
      SUM(COALESCE(ac.sms_cost_eur, 0)) AS provider_cost,

      -- Margin
      SUM(COALESCE(ac.sms_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage_sms, 0) / 100.0)) AS margin,

      -- Volume
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

    -- ========================================================================
    -- EMAIL CHANNEL
    -- ========================================================================
    SELECT
      'email' AS channel_name,
      'Emails' AS channel_label,
      '📧' AS channel_icon,

      -- Revenue (Email cost + Voipia margin)
      SUM(COALESCE(ac.email_cost_eur, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage_email, 0) / 100.0)) AS revenue,

      -- Provider cost
      SUM(COALESCE(ac.email_cost_eur, 0)) AS provider_cost,

      -- Margin
      SUM(COALESCE(ac.email_cost_eur, 0) * (COALESCE(v_deployment.voipia_margin_percentage_email, 0) / 100.0)) AS margin,

      -- Volume
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

    -- ========================================================================
    -- LEASING CHANNEL (only if leasing pricing model)
    -- ========================================================================
    SELECT
      'leasing' AS channel_name,
      'Leasing' AS channel_label,
      '💰' AS channel_icon,

      -- Revenue (pro-rated leasing)
      (COALESCE(v_deployment.leasing_monthly_price, 0) / 30.0) * v_duration_days AS revenue,

      -- No provider cost for leasing
      0 AS provider_cost,

      -- 100% margin (all leasing revenue is profit)
      (COALESCE(v_deployment.leasing_monthly_price, 0) / 30.0) * v_duration_days AS margin,

      -- Volume = days in period
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
      -- Channel identification
      'channel_name', channel_name,
      'channel_label', channel_label,
      'channel_icon', channel_icon,

      -- Financial metrics
      'revenue', COALESCE(revenue, 0),
      'provider_cost', COALESCE(provider_cost, 0),
      'margin', COALESCE(margin, 0),
      'margin_percentage', CASE
        WHEN COALESCE(revenue, 0) > 0
        THEN ROUND((COALESCE(margin, 0) / revenue * 100)::numeric, 2)
        ELSE 0
      END,

      -- Volume metrics
      'volume', COALESCE(volume, 0),
      'answered_calls', answered_calls,
      'appointments', appointments,

      -- Performance metrics
      'avg_duration', avg_duration,
      'answer_rate', answer_rate,

      -- Unit economics
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

  -- Return result or empty array if no channels found
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_deployment_channels_breakdown: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_deployment_channels_breakdown(UUID, DATE, DATE) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_deployment_channels_breakdown IS
  'Returns financial breakdown by channel (Calls, SMS, Email, Leasing) for a specific deployment. Used for drill-down from deployment to channel level in financial dashboard. Respects RLS via user_has_access column.';

-- ============================================================================
-- Verification Queries (uncomment to test after applying migration)
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames, prosrc
-- FROM pg_proc
-- WHERE proname = 'get_deployment_channels_breakdown';

-- Test 2: Execute for a deployment (replace with actual deployment_id)
-- SELECT jsonb_pretty(
--   get_deployment_channels_breakdown(
--     'DEPLOYMENT_ID_HERE'::uuid,
--     CURRENT_DATE - INTERVAL '30 days',
--     CURRENT_DATE
--   )
-- );

-- Test 3: Verify channel totals match deployment totals
-- WITH deployment_total AS (
--   SELECT
--     SUM(vapi_cost_eur + sms_cost_eur + email_cost_eur) AS total_cost,
--     COUNT(*) AS total_calls,
--     SUM(sms_count) AS total_sms,
--     SUM(email_count) AS total_emails
--   FROM v_agent_calls_enriched
--   WHERE deployment_id = 'DEPLOYMENT_ID_HERE'::uuid
--     AND created_at >= CURRENT_DATE - 30
-- )
-- SELECT * FROM deployment_total;

-- ============================================================================
-- Expected Impact:
-- - Enables drill-down from deployment to channel level in financial dashboard
-- - Returns detailed metrics per channel (Calls, SMS, Email, Leasing)
-- - Properly calculates margins per channel based on deployment config
-- - Respects Row Level Security with user_has_access filtering
-- ============================================================================
