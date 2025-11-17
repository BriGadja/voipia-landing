-- ============================================================================
-- Migration: Add detailed cost breakdown to v_financial_metrics_enriched
-- Date: 2025-01-17
-- Author: Claude
-- Purpose: Add STT, TTS, LLM, Telecom, and Dipler Commission costs
-- ============================================================================
--
-- Changes:
-- 1. Drop and recreate v_financial_metrics_enriched with detailed cost columns
-- 2. Update call_metrics CTE to use agent_calls directly (not v_agent_calls_enriched)
-- 3. Add new columns: stt_cost, tts_cost, llm_cost, telecom_cost, dipler_commission
--
-- ============================================================================

-- Drop the existing view
DROP VIEW IF EXISTS v_financial_metrics_enriched CASCADE;

-- Recreate the view with detailed costs
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
    (EXISTS (
      SELECT 1
      FROM user_client_permissions ucp
      WHERE ucp.client_id = d.client_id
        AND ucp.user_id = auth.uid()
    )) AS user_has_access
  FROM agent_deployments d
  JOIN agent_types at ON d.agent_type_id = at.id
  JOIN clients c ON d.client_id = c.id
),
call_metrics AS (
  SELECT
    ac.deployment_id,
    DATE_TRUNC('day', ac.created_at) AS metric_date,

    -- Volume metrics
    COUNT(*) AS call_count,
    COUNT(*) FILTER (WHERE
      ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'failed')
    ) AS answered_calls,
    COUNT(*) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,

    -- Duration metrics
    SUM(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS total_duration_seconds,
    AVG(ac.duration_seconds) FILTER (WHERE ac.duration_seconds > 0) AS avg_duration_seconds,

    -- Revenue (based on cost_per_min)
    SUM((ac.duration_seconds::numeric / 60.0) * db.cost_per_min) AS call_revenue,

    -- Provider costs (existing)
    SUM(COALESCE(ac.total_cost, 0)) AS call_provider_cost,

    -- DETAILED COSTS (NEW) - from agent_calls table directly
    SUM(COALESCE(ac.stt_cost, 0)) AS call_stt_cost,
    SUM(COALESCE(ac.tts_cost, 0)) AS call_tts_cost,
    SUM(COALESCE(ac.llm_cost, 0)) AS call_llm_cost,
    SUM(COALESCE(ac.telecom_cost, 0)) AS call_telecom_cost,
    SUM(COALESCE(ac.dipler_commission, 0)) AS call_dipler_commission

  FROM agent_calls ac
  JOIN deployment_base db ON ac.deployment_id = db.deployment_id
  WHERE ac.created_at IS NOT NULL
  GROUP BY ac.deployment_id, DATE_TRUNC('day', ac.created_at)
),
sms_metrics AS (
  SELECT
    asms.deployment_id,
    DATE_TRUNC('day', asms.sent_at) AS metric_date,
    COUNT(*) AS sms_count,
    COUNT(*) FILTER (WHERE asms.delivered_at IS NOT NULL) AS sms_delivered,
    SUM(COALESCE(asms.billed_cost, 0)) AS sms_revenue,
    SUM(COALESCE(asms.provider_cost, 0)) AS sms_provider_cost
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
    COUNT(*) FILTER (WHERE ae.sent_at IS NOT NULL AND ae.failed_at IS NULL) AS email_delivered,
    SUM(COALESCE(ae.billed_cost, 0)) AS email_revenue,
    SUM(COALESCE(ae.provider_cost, 0)) AS email_provider_cost
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

    -- NEW: Detailed call costs
    COALESCE(cm.call_stt_cost, 0) AS call_stt_cost,
    COALESCE(cm.call_tts_cost, 0) AS call_tts_cost,
    COALESCE(cm.call_llm_cost, 0) AS call_llm_cost,
    COALESCE(cm.call_telecom_cost, 0) AS call_telecom_cost,
    COALESCE(cm.call_dipler_commission, 0) AS call_dipler_commission,

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

    -- Leasing
    COALESCE(db.leasing / 30.0, 0) AS leasing_revenue_daily,

    -- Totals
    (COALESCE(cm.call_revenue, 0) + COALESCE(sm.sms_revenue, 0) +
     COALESCE(em.email_revenue, 0) + COALESCE(db.leasing / 30.0, 0)) AS total_revenue,

    (COALESCE(cm.call_provider_cost, 0) + COALESCE(sm.sms_provider_cost, 0) +
     COALESCE(em.email_provider_cost, 0)) AS total_provider_cost,

    (COALESCE(cm.call_revenue, 0) + COALESCE(sm.sms_revenue, 0) +
     COALESCE(em.email_revenue, 0) + COALESCE(db.leasing / 30.0, 0) -
     (COALESCE(cm.call_provider_cost, 0) + COALESCE(sm.sms_provider_cost, 0) +
      COALESCE(em.email_provider_cost, 0))) AS total_margin

  FROM all_metric_dates amd
  JOIN deployment_base db ON amd.deployment_id = db.deployment_id
  LEFT JOIN call_metrics cm ON amd.deployment_id = cm.deployment_id
    AND amd.metric_date = cm.metric_date
  LEFT JOIN sms_metrics sm ON amd.deployment_id = sm.deployment_id
    AND amd.metric_date = sm.metric_date
  LEFT JOIN email_metrics em ON amd.deployment_id = em.deployment_id
    AND amd.metric_date = em.metric_date
)
SELECT
  deployment_id,
  metric_date,
  client_id,
  client_name,
  agent_type_id,
  agent_type_name,
  deployment_status,
  user_has_access,
  call_count,
  answered_calls,
  appointments_scheduled,
  total_duration_seconds,
  avg_duration_seconds,
  call_revenue,
  call_provider_cost,

  -- NEW: Detailed cost columns
  call_stt_cost,
  call_tts_cost,
  call_llm_cost,
  call_telecom_cost,
  call_dipler_commission,

  sms_count,
  sms_delivered,
  sms_revenue,
  sms_provider_cost,
  email_count,
  email_delivered,
  email_revenue,
  email_provider_cost,
  leasing_revenue_daily,
  total_revenue,
  total_provider_cost,
  total_margin,
  CASE
    WHEN total_revenue > 0
    THEN (total_margin / total_revenue * 100)
    ELSE 0
  END AS margin_percentage
FROM combined_metrics;

-- Add comment to view
COMMENT ON VIEW v_financial_metrics_enriched IS
  'Financial metrics aggregated by deployment and date with detailed cost breakdown (STT, TTS, LLM, Telecom, Dipler Commission). RLS enforced via user_has_access column.';

-- ============================================================================
-- Verification Query
-- ============================================================================

-- Test that new columns exist and have data
-- SELECT
--   deployment_id,
--   metric_date,
--   call_count,
--   call_provider_cost,
--   call_stt_cost,
--   call_tts_cost,
--   call_llm_cost,
--   call_telecom_cost,
--   call_dipler_commission
-- FROM v_financial_metrics_enriched
-- WHERE metric_date >= CURRENT_DATE - 30
--   AND call_count > 0
-- ORDER BY metric_date DESC
-- LIMIT 10;
