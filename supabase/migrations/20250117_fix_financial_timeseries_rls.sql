-- ============================================================================
-- Migration: Fix get_financial_timeseries with proper RLS
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 1 FIX
-- ============================================================================
--
-- Purpose: Fix RLS implementation using user_client_permissions table
-- Previous version used non-existent user_has_access column
--
-- Changes:
-- 1. Replace function with proper RLS filtering
-- 2. Use user_client_permissions table for access control
-- 3. Filter by auth.uid() and client_id
--
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT);

-- Create corrected function
CREATE OR REPLACE FUNCTION public.get_financial_timeseries(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_granularity TEXT DEFAULT 'day'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_user_id UUID;
  v_date_trunc_format TEXT;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  -- Determine date truncation format based on granularity
  v_date_trunc_format := CASE p_granularity
    WHEN 'week' THEN 'week'
    WHEN 'month' THEN 'month'
    ELSE 'day'
  END;

  -- Build time series data with RLS filtering
  WITH accessible_clients AS (
    -- Get list of clients accessible by current user
    SELECT client_id
    FROM user_client_permissions
    WHERE user_id = v_user_id
  ),
  filtered_calls AS (
    -- Get calls with access control
    SELECT
      ac.*,
      d.client_id,
      d.pricing_model,
      d.leasing_monthly_price,
      d.voipia_margin_percentage,
      at.name as agent_type_name
    FROM v_agent_calls_enriched ac
    JOIN agent_deployments d ON ac.deployment_id = d.id
    JOIN agent_types at ON d.agent_type_id = at.id
    WHERE ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
      AND d.client_id IN (SELECT client_id FROM accessible_clients)
      AND (p_client_id IS NULL OR d.client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR d.id = p_deployment_id)
  ),
  time_series AS (
    SELECT
      DATE_TRUNC(v_date_trunc_format, fc.created_at)::date AS period_date,

      -- Revenue by channel
      SUM(
        CASE
          WHEN fc.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(fc.total_cost, 0) * (1 + COALESCE(fc.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) AS call_revenue,
      0 AS sms_revenue,
      0 AS email_revenue,
      0 AS leasing_revenue,

      -- Provider costs
      SUM(COALESCE(fc.total_cost, 0)) AS call_cost,
      0 AS sms_cost,
      0 AS email_cost,

      -- Volume metrics
      COUNT(*) AS call_count,
      COUNT(*) FILTER (WHERE fc.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed')) AS answered_calls,
      0 AS sms_count,
      0 AS email_count,
      COUNT(*) FILTER (WHERE fc.outcome = 'appointment_scheduled') AS appointments,

      -- Unique counts
      COUNT(DISTINCT fc.client_id) AS unique_clients,
      COUNT(DISTINCT fc.deployment_id) AS unique_deployments

    FROM filtered_calls fc
    GROUP BY DATE_TRUNC(v_date_trunc_format, fc.created_at)::date
  )
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'date', period_date,
      'revenue', JSONB_BUILD_OBJECT(
        'total', COALESCE(call_revenue + sms_revenue + email_revenue + leasing_revenue, 0),
        'calls', COALESCE(call_revenue, 0),
        'sms', COALESCE(sms_revenue, 0),
        'email', COALESCE(email_revenue, 0),
        'leasing', COALESCE(leasing_revenue, 0)
      ),
      'cost', JSONB_BUILD_OBJECT(
        'total', COALESCE(call_cost + sms_cost + email_cost, 0),
        'calls', COALESCE(call_cost, 0),
        'sms', COALESCE(sms_cost, 0),
        'email', COALESCE(email_cost, 0)
      ),
      'margin', JSONB_BUILD_OBJECT(
        'total', COALESCE(
          (call_revenue + sms_revenue + email_revenue + leasing_revenue) -
          (call_cost + sms_cost + email_cost),
          0
        ),
        'percentage', CASE
          WHEN COALESCE(call_revenue + sms_revenue + email_revenue + leasing_revenue, 0) > 0
          THEN ROUND((
            (call_revenue + sms_revenue + email_revenue + leasing_revenue - call_cost - sms_cost - email_cost) /
            (call_revenue + sms_revenue + email_revenue + leasing_revenue) * 100
          )::numeric, 2)
          ELSE 0
        END
      ),
      'volume', JSONB_BUILD_OBJECT(
        'calls', COALESCE(call_count, 0),
        'answered_calls', COALESCE(answered_calls, 0),
        'sms', COALESCE(sms_count, 0),
        'email', COALESCE(email_count, 0),
        'appointments', COALESCE(appointments, 0)
      ),
      'metrics', JSONB_BUILD_OBJECT(
        'unique_clients', COALESCE(unique_clients, 0),
        'unique_deployments', COALESCE(unique_deployments, 0),
        'answer_rate', CASE
          WHEN COALESCE(call_count, 0) > 0
          THEN ROUND((COALESCE(answered_calls, 0)::numeric / call_count * 100), 2)
          ELSE 0
        END,
        'conversion_rate', CASE
          WHEN COALESCE(answered_calls, 0) > 0
          THEN ROUND((COALESCE(appointments, 0)::numeric / answered_calls * 100), 2)
          ELSE 0
        END
      )
    ) ORDER BY period_date
  ) INTO v_result
  FROM time_series;

  -- Return result or empty array
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_financial_timeseries: %', SQLERRM;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.get_financial_timeseries IS
  'Returns financial time series data with daily/weekly/monthly granularity. RLS enforced via user_client_permissions table.';
