-- Migration: Backfill TTS Provider and Voice ID from metadata
-- Date: 2025-01-20
-- Author: Claude
-- Risk: LOW (only UPDATE, no schema changes)
--
-- Context:
-- The columns `tts_provider` and `tts_voice_id` are currently 88% NULL (only 12% filled).
-- This data exists in metadata->'stack'->'tts' JSONB but hasn't been extracted to dedicated columns.
--
-- Changes:
-- 1. Extract tts_provider from metadata->'stack'->'tts'->0->>'ttsProvider'
-- 2. Extract tts_voice_id from metadata->'stack'->'tts'->0->>'voiceId'
-- 3. Only update rows where these columns are currently NULL
-- 4. Only update rows that actually have the data in metadata
--
-- Expected Impact:
-- - Fill rate: 12% → ~30%+ (for calls that have metadata.stack.tts)
-- - No impact on dashboard queries (columns already exist)
-- - Better analytics on TTS provider performance

BEGIN;

-- Get baseline stats BEFORE update
DO $$
DECLARE
  total_count INTEGER;
  null_provider_count INTEGER;
  null_voice_count INTEGER;
  has_metadata_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM agent_calls;

  SELECT COUNT(*) INTO null_provider_count
  FROM agent_calls
  WHERE tts_provider IS NULL;

  SELECT COUNT(*) INTO null_voice_count
  FROM agent_calls
  WHERE tts_voice_id IS NULL;

  SELECT COUNT(*) INTO has_metadata_count
  FROM agent_calls
  WHERE metadata->'stack'->'tts' IS NOT NULL;

  RAISE NOTICE '';
  RAISE NOTICE '=== BEFORE BACKFILL ===';
  RAISE NOTICE 'Total calls: %', total_count;
  RAISE NOTICE 'Calls with NULL tts_provider: % (%.1f%%)',
    null_provider_count,
    (100.0 * null_provider_count / NULLIF(total_count, 0));
  RAISE NOTICE 'Calls with NULL tts_voice_id: % (%.1f%%)',
    null_voice_count,
    (100.0 * null_voice_count / NULLIF(total_count, 0));
  RAISE NOTICE 'Calls with metadata.stack.tts: % (%.1f%%)',
    has_metadata_count,
    (100.0 * has_metadata_count / NULLIF(total_count, 0));
  RAISE NOTICE '';
END $$;

-- Backfill tts_provider and tts_voice_id from metadata
UPDATE agent_calls
SET
  tts_provider = metadata->'stack'->'tts'->0->>'ttsProvider',
  tts_voice_id = metadata->'stack'->'tts'->0->>'voiceId'
WHERE
  -- Only update rows with NULL values
  (tts_provider IS NULL OR tts_voice_id IS NULL)
  -- Only update rows that have the data in metadata
  AND metadata->'stack'->'tts' IS NOT NULL
  AND metadata->'stack'->'tts'->0 IS NOT NULL;

-- Get baseline stats AFTER update
DO $$
DECLARE
  total_count INTEGER;
  null_provider_count INTEGER;
  null_voice_count INTEGER;
  has_provider_count INTEGER;
  has_voice_count INTEGER;
  updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM agent_calls;

  SELECT COUNT(*) INTO null_provider_count
  FROM agent_calls
  WHERE tts_provider IS NULL;

  SELECT COUNT(*) INTO null_voice_count
  FROM agent_calls
  WHERE tts_voice_id IS NULL;

  SELECT COUNT(*) INTO has_provider_count
  FROM agent_calls
  WHERE tts_provider IS NOT NULL;

  SELECT COUNT(*) INTO has_voice_count
  FROM agent_calls
  WHERE tts_voice_id IS NOT NULL;

  updated_count := has_provider_count - (total_count - null_provider_count);

  RAISE NOTICE '';
  RAISE NOTICE '=== AFTER BACKFILL ===';
  RAISE NOTICE 'Total calls: %', total_count;
  RAISE NOTICE 'Calls with tts_provider: % (%.1f%%)',
    has_provider_count,
    (100.0 * has_provider_count / NULLIF(total_count, 0));
  RAISE NOTICE 'Calls with tts_voice_id: % (%.1f%%)',
    has_voice_count,
    (100.0 * has_voice_count / NULLIF(total_count, 0));
  RAISE NOTICE 'Calls still NULL provider: % (%.1f%%)',
    null_provider_count,
    (100.0 * null_provider_count / NULLIF(total_count, 0));
  RAISE NOTICE '';
  RAISE NOTICE '✅ Backfill completed successfully!';
  RAISE NOTICE '';
END $$;

COMMIT;

-- ===================================
-- VERIFICATION QUERIES (commented out)
-- Run these manually after migration to verify results
-- ===================================

-- Check sample of backfilled data
-- SELECT
--   id,
--   started_at,
--   tts_provider,
--   tts_voice_id,
--   metadata->'stack'->'tts'->0->>'ttsProvider' as metadata_provider,
--   metadata->'stack'->'tts'->0->>'voiceId' as metadata_voice
-- FROM agent_calls
-- WHERE tts_provider IS NOT NULL
-- ORDER BY started_at DESC
-- LIMIT 10;

-- Distribution of TTS providers
-- SELECT
--   tts_provider,
--   COUNT(*) as call_count,
--   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
-- FROM agent_calls
-- WHERE tts_provider IS NOT NULL
-- GROUP BY tts_provider
-- ORDER BY call_count DESC;

-- Distribution of TTS voices
-- SELECT
--   tts_voice_id,
--   COUNT(*) as call_count
-- FROM agent_calls
-- WHERE tts_voice_id IS NOT NULL
-- GROUP BY tts_voice_id
-- ORDER BY call_count DESC
-- LIMIT 10;

-- Calls that still don't have TTS data (expected if metadata is missing)
-- SELECT COUNT(*) as calls_without_tts_data
-- FROM agent_calls
-- WHERE tts_provider IS NULL
--   AND metadata->'stack'->'tts' IS NULL;
