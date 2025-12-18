-- Migration: Admin Calls Paginated RPC Functions
-- Date: 2024-12-18
-- Purpose: Server-side pagination and export for admin calls table
-- Changes: Creates get_admin_calls_paginated and get_admin_calls_export functions

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_admin_calls_paginated(DATE, DATE, UUID[], TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_admin_calls_export(DATE, DATE, UUID[], TEXT, TEXT[], TEXT, TEXT, TEXT);

-- ============================================================================
-- Function: get_admin_calls_paginated
-- Purpose: Fetches paginated call data with filters for admin table
-- ============================================================================
CREATE OR REPLACE FUNCTION get_admin_calls_paginated(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_outcomes TEXT[] DEFAULT NULL,
  p_emotion TEXT DEFAULT NULL,
  p_direction TEXT DEFAULT NULL,
  p_search_text TEXT DEFAULT NULL,
  p_sort_column TEXT DEFAULT 'started_at',
  p_sort_direction TEXT DEFAULT 'desc',
  p_page INTEGER DEFAULT 1,
  p_page_size INTEGER DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_offset INTEGER;
  v_total_count INTEGER;
  v_data JSONB;
  v_search_pattern TEXT;
BEGIN
  -- Calculate offset
  v_offset := (p_page - 1) * p_page_size;

  -- Prepare search pattern
  v_search_pattern := CASE WHEN p_search_text IS NOT NULL AND p_search_text != ''
    THEN '%' || LOWER(p_search_text) || '%'
    ELSE NULL
  END;

  -- Get total count first (for pagination metadata)
  SELECT COUNT(*)
  INTO v_total_count
  FROM agent_calls ac
  JOIN agent_deployments ad ON ac.deployment_id = ad.id
  JOIN clients c ON ad.client_id = c.id
  JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE ac.started_at::date BETWEEN p_start_date AND p_end_date
    AND (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
    AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
    AND (p_outcomes IS NULL OR ac.outcome = ANY(p_outcomes))
    AND (p_emotion IS NULL OR ac.emotion = p_emotion)
    AND (p_direction IS NULL OR ac.direction = p_direction)
    AND (v_search_pattern IS NULL OR (
      LOWER(COALESCE(ac.first_name, '')) LIKE v_search_pattern OR
      LOWER(COALESCE(ac.last_name, '')) LIKE v_search_pattern OR
      LOWER(COALESCE(ac.phone_number, '')) LIKE v_search_pattern OR
      LOWER(COALESCE(ac.email, '')) LIKE v_search_pattern
    ));

  -- Get paginated data
  WITH filtered_calls AS (
    SELECT
      ac.id,
      ac.deployment_id,
      ac.started_at,
      ac.ended_at,
      ac.created_at,
      ac.first_name,
      ac.last_name,
      ac.email,
      ac.phone_number,
      c.id as client_id,
      c.name as client_name,
      at.name as agent_type_name,
      ad.name as deployment_name,
      ac.outcome,
      ac.emotion,
      -- Compute answered: not in failed outcomes
      CASE
        WHEN ac.outcome IS NULL THEN false
        WHEN ac.outcome IN ('voicemail', 'call_failed', 'too_short') THEN false
        ELSE true
      END as answered,
      -- Compute appointment_scheduled
      COALESCE(ac.outcome = 'appointment_scheduled', false) as appointment_scheduled,
      ac.call_quality_score,
      ac.sentiment_analysis,
      ac.duration_seconds,
      -- Latencies LLM
      ac.avg_llm_latency_ms,
      ac.min_llm_latency_ms,
      ac.max_llm_latency_ms,
      -- Latencies TTS
      ac.avg_tts_latency_ms,
      ac.min_tts_latency_ms,
      ac.max_tts_latency_ms,
      -- Latencies Total
      ac.avg_total_latency_ms,
      ac.min_total_latency_ms,
      ac.max_total_latency_ms,
      -- Costs
      ac.total_cost,
      ac.stt_cost,
      ac.tts_cost,
      ac.llm_cost,
      ac.telecom_cost,
      ac.dipler_commission,
      -- Technical
      ac.conversation_id,
      ac.call_sid,
      ac.llm_model,
      ac.tts_provider,
      ac.stt_provider,
      ac.direction,
      -- Media
      ac.recording_url,
      ac.transcript,
      ac.transcript_summary,
      ac.metadata
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN clients c ON ad.client_id = c.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_outcomes IS NULL OR ac.outcome = ANY(p_outcomes))
      AND (p_emotion IS NULL OR ac.emotion = p_emotion)
      AND (p_direction IS NULL OR ac.direction = p_direction)
      AND (v_search_pattern IS NULL OR (
        LOWER(COALESCE(ac.first_name, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.last_name, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.phone_number, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.email, '')) LIKE v_search_pattern
      ))
    ORDER BY
      CASE WHEN p_sort_direction = 'asc' THEN
        CASE p_sort_column
          WHEN 'started_at' THEN ac.started_at::text
          WHEN 'client_name' THEN c.name
          WHEN 'deployment_name' THEN ad.name
          WHEN 'duration_seconds' THEN LPAD(COALESCE(ac.duration_seconds, 0)::text, 10, '0')
          WHEN 'total_cost' THEN LPAD(COALESCE(ac.total_cost::numeric * 1000000, 0)::bigint::text, 15, '0')
          WHEN 'outcome' THEN COALESCE(ac.outcome, 'zzz')
          WHEN 'emotion' THEN COALESCE(ac.emotion, 'zzz')
          ELSE ac.started_at::text
        END
      END ASC NULLS LAST,
      CASE WHEN p_sort_direction = 'desc' THEN
        CASE p_sort_column
          WHEN 'started_at' THEN ac.started_at::text
          WHEN 'client_name' THEN c.name
          WHEN 'deployment_name' THEN ad.name
          WHEN 'duration_seconds' THEN LPAD(COALESCE(ac.duration_seconds, 0)::text, 10, '0')
          WHEN 'total_cost' THEN LPAD(COALESCE(ac.total_cost::numeric * 1000000, 0)::bigint::text, 15, '0')
          WHEN 'outcome' THEN COALESCE(ac.outcome, 'zzz')
          WHEN 'emotion' THEN COALESCE(ac.emotion, 'zzz')
          ELSE ac.started_at::text
        END
      END DESC NULLS LAST
    LIMIT p_page_size
    OFFSET v_offset
  )
  SELECT COALESCE(jsonb_agg(to_jsonb(fc)), '[]'::jsonb)
  INTO v_data
  FROM filtered_calls fc;

  -- Return result with pagination metadata
  RETURN jsonb_build_object(
    'data', v_data,
    'pagination', jsonb_build_object(
      'page', p_page,
      'pageSize', p_page_size,
      'totalCount', v_total_count,
      'totalPages', CEIL(v_total_count::float / p_page_size)::integer
    )
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_calls_paginated(DATE, DATE, UUID[], TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER) TO authenticated;


-- ============================================================================
-- Function: get_admin_calls_export
-- Purpose: Fetches all filtered calls for CSV export (no pagination, limit 10k)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_admin_calls_export(
  p_start_date DATE,
  p_end_date DATE,
  p_client_ids UUID[] DEFAULT NULL,
  p_agent_type_name TEXT DEFAULT NULL,
  p_outcomes TEXT[] DEFAULT NULL,
  p_emotion TEXT DEFAULT NULL,
  p_direction TEXT DEFAULT NULL,
  p_search_text TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_data JSONB;
  v_search_pattern TEXT;
  v_total_count INTEGER;
BEGIN
  -- Prepare search pattern
  v_search_pattern := CASE WHEN p_search_text IS NOT NULL AND p_search_text != ''
    THEN '%' || LOWER(p_search_text) || '%'
    ELSE NULL
  END;

  -- Get data (limit to 10,000 rows for safety)
  WITH filtered_calls AS (
    SELECT
      ac.id,
      ac.started_at,
      ac.ended_at,
      ac.first_name,
      ac.last_name,
      ac.email,
      ac.phone_number,
      c.name as client_name,
      at.name as agent_type_name,
      ad.name as deployment_name,
      ac.outcome,
      ac.emotion,
      CASE
        WHEN ac.outcome IS NULL THEN false
        WHEN ac.outcome IN ('voicemail', 'call_failed', 'too_short') THEN false
        ELSE true
      END as answered,
      COALESCE(ac.outcome = 'appointment_scheduled', false) as appointment_scheduled,
      ac.call_quality_score,
      ac.duration_seconds,
      -- Latencies
      ac.avg_llm_latency_ms,
      ac.avg_tts_latency_ms,
      ac.avg_total_latency_ms,
      -- Costs
      ac.total_cost,
      ac.stt_cost,
      ac.tts_cost,
      ac.llm_cost,
      ac.telecom_cost,
      ac.dipler_commission,
      -- Technical
      ac.conversation_id,
      ac.call_sid,
      ac.llm_model,
      ac.tts_provider,
      ac.direction,
      -- Media
      ac.recording_url,
      ac.transcript_summary
    FROM agent_calls ac
    JOIN agent_deployments ad ON ac.deployment_id = ad.id
    JOIN clients c ON ad.client_id = c.id
    JOIN agent_types at ON ad.agent_type_id = at.id
    WHERE ac.started_at::date BETWEEN p_start_date AND p_end_date
      AND (p_client_ids IS NULL OR c.id = ANY(p_client_ids))
      AND (p_agent_type_name IS NULL OR at.name = p_agent_type_name)
      AND (p_outcomes IS NULL OR ac.outcome = ANY(p_outcomes))
      AND (p_emotion IS NULL OR ac.emotion = p_emotion)
      AND (p_direction IS NULL OR ac.direction = p_direction)
      AND (v_search_pattern IS NULL OR (
        LOWER(COALESCE(ac.first_name, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.last_name, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.phone_number, '')) LIKE v_search_pattern OR
        LOWER(COALESCE(ac.email, '')) LIKE v_search_pattern
      ))
    ORDER BY ac.started_at DESC
    LIMIT 10000
  )
  SELECT COALESCE(jsonb_agg(to_jsonb(fc)), '[]'::jsonb), COUNT(*)
  INTO v_data, v_total_count
  FROM filtered_calls fc;

  RETURN jsonb_build_object(
    'data', v_data,
    'exportedCount', v_total_count,
    'limitReached', v_total_count >= 10000
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_calls_export(DATE, DATE, UUID[], TEXT, TEXT[], TEXT, TEXT, TEXT) TO authenticated;


-- ============================================================================
-- Verification queries (commented out)
-- ============================================================================
-- SELECT get_admin_calls_paginated('2024-01-01', '2024-12-31', NULL, NULL, NULL, NULL, NULL, NULL, 'started_at', 'desc', 1, 10);
-- SELECT get_admin_calls_export('2024-01-01', '2024-12-31', NULL, NULL, NULL, NULL, NULL, NULL);
