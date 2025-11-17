-- ============================================================================
-- Migration: Create function for detailed cost breakdown
-- Date: 2025-01-17
-- Author: Claude
-- Purpose: Get detailed breakdown of costs by technology (STT, TTS, LLM, etc.)
-- ============================================================================
--
-- Function: get_cost_breakdown
-- Returns: JSONB with detailed cost breakdown by technology
--
-- ============================================================================

-- Create function to get cost breakdown
CREATE OR REPLACE FUNCTION public.get_cost_breakdown(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Aggregate cost breakdown from v_financial_metrics_enriched
  SELECT JSONB_BUILD_OBJECT(
    'call_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(call_provider_cost), 0),
      'stt', COALESCE(SUM(call_stt_cost), 0),
      'tts', COALESCE(SUM(call_tts_cost), 0),
      'llm', COALESCE(SUM(call_llm_cost), 0),
      'telecom', COALESCE(SUM(call_telecom_cost), 0),
      'dipler_commission', COALESCE(SUM(call_dipler_commission), 0)
    ),
    'sms_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(sms_provider_cost), 0)
    ),
    'email_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(email_provider_cost), 0)
    ),
    'total_costs', JSONB_BUILD_OBJECT(
      'provider_cost', COALESCE(SUM(call_provider_cost + sms_provider_cost + email_provider_cost), 0),
      'stt', COALESCE(SUM(call_stt_cost), 0),
      'tts', COALESCE(SUM(call_tts_cost), 0),
      'llm', COALESCE(SUM(call_llm_cost), 0),
      'telecom', COALESCE(SUM(call_telecom_cost), 0),
      'dipler_commission', COALESCE(SUM(call_dipler_commission), 0),
      'all_channels', COALESCE(SUM(
        call_provider_cost +
        call_dipler_commission +
        sms_provider_cost +
        email_provider_cost
      ), 0)
    ),
    'volume', JSONB_BUILD_OBJECT(
      'calls', COALESCE(SUM(call_count), 0),
      'sms', COALESCE(SUM(sms_count), 0),
      'emails', COALESCE(SUM(email_count), 0)
    )
  ) INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_type_name IS NULL OR agent_type_name = p_agent_type_name)
    AND (p_deployment_id IS NULL OR deployment_id = p_deployment_id);

  RETURN COALESCE(v_result, '{}'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_cost_breakdown: %', SQLERRM;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.get_cost_breakdown IS
  'Returns detailed breakdown of costs by technology (STT, TTS, LLM, Telecom, Dipler Commission) for a given period. RLS enforced via v_financial_metrics_enriched.';

-- ============================================================================
-- Verification Query
-- ============================================================================

-- Test the function
-- SELECT jsonb_pretty(
--   get_cost_breakdown(
--     CURRENT_DATE - 30,
--     CURRENT_DATE,
--     NULL,  -- all clients
--     NULL,  -- all agent types
--     NULL   -- all deployments
--   )
-- );
