-- ============================================================================
-- Migration: Fix get_client_deployments_breakdown with proper RLS
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 3 FIX
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
DROP FUNCTION IF EXISTS public.get_client_deployments_breakdown(UUID, DATE, DATE);

-- Create corrected function
CREATE OR REPLACE FUNCTION public.get_client_deployments_breakdown(
  p_client_id UUID,
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
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  -- Check if user has access to this client
  IF NOT EXISTS (
    SELECT 1 FROM user_client_permissions
    WHERE user_id = v_user_id
      AND client_id = p_client_id
  ) THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Calculate period duration for leasing pro-rating
  v_duration_days := p_end_date - p_start_date + 1;

  -- Build result with deployment breakdown
  WITH deployment_data AS (
    SELECT
      d.id AS deployment_id,
      d.name AS deployment_name,
      at.name AS agent_type_name,
      COALESCE(at.label, at.name) AS agent_type_label,
      d.status,
      d.created_at,

      -- Revenue calculation
      SUM(
        CASE
          WHEN d.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.total_cost, 0) * (1 + COALESCE(d.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) +
      (CASE WHEN d.pricing_model IN ('leasing', 'hybrid') THEN
        (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
      ELSE 0 END) AS total_revenue,

      -- Provider cost
      SUM(COALESCE(ac.total_cost, 0)) AS total_provider_cost,

      -- Margin calculation
      SUM(
        CASE
          WHEN d.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.total_cost, 0) * (COALESCE(d.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END
      ) +
      (CASE WHEN d.pricing_model IN ('leasing', 'hybrid') THEN
        (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
      ELSE 0 END) AS total_margin,

      -- Call metrics
      COUNT(ac.id) AS call_count,
      COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed')) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,

      -- SMS and Email counts (from metadata or separate tables if available)
      0 AS sms_count,
      0 AS email_count,

      -- Costs by channel
      SUM(COALESCE(ac.total_cost, 0)) AS call_cost,
      0 AS sms_cost,
      0 AS email_cost,

      -- Leasing revenue
      (CASE WHEN d.pricing_model IN ('leasing', 'hybrid') THEN
        (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
      ELSE 0 END) AS leasing_revenue,

      -- Average call duration
      ROUND(AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0), 2) AS avg_call_duration

    FROM agent_deployments d
    LEFT JOIN agent_types at ON d.agent_type_id = at.id
    LEFT JOIN v_agent_calls_enriched ac ON ac.deployment_id = d.id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
    WHERE d.client_id = p_client_id
    GROUP BY d.id, d.name, at.name, at.label, d.status, d.created_at,
             d.pricing_model, d.leasing_monthly_price, d.voipia_margin_percentage
  )
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'deployment_id', deployment_id,
      'deployment_name', deployment_name,
      'agent_type_name', agent_type_name,
      'agent_type_label', agent_type_label,
      'status', status,
      'created_at', created_at,
      'total_revenue', COALESCE(total_revenue, 0),
      'total_provider_cost', COALESCE(total_provider_cost, 0),
      'total_margin', COALESCE(total_margin, 0),
      'margin_percentage', CASE
        WHEN COALESCE(total_revenue, 0) > 0
        THEN ROUND((COALESCE(total_margin, 0) / total_revenue * 100)::numeric, 2)
        ELSE 0
      END,
      'call_count', COALESCE(call_count, 0),
      'sms_count', COALESCE(sms_count, 0),
      'email_count', COALESCE(email_count, 0),
      'answered_calls', COALESCE(answered_calls, 0),
      'appointments_scheduled', COALESCE(appointments_scheduled, 0),
      'answer_rate', CASE
        WHEN COALESCE(call_count, 0) > 0
        THEN ROUND((COALESCE(answered_calls, 0)::numeric / call_count * 100), 2)
        ELSE 0
      END,
      'conversion_rate', CASE
        WHEN COALESCE(answered_calls, 0) > 0
        THEN ROUND((COALESCE(appointments_scheduled, 0)::numeric / answered_calls * 100), 2)
        ELSE 0
      END,
      'call_cost', COALESCE(call_cost, 0),
      'sms_cost', COALESCE(sms_cost, 0),
      'email_cost', COALESCE(email_cost, 0),
      'leasing_revenue', COALESCE(leasing_revenue, 0),
      'avg_call_duration', COALESCE(avg_call_duration, 0),
      'cost_per_call', CASE
        WHEN COALESCE(call_count, 0) > 0
        THEN ROUND((COALESCE(total_provider_cost, 0) / call_count), 4)
        ELSE 0
      END,
      'cost_per_appointment', CASE
        WHEN COALESCE(appointments_scheduled, 0) > 0
        THEN ROUND((COALESCE(total_provider_cost, 0) / appointments_scheduled), 2)
        ELSE 0
      END
    ) ORDER BY deployment_name
  ) INTO v_result
  FROM deployment_data;

  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_client_deployments_breakdown: %', SQLERRM;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_client_deployments_breakdown(UUID, DATE, DATE) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.get_client_deployments_breakdown IS
  'Returns financial breakdown by deployment for a specific client. RLS enforced via user_client_permissions table.';
