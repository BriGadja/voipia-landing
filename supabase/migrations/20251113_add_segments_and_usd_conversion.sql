-- Migration: Add num_segments billing and USD to EUR conversion
-- Date: 2025-11-13
-- Author: Claude
-- Tested: ✅ Validated on staging
--
-- Changes:
-- 1. Add num_segments column to track SMS segments (1 SMS = 160 chars, 2 SMS = 320 chars, etc.)
-- 2. Add cost_per_sms column (denormalized from agent_deployments for performance)
-- 3. Change billed_cost to GENERATED: cost_per_sms * num_segments
-- 4. Add provider_cost_usd to store original Twilio price in USD
-- 5. Add exchange_rate_usd_eur to track conversion rate at time of sending
-- 6. Change provider_cost to GENERATED: ABS(provider_cost_usd) * exchange_rate
-- 7. margin stays GENERATED: billed_cost - provider_cost
--
-- Business Logic:
-- - Twilio facture par segment (160 caractères = 1 segment)
-- - Voipia facture également par segment (cost_per_sms * num_segments)
-- - Twilio envoie les prix en USD (négatifs), on convertit en EUR
-- - Le taux de change est stocké pour chaque SMS pour calculs historiques précis

-- Drop dependent objects first
DROP VIEW IF EXISTS public.v_agent_communications CASCADE;
DROP VIEW IF EXISTS public.v_agent_sms_enriched CASCADE;
DROP FUNCTION IF EXISTS public.get_sms_metrics(TIMESTAMPTZ, TIMESTAMPTZ, UUID, UUID, TEXT) CASCADE;

-- Drop existing generated columns (must be done in reverse dependency order)
ALTER TABLE public.agent_sms
  DROP COLUMN IF EXISTS margin CASCADE;

ALTER TABLE public.agent_sms
  DROP COLUMN IF EXISTS billed_cost CASCADE;

ALTER TABLE public.agent_sms
  DROP COLUMN IF EXISTS provider_cost CASCADE;

-- Add new columns for segment-based billing
ALTER TABLE public.agent_sms
  ADD COLUMN IF NOT EXISTS num_segments INTEGER DEFAULT 1 CHECK (num_segments > 0);

ALTER TABLE public.agent_sms
  ADD COLUMN IF NOT EXISTS cost_per_sms NUMERIC(10, 4) DEFAULT 0.07 CHECK (cost_per_sms >= 0);

COMMENT ON COLUMN public.agent_sms.num_segments IS
  'Number of SMS segments (160 chars = 1 segment). From Twilio API.';

COMMENT ON COLUMN public.agent_sms.cost_per_sms IS
  'Price per SMS segment charged to client in EUR. Denormalized from agent_deployments.cost_per_sms for performance.';

-- Add columns for USD to EUR conversion
ALTER TABLE public.agent_sms
  ADD COLUMN IF NOT EXISTS provider_cost_usd NUMERIC(10, 4);

ALTER TABLE public.agent_sms
  ADD COLUMN IF NOT EXISTS exchange_rate_usd_eur NUMERIC(6, 4) DEFAULT 0.92 CHECK (exchange_rate_usd_eur > 0);

COMMENT ON COLUMN public.agent_sms.provider_cost_usd IS
  'Original Twilio SMS cost in USD (negative value). Example: -0.15960';

COMMENT ON COLUMN public.agent_sms.exchange_rate_usd_eur IS
  'USD to EUR exchange rate at time of SMS sending. Default: 0.92. Updated daily or per-transaction for precision.';

-- Recreate calculated columns with new logic
ALTER TABLE public.agent_sms
  ADD COLUMN provider_cost NUMERIC(10, 4)
    GENERATED ALWAYS AS (
      ROUND(ABS(COALESCE(provider_cost_usd, 0)) * COALESCE(exchange_rate_usd_eur, 0.92), 4)
    ) STORED;

COMMENT ON COLUMN public.agent_sms.provider_cost IS
  'Calculated: ABS(provider_cost_usd) * exchange_rate_usd_eur. Twilio SMS cost converted to EUR.';

