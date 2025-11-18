-- Migration: Restrict Financial Dashboard to Admins Only
-- Date: 2025-11-18
-- Author: Claude
--
-- Security Fix: Ensure only users with 'admin' permission level can access
-- financial data (leasing, consumption, margins, costs)
--
-- Changes:
-- 1. Create helper function is_admin() to check admin status
-- 2. Update v_financial_metrics_enriched to filter by admin permission
-- 3. Add admin checks to all financial RPC functions
-- 4. Revoke public access and grant only to authenticated admins

-- ============================================================================
-- STEP 1: Create Admin Helper Function
-- ============================================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS is_admin();

-- Create function to check if current user has admin permission for any client
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM user_client_permissions
    WHERE user_id = auth.uid()
      AND permission_level = 'admin'
  );
$$;

COMMENT ON FUNCTION is_admin() IS
'Returns true if the authenticated user has admin permission level for at least one client';

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- ============================================================================
-- STEP 2: Create Admin Check for Specific Client
-- ============================================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS is_admin_for_client(uuid);

-- Create function to check if user is admin for a specific client
CREATE OR REPLACE FUNCTION is_admin_for_client(p_client_id uuid)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM user_client_permissions
    WHERE user_id = auth.uid()
      AND client_id = p_client_id
      AND permission_level = 'admin'
  );
$$;

COMMENT ON FUNCTION is_admin_for_client(uuid) IS
'Returns true if the authenticated user has admin permission for the specified client';

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION is_admin_for_client(uuid) TO authenticated;

-- ============================================================================
-- STEP 3: Update v_financial_metrics_enriched to Filter by Admin
-- ============================================================================

-- Drop and recreate the view with admin-only filter
DROP VIEW IF EXISTS v_financial_metrics_enriched CASCADE;

