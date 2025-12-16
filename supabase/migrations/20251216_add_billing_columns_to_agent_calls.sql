-- Migration: Add billing columns to agent_calls
-- Date: 2025-12-16
-- Description: Ajoute les colonnes client_rate_per_min et billed_cost pour la facturation
--
-- Problème résolu: La colonne cost_per_minute existante contient le coût provider,
-- pas le tarif client. On ajoute donc des colonnes dédiées à la facturation.

-- ============================================================================
-- 1. Ajouter colonne pour le tarif client (snapshot au moment de l'appel)
-- ============================================================================
ALTER TABLE agent_calls
ADD COLUMN IF NOT EXISTS client_rate_per_min NUMERIC;

COMMENT ON COLUMN agent_calls.client_rate_per_min IS
'Tarif facturé au client en EUR/min. Copié depuis agent_deployments.cost_per_min au moment de l''insertion. Permet de conserver le tarif même si le contrat change.';

-- ============================================================================
-- 2. Ajouter colonne pour le montant facturé
-- ============================================================================
ALTER TABLE agent_calls
ADD COLUMN IF NOT EXISTS billed_cost NUMERIC;

COMMENT ON COLUMN agent_calls.billed_cost IS
'Montant total facturé au client en EUR. Calculé: (duration_seconds/60) * client_rate_per_min.';

-- ============================================================================
-- 3. Backfill des données existantes depuis agent_deployments
-- ============================================================================
UPDATE agent_calls ac
SET
  client_rate_per_min = ad.cost_per_min,
  billed_cost = ROUND((COALESCE(ac.duration_seconds, 0)::numeric / 60.0) * ad.cost_per_min, 4)
FROM agent_deployments ad
WHERE ac.deployment_id = ad.id
  AND ac.client_rate_per_min IS NULL;

-- ============================================================================
-- 4. Créer un trigger pour remplir automatiquement ces colonnes
-- ============================================================================
DROP FUNCTION IF EXISTS set_agent_call_billing() CASCADE;

CREATE OR REPLACE FUNCTION set_agent_call_billing()
RETURNS TRIGGER AS $$
BEGIN
  -- Récupérer le tarif client depuis le deployment si non fourni
  IF NEW.client_rate_per_min IS NULL THEN
    SELECT cost_per_min INTO NEW.client_rate_per_min
    FROM agent_deployments
    WHERE id = NEW.deployment_id;
  END IF;

  -- Calculer le montant facturé
  NEW.billed_cost := ROUND(
    (COALESCE(NEW.duration_seconds, 0)::numeric / 60.0) * COALESCE(NEW.client_rate_per_min, 0.27),
    4
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur INSERT et UPDATE de duration_seconds
DROP TRIGGER IF EXISTS trigger_set_agent_call_billing ON agent_calls;

CREATE TRIGGER trigger_set_agent_call_billing
BEFORE INSERT OR UPDATE OF duration_seconds, client_rate_per_min
ON agent_calls
FOR EACH ROW
EXECUTE FUNCTION set_agent_call_billing();

-- ============================================================================
-- 5. Index pour améliorer les performances des requêtes de facturation
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_agent_calls_billing_lookup
ON agent_calls (deployment_id, started_at)
WHERE duration_seconds > 0;

-- ============================================================================
-- Vérification (à exécuter manuellement après la migration)
-- ============================================================================
-- SELECT
--     COUNT(*) as total,
--     COUNT(client_rate_per_min) as with_client_rate,
--     COUNT(billed_cost) as with_billed_cost,
--     ROUND(AVG(client_rate_per_min), 4) as avg_client_rate,
--     ROUND(SUM(billed_cost), 2) as total_billed
-- FROM agent_calls
-- WHERE created_at >= '2025-11-01';
