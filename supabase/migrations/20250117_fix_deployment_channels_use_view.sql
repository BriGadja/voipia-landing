-- ============================================================================
-- Migration: Fix get_deployment_channels_breakdown to use v_financial_metrics_enriched
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 4 FINAL FIX
-- ============================================================================
--
-- Purpose: Use existing v_financial_metrics_enriched view instead of manual calculations
-- Previous version tried to access non-existent columns (pricing_model, voipia_margin_percentage, etc.)
--
-- Changes:
-- 1. Use v_financial_metrics_enriched which already has all channel-specific calculations
-- 2. RLS is already enforced in the view via user_has_access column
-- 3. Aggregate metrics by channel from the view
--
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_deployment_channels_breakdown(UUID, DATE, DATE);

-- Create corrected function using the view
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
  v_user_id UUID;
  v_client_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  -- Get client_id for this deployment
  SELECT client_id INTO v_client_id
  FROM agent_deployments
  WHERE id = p_deployment_id;

  -- If deployment not found, return empty array
  IF NOT FOUND THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Check if user has access to this deployment's client
  IF NOT EXISTS (
    SELECT 1 FROM user_client_permissions
    WHERE user_id = v_user_id
      AND client_id = v_client_id
  ) THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Build result with channel breakdown from the view
  WITH channel_aggregates AS (
    SELECT
      -- Aggregate metrics from v_financial_metrics_enriched
      SUM(call_revenue) AS total_call_revenue,
      SUM(call_provider_cost) AS total_call_cost,
      SUM(call_count) AS total_calls,
      SUM(answered_calls) AS total_answered,
      SUM(appointments_scheduled) AS total_appointments,
      AVG(avg_duration_seconds) AS avg_duration,

      SUM(sms_revenue) AS total_sms_revenue,
      SUM(sms_provider_cost) AS total_sms_cost,
      SUM(sms_count) AS total_sms,
      SUM(sms_delivered) AS total_sms_delivered,

      SUM(email_revenue) AS total_email_revenue,
      SUM(email_provider_cost) AS total_email_cost,
      SUM(email_count) AS total_emails,
      SUM(email_delivered) AS total_email_delivered,

      SUM(leasing_revenue_daily) AS total_leasing_revenue

    FROM v_financial_metrics_enriched
    WHERE deployment_id = p_deployment_id
      AND metric_date >= p_start_date
      AND metric_date <= p_end_date
      AND user_has_access = true  -- RLS filtering
  ),
  channel_data AS (
    -- ========================================================================
    -- CALLS CHANNEL
    -- ========================================================================
    SELECT
      'calls' AS channel_name,
      'Appels' AS channel_label,
      '📞' AS channel_icon,

      ca.total_call_revenue AS revenue,
      ca.total_call_cost AS provider_cost,
      ca.total_call_revenue - ca.total_call_cost AS margin,

      ca.total_calls AS volume,
      ca.total_answered AS answered_calls,
      ca.total_appointments AS appointments,

      ca.avg_duration AS avg_duration,
      CASE
        WHEN ca.total_calls > 0
        THEN ROUND((ca.total_answered::numeric / ca.total_calls * 100), 2)
        ELSE 0
      END AS answer_rate,

      1 AS sort_order

    FROM channel_aggregates ca
    WHERE ca.total_calls > 0  -- Only show if there are calls

    UNION ALL

    -- ========================================================================
    -- SMS CHANNEL
    -- ========================================================================
    SELECT
      'sms' AS channel_name,
      'SMS' AS channel_label,
      '💬' AS channel_icon,

      ca.total_sms_revenue AS revenue,
      ca.total_sms_cost AS provider_cost,
      ca.total_sms_revenue - ca.total_sms_cost AS margin,

      ca.total_sms AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,

      NULL::numeric AS avg_duration,
      CASE
        WHEN ca.total_sms > 0
        THEN ROUND((ca.total_sms_delivered::numeric / ca.total_sms * 100), 2)
        ELSE 0
      END AS answer_rate,  -- Reuse as delivery rate

      2 AS sort_order

    FROM channel_aggregates ca
    WHERE ca.total_sms > 0  -- Only show if there are SMS

    UNION ALL

    -- ========================================================================
    -- EMAIL CHANNEL
    -- ========================================================================
    SELECT
      'email' AS channel_name,
      'Emails' AS channel_label,
      '📧' AS channel_icon,

      ca.total_email_revenue AS revenue,
      ca.total_email_cost AS provider_cost,
      ca.total_email_revenue - ca.total_email_cost AS margin,

      ca.total_emails AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,

      NULL::numeric AS avg_duration,
      CASE
        WHEN ca.total_emails > 0
        THEN ROUND((ca.total_email_delivered::numeric / ca.total_emails * 100), 2)
        ELSE 0
      END AS answer_rate,  -- Reuse as delivery rate

      3 AS sort_order

    FROM channel_aggregates ca
    WHERE ca.total_emails > 0  -- Only show if there are emails

    UNION ALL

    -- ========================================================================
    -- LEASING CHANNEL
    -- ========================================================================
    SELECT
      'leasing' AS channel_name,
      'Leasing' AS channel_label,
      '💰' AS channel_icon,

      ca.total_leasing_revenue AS revenue,
      0 AS provider_cost,  -- No provider cost for leasing
      ca.total_leasing_revenue AS margin,  -- 100% margin

      (p_end_date - p_start_date + 1) AS volume,  -- Days in period
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,

      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,

      4 AS sort_order

    FROM channel_aggregates ca
    WHERE ca.total_leasing_revenue > 0  -- Only show if there's leasing revenue
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
  'Returns financial breakdown by channel (Calls, SMS, Email, Leasing) for a specific deployment. Uses v_financial_metrics_enriched view with RLS.';

-- ============================================================================
-- Verification Query (run after migration)
-- ============================================================================

-- First, get a deployment ID to test with
-- SELECT d.id, d.name, c.name as client_name
-- FROM agent_deployments d
-- JOIN clients c ON d.client_id = c.id
-- WHERE d.client_id IN (
--   SELECT client_id FROM user_client_permissions WHERE user_id = auth.uid()
-- )
-- LIMIT 5;

-- Then test with a deployment (replace DEPLOYMENT_ID)
-- SELECT jsonb_pretty(
--   get_deployment_channels_breakdown(
--     'DEPLOYMENT_ID_HERE'::uuid,
--     CURRENT_DATE - 30,
--     CURRENT_DATE
--   )
-- );