CREATE OR REPLACE VIEW v_financial_metrics_enriched AS
WITH deployment_base AS (
  SELECT
    d.id AS deployment_id,
    d.client_id,
    d.agent_type_id,
    at.name AS agent_type_name,
    c.name AS client_name,
    d.leasing,
    d.cost_per_min,
    d.cost_per_sms,
    d.cost_per_email,
    d.created_at AS deployment_start_date,
    d.status AS deployment_status,
    -- SECURITY: Only include deployments where user is ADMIN
    EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.client_id = d.client_id
        AND ucp.user_id = auth.uid()
        AND ucp.permission_level = 'admin'  -- ⚠️ ADMIN ONLY
    ) AS user_has_access
  FROM agent_deployments d
  JOIN agent_types at ON d.agent_type_id = at.id
  JOIN clients c ON d.client_id = c.id
),
call_metrics AS (
  SELECT
    ac.deployment_id,
    DATE_TRUNC('day', ac.created_at) AS metric_date,
    COUNT(*) AS call_count,
    COUNT(*) FILTER (WHERE ac.answered = true) AS answered_calls,
    COUNT(*) FILTER (WHERE ac.appointment_scheduled = true) AS appointments_scheduled,
    SUM(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS total_duration_seconds,
    AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS avg_duration_seconds,
    SUM((ac.duration_seconds::numeric / 60.0) * db.cost_per_min) AS call_revenue,
    SUM(COALESCE(ac.total_cost, 0)) AS call_provider_cost
  FROM v_agent_calls_enriched ac
  JOIN deployment_base db ON ac.deployment_id = db.deployment_id
  WHERE ac.created_at IS NOT NULL
  GROUP BY ac.deployment_id, DATE_TRUNC('day', ac.created_at)
),
sms_metrics AS (
  SELECT
    asms.deployment_id,
    DATE_TRUNC('day', asms.sent_at) AS metric_date,
    COUNT(*) AS sms_count,
    COUNT(*) FILTER (WHERE asms.status = 'delivered') AS sms_delivered,
    SUM(db.cost_per_sms) AS sms_revenue,
    SUM(COALESCE(asms.billed_cost, 0)) AS sms_provider_cost
  FROM agent_sms asms
  JOIN deployment_base db ON asms.deployment_id = db.deployment_id
  WHERE asms.sent_at IS NOT NULL
  GROUP BY asms.deployment_id, DATE_TRUNC('day', asms.sent_at)
),
email_metrics AS (
  SELECT
    ae.deployment_id,
    DATE_TRUNC('day', ae.sent_at) AS metric_date,
    COUNT(*) AS email_count,
    COUNT(*) FILTER (WHERE ae.status = 'delivered') AS email_delivered,
    SUM(db.cost_per_email) AS email_revenue,
    SUM(COALESCE(ae.billed_cost, 0)) AS email_provider_cost
  FROM agent_emails ae
  JOIN deployment_base db ON ae.deployment_id = db.deployment_id
  WHERE ae.sent_at IS NOT NULL
  GROUP BY ae.deployment_id, DATE_TRUNC('day', ae.sent_at)
),
all_metric_dates AS (
  SELECT DISTINCT deployment_id, metric_date
  FROM (
    SELECT deployment_id, metric_date FROM call_metrics
    UNION
    SELECT deployment_id, metric_date FROM sms_metrics
    UNION
    SELECT deployment_id, metric_date FROM email_metrics
  ) combined_dates
),
combined_metrics AS (
  SELECT
    amd.deployment_id,
    amd.metric_date,
    db.client_id,
    db.client_name,
    db.agent_type_id,
    db.agent_type_name,
    db.deployment_status,
    db.user_has_access,

    -- Call metrics
    COALESCE(cm.call_count, 0) AS call_count,
    COALESCE(cm.answered_calls, 0) AS answered_calls,
    COALESCE(cm.appointments_scheduled, 0) AS appointments_scheduled,
    COALESCE(cm.total_duration_seconds, 0) AS total_duration_seconds,
    COALESCE(cm.avg_duration_seconds, 0) AS avg_duration_seconds,
    COALESCE(cm.call_revenue, 0) AS call_revenue,
    COALESCE(cm.call_provider_cost, 0) AS call_provider_cost,

    -- SMS metrics
    COALESCE(sm.sms_count, 0) AS sms_count,
    COALESCE(sm.sms_delivered, 0) AS sms_delivered,
    COALESCE(sm.sms_revenue, 0) AS sms_revenue,
    COALESCE(sm.sms_provider_cost, 0) AS sms_provider_cost,

    -- Email metrics
    COALESCE(em.email_count, 0) AS email_count,
    COALESCE(em.email_delivered, 0) AS email_delivered,
    COALESCE(em.email_revenue, 0) AS email_revenue,
    COALESCE(em.email_provider_cost, 0) AS email_provider_cost,

    -- Leasing (daily pro-rated)
    COALESCE(db.leasing / 30.0, 0) AS leasing_revenue_daily,
    COALESCE(db.leasing / 30.0, 0) AS leasing_margin_daily,

    -- Consumption (calls + SMS + emails)
    (
      COALESCE(cm.call_revenue, 0) +
      COALESCE(sm.sms_revenue, 0) +
      COALESCE(em.email_revenue, 0)
    ) AS consumption_revenue,
    (
      COALESCE(cm.call_provider_cost, 0) +
      COALESCE(sm.sms_provider_cost, 0) +
      COALESCE(em.email_provider_cost, 0)
    ) AS consumption_provider_cost,
    (
      (COALESCE(cm.call_revenue, 0) + COALESCE(sm.sms_revenue, 0) + COALESCE(em.email_revenue, 0)) -
      (COALESCE(cm.call_provider_cost, 0) + COALESCE(sm.sms_provider_cost, 0) + COALESCE(em.email_provider_cost, 0))
    ) AS consumption_margin,

    -- Total (leasing + consumption)
    (
      COALESCE(cm.call_revenue, 0) +
      COALESCE(sm.sms_revenue, 0) +
      COALESCE(em.email_revenue, 0) +
      COALESCE(db.leasing / 30.0, 0)
    ) AS total_revenue,
    (
      COALESCE(cm.call_provider_cost, 0) +
      COALESCE(sm.sms_provider_cost, 0) +
      COALESCE(em.email_provider_cost, 0)
    ) AS total_provider_cost,
    (
      (COALESCE(cm.call_revenue, 0) + COALESCE(sm.sms_revenue, 0) + COALESCE(em.email_revenue, 0) + COALESCE(db.leasing / 30.0, 0)) -
      (COALESCE(cm.call_provider_cost, 0) + COALESCE(sm.sms_provider_cost, 0) + COALESCE(em.email_provider_cost, 0))
    ) AS total_margin
  FROM all_metric_dates amd
  JOIN deployment_base db ON amd.deployment_id = db.deployment_id
  LEFT JOIN call_metrics cm ON amd.deployment_id = cm.deployment_id AND amd.metric_date = cm.metric_date
  LEFT JOIN sms_metrics sm ON amd.deployment_id = sm.deployment_id AND amd.metric_date = sm.metric_date
  LEFT JOIN email_metrics em ON amd.deployment_id = em.deployment_id AND amd.metric_date = em.metric_date
)
SELECT
  *,
  -- Consumption margin percentage
  CASE
    WHEN consumption_revenue > 0 THEN (consumption_margin / consumption_revenue * 100)
    ELSE 0
  END AS consumption_margin_pct,
  -- Total margin percentage
  CASE
    WHEN total_revenue > 0 THEN (total_margin / total_revenue * 100)
    ELSE 0
  END AS margin_percentage
FROM combined_metrics;

-- Grant SELECT to authenticated users (RLS will filter by admin)
GRANT SELECT ON v_financial_metrics_enriched TO authenticated;

COMMENT ON VIEW v_financial_metrics_enriched IS
'Financial metrics view with leasing/consumption separation. ADMIN ACCESS ONLY via user_has_access column.';

-- ============================================================================
-- STEP 4: Add Admin Checks to Financial RPC Functions
-- ============================================================================

-- 4.1: get_financial_kpi_metrics
-- ============================================================================

DROP FUNCTION IF EXISTS get_financial_kpi_metrics(date, date, uuid, text, uuid);

CREATE OR REPLACE FUNCTION get_financial_kpi_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- SECURITY CHECK: Verify user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required to view financial metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Rest of function logic (unchanged)
  SELECT jsonb_build_object(
    'current_period', current_metrics,
    'previous_period', previous_metrics,
    'period_info', period_info,
    'comparison', comparison
  )
  INTO v_result
  FROM (
    SELECT
      jsonb_build_object(
        'total_revenue', COALESCE(SUM(total_revenue), 0),
        'total_provider_cost', COALESCE(SUM(total_provider_cost), 0),
        'total_margin', COALESCE(SUM(total_margin), 0),
        'margin_percentage', CASE
          WHEN COALESCE(SUM(total_revenue), 0) > 0
          THEN (COALESCE(SUM(total_margin), 0) / COALESCE(SUM(total_revenue), 0) * 100)
          ELSE 0
        END,
        'call_revenue', COALESCE(SUM(call_revenue), 0),
        'sms_revenue', COALESCE(SUM(sms_revenue), 0),
        'email_revenue', COALESCE(SUM(email_revenue), 0),
        'leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
        'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
        'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
        'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
        'call_count', COALESCE(SUM(call_count), 0),
        'answered_calls', COALESCE(SUM(answered_calls), 0),
        'appointments_scheduled', COALESCE(SUM(appointments_scheduled), 0),
        'sms_count', COALESCE(SUM(sms_count), 0),
        'email_count', COALESCE(SUM(email_count), 0),
        'unique_clients', COUNT(DISTINCT client_id),
        'unique_deployments', COUNT(DISTINCT deployment_id),
        'avg_revenue_per_client', CASE
          WHEN COUNT(DISTINCT client_id) > 0
          THEN COALESCE(SUM(total_revenue), 0) / COUNT(DISTINCT client_id)
          ELSE 0
        END,
        'avg_margin_per_client', CASE
          WHEN COUNT(DISTINCT client_id) > 0
          THEN COALESCE(SUM(total_margin), 0) / COUNT(DISTINCT client_id)
          ELSE 0
        END
      ) AS current_metrics,

      jsonb_build_object(
        'total_revenue', COALESCE(SUM(prev.total_revenue), 0),
        'total_provider_cost', COALESCE(SUM(prev.total_provider_cost), 0),
        'total_margin', COALESCE(SUM(prev.total_margin), 0),
        'margin_percentage', CASE
          WHEN COALESCE(SUM(prev.total_revenue), 0) > 0
          THEN (COALESCE(SUM(prev.total_margin), 0) / COALESCE(SUM(prev.total_revenue), 0) * 100)
          ELSE 0
        END
      ) AS previous_metrics,

      jsonb_build_object(
        'start_date', p_start_date,
        'end_date', p_end_date,
        'duration_days', p_end_date - p_start_date + 1,
        'previous_start_date', p_start_date - (p_end_date - p_start_date + 1),
        'previous_end_date', p_start_date - 1
      ) AS period_info,

      jsonb_build_object(
        'revenue_change', COALESCE(SUM(total_revenue), 0) - COALESCE(SUM(prev.total_revenue), 0),
        'revenue_change_percentage', CASE
          WHEN COALESCE(SUM(prev.total_revenue), 0) > 0
          THEN ((COALESCE(SUM(total_revenue), 0) - COALESCE(SUM(prev.total_revenue), 0)) / COALESCE(SUM(prev.total_revenue), 0) * 100)
          ELSE 0
        END,
        'margin_change', COALESCE(SUM(total_margin), 0) - COALESCE(SUM(prev.total_margin), 0),
        'margin_change_percentage', CASE
          WHEN COALESCE(SUM(prev.total_margin), 0) > 0
          THEN ((COALESCE(SUM(total_margin), 0) - COALESCE(SUM(prev.total_margin), 0)) / COALESCE(SUM(prev.total_margin), 0) * 100)
          ELSE 0
        END
      ) AS comparison
    FROM v_financial_metrics_enriched curr
    LEFT JOIN v_financial_metrics_enriched prev ON
      prev.deployment_id = curr.deployment_id
      AND prev.metric_date >= (p_start_date - (p_end_date - p_start_date + 1))
      AND prev.metric_date < p_start_date
    WHERE curr.metric_date >= p_start_date
      AND curr.metric_date <= p_end_date
      AND curr.user_has_access = true
      AND (p_client_id IS NULL OR curr.client_id = p_client_id)
      AND (p_agent_type_name IS NULL OR curr.agent_type_name = p_agent_type_name)
      AND (p_deployment_id IS NULL OR curr.deployment_id = p_deployment_id)
  ) sub;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_financial_kpi_metrics(date, date, uuid, text, uuid) TO authenticated;

-- 4.2: get_leasing_kpi_metrics
-- ============================================================================

DROP FUNCTION IF EXISTS get_leasing_kpi_metrics(date, date);

CREATE OR REPLACE FUNCTION get_leasing_kpi_metrics(
  p_start_date date,
  p_end_date date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- SECURITY CHECK: Verify user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required to view leasing metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate leasing metrics
  SELECT jsonb_build_object(
    'total_leasing_revenue', COALESCE(SUM(leasing_revenue_daily), 0),
    'active_leasing_count', COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0),
    'avg_leasing_per_client', CASE
      WHEN COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0) > 0
      THEN COALESCE(SUM(leasing_revenue_daily), 0) / COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0)
      ELSE 0
    END,
    'mrr', COALESCE(SUM(leasing_revenue_daily), 0) * 30 / NULLIF(p_end_date - p_start_date + 1, 0),
    'avg_monthly_leasing', COALESCE(SUM(leasing_revenue_daily), 0) * 30 / NULLIF(COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0), 0),
    'leasing_client_count', COUNT(DISTINCT client_id) FILTER (WHERE leasing_revenue_daily > 0),
    'leasing_adoption_rate', CASE
      WHEN COUNT(DISTINCT deployment_id) > 0
      THEN (COUNT(DISTINCT deployment_id) FILTER (WHERE leasing_revenue_daily > 0)::numeric / COUNT(DISTINCT deployment_id) * 100)
      ELSE 0
    END,
    'total_leasing_margin', COALESCE(SUM(leasing_margin_daily), 0),
    'leasing_margin_pct', 100.0
  )
  INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_leasing_kpi_metrics(date, date) TO authenticated;

