-- Migration: Fix outcome and emotion columns from call_status and sentiment_analysis
-- Date: 2025-11-13
-- Author: Claude
--
-- Context:
-- Some recent calls have empty 'outcome' and 'emotion' columns, but have data in
-- 'call_status' and 'sentiment_analysis' instead. This is likely due to a change in n8n.
--
-- The dashboards rely on 'outcome' and 'emotion', so we need to:
-- 1. Copy existing data from call_status → outcome and sentiment_analysis → emotion
-- 2. Add a trigger to automatically sync these columns for future calls
--
-- Affected: 4 calls as of 2025-11-13
-- Decision: Continue using 'outcome' and 'emotion' as the source of truth

-- ============================================================================
-- PART 1: Copy existing data from new columns to old columns
-- ============================================================================

-- Update outcome from call_status where outcome is empty
UPDATE agent_calls
SET outcome = call_status
WHERE (outcome IS NULL OR outcome = '')
  AND call_status IS NOT NULL
  AND call_status != '';

-- Update emotion from sentiment_analysis where emotion is empty
UPDATE agent_calls
SET emotion = sentiment_analysis
WHERE (emotion IS NULL OR emotion = '')
  AND sentiment_analysis IS NOT NULL
  AND sentiment_analysis != '';

-- ============================================================================
-- PART 2: Create trigger function to automatically sync columns
-- ============================================================================

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS trg_sync_outcome_emotion ON agent_calls;
DROP FUNCTION IF EXISTS sync_outcome_emotion_columns();

-- Create function to sync columns
CREATE OR REPLACE FUNCTION sync_outcome_emotion_columns()
RETURNS TRIGGER AS $$
BEGIN
  -- If outcome is empty but call_status has a value, copy it
  IF (NEW.outcome IS NULL OR NEW.outcome = '') AND
     (NEW.call_status IS NOT NULL AND NEW.call_status != '') THEN
    NEW.outcome := NEW.call_status;
  END IF;

  -- If emotion is empty but sentiment_analysis has a value, copy it
  IF (NEW.emotion IS NULL OR NEW.emotion = '') AND
     (NEW.sentiment_analysis IS NOT NULL AND NEW.sentiment_analysis != '') THEN
    NEW.emotion := NEW.sentiment_analysis;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires BEFORE INSERT OR UPDATE
CREATE TRIGGER trg_sync_outcome_emotion
  BEFORE INSERT OR UPDATE ON agent_calls
  FOR EACH ROW
  EXECUTE FUNCTION sync_outcome_emotion_columns();

-- ============================================================================
-- PART 3: Add comments for documentation
-- ============================================================================

COMMENT ON FUNCTION sync_outcome_emotion_columns() IS
'Automatically syncs call_status → outcome and sentiment_analysis → emotion
to maintain backward compatibility with dashboards.
Created 2025-11-13 to fix n8n workflow changes.';

COMMENT ON TRIGGER trg_sync_outcome_emotion ON agent_calls IS
'Ensures outcome and emotion are always populated from call_status and sentiment_analysis
if they are empty. Maintains dashboard compatibility.';

-- ============================================================================
-- VERIFICATION QUERIES (commented out, run manually to verify)
-- ============================================================================

-- Check that all recent calls now have outcome populated
-- SELECT
--   COUNT(*) as total_calls,
--   COUNT(*) FILTER (WHERE outcome IS NOT NULL AND outcome != '') as with_outcome,
--   COUNT(*) FILTER (WHERE emotion IS NOT NULL AND emotion != '') as with_emotion
-- FROM agent_calls
-- WHERE started_at >= '2025-11-01';

-- Check the 4 affected calls were fixed
-- SELECT
--   id,
--   started_at,
--   outcome,
--   call_status,
--   emotion,
--   sentiment_analysis
-- FROM agent_calls
-- WHERE started_at >= '2025-11-01'
--   AND (outcome = '' OR emotion IS NULL)
-- ORDER BY started_at DESC;
