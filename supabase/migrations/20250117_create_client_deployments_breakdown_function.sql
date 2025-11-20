-- ============================================================================
-- Migration: Create get_client_deployments_breakdown function
-- Date: 2025-01-17
-- Author: Claude
-- Phase: Financial Dashboard - Phase 3 (Drill Down Level 1)
-- ============================================================================
--
-- Purpose: Drill down from client level to deployment level
-- Returns: JSONB array with deployment financial metrics for a specific client
--
-- Changes:
-- 1. Create function get_client_deployments_breakdown
-- 2. Returns financial breakdown by deployment for a client
-- 3. Calculates revenue, costs, margin, and KPIs per deployment
-- 4. Includes leasing pro-rating based on date range
-- 5. Respects RLS with user_has_access filtering
--
-- Usage Example:
--   SELECT get_client_deployments_breakdown(
--     'e63beaf9-2e3c-44e9-8f5d-5d063cac82fd'::uuid,
--     '2024-12-01',
--     '2025-01-17'
--   );
-- ============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_client_deployments_breakdown(UUID, DATE, DATE);

-- Create the function
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
BEGIN
  -- Calculate period duration for leasing pro-rating
  v_duration_days := p_end_date - p_start_date + 1;

  -- Build result with deployment breakdown
  SELECT JSONB_AGG(
    JSONB_BUILD_OBJECT(
      -- Deployment info
      'deployment_id', deployment_id,
      'deployment_name', deployment_name,
      'agent_type_name', agent_type_name,
      'agent_type_label', agent_type_label,
      'status', status,
      'created_at', created_at,

      -- Financial metrics
      'total_revenue', COALESCE(total_revenue, 0),
      'total_provider_cost', COALESCE(total_provider_cost, 0),
      'total_margin', COALESCE(total_margin, 0),
      'margin_percentage', CASE
        WHEN COALESCE(total_revenue, 0) > 0
        THEN ROUND((COALESCE(total_margin, 0) / total_revenue * 100)::numeric, 2)
        ELSE 0
      END,

      -- Volume metrics
      'call_count', COALESCE(call_count, 0),
      'sms_count', COALESCE(sms_count, 0),
      'email_count', COALESCE(email_count, 0),
      'answered_calls', COALESCE(answered_calls, 0),
      'appointments_scheduled', COALESCE(appointments_scheduled, 0),

      -- Conversion rates
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

      -- Cost breakdown
      'call_cost', COALESCE(call_cost, 0),
      'sms_cost', COALESCE(sms_cost, 0),
      'email_cost', COALESCE(email_cost, 0),
      'leasing_revenue', COALESCE(leasing_revenue, 0),

      -- Averages
      'avg_call_duration', CASE
        WHEN COALESCE(answered_calls, 0) > 0
        THEN ROUND((COALESCE(total_call_duration, 0)::numeric / answered_calls), 2)
        ELSE 0
      END,
      'cost_per_call', CASE
        WHEN COALESCE(call_count, 0) > 0
        THEN ROUND((COALESCE(total_provider_cost, 0) / call_count), 2)
        ELSE 0
      END,
      'cost_per_appointment', CASE
        WHEN COALESCE(appointments_scheduled, 0) > 0
        THEN ROUND((COALESCE(total_provider_cost, 0) / appointments_scheduled), 2)
        ELSE 0
      END
    )
  ) INTO v_result
  FROM (
    SELECT
      d.id AS deployment_id,
      d.name AS deployment_name,
      at.name AS agent_type_name,
      COALESCE(at.label, at.name) AS agent_type_label,
      d.status,
      d.created_at,

      -- Revenue calculation (leasing pro-rated + VAPI consumption with margins)
      SUM(
        -- Leasing revenue (pro-rated for the period)
        CASE
          WHEN d.pricing_model = 'leasing' THEN
            (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
          ELSE
            0
        END +
        -- VAPI consumption revenue (with margin)
        CASE
          WHEN d.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (1 + COALESCE(d.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END +
        -- SMS revenue (with margin)
        COALESCE(ac.sms_cost_eur, 0) * (1 + COALESCE(d.voipia_margin_percentage_sms, 0) / 100.0) +
        -- Email revenue (with margin)
        COALESCE(ac.email_cost_eur, 0) * (1 + COALESCE(d.voipia_margin_percentage_email, 0) / 100.0)
      ) AS total_revenue,

      -- Provider cost calculation (actual costs without margins)
      SUM(
        COALESCE(ac.vapi_cost_eur, 0) +
        COALESCE(ac.sms_cost_eur, 0) +
        COALESCE(ac.email_cost_eur, 0)
      ) AS total_provider_cost,

      -- Margin calculation (revenue - provider costs = leasing + margins)
      SUM(
        -- Leasing margin
        CASE
          WHEN d.pricing_model = 'leasing' THEN
            (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
          ELSE
            0
        END +
        -- VAPI margin
        CASE
          WHEN d.pricing_model IN ('consumption', 'hybrid') THEN
            COALESCE(ac.vapi_cost_eur, 0) * (COALESCE(d.voipia_margin_percentage, 0) / 100.0)
          ELSE
            0
        END +
        -- SMS margin
        COALESCE(ac.sms_cost_eur, 0) * (COALESCE(d.voipia_margin_percentage_sms, 0) / 100.0) +
        -- Email margin
        COALESCE(ac.email_cost_eur, 0) * (COALESCE(d.voipia_margin_percentage_email, 0) / 100.0)
      ) AS total_margin,

      -- Volume counts
      COUNT(*) FILTER (WHERE ac.id IS NOT NULL) AS call_count,
      COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
      COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
      COALESCE(SUM(ac.sms_count), 0) AS sms_count,
      COALESCE(SUM(ac.email_count), 0) AS email_count,

      -- Cost breakdown
      SUM(COALESCE(ac.vapi_cost_eur, 0)) AS call_cost,
      SUM(COALESCE(ac.sms_cost_eur, 0)) AS sms_cost,
      SUM(COALESCE(ac.email_cost_eur, 0)) AS email_cost,

      -- Leasing revenue
      SUM(
        CASE
          WHEN d.pricing_model = 'leasing' THEN
            (COALESCE(d.leasing_monthly_price, 0) / 30.0) * v_duration_days
          ELSE
            0
        END
      ) AS leasing_revenue,

      -- Duration
      SUM(COALESCE(ac.duration_seconds, 0)) AS total_call_duration

    FROM agent_deployments d
    INNER JOIN agent_types at ON d.agent_type_id = at.id
    LEFT JOIN v_agent_calls_enriched ac ON ac.deployment_id = d.id
      AND ac.created_at::date >= p_start_date
      AND ac.created_at::date <= p_end_date
      AND ac.user_has_access = true  -- RLS filtering
    WHERE d.client_id = p_client_id
      AND d.user_has_access = true  -- RLS filtering
    GROUP BY d.id, d.name, at.name, at.label, d.status, d.created_at
    ORDER BY total_revenue DESC
  ) sub;

  -- Return result or empty array if no deployments found
  RETURN COALESCE(v_result, '[]'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_client_deployments_breakdown: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_client_deployments_breakdown(UUID, DATE, DATE) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_client_deployments_breakdown IS
  'Returns financial breakdown by deployment for a specific client. Used for drill-down from client to deployment level in financial dashboard. Respects RLS via user_has_access column.';

-- ============================================================================
-- Verification Queries (uncomment to test after applying migration)
-- ============================================================================

-- Test 1: Check function exists
-- SELECT proname, proargnames, prosrc
-- FROM pg_proc
-- WHERE proname = 'get_client_deployments_breakdown';

-- Test 2: Execute for a client (replace with actual client_id)
-- SELECT jsonb_pretty(
--   get_client_deployments_breakdown(
--     'CLIENT_ID_HERE'::uuid,
--     CURRENT_DATE - INTERVAL '30 days',
--     CURRENT_DATE
--   )
-- );

-- Test 3: Verify deployment count matches for a client
-- SELECT
--   c.name AS client_name,
--   COUNT(d.id) AS deployment_count,
--   jsonb_array_length(
--     get_client_deployments_breakdown(c.id, CURRENT_DATE - 30, CURRENT_DATE)
--   ) AS function_deployment_count
-- FROM clients c
-- LEFT JOIN agent_deployments d ON d.client_id = c.id
-- WHERE c.user_has_access = true
-- GROUP BY c.id, c.name
-- LIMIT 5;

-- ============================================================================
-- Expected Impact:
-- - Enables drill-down from client to deployment level in financial dashboard
-- - Returns comprehensive metrics per deployment (revenue, costs, margin, KPIs)
-- - Properly calculates leasing pro-rating for any date range
-- - Respects Row Level Security with user_has_access filtering
-- ============================================================================