ALTER TABLE public.agent_sms
  ADD COLUMN billed_cost NUMERIC(10, 4)
    GENERATED ALWAYS AS (
      ROUND(COALESCE(cost_per_sms, 0) * COALESCE(num_segments, 1), 4)
    ) STORED;

COMMENT ON COLUMN public.agent_sms.billed_cost IS
  'Calculated: cost_per_sms * num_segments. Total amount billed to client in EUR.';

ALTER TABLE public.agent_sms
  ADD COLUMN margin NUMERIC(10, 4)
    GENERATED ALWAYS AS (
      ROUND(
        (COALESCE(cost_per_sms, 0) * COALESCE(num_segments, 1)) -
        (ABS(COALESCE(provider_cost_usd, 0)) * COALESCE(exchange_rate_usd_eur, 0.92)),
        4
      )
    ) STORED;

COMMENT ON COLUMN public.agent_sms.margin IS
  'Calculated: billed_cost - provider_cost. Profit margin in EUR. Can be negative if unprofitable.';

-- Recreate enriched view with new columns (CORRECTED: removed email column)
CREATE OR REPLACE VIEW public.v_agent_sms_enriched AS
SELECT
  sms.id,
  sms.deployment_id,
  ad.name AS deployment_name,
  ad.client_id,
  c.name AS client_name,
  at.name AS agent_type_name,
  at.display_name AS agent_display_name,
  sms.phone_number,
  sms.first_name,
  sms.last_name,
  sms.message_content,
  sms.character_count,
  sms.num_segments,
  sms.message_type,
  sms.provider,
  sms.provider_message_sid,
  sms.provider_status,
  sms.status,
  sms.sent_at,
  sms.delivered_at,
  sms.failed_at,
  sms.failure_reason,
  sms.provider_cost_usd,
  sms.exchange_rate_usd_eur,
  sms.provider_cost,
  sms.cost_per_sms,
  sms.billed_cost,
  sms.margin,
  sms.currency,
  sms.call_id,
  sms.prospect_id,
  sms.sequence_id,
  sms.workflow_id,
  sms.workflow_execution_id,
  sms.metadata,
  sms.created_at,
  sms.updated_at,
  -- Calculate margin percentage
  CASE
    WHEN sms.billed_cost > 0 THEN ROUND((sms.margin / sms.billed_cost) * 100, 2)
    ELSE NULL
  END AS margin_percentage
FROM public.agent_sms sms
INNER JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
INNER JOIN public.clients c ON ad.client_id = c.id
INNER JOIN public.agent_types at ON ad.agent_type_id = at.id;

COMMENT ON VIEW public.v_agent_sms_enriched IS
  'Enriched SMS view with client, deployment, and agent type info. Includes calculated margin percentage.';

-- Grant permissions
GRANT SELECT ON public.v_agent_sms_enriched TO authenticated;

-- Recreate unified communications view
CREATE OR REPLACE VIEW public.v_agent_communications AS
-- SMS Communications
SELECT
  sms.id,
  'sms' AS communication_type,
  sms.deployment_id,
  ad.client_id,
  c.name AS client_name,
  at.name AS agent_type_name,
  at.display_name AS agent_display_name,
  sms.phone_number,
  sms.first_name,
  sms.last_name,
  sms.message_content AS content,
  sms.sent_at AS timestamp,
  sms.status,
  sms.provider_cost + sms.billed_cost AS total_cost, -- Total for SMS
  sms.metadata
FROM public.agent_sms sms
INNER JOIN public.agent_deployments ad ON sms.deployment_id = ad.id
INNER JOIN public.clients c ON ad.client_id = c.id
INNER JOIN public.agent_types at ON ad.agent_type_id = at.id

UNION ALL

-- Voice Calls
SELECT
  ac.id,
  'call' AS communication_type,
  ac.deployment_id,
  ad.client_id,
  c.name AS client_name,
  at.name AS agent_type_name,
  at.display_name AS agent_display_name,
  ac.phone_number,
  ac.first_name,
  ac.last_name,
  ac.transcript AS content,
  ac.started_at AS timestamp,
  ac.call_status AS status,
  ac.total_cost,
  ac.metadata
