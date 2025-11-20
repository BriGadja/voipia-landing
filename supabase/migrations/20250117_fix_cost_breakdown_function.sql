-- Migration: Fix get_cost_breakdown function
-- Date: 2025-01-17
-- Author: Claude
--
-- Problem: Function tries to access detailed cost columns that don't exist in v_financial_metrics_enriched
-- Solution: Simplify to use only available aggregated columns
--
-- Changes:
-- - Removed references to call_stt_cost, call_tts_cost, call_llm_cost, call_telecom_cost, call_dipler_commission
-- - Use only call_provider_cost (total) which exists in the view

DROP FUNCTION IF EXISTS get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID);

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
SET search_path TO 'public'
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Aggregate cost breakdown from v_financial_metrics_enriched
  -- Note: Detailed cost breakdown (STT, TTS, LLM) not available in view, using totals only
  SELECT JSONB_BUILD_OBJECT(
    'call_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(call_provider_cost), 0)
    ),
    'sms_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(sms_provider_cost), 0)
    ),
    'email_costs', JSONB_BUILD_OBJECT(
      'total', COALESCE(SUM(email_provider_cost), 0)
    ),
    'total_costs', JSONB_BUILD_OBJECT(
      'provider_cost', COALESCE(SUM(call_provider_cost + sms_provider_cost + email_provider_cost), 0),
      'all_channels', COALESCE(SUM(
        call_provider_cost +
        sms_provider_cost +
        email_provider_cost
      ), 0)
    ),
    'volume', JSONB_BUILD_OBJECT(
      'calls', COALESCE(SUM(call_count), 0),
      'sms', COALESCE(SUM(sms_count), 0),
      'emails', COALESCE(SUM(email_count), 0)
    ),
    'revenue', JSONB_BUILD_OBJECT(
      'call_revenue', COALESCE(SUM(call_revenue), 0),
      'sms_revenue', COALESCE(SUM(sms_revenue), 0),
      'email_revenue', COALESCE(SUM(email_revenue), 0),
      'total_revenue', COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0)
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID) TO authenticated;

-- Verification query
-- SELECT jsonb_pretty(get_cost_breakdown(CURRENT_DATE - 30, CURRENT_DATE));
