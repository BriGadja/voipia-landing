-- Migration: Create v_financial_metrics_enriched view
-- Date: 2025-01-17
-- Author: Claude
-- Priority: CRITICAL - Required by Dashboard Financier
--
-- Description:
-- This view aggregates financial metrics by deployment and date:
-- - Call revenue/costs (from agent_calls)
-- - SMS revenue/costs (from agent_sms)
-- - Email revenue/costs (from agent_emails)
-- - Leasing revenue (from agent_deployments)
-- - Total revenue, costs, margins
-- - RLS integrated via user_has_access column
--
-- Dependencies:
-- - v_agent_calls_enriched (must exist)
-- - agent_deployments, agent_types, clients
-- - agent_sms, agent_emails
--
-- Used by:
-- - get_financial_timeseries()
-- - get_client_deployments_breakdown()
-- - get_deployment_channels_breakdown()
-- - get_cost_breakdown()

-- Drop existing view if it exists
DROP VIEW IF EXISTS v_financial_metrics_enriched CASCADE;

-- Create the financial metrics view
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
        EXISTS (
            SELECT 1
            FROM user_client_permissions ucp
            WHERE ucp.client_id = d.client_id
            AND ucp.user_id = auth.uid()
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
        -- Revenue: duration in minutes * cost_per_min
        SUM(ac.duration_seconds::NUMERIC / 60.0 * db.cost_per_min) AS call_revenue,
        -- Provider cost: total_cost from agent_calls
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
        COUNT(*) FILTER (WHERE asms.delivered_at IS NOT NULL) AS sms_delivered,
        -- Revenue: billed_cost from agent_sms
        SUM(COALESCE(asms.billed_cost, 0)) AS sms_revenue,
        -- Provider cost: provider_cost from agent_sms
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
        -- Revenue: billed_cost from agent_emails
        SUM(COALESCE(ae.billed_cost, 0)) AS email_revenue,
        -- Provider cost: provider_cost from agent_emails
        SUM(COALESCE(ae.provider_cost, 0)) AS email_provider_cost
    FROM agent_emails ae
    JOIN deployment_base db ON ae.deployment_id = db.deployment_id
    WHERE ae.sent_at IS NOT NULL
    GROUP BY ae.deployment_id, DATE_TRUNC('day', ae.sent_at)
),
all_metric_dates AS (
    -- Get all unique (deployment_id, metric_date) combinations
    SELECT DISTINCT deployment_id, metric_date
    FROM (
        SELECT deployment_id, metric_date FROM call_metrics
        UNION
        SELECT deployment_id, metric_date FROM sms_metrics
        UNION
        SELECT deployment_id, metric_date FROM email_metrics
    ) AS combined_dates
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

        -- Leasing revenue (prorated daily)
        COALESCE(db.leasing / 30.0, 0) AS leasing_revenue_daily,

        -- Total revenue (calls + sms + emails + leasing)
        COALESCE(cm.call_revenue, 0) +
        COALESCE(sm.sms_revenue, 0) +
        COALESCE(em.email_revenue, 0) +
        COALESCE(db.leasing / 30.0, 0) AS total_revenue,

        -- Total provider cost (calls + sms + emails)
        COALESCE(cm.call_provider_cost, 0) +
        COALESCE(sm.sms_provider_cost, 0) +
        COALESCE(em.email_provider_cost, 0) AS total_provider_cost,

        -- Total margin (revenue - cost)
        (COALESCE(cm.call_revenue, 0) +
         COALESCE(sm.sms_revenue, 0) +
         COALESCE(em.email_revenue, 0) +
         COALESCE(db.leasing / 30.0, 0)) -
        (COALESCE(cm.call_provider_cost, 0) +
         COALESCE(sm.sms_provider_cost, 0) +
         COALESCE(em.email_provider_cost, 0)) AS total_margin

    FROM all_metric_dates amd
    JOIN deployment_base db ON amd.deployment_id = db.deployment_id
    LEFT JOIN call_metrics cm ON amd.deployment_id = cm.deployment_id AND amd.metric_date = cm.metric_date
    LEFT JOIN sms_metrics sm ON amd.deployment_id = sm.deployment_id AND amd.metric_date = sm.metric_date
    LEFT JOIN email_metrics em ON amd.deployment_id = em.deployment_id AND amd.metric_date = em.metric_date
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
    -- Margin percentage
    CASE
        WHEN total_revenue > 0 THEN (total_margin / total_revenue * 100)
        ELSE 0
    END AS margin_percentage
FROM combined_metrics;

-- Grant permissions
GRANT SELECT ON v_financial_metrics_enriched TO authenticated;

-- Add comment
COMMENT ON VIEW v_financial_metrics_enriched IS
'Aggregated financial metrics by deployment and date. Includes call/sms/email revenue/costs, leasing, margins. RLS enforced via user_has_access column.';

-- Verification queries
-- SELECT COUNT(*) FROM v_financial_metrics_enriched;
-- SELECT * FROM v_financial_metrics_enriched WHERE user_has_access = true LIMIT 10;
-- SELECT DISTINCT agent_type_name FROM v_financial_metrics_enriched;