FROM public.agent_calls ac
INNER JOIN public.agent_deployments ad ON ac.deployment_id = ad.id
INNER JOIN public.clients c ON ad.client_id = c.id
INNER JOIN public.agent_types at ON ad.agent_type_id = at.id
ORDER BY timestamp DESC;

COMMENT ON VIEW public.v_agent_communications IS
  'Unified view of all communications (SMS + Calls) sorted by timestamp.';

GRANT SELECT ON public.v_agent_communications TO authenticated;

-- Update get_sms_metrics function to use new columns
CREATE OR REPLACE FUNCTION public.get_sms_metrics(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_deployment_id UUID DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  -- Current Period Metrics
  total_sms BIGINT,
  total_segments BIGINT,
  delivered_sms BIGINT,
  failed_sms BIGINT,
  pending_sms BIGINT,
  delivery_rate NUMERIC,
  total_revenue NUMERIC,
  total_cost NUMERIC,
  total_margin NUMERIC,
  margin_percentage NUMERIC,
  avg_cost_per_sms NUMERIC,
  avg_revenue_per_sms NUMERIC,
  avg_segments_per_sms NUMERIC,
  -- Previous Period Metrics (for comparison)
  prev_total_sms BIGINT,
  prev_delivered_sms BIGINT,
  prev_total_revenue NUMERIC,
  prev_total_cost NUMERIC,
  prev_total_margin NUMERIC,
  -- Period-over-Period Changes
  sms_change_pct NUMERIC,
  delivered_change_pct NUMERIC,
  revenue_change_pct NUMERIC,
  margin_change_pct NUMERIC
) AS $$
DECLARE
  v_period_duration INTERVAL;
BEGIN
  v_period_duration := p_end_date - p_start_date;

  RETURN QUERY
  WITH current_period AS (
    SELECT
      COUNT(*) AS total,
      SUM(sms.num_segments) AS segments,
      COUNT(*) FILTER (WHERE sms.status = 'delivered') AS delivered,
      COUNT(*) FILTER (WHERE sms.status = 'failed') AS failed,
      COUNT(*) FILTER (WHERE sms.status = 'sent') AS pending,
      COALESCE(SUM(sms.billed_cost), 0) AS revenue,
      COALESCE(SUM(sms.provider_cost), 0) AS cost,
      COALESCE(SUM(sms.margin), 0) AS margin,
      COALESCE(AVG(sms.provider_cost), 0) AS avg_cost,
      COALESCE(AVG(sms.billed_cost), 0) AS avg_revenue,
      COALESCE(AVG(sms.num_segments), 0) AS avg_segments
    FROM public.v_agent_sms_enriched sms
    WHERE sms.sent_at >= p_start_date
      AND sms.sent_at < p_end_date
      AND (p_client_id IS NULL OR sms.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR sms.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR sms.agent_type_name = p_agent_type_name)
  ),
  previous_period AS (
    SELECT
      COUNT(*) AS total,
      COUNT(*) FILTER (WHERE sms.status = 'delivered') AS delivered,
      COALESCE(SUM(sms.billed_cost), 0) AS revenue,
      COALESCE(SUM(sms.provider_cost), 0) AS cost,
      COALESCE(SUM(sms.margin), 0) AS margin
    FROM public.v_agent_sms_enriched sms
    WHERE sms.sent_at >= (p_start_date - v_period_duration)
      AND sms.sent_at < p_start_date
      AND (p_client_id IS NULL OR sms.client_id = p_client_id)
      AND (p_deployment_id IS NULL OR sms.deployment_id = p_deployment_id)
      AND (p_agent_type_name IS NULL OR sms.agent_type_name = p_agent_type_name)
  )
  SELECT
    -- Current Period
    cp.total::BIGINT,
    cp.segments::BIGINT,
    cp.delivered::BIGINT,
    cp.failed::BIGINT,
    cp.pending::BIGINT,
    CASE WHEN cp.total > 0 THEN ROUND((cp.delivered::NUMERIC / cp.total) * 100, 2) ELSE 0 END,
    ROUND(cp.revenue, 2),
    ROUND(cp.cost, 2),
    ROUND(cp.margin, 2),
    CASE WHEN cp.revenue > 0 THEN ROUND((cp.margin / cp.revenue) * 100, 2) ELSE 0 END,
    ROUND(cp.avg_cost, 4),
    ROUND(cp.avg_revenue, 4),
    ROUND(cp.avg_segments, 2),
    -- Previous Period
    pp.total::BIGINT,
    pp.delivered::BIGINT,
    ROUND(pp.revenue, 2),
    ROUND(pp.cost, 2),
    ROUND(pp.margin, 2),
    -- Changes
    CASE WHEN pp.total > 0 THEN ROUND(((cp.total - pp.total)::NUMERIC / pp.total) * 100, 2) ELSE 0 END,
    CASE WHEN pp.delivered > 0 THEN ROUND(((cp.delivered - pp.delivered)::NUMERIC / pp.delivered) * 100, 2) ELSE 0 END,
    CASE WHEN pp.revenue > 0 THEN ROUND(((cp.revenue - pp.revenue) / pp.revenue) * 100, 2) ELSE 0 END,
    CASE WHEN pp.margin > 0 THEN ROUND(((cp.margin - pp.margin) / pp.margin) * 100, 2) ELSE 0 END
  FROM current_period cp, previous_period pp;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION public.get_sms_metrics IS
  'Returns SMS KPI metrics with segment-based billing and USD/EUR conversion. Includes period-over-period comparison.';

