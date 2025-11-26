-- Migration: Modify call_quality_score constraint to accept values 0-100
-- Date: 2025-11-24
-- Author: Claude
--
-- Changes:
-- 1. Drop existing constraint (1-10 range)
-- 2. Create new constraint (0-100 range)
-- 3. This allows quality scores on a 100-point scale
--
-- Why: The AI agents return quality scores on a 100-point scale,
-- but the old constraint only allowed 1-10, causing insertion failures.

-- Drop the existing constraint
ALTER TABLE agent_calls
DROP CONSTRAINT IF EXISTS agent_calls_call_quality_score_check;

-- Add new constraint with 0-100 range
ALTER TABLE agent_calls
ADD CONSTRAINT agent_calls_call_quality_score_check
CHECK ((call_quality_score >= 0) AND (call_quality_score <= 100));

-- Verification queries (commented out)
-- Test that NULL is still accepted:
-- SELECT COUNT(*) FROM agent_calls WHERE call_quality_score IS NULL;

-- Test that existing scores are valid:
-- SELECT MIN(call_quality_score), MAX(call_quality_score)
-- FROM agent_calls
-- WHERE call_quality_score IS NOT NULL;

-- Test the constraint with sample values:
-- INSERT INTO agent_calls (call_quality_score, ...) VALUES (0, ...);   -- Should work
-- INSERT INTO agent_calls (call_quality_score, ...) VALUES (50, ...);  -- Should work
-- INSERT INTO agent_calls (call_quality_score, ...) VALUES (100, ...); -- Should work
-- INSERT INTO agent_calls (call_quality_score, ...) VALUES (101, ...); -- Should fail
