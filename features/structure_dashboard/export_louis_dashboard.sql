-- Script SQL pour exporter les données du Dashboard Louis
-- À exécuter dans Supabase SQL Editor
-- Le résultat peut être exporté en CSV directement depuis l'interface

SELECT
  -- Date et heure
  TO_CHAR(ac.started_at AT TIME ZONE 'UTC', 'YYYY-MM-DD') as date,
  TO_CHAR(ac.started_at AT TIME ZONE 'UTC', 'HH24:MI:SS') as heure,

  -- Entreprise anonymisée
  CASE c.name
    WHEN 'Norloc' THEN 'Entreprise A'
    WHEN 'Exotic Design' THEN 'Entreprise B'
    WHEN 'Stefano Design' THEN 'Entreprise C'
    WHEN 'Voipia' THEN 'Entreprise D'
    ELSE 'Entreprise Inconnue'
  END as entreprise,

  -- Résultat de l'appel traduit en français
  CASE ac.outcome
    WHEN 'appointment_scheduled' THEN 'RDV Pris'
    WHEN 'appointment_refused' THEN 'RDV Refusé'
    WHEN 'voicemail' THEN 'Messagerie'
    WHEN 'not_interested' THEN 'Pas Intéressé'
    WHEN 'callback_requested' THEN 'Rappel Demandé'
    WHEN 'too_short' THEN 'Appel Trop Court'
    WHEN 'call_failed' THEN 'Échec Appel'
    WHEN 'no_answer' THEN 'Pas de Réponse'
    WHEN 'busy' THEN 'Occupé'
    ELSE 'Inconnu'
  END as resultat_appel,

  -- Durée et coût
  ac.duration_seconds as duree_secondes,
  ROUND(ac.cost::numeric, 4) as cout_euro,

  -- Émotion traduite en français
  CASE ac.emotion
    WHEN 'positive' THEN 'Positif'
    WHEN 'neutral' THEN 'Neutre'
    WHEN 'negative' THEN 'Négatif'
    WHEN 'unknown' THEN 'Inconnu'
    ELSE 'Inconnu'
  END as emotion,

  -- Appel décroché (calculé)
  CASE
    WHEN ac.outcome NOT IN ('voicemail', 'call_failed', 'no_answer', 'busy')
      AND ac.outcome IS NOT NULL
    THEN 'Oui'
    ELSE 'Non'
  END as appel_decroche,

  -- RDV pris (calculé)
  CASE
    WHEN ac.outcome = 'appointment_scheduled' THEN 'Oui'
    ELSE 'Non'
  END as rdv_pris

FROM agent_calls ac
JOIN agent_deployments ad ON ac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
JOIN clients c ON ad.client_id = c.id

WHERE at.name = 'louis'  -- Filtre uniquement Louis

ORDER BY ac.started_at DESC;

-- INSTRUCTIONS D'EXPORT :
-- 1. Copie ce script dans Supabase SQL Editor
-- 2. Exécute la requête
-- 3. Clique sur "Download CSV" dans les résultats
-- 4. Tu obtiens ton fichier plat anonymisé et prêt à l'emploi !