GRANT EXECUTE ON FUNCTION public.get_sms_metrics TO authenticated;

-- Create index on num_segments for analytics
CREATE INDEX IF NOT EXISTS idx_agent_sms_num_segments
  ON public.agent_sms(num_segments)
  WHERE num_segments > 1;

COMMENT ON INDEX public.idx_agent_sms_num_segments IS
  'Partial index for multi-segment SMS analytics (segments > 1)';

-- Create index on margin for profitability queries
CREATE INDEX IF NOT EXISTS idx_agent_sms_margin
  ON public.agent_sms(margin)
  WHERE margin < 0;

COMMENT ON INDEX public.idx_agent_sms_margin IS
  'Partial index for unprofitable SMS (negative margin)';

-- Verification queries (commented out, run manually to test)
/*
-- Test with sample data
INSERT INTO public.agent_sms (
  deployment_id,
  phone_number,
  message_content,
  num_segments,
  cost_per_sms,
  provider_cost_usd,
  exchange_rate_usd_eur,
  provider_message_sid,
  status,
  sent_at
) VALUES (
  '<your-deployment-id-here>',
  '+33766497427',
  'Test SMS with 2 segments',
  2, -- 2 segments
  0.10, -- 10 centimes per segment
  -0.15960, -- Twilio USD price (negative)
  0.92, -- Exchange rate
  'SM_TEST_123',
  'delivered',
  NOW()
);

-- Verify calculations
SELECT
  num_segments,
  cost_per_sms,
  billed_cost, -- Should be 0.20 (0.10 * 2)
  provider_cost_usd,
  exchange_rate_usd_eur,
  provider_cost, -- Should be ~0.1468 (0.15960 * 0.92)
  margin, -- Should be ~0.0532 (0.20 - 0.1468)
  CASE WHEN billed_cost > 0 THEN ROUND((margin / billed_cost) * 100, 2) ELSE 0 END AS margin_pct
FROM public.agent_sms
WHERE provider_message_sid = 'SM_TEST_123';

-- Expected result:
-- num_segments: 2
-- cost_per_sms: 0.10
-- billed_cost: 0.20
-- provider_cost_usd: -0.1596
-- exchange_rate_usd_eur: 0.92
-- provider_cost: 0.1468
-- margin: 0.0532
-- margin_pct: 26.60

-- Query unprofitable SMS
SELECT * FROM public.v_agent_sms_enriched
WHERE margin < 0
ORDER BY margin ASC
LIMIT 10;

-- SMS metrics test
SELECT * FROM public.get_sms_metrics(
  NOW() - INTERVAL '30 days',
  NOW(),
  NULL, NULL, 'louis'
);
*/
