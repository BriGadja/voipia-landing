-- ============================================================================
-- Migration: Fix get_deployment_channels_breakdown with proper RLS
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 4 FIX
-- ============================================================================
--
-- Purpose: Fix RLS implementation using user_client_permissions table
-- Previous version used non-existent user_has_access column
--
-- Changes:
-- 1. Replace function with proper RLS filtering
-- 2. Use user_client_permissions table for access control
-- 3. Filter by auth.uid() and client_id (via deployment → client relationship)
--
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_deployment_channels_breakdown(UUID, DATE, DATE);

-- Create corrected function
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
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  -- Calculate period duration for leasing pro-rating
  v_duration_days := p_end_date - p_start_date + 1;

  -- Get deployment info and check RLS access
  SELECT
    d.pricing_model,
    d.leasing_monthly_price,
    d.voipia_margin_percentage,
    d.voipia_margin_percentage_sms,
    d.voipia_margin_percentage_email,
    d.client_id
  INTO v_deployment
  FROM agent_deployments d
  WHERE d.id = p_deployment_id;

  -- If deployment not found, return empty array
  IF NOT FOUND THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Check if user has access to this deployment's client
  IF NOT EXISTS (
    SELECT 1 FROM user_client_permissions
    WHERE user_id = v_user_id
      AND client_id = v_deployment.client_id
  ) THEN
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
            COALESCE(ac.total_cost, 0) * (1 + COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS revenue,

      -- Provider cost (actual VAPI cost)
      SUM(COALESCE(ac.total_cost, 0)) AS provider_cost,

      -- Margin (Voipia profit on calls)
      SUM(
        CASE
          WHEN v_deployment.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.total_cost, 0) * (COALESCE(v_deployment.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS margin,

      -- Volume metrics
      COUNT(*) AS volume,
      COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed')) AS answered_calls,
      COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments,

      -- Performance metrics
      ROUND(AVG(ac.duration_seconds) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed')), 2) AS avg_duration,
      CASE
        WHEN COUNT(*) > 0
        THEN ROUND((COUNT(*) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed'))::numeric / COUNT(*) * 100), 2)
        ELSE 0
      END AS answer_rate,

      1 AS sort_order
    FROM v_agent_calls_enriched ac
    WHERE ac.deployment_id = p_deployment_id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
    HAVING COUNT(*) > 0

    UNION ALL

    -- ========================================================================
    -- SMS CHANNEL (if SMS data available in future)
    -- ========================================================================
    SELECT
      'sms' AS channel_name,
      'SMS' AS channel_label,
      '💬' AS channel_icon,
      0 AS revenue,
      0 AS provider_cost,
      0 AS margin,
      0 AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,
      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,
      2 AS sort_order
    WHERE FALSE  -- Disabled until SMS tracking is implemented

    UNION ALL

    -- ========================================================================
    -- EMAIL CHANNEL (if Email data available in future)
    -- ========================================================================
    SELECT
      'email' AS channel_name,
      'Emails' AS channel_label,
      '📧' AS channel_icon,
      0 AS revenue,
      0 AS provider_cost,
      0 AS margin,
      0 AS volume,
      NULL::bigint AS answered_calls,
      NULL::bigint AS appointments,
      NULL::numeric AS avg_duration,
      NULL::numeric AS answer_rate,
      3 AS sort_order
    WHERE FALSE  -- Disabled until Email tracking is implemented

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
    WHERE v_deployment.pricing_model IN ('leasing', 'hybrid')
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
  'Returns financial breakdown by channel (Calls, SMS, Email, Leasing) for a specific deployment. RLS enforced via user_client_permissions table.';
