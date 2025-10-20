-- Migration: Corriger la logique RDV - Utiliser UNIQUEMENT l'outcome
-- Description: Fix le bug des 118 RDV (au lieu de 13) causé par metadata ? 'key'
-- Date: 2025-01-20
-- Author: Claude
--
-- PROBLÈME IDENTIFIÉ :
-- - metadata ? 'appointment_scheduled_at' renvoie TRUE si la CLÉ existe
-- - Même si la VALEUR est null !
-- - Résultat : 105 VOICEMAIL comptés comme RDV pris
--
-- SOLUTION :
-- - Utiliser UNIQUEMENT outcome = 'appointment_scheduled'
-- - Source de vérité = outcome, pas metadata

-- ==============================================================================
-- STEP 1: Recréer la vue enrichie avec la BONNE logique
-- ==============================================================================

CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT
  ac.*,

  -- Calculate if call was answered
  -- Answered = person picked up (NOT voicemail, NOT error)
  -- IMPORTANT: Vos outcomes sont en minuscules selon les données réelles
  CASE
    -- Explicit NOT answered outcomes (basé sur vos données réelles)
    WHEN ac.outcome IN (
      'voicemail',           -- 134 appels
      'call_failed',         -- 2 appels
      'no_answer',           -- Pas encore vu mais probable
      'busy',                -- Pas encore vu mais probable
      'invalid_number',      -- Pas encore vu mais probable
      'error',               -- Pas encore vu mais probable
      'canceled',            -- Pas encore vu mais probable
      'rejected'             -- Pas encore vu mais probable
    ) THEN false

    -- NULL outcome = pas répondu aussi
    WHEN ac.outcome IS NULL THEN false

    -- All other outcomes mean the call was answered
    -- Cela inclut: appointment_scheduled (13), appointment_refused (16),
    -- too_short (23), not_interested (3), callback_requested (3)
    ELSE true
  END AS answered,

  -- Calculate if appointment was scheduled
  -- CORRECTION: Utiliser UNIQUEMENT l'outcome
  CASE
    WHEN ac.outcome = 'appointment_scheduled' THEN true
    ELSE false
  END AS appointment_scheduled

FROM agent_calls ac;

-- Add comment for documentation
COMMENT ON VIEW v_agent_calls_enriched IS
  'Enriched view of agent_calls. CORRECTED: appointment_scheduled based ONLY on outcome, not metadata (metadata has null values).';

-- Grant SELECT to authenticated users
GRANT SELECT ON v_agent_calls_enriched TO authenticated;


-- ==============================================================================
-- VERIFICATION : Vérifier que ça donne bien 13 RDV maintenant
-- ==============================================================================

-- Devrait maintenant retourner 13 au lieu de 118
-- SELECT COUNT(*) FILTER (WHERE appointment_scheduled = true) as rdv_count
-- FROM v_agent_calls_enriched;

-- Vérifier la répartition
-- SELECT
--   answered,
--   appointment_scheduled,
--   COUNT(*) as count
-- FROM v_agent_calls_enriched
-- GROUP BY answered, appointment_scheduled
-- ORDER BY count DESC;
