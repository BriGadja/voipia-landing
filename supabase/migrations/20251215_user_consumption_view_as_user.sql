-- Migration: User Consumption Metrics View As User Support
-- Date: 2025-12-15
-- Description: Modifie get_user_consumption_metrics pour supporter view_as_user
-- SECURITE: Ne retourne JAMAIS provider_cost, margin, margin_percentage aux utilisateurs

DROP FUNCTION IF EXISTS get_user_consumption_metrics(DATE, DATE, UUID);
DROP FUNCTION IF EXISTS get_user_consumption_metrics(DATE, DATE, UUID, UUID);

CREATE OR REPLACE FUNCTION get_user_consumption_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_client_id UUID DEFAULT NULL,
  p_view_as_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_is_admin BOOLEAN;
  v_effective_user_id UUID;
  v_result JSONB;
  v_accessible_client_ids UUID[];
BEGIN
  -- Get current user
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Check if user is admin
  v_is_admin := is_admin();

  -- Determine effective user ID for permissions
  -- If admin and view_as_user_id is provided, use that user's permissions
  IF v_is_admin AND p_view_as_user_id IS NOT NULL THEN
    v_effective_user_id := p_view_as_user_id;
  ELSE
    v_effective_user_id := v_user_id;
  END IF;

  -- Get accessible client IDs based on effective user
  -- Admin viewing as self (no view_as_user) sees everything
  IF v_is_admin AND p_view_as_user_id IS NULL THEN
    SELECT ARRAY_AGG(DISTINCT c.id)
    INTO v_accessible_client_ids
    FROM clients c
    WHERE (p_client_id IS NULL OR c.id = p_client_id);
  ELSE
    -- Use effective user's permissions
    SELECT ARRAY_AGG(DISTINCT ucp.client_id)
    INTO v_accessible_client_ids
    FROM user_client_permissions ucp
    WHERE ucp.user_id = v_effective_user_id
      AND (p_client_id IS NULL OR ucp.client_id = p_client_id);
  END IF;

  -- Return empty result if no accessible clients
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'current_period', jsonb_build_object(
        'total_minutes', 0, 'total_seconds', 0, 'total_sms_segments', 0,
        'total_emails', 0, 'total_calls', 0, 'answered_calls', 0,
        'appointments_scheduled', 0, 'total_cost', 0, 'call_cost', 0,
        'sms_cost', 0, 'email_cost', 0
      ),
      'pricing', jsonb_build_object(
        'avg_price_per_minute', 0, 'avg_price_per_sms', 0, 'avg_price_per_email', 0
      ),
      'by_agent', '[]'::jsonb
    );
  END IF;

  WITH call_metrics AS (
    SELECT
      ad.id AS deployment_id, ad.name AS deployment_name,
      at.name AS agent_type_name, c.name AS client_name,
      ad.cost_per_min, ad.cost_per_sms, ad.cost_per_email,
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,
      COALESCE(SUM(ac.duration_seconds), 0) AS total_seconds,
      COALESCE(SUM(ac.duration_seconds / 60.0 * ad.cost_per_min), 0) AS call_cost
    FROM agent_deployments ad
    JOIN agent_types at ON ad.agent_type_id = at.id
    JOIN clients c ON ad.client_id = c.id
    LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids) AND ad.status = 'active'
    GROUP BY ad.id, ad.name, at.name, c.name, ad.cost_per_min, ad.cost_per_sms, ad.cost_per_email
  ),
  sms_metrics AS (
    SELECT ad.id AS deployment_id,
      COUNT(asms.id) AS total_sms,
      COALESCE(SUM(asms.num_segments), COUNT(asms.id)) AS total_segments,
      COALESCE(SUM(asms.billed_cost), 0) AS sms_cost
    FROM agent_deployments ad
    LEFT JOIN agent_sms asms ON ad.id = asms.deployment_id
      AND asms.sent_at >= p_start_date AND asms.sent_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids) AND ad.status = 'active'
    GROUP BY ad.id
  ),
  email_metrics AS (
    SELECT ad.id AS deployment_id,
      COUNT(ae.id) AS total_emails,
      COALESCE(SUM(ae.billed_cost), 0) AS email_cost
    FROM agent_deployments ad
    LEFT JOIN agent_emails ae ON ad.id = ae.deployment_id
      AND ae.sent_at >= p_start_date AND ae.sent_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids) AND ad.status = 'active'
    GROUP BY ad.id
  ),
  combined AS (
    SELECT cm.*, COALESCE(sm.total_sms, 0) AS total_sms,
      COALESCE(sm.total_segments, 0) AS total_segments, COALESCE(sm.sms_cost, 0) AS sms_cost,
      COALESCE(em.total_emails, 0) AS total_emails, COALESCE(em.email_cost, 0) AS email_cost
    FROM call_metrics cm
    LEFT JOIN sms_metrics sm ON cm.deployment_id = sm.deployment_id
    LEFT JOIN email_metrics em ON cm.deployment_id = em.deployment_id
  ),
  totals AS (
    SELECT SUM(total_calls) AS total_calls, SUM(answered_calls) AS answered_calls,
      SUM(appointments_scheduled) AS appointments_scheduled, SUM(total_seconds) AS total_seconds,
      SUM(call_cost) AS call_cost, SUM(total_segments) AS total_segments,
      SUM(sms_cost) AS sms_cost, SUM(total_emails) AS total_emails, SUM(email_cost) AS email_cost
    FROM combined
  )
  SELECT jsonb_build_object(
    'current_period', jsonb_build_object(
      'total_minutes', ROUND((t.total_seconds / 60.0)::numeric, 2),
      'total_seconds', t.total_seconds,
      'total_sms_segments', t.total_segments,
      'total_emails', t.total_emails,
      'total_calls', t.total_calls,
      'answered_calls', t.answered_calls,
      'appointments_scheduled', t.appointments_scheduled,
      'total_cost', ROUND((t.call_cost + t.sms_cost + t.email_cost)::numeric, 2),
      'call_cost', ROUND(t.call_cost::numeric, 2),
      'sms_cost', ROUND(t.sms_cost::numeric, 2),
      'email_cost', ROUND(t.email_cost::numeric, 2)
    ),
    'pricing', jsonb_build_object(
      'avg_price_per_minute', CASE WHEN t.total_seconds > 0 THEN ROUND((t.call_cost / (t.total_seconds / 60.0))::numeric, 4) ELSE 0 END,
      'avg_price_per_sms', CASE WHEN t.total_segments > 0 THEN ROUND((t.sms_cost / t.total_segments)::numeric, 4) ELSE 0 END,
      'avg_price_per_email', CASE WHEN t.total_emails > 0 THEN ROUND((t.email_cost / t.total_emails)::numeric, 4) ELSE 0 END
    ),
    'by_agent', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'deployment_id', c.deployment_id, 'deployment_name', c.deployment_name,
          'agent_type_name', c.agent_type_name, 'client_name', c.client_name,
          'total_minutes', ROUND((c.total_seconds / 60.0)::numeric, 2),
          'total_seconds', c.total_seconds, 'total_sms_segments', c.total_segments,
          'total_emails', c.total_emails, 'total_calls', c.total_calls,
          'answered_calls', c.answered_calls, 'appointments_scheduled', c.appointments_scheduled,
          'total_cost', ROUND((c.call_cost + c.sms_cost + c.email_cost)::numeric, 2),
          'price_per_minute', COALESCE(c.cost_per_min, 0),
          'price_per_sms', COALESCE(c.cost_per_sms, 0),
          'price_per_email', COALESCE(c.cost_per_email, 0)
        ) ORDER BY (c.call_cost + c.sms_cost + c.email_cost) DESC
      ), '[]'::jsonb)
      FROM combined c
      WHERE c.total_calls > 0 OR c.total_segments > 0 OR c.total_emails > 0
    )
  ) INTO v_result FROM totals t;

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_consumption_metrics(DATE, DATE, UUID, UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_user_consumption_metrics IS 'Returns user consumption metrics for Ma Conso dashboard. Supports view_as_user for admin preview. SECURITY: Never returns provider_cost or margin data.';
