-- ============================================================================
-- Migration: Fix get_client_deployments_breakdown to use v_financial_metrics_enriched
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 3 FINAL FIX
-- ============================================================================
--
-- Purpose: Use existing v_financial_metrics_enriched view instead of manual calculations
-- Previous version tried to access non-existent columns (at.label, pricing_model, etc.)
--
-- Changes:
-- 1. Use v_financial_metrics_enriched which already has all calculations
-- 2. RLS is already enforced in the view via user_has_access column
-- 3. Join with agent_deployments only for metadata (name, status, created_at)
-- 4. Use agent_types.display_name instead of non-existent label column
--
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_client_deployments_breakdown(UUID, DATE, DATE);

-- Create corrected function using the view
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

  -- Build result with deployment breakdown using the view
  WITH deployment_data AS (
    SELECT
      d.id AS deployment_id,
      d.name AS deployment_name,
      at.name AS agent_type_name,
      at.display_name AS agent_type_label,
      d.status,
      d.created_at,

      -- Financial metrics (sum from view)
      SUM(fm.total_revenue) AS total_revenue,
      SUM(fm.total_provider_cost) AS total_provider_cost,
      SUM(fm.total_margin) AS total_margin,

      -- Volume metrics
      SUM(fm.call_count) AS call_count,
      SUM(fm.sms_count) AS sms_count,
      SUM(fm.email_count) AS email_count,
      SUM(fm.answered_calls) AS answered_calls,
      SUM(fm.appointments_scheduled) AS appointments_scheduled,

      -- Costs by channel
      SUM(fm.call_provider_cost) AS call_cost,
      SUM(fm.sms_provider_cost) AS sms_cost,
      SUM(fm.email_provider_cost) AS email_cost,

      -- Revenue by channel
      SUM(fm.call_revenue) AS call_revenue,
      SUM(fm.sms_revenue) AS sms_revenue,
      SUM(fm.email_revenue) AS email_revenue,
      SUM(fm.leasing_revenue_daily) AS leasing_revenue,

      -- Average call duration
      AVG(fm.avg_duration_seconds) AS avg_call_duration

    FROM agent_deployments d
    JOIN agent_types at ON d.agent_type_id = at.id
    LEFT JOIN v_financial_metrics_enriched fm ON fm.deployment_id = d.id
      AND fm.metric_date >= p_start_date
      AND fm.metric_date <= p_end_date
      AND fm.user_has_access = true  -- RLS filtering
    WHERE d.client_id = p_client_id
    GROUP BY d.id, d.name, at.name, at.display_name, d.status, d.created_at
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
      'call_revenue', COALESCE(call_revenue, 0),
      'sms_revenue', COALESCE(sms_revenue, 0),
      'email_revenue', COALESCE(email_revenue, 0),
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
  'Returns financial breakdown by deployment for a specific client. Uses v_financial_metrics_enriched view with RLS.';

-- ============================================================================
-- Verification Query (run after migration)
-- ============================================================================

-- First, get a client ID to test with
-- SELECT id, name FROM clients WHERE id IN (
--   SELECT client_id FROM user_client_permissions WHERE user_id = auth.uid()
-- ) LIMIT 5;

-- Then test with a client (replace CLIENT_ID)
-- SELECT jsonb_pretty(
--   get_client_deployments_breakdown(
--     'CLIENT_ID_HERE'::uuid,
--     CURRENT_DATE - 30,
--     CURRENT_DATE
--   )
-- );
