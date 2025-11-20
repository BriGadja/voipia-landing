-- Migration: Cleanup obsolete voipia_margin column
-- Date: 2025-11-13
-- Author: Claude
--
-- Changes:
-- Remove obsolete voipia_margin column (replaced by calculated margin column)
--
-- Context:
-- The old pricing model used voipia_margin as input (fixed margin per SMS)
-- The new V2 model uses margin as GENERATED column (billed_cost - provider_cost)
-- voipia_margin is no longer used anywhere and should be removed

-- Drop the obsolete column
ALTER TABLE public.agent_sms
  DROP COLUMN IF EXISTS voipia_margin;

-- Verification query (commented out)
/*
-- Verify the column is gone
SELECT column_name, data_type, is_generated
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'agent_sms'
  AND column_name LIKE '%margin%';

-- Expected result: Only 'margin' column with is_generated = 'ALWAYS'
*/
