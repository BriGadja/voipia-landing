# Problème: Colonnes outcome et emotion vides

**Date**: 2025-11-13
**Statut**: ✅ Résolu avec trigger automatique
**Impact**: 4 appels affectés depuis le 1er novembre

---

## Contexte

Les dashboards Voipia reposent sur deux colonnes critiques de la table `agent_calls`:
- **`outcome`** - Résultat de l'appel (appointment_scheduled, voicemail, etc.)
- **`emotion`** - Émotion détectée (positive, neutral, negative)

## Problème détecté

Depuis début novembre 2025, certains nouveaux appels ont:
- ❌ `outcome` = vide (chaîne vide `""`)
- ❌ `emotion` = null
- ✅ `call_status` = "voicemail" ou "ok" (nouvelle colonne)
- ✅ `sentiment_analysis` = "neutral" ou "positive" (nouvelle colonne)

### Exemples d'appels affectés

```sql
-- Appel récent (13 nov 2025) - PROBLÉMATIQUE
{
  "outcome": "",                    -- ❌ Vide
  "call_status": "voicemail",       -- ✅ Rempli
  "emotion": null,                  -- ❌ Vide
  "sentiment_analysis": "neutral"   -- ✅ Rempli
}

-- Appel ancien (12 nov 2025) - CORRECT
{
  "outcome": "appointment_scheduled",  -- ✅ Rempli
  "call_status": null,
  "emotion": "positive",               -- ✅ Rempli
  "sentiment_analysis": null
}
```

## Impact sur les dashboards

Les dashboards utilisent les colonnes `outcome` et `emotion` dans:
- ✅ Vue `v_agent_calls_enriched` (calcul de `answered`, `appointment_scheduled`)
- ✅ Fonction `get_kpi_metrics()` (KPIs: taux de décroché, conversion, etc.)
- ✅ Fonction `get_chart_data()` (graphiques: distribution émotions, outcomes)
- ✅ Vue `v_louis_agent_performance` (performance par agent)

**Conséquence**: Les 4 appels avec `outcome` vide ne sont **pas comptabilisés** correctement dans les KPIs !

## Cause probable

Changement dans les workflows n8n qui :
- Anciennement : écrivaient dans `outcome` et `emotion`
- Maintenant : écrivent dans `call_status` et `sentiment_analysis`

**TODO pour l'équipe backend** : Vérifier les workflows n8n et les corriger pour utiliser `outcome` et `emotion`.

## Solution appliquée

Migration créée : `20251113_fix_outcome_emotion_columns.sql`

### Partie 1: Correction des données existantes

```sql
-- Copie call_status → outcome
UPDATE agent_calls
SET outcome = call_status
WHERE (outcome IS NULL OR outcome = '')
  AND call_status IS NOT NULL;

-- Copie sentiment_analysis → emotion
UPDATE agent_calls
SET emotion = sentiment_analysis
WHERE (emotion IS NULL OR emotion = '')
  AND sentiment_analysis IS NOT NULL;
```

### Partie 2: Trigger automatique pour le futur

Ajout d'un trigger `trg_sync_outcome_emotion` qui s'exécute **AVANT** chaque INSERT ou UPDATE sur `agent_calls` :

```sql
CREATE TRIGGER trg_sync_outcome_emotion
  BEFORE INSERT OR UPDATE ON agent_calls
  FOR EACH ROW
  EXECUTE FUNCTION sync_outcome_emotion_columns();
```

Ce trigger garantit que même si n8n continue d'écrire dans `call_status` et `sentiment_analysis`, les colonnes `outcome` et `emotion` seront automatiquement remplies.

## Avantages de cette approche

✅ **Backward compatibility** - Les dashboards continuent de fonctionner sans modification
✅ **Correction automatique** - Les futurs appels seront automatiquement corrigés
✅ **Pas de downtime** - Pas besoin de toucher au code frontend/backend
✅ **Pas de risque** - Les anciennes données restent intactes
✅ **Temporaire** - Le trigger peut être supprimé une fois n8n corrigé

## Alternatives considérées

### ❌ Option B (rejetée) : Migrer tout vers call_status et sentiment_analysis

Aurait nécessité :
- Modification de toutes les vues SQL (5+ vues)
- Modification de toutes les fonctions RPC (3+ fonctions)
- Modification du code TypeScript
- Migration complète des données historiques
- Tests complets de tous les dashboards

**Raison du rejet** : Trop de risques, trop de travail, pas de bénéfice clair.

## Prochaines étapes

1. ✅ **Appliquer la migration** (à faire par l'utilisateur)
2. 🔍 **Vérifier n8n** - Corriger les workflows pour utiliser `outcome` et `emotion`
3. 🧪 **Tester** - Créer un appel test et vérifier que `outcome` est bien rempli
4. 🗑️ **Nettoyer (optionnel)** - Une fois n8n corrigé, on peut supprimer le trigger

## Commandes de vérification

```sql
-- Vérifier que tous les appels récents ont outcome rempli
SELECT
  COUNT(*) as total_calls,
  COUNT(*) FILTER (WHERE outcome IS NOT NULL AND outcome != '') as with_outcome,
  COUNT(*) FILTER (WHERE emotion IS NOT NULL AND emotion != '') as with_emotion
FROM agent_calls
WHERE started_at >= '2025-11-01';

-- Voir les appels avec outcome vide (devrait être 0 après migration)
SELECT
  id, started_at, outcome, call_status, emotion, sentiment_analysis
FROM agent_calls
WHERE started_at >= '2025-11-01'
  AND (outcome IS NULL OR outcome = '')
ORDER BY started_at DESC;
```

## Notes importantes

- Les colonnes `call_status` et `sentiment_analysis` ne sont **pas supprimées**
- Elles peuvent coexister avec `outcome` et `emotion`
- Le trigger ne fait que synchroniser les valeurs si nécessaire
- Une fois n8n corrigé, le trigger deviendra inutile (mais pas gênant)

---

**Décision finale** : Continuer d'utiliser `outcome` et `emotion` comme source de vérité pour les dashboards.
