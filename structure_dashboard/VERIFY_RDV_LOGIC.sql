-- Script de vérification : Comprendre comment les RDV sont comptés
-- Exécutez ces requêtes dans Supabase pour comprendre vos données

-- ============================================================================
-- 1. QUELS SONT LES OUTCOMES RÉELS ?
-- ============================================================================
-- Cette requête montre tous les outcomes distincts et leur nombre
SELECT
  outcome,
  COUNT(*) as nombre_appels
FROM agent_calls
GROUP BY outcome
ORDER BY nombre_appels DESC;

-- ============================================================================
-- 2. COMBIEN D'APPELS ONT 'RDV PRIS' VS 'appointment_scheduled' ?
-- ============================================================================
-- Vérifier les différentes façons de marquer un RDV
SELECT
  'RDV PRIS dans outcome' as type,
  COUNT(*) as nombre
FROM agent_calls
WHERE outcome = 'RDV PRIS'

UNION ALL

SELECT
  'appointment_scheduled dans outcome' as type,
  COUNT(*) as nombre
FROM agent_calls
WHERE outcome = 'appointment_scheduled'

UNION ALL

SELECT
  'RDV REFUSÉ dans outcome' as type,
  COUNT(*) as nombre
FROM agent_calls
WHERE outcome = 'RDV REFUSÉ';

-- ============================================================================
-- 3. COMBIEN D'APPELS ONT appointment_scheduled_at DANS METADATA ?
-- ============================================================================
-- Vérifier si les RDV sont marqués dans les métadonnées
SELECT
  COUNT(*) as appels_avec_metadata_rdv
FROM agent_calls
WHERE metadata ? 'appointment_scheduled_at';

-- ============================================================================
-- 4. RÉPARTITION DÉTAILLÉE DES RDV
-- ============================================================================
-- Voir TOUTES les combinaisons possibles
SELECT
  CASE
    WHEN outcome = 'RDV PRIS' THEN 'Outcome = RDV PRIS'
    WHEN outcome = 'appointment_scheduled' THEN 'Outcome = appointment_scheduled'
    WHEN outcome = 'RDV REFUSÉ' THEN 'Outcome = RDV REFUSÉ'
    ELSE 'Autre outcome'
  END as outcome_type,
  CASE
    WHEN metadata ? 'appointment_scheduled_at' THEN 'OUI'
    ELSE 'NON'
  END as a_metadata_rdv,
  COUNT(*) as nombre
FROM agent_calls
GROUP BY outcome_type, a_metadata_rdv
ORDER BY nombre DESC;

-- ============================================================================
-- 5. EXEMPLE D'APPELS AVEC RDV (pour inspection manuelle)
-- ============================================================================
-- Voir quelques exemples d'appels considérés comme "RDV pris"
SELECT
  id,
  started_at,
  outcome,
  metadata->>'appointment_scheduled_at' as rdv_date,
  first_name,
  last_name,
  deployment_id
FROM agent_calls
WHERE outcome = 'RDV PRIS'
   OR metadata ? 'appointment_scheduled_at'
LIMIT 20;

-- ============================================================================
-- 6. VÉRIFIER LA LOGIQUE ACTUELLE DE LA VUE (si déjà exécutée)
-- ============================================================================
-- Si vous avez déjà exécuté les migrations, cette requête montre ce qui est compté
SELECT
  COUNT(*) as total_appels,
  COUNT(*) FILTER (WHERE appointment_scheduled = true) as rdv_comptés,
  COUNT(*) FILTER (WHERE outcome = 'RDV PRIS') as outcome_rdv_pris,
  COUNT(*) FILTER (WHERE metadata ? 'appointment_scheduled_at') as metadata_rdv
FROM v_agent_calls_enriched;

-- ============================================================================
-- 7. RÉPARTITION PAR AGENT TYPE
-- ============================================================================
-- Voir combien de RDV par type d'agent (Louis vs Arthur)
SELECT
  at.name as agent_type,
  COUNT(*) FILTER (WHERE ac.outcome = 'RDV PRIS' OR ac.metadata ? 'appointment_scheduled_at') as rdv_total,
  COUNT(*) FILTER (WHERE ac.outcome = 'RDV PRIS') as rdv_outcome,
  COUNT(*) FILTER (WHERE ac.metadata ? 'appointment_scheduled_at') as rdv_metadata
FROM agent_calls ac
INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
INNER JOIN agent_types at ON ad.agent_type_id = at.id
GROUP BY at.name;