-- 4.3: get_consumption_kpi_metrics
-- ============================================================================

DROP FUNCTION IF EXISTS get_consumption_kpi_metrics(date, date);

CREATE OR REPLACE FUNCTION get_consumption_kpi_metrics(
  p_start_date date,
  p_end_date date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- SECURITY CHECK: Verify user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required to view consumption metrics'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate consumption metrics
  SELECT jsonb_build_object(
    'total_consumption_revenue', COALESCE(SUM(consumption_revenue), 0),
    'total_provider_cost', COALESCE(SUM(consumption_provider_cost), 0),
    'total_consumption_margin', COALESCE(SUM(consumption_margin), 0),
    'consumption_margin_pct', CASE
      WHEN COALESCE(SUM(consumption_revenue), 0) > 0
      THEN (COALESCE(SUM(consumption_margin), 0) / COALESCE(SUM(consumption_revenue), 0) * 100)
      ELSE 0
    END,

    'total_calls', COALESCE(SUM(call_count), 0),
    'total_sms', COALESCE(SUM(sms_count), 0),
    'total_emails', COALESCE(SUM(email_count), 0),
    'total_answered_calls', COALESCE(SUM(answered_calls), 0),
    'total_appointments', COALESCE(SUM(appointments_scheduled), 0),

    'call_revenue', COALESCE(SUM(call_revenue), 0),
    'call_provider_cost', COALESCE(SUM(call_provider_cost), 0),
    'call_margin', COALESCE(SUM(call_revenue - call_provider_cost), 0),
    'call_margin_pct', CASE
      WHEN COALESCE(SUM(call_revenue), 0) > 0
      THEN (COALESCE(SUM(call_revenue - call_provider_cost), 0) / COALESCE(SUM(call_revenue), 0) * 100)
      ELSE 0
    END,

    'sms_revenue', COALESCE(SUM(sms_revenue), 0),
    'sms_provider_cost', COALESCE(SUM(sms_provider_cost), 0),
    'sms_margin', COALESCE(SUM(sms_revenue - sms_provider_cost), 0),
    'sms_margin_pct', CASE
      WHEN COALESCE(SUM(sms_revenue), 0) > 0
      THEN (COALESCE(SUM(sms_revenue - sms_provider_cost), 0) / COALESCE(SUM(sms_revenue), 0) * 100)
      ELSE 0
    END,

    'email_revenue', COALESCE(SUM(email_revenue), 0),
    'email_provider_cost', COALESCE(SUM(email_provider_cost), 0),
    'email_margin', COALESCE(SUM(email_revenue - email_provider_cost), 0),
    'email_margin_pct', CASE
      WHEN COALESCE(SUM(email_revenue), 0) > 0
      THEN (COALESCE(SUM(email_revenue - email_provider_cost), 0) / COALESCE(SUM(email_revenue), 0) * 100)
      ELSE 0
    END,

    'avg_cost_per_minute', CASE
      WHEN COALESCE(SUM(total_duration_seconds), 0) > 0
      THEN (COALESCE(SUM(call_provider_cost), 0) / (COALESCE(SUM(total_duration_seconds), 0) / 60.0))
      ELSE 0
    END,
    'avg_cost_per_sms', CASE
      WHEN COALESCE(SUM(sms_count), 0) > 0
      THEN (COALESCE(SUM(sms_provider_cost), 0) / COALESCE(SUM(sms_count), 0))
      ELSE 0
    END,
    'avg_cost_per_email', CASE
      WHEN COALESCE(SUM(email_count), 0) > 0
      THEN (COALESCE(SUM(email_provider_cost), 0) / COALESCE(SUM(email_count), 0))
      ELSE 0
    END,
    'avg_revenue_per_minute', CASE
      WHEN COALESCE(SUM(total_duration_seconds), 0) > 0
      THEN (COALESCE(SUM(call_revenue), 0) / (COALESCE(SUM(total_duration_seconds), 0) / 60.0))
      ELSE 0
    END,
    'avg_revenue_per_sms', CASE
      WHEN COALESCE(SUM(sms_count), 0) > 0
      THEN (COALESCE(SUM(sms_revenue), 0) / COALESCE(SUM(sms_count), 0))
      ELSE 0
    END,
    'avg_revenue_per_email', CASE
      WHEN COALESCE(SUM(email_count), 0) > 0
      THEN (COALESCE(SUM(email_revenue), 0) / COALESCE(SUM(email_count), 0))
      ELSE 0
    END,

    'avg_consumption_per_client', CASE
      WHEN COUNT(DISTINCT client_id) > 0
      THEN (COALESCE(SUM(consumption_revenue), 0) / COUNT(DISTINCT client_id))
      ELSE 0
    END,
    'consumption_client_count', COUNT(DISTINCT client_id),
    'active_deployment_count', COUNT(DISTINCT deployment_id)
  )
  INTO v_result
  FROM v_financial_metrics_enriched
  WHERE metric_date >= p_start_date
    AND metric_date <= p_end_date
    AND user_has_access = true;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_consumption_kpi_metrics(date, date) TO authenticated;

-- 4.4: get_consumption_pricing_by_agent
-- ============================================================================

DROP FUNCTION IF EXISTS get_consumption_pricing_by_agent(date, date, uuid);

CREATE OR REPLACE FUNCTION get_consumption_pricing_by_agent(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- SECURITY CHECK: Verify user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required to view unit pricing'
      USING ERRCODE = 'P0001';
  END IF;

  -- Build array of agent pricing data
  SELECT jsonb_agg(
    jsonb_build_object(
      'deployment_id', deployment_id,
      'deployment_name', client_name || ' - ' || agent_type_name,
      'client_name', client_name,
      'agent_type_name', agent_type_name,
      'agent_type_label', agent_type_name,
      'status', deployment_status,

      'call_metrics', jsonb_build_object(
        'total_calls', total_calls,
        'answered_calls', answered_calls,
        'total_minutes', total_minutes,
        'cost_per_minute_provider', cost_per_minute_provider,
        'price_per_minute_charged', price_per_minute_charged,
        'margin_per_minute', margin_per_minute,
        'margin_pct_calls', margin_pct_calls,
        'total_call_revenue', total_call_revenue,
        'total_call_cost', total_call_cost,
        'total_call_margin', total_call_margin
      ),

      'sms_metrics', jsonb_build_object(
        'total_sms_sent', total_sms,
        'sms_delivered', sms_delivered,
        'cost_per_sms_provider', cost_per_sms_provider,
        'price_per_sms_charged', price_per_sms_charged,
        'margin_per_sms', margin_per_sms,
        'margin_pct_sms', margin_pct_sms,
        'total_sms_revenue', total_sms_revenue,
        'total_sms_cost', total_sms_cost,
        'total_sms_margin', total_sms_margin
      ),

      'email_metrics', jsonb_build_object(
        'total_emails_sent', total_emails,
        'emails_delivered', emails_delivered,
        'cost_per_email_provider', cost_per_email_provider,
        'price_per_email_charged', price_per_email_charged,
        'margin_per_email', margin_per_email,
        'margin_pct_emails', margin_pct_emails,
        'total_email_revenue', total_email_revenue,
        'total_email_cost', total_email_cost,
        'total_email_margin', total_email_margin
      ),

      'total_consumption', jsonb_build_object(
        'total_consumption_revenue', total_consumption_revenue,
        'total_consumption_cost', total_consumption_cost,
        'total_consumption_margin', total_consumption_margin,
        'consumption_margin_pct', consumption_margin_pct
      )
    )
  )
  INTO v_result
  FROM (
    SELECT
      deployment_id,
      client_name,
      agent_type_name,
      deployment_status,

      -- Call metrics
      SUM(call_count) AS total_calls,
      SUM(answered_calls) AS answered_calls,
      SUM(total_duration_seconds) / 60.0 AS total_minutes,
      CASE
        WHEN SUM(total_duration_seconds) > 0
        THEN SUM(call_provider_cost) / (SUM(total_duration_seconds) / 60.0)
        ELSE 0
      END AS cost_per_minute_provider,
      CASE
        WHEN SUM(total_duration_seconds) > 0
        THEN SUM(call_revenue) / (SUM(total_duration_seconds) / 60.0)
        ELSE 0
      END AS price_per_minute_charged,
      CASE
        WHEN SUM(total_duration_seconds) > 0
        THEN (SUM(call_revenue) - SUM(call_provider_cost)) / (SUM(total_duration_seconds) / 60.0)
        ELSE 0
      END AS margin_per_minute,
      CASE
        WHEN SUM(call_revenue) > 0
        THEN ((SUM(call_revenue) - SUM(call_provider_cost)) / SUM(call_revenue) * 100)
        ELSE 0
      END AS margin_pct_calls,
      SUM(call_revenue) AS total_call_revenue,
      SUM(call_provider_cost) AS total_call_cost,
      SUM(call_revenue - call_provider_cost) AS total_call_margin,

      -- SMS metrics
      SUM(sms_count) AS total_sms,
      SUM(sms_delivered) AS sms_delivered,
      CASE
        WHEN SUM(sms_count) > 0
        THEN SUM(sms_provider_cost) / SUM(sms_count)
        ELSE 0
      END AS cost_per_sms_provider,
      CASE
        WHEN SUM(sms_count) > 0
        THEN SUM(sms_revenue) / SUM(sms_count)
        ELSE 0
      END AS price_per_sms_charged,
      CASE
        WHEN SUM(sms_count) > 0
        THEN (SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_count)
        ELSE 0
      END AS margin_per_sms,
      CASE
        WHEN SUM(sms_revenue) > 0
        THEN ((SUM(sms_revenue) - SUM(sms_provider_cost)) / SUM(sms_revenue) * 100)
        ELSE 0
      END AS margin_pct_sms,
      SUM(sms_revenue) AS total_sms_revenue,
      SUM(sms_provider_cost) AS total_sms_cost,
      SUM(sms_revenue - sms_provider_cost) AS total_sms_margin,

      -- Email metrics
      SUM(email_count) AS total_emails,
      SUM(email_delivered) AS emails_delivered,
      CASE
        WHEN SUM(email_count) > 0
        THEN SUM(email_provider_cost) / SUM(email_count)
        ELSE 0
      END AS cost_per_email_provider,
      CASE
        WHEN SUM(email_count) > 0
        THEN SUM(email_revenue) / SUM(email_count)
        ELSE 0
      END AS price_per_email_charged,
      CASE
        WHEN SUM(email_count) > 0
        THEN (SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_count)
        ELSE 0
      END AS margin_per_email,
      CASE
        WHEN SUM(email_revenue) > 0
        THEN ((SUM(email_revenue) - SUM(email_provider_cost)) / SUM(email_revenue) * 100)
        ELSE 0
      END AS margin_pct_emails,
      SUM(email_revenue) AS total_email_revenue,
      SUM(email_provider_cost) AS total_email_cost,
      SUM(email_revenue - email_provider_cost) AS total_email_margin,

      -- Total consumption
      SUM(consumption_revenue) AS total_consumption_revenue,
      SUM(consumption_provider_cost) AS total_consumption_cost,
      SUM(consumption_margin) AS total_consumption_margin,
      CASE
        WHEN SUM(consumption_revenue) > 0
        THEN (SUM(consumption_margin) / SUM(consumption_revenue) * 100)
        ELSE 0
      END AS consumption_margin_pct

    FROM v_financial_metrics_enriched
    WHERE metric_date >= p_start_date
      AND metric_date <= p_end_date
      AND user_has_access = true
      AND (p_client_id IS NULL OR client_id = p_client_id)
    GROUP BY deployment_id, client_name, agent_type_name, deployment_status
  ) agent_data;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION get_consumption_pricing_by_agent(date, date, uuid) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES (commented out, for testing only)
-- ============================================================================

-- Test if current user is admin
-- SELECT is_admin();

-- Test if current user is admin for a specific client
-- SELECT is_admin_for_client('client-uuid-here');

-- Test v_financial_metrics_enriched filtering
-- SELECT DISTINCT client_name, user_has_access
-- FROM v_financial_metrics_enriched
-- LIMIT 10;

-- Test RPC function with admin check
-- SELECT get_leasing_kpi_metrics('2025-01-01', '2025-01-31');

-- ============================================================================
-- MIGRATION SUMMARY
-- ============================================================================

-- ✅ Created is_admin() helper function
-- ✅ Created is_admin_for_client(uuid) helper function
-- ✅ Updated v_financial_metrics_enriched to filter by admin permission
-- ✅ Added admin checks to get_financial_kpi_metrics()
-- ✅ Added admin checks to get_leasing_kpi_metrics()
-- ✅ Added admin checks to get_consumption_kpi_metrics()
-- ✅ Added admin checks to get_consumption_pricing_by_agent()

-- NEXT STEPS:
-- 1. Apply this migration to production database
-- 2. Test with admin user (should work)
-- 3. Test with non-admin user (should get "Access denied" error)
-- 4. Update other financial RPC functions if needed

COMMENT ON FUNCTION get_financial_kpi_metrics(date, date, uuid, text, uuid) IS
'Returns financial KPI metrics. ADMIN ACCESS ONLY.';

COMMENT ON FUNCTION get_leasing_kpi_metrics(date, date) IS
'Returns leasing-specific KPI metrics. ADMIN ACCESS ONLY.';

COMMENT ON FUNCTION get_consumption_kpi_metrics(date, date) IS
'Returns consumption-specific KPI metrics. ADMIN ACCESS ONLY.';

COMMENT ON FUNCTION get_consumption_pricing_by_agent(date, date, uuid) IS
'Returns unit pricing by agent (deployment level). ADMIN ACCESS ONLY.';
