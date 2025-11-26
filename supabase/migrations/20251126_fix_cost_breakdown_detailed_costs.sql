-- Migration: Fix get_cost_breakdown to include detailed call costs
-- Date: 2025-11-26
-- Changes: Add STT, TTS, LLM, Telecom breakdown instead of just total call cost
-- Problem: Frontend expects detailed costs but function only returns totals

DROP FUNCTION IF EXISTS get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION get_cost_breakdown(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
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
  -- Aggregate cost breakdown directly from agent_calls with detailed costs
  -- Also include SMS and Email costs from their respective tables
  WITH call_costs AS (
    SELECT
      COALESCE(SUM(ac.stt_cost), 0) AS stt_cost,
      COALESCE(SUM(ac.tts_cost), 0) AS tts_cost,
      COALESCE(SUM(ac.llm_cost), 0) AS llm_cost,
      COALESCE(SUM(ac.telecom_cost), 0) AS telecom_cost,
      COALESCE(SUM(ac.total_cost), 0) AS total_cost,
      COUNT(ac.id) AS call_count
    FROM agent_calls ac
    INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND ac.started_at >= p_start_date
      AND ac.started_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  ),
  sms_costs AS (
    SELECT
      COALESCE(SUM(s.provider_cost), 0) AS total_cost,
      COUNT(s.id) AS sms_count
    FROM agent_sms s
    INNER JOIN agent_deployments ad ON s.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND s.sent_at >= p_start_date
      AND s.sent_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  ),
  email_costs AS (
    SELECT
      COALESCE(SUM(e.provider_cost), 0) AS total_cost,
      COUNT(e.id) AS email_count
    FROM agent_emails e
    INNER JOIN agent_deployments ad ON e.deployment_id = ad.id
    INNER JOIN clients c ON ad.client_id = c.id
    INNER JOIN agent_types at ON ad.agent_type_id = at.id
    INNER JOIN user_client_permissions ucp ON c.id = ucp.client_id
    WHERE ucp.user_id = auth.uid()
      AND e.sent_at >= p_start_date
      AND e.sent_at <= p_end_date + INTERVAL '1 day'
      AND (p_client_id IS NULL OR c.id = p_client_id)
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR ad.id = p_deployment_id)
  )
  SELECT JSONB_BUILD_OBJECT(
    'call_costs', JSONB_BUILD_OBJECT(
      'stt', (SELECT stt_cost FROM call_costs),
      'tts', (SELECT tts_cost FROM call_costs),
      'llm', (SELECT llm_cost FROM call_costs),
      'telecom', (SELECT telecom_cost FROM call_costs),
      'dipler_commission', 0, -- Not tracked yet
      'total', (SELECT total_cost FROM call_costs)
    ),
    'sms_costs', JSONB_BUILD_OBJECT(
      'total', (SELECT total_cost FROM sms_costs)
    ),
    'email_costs', JSONB_BUILD_OBJECT(
      'total', (SELECT total_cost FROM email_costs)
    ),
    'total_costs', JSONB_BUILD_OBJECT(
      'provider_cost', (
        (SELECT total_cost FROM call_costs) +
        (SELECT total_cost FROM sms_costs) +
        (SELECT total_cost FROM email_costs)
      ),
      'all_channels', (
        (SELECT total_cost FROM call_costs) +
        (SELECT total_cost FROM sms_costs) +
        (SELECT total_cost FROM email_costs)
      )
    ),
    'volume', JSONB_BUILD_OBJECT(
      'calls', (SELECT call_count FROM call_costs),
      'sms', (SELECT sms_count FROM sms_costs),
      'emails', (SELECT email_count FROM email_costs)
    ),
    'revenue', JSONB_BUILD_OBJECT(
      'call_revenue', 0, -- Revenue calculation would need pricing data
      'sms_revenue', 0,
      'email_revenue', 0,
      'total_revenue', 0
    )
  ) INTO v_result;

  RETURN COALESCE(v_result, '{}'::jsonb);

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error in get_cost_breakdown: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION get_cost_breakdown(DATE, DATE, UUID, TEXT, UUID) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERY (run manually to test)
-- ============================================================================
-- SELECT get_cost_breakdown();
