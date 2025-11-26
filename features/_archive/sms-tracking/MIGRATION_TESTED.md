# Migration SMS Tracking V2 - Testée et Validée

**Date** : 2025-11-13
**Statut** : ✅ **TESTÉE SUR STAGING - PRÊTE POUR PRODUCTION**

---

## ✅ Ce qui a été fait

### 1. Tests sur Staging
La migration a été **entièrement testée sur la base staging** avec succès :

**Résultats des tests** :
```
✅ Structure modifiée : Colonnes ajoutées/supprimées correctement
✅ Colonnes GENERATED : Calculs automatiques fonctionnent
✅ Vue enrichie : v_agent_sms_enriched créée sans erreur
✅ Fonction RPC : get_sms_metrics retourne les bonnes métriques
✅ Test données réelles : SMS 2 segments → Marge 26.60% calculée correctement
```

**Exemple de test réussi** :
```sql
-- SMS inséré :
num_segments = 2
cost_per_sms = 0.10€
provider_cost_usd = -0.1596

-- Résultat automatique :
provider_cost = 0.1468€ ✅
billed_cost = 0.20€ (0.10 × 2) ✅
margin = 0.0532€ (26.60%) ✅
```

### 2. Problème Corrigé
**Erreur initiale** : `column sms.email does not exist`
**Cause** : La colonne `email` n'existe pas dans la table `agent_sms`
**Solution** : Vue `v_agent_sms_enriched` recréée sans référence à `email`

### 3. Migration Corrigée
Le fichier **`supabase/migrations/20251113_add_segments_and_usd_conversion.sql`** a été mis à jour et validé.

---

## 🚀 Prêt pour Production

La migration est **100% prête** à être appliquée en production.

### Fichier à Exécuter
```
supabase/migrations/20251113_add_segments_and_usd_conversion.sql
```

### Contenu de la Migration

**Ajouts** :
- `num_segments` (INTEGER) - Nombre de segments SMS
- `cost_per_sms` (NUMERIC) - Prix par segment
- `provider_cost_usd` (NUMERIC) - Prix Twilio en USD
- `exchange_rate_usd_eur` (NUMERIC) - Taux de change

**Colonnes Calculées (GENERATED)** :
- `provider_cost` = ABS(provider_cost_usd) × exchange_rate
- `billed_cost` = cost_per_sms × num_segments
- `margin` = billed_cost - provider_cost

**Vues et Fonctions** :
- `v_agent_sms_enriched` (vue enrichie avec margin_percentage)
- `v_agent_communications` (vue unifiée SMS + Calls)
- `get_sms_metrics()` (fonction RPC avec KPIs par segment)

**Index de Performance** :
- `idx_agent_sms_num_segments` (SMS multi-segments)
- `idx_agent_sms_margin` (SMS non rentables)

---

## 📋 Instructions d'Exécution

### Étape 1 : Ouvrir Supabase Dashboard
1. Aller sur https://supabase.com/dashboard
2. Sélectionner votre projet **PRODUCTION**
3. Aller dans **SQL Editor**

### Étape 2 : Copier la Migration
1. Ouvrir le fichier : `supabase/migrations/20251113_add_segments_and_usd_conversion.sql`
2. Copier **tout le contenu** du fichier
3. Coller dans le SQL Editor de Supabase

### Étape 3 : Exécuter
1. Cliquer sur **"Run"** ou appuyer sur `Ctrl+Enter`
2. Attendre la fin de l'exécution (~10-15 secondes)
3. Vérifier qu'il n'y a **aucune erreur rouge**

### Étape 4 : Vérification Post-Migration
Exécuter cette query de vérification :
```sql
-- Vérifier les colonnes
SELECT column_name, data_type, is_generated
FROM information_schema.columns
WHERE table_name = 'agent_sms'
  AND column_name IN (
    'num_segments',
    'cost_per_sms',
    'provider_cost_usd',
    'exchange_rate_usd_eur',
    'provider_cost',
    'billed_cost',
    'margin'
  )
ORDER BY column_name;
```

**Résultat attendu** :
```
billed_cost              | numeric | ALWAYS
cost_per_sms             | numeric | NEVER
exchange_rate_usd_eur    | numeric | NEVER
margin                   | numeric | ALWAYS
num_segments             | integer | NEVER
provider_cost            | numeric | ALWAYS
provider_cost_usd        | numeric | NEVER
```

---

## 🔧 Configuration Post-Migration

### Ajouter cost_per_sms à agent_deployments

**Si la colonne n'existe pas encore** :
```sql
ALTER TABLE agent_deployments
ADD COLUMN IF NOT EXISTS cost_per_sms NUMERIC(10, 4) DEFAULT 0.10;

COMMENT ON COLUMN agent_deployments.cost_per_sms IS
  'Prix par segment SMS facturé au client en EUR. Recommandé : 0.10€ pour marge ~27%';
```

**Configurer les prix pour vos deployments** :
```sql
-- Prix standard pour tous les deployments actifs
UPDATE agent_deployments
SET cost_per_sms = 0.10
WHERE status = 'active' AND cost_per_sms IS NULL;
```

---

## 🧪 Test de Validation en Production

Après la migration, testez avec un SMS réel :

```sql
-- Insérer un SMS de test (remplacer deployment_id par un ID valide)
INSERT INTO public.agent_sms (
  deployment_id,
  phone_number,
  message_content,
  num_segments,
  cost_per_sms,
  provider_cost_usd,
  exchange_rate_usd_eur,
  provider_message_sid,
  status,
  sent_at
) VALUES (
  'votre-deployment-id-ici',
  '+33612345678',
  'SMS de test pour valider la migration V2',
  1,
  0.10,
  -0.07300,
  0.92,
  'SM_TEST_PROD_001',
  'delivered',
  NOW()
) RETURNING
  num_segments,
  cost_per_sms,
  provider_cost_usd,
  provider_cost,
  billed_cost,
  margin,
  CASE WHEN billed_cost > 0 THEN ROUND((margin / billed_cost) * 100, 2) ELSE 0 END AS margin_pct;
```

**Résultat attendu** :
```
num_segments     : 1
cost_per_sms     : 0.10
provider_cost_usd: -0.0730
provider_cost    : 0.0672  (0.0730 × 0.92)
billed_cost      : 0.10    (0.10 × 1)
margin           : 0.0328  (0.10 - 0.0672)
margin_pct       : 32.80   (32.80%)
```

**Si tout est OK** :
```sql
-- Supprimer le SMS de test
DELETE FROM agent_sms WHERE provider_message_sid = 'SM_TEST_PROD_001';
```

---

## 📊 Queries de Monitoring

### 1. Vérifier les SMS existants
```sql
SELECT
  COUNT(*) AS total_sms,
  COUNT(*) FILTER (WHERE num_segments IS NOT NULL) AS avec_segments,
  COUNT(*) FILTER (WHERE num_segments IS NULL) AS sans_segments
FROM agent_sms;
```

### 2. Rentabilité globale
```sql
SELECT
  COUNT(*) AS total_sms,
  AVG(num_segments) AS avg_segments,
  SUM(billed_cost) AS total_revenue,
  SUM(provider_cost) AS total_cost,
  SUM(margin) AS total_margin,
  ROUND(AVG(margin / NULLIF(billed_cost, 0)) * 100, 2) AS avg_margin_pct
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '30 days';
```

### 3. Identifier SMS non rentables
```sql
SELECT
  deployment_id,
  phone_number,
  num_segments,
  billed_cost,
  provider_cost,
  margin,
  ROUND((margin / NULLIF(billed_cost, 0)) * 100, 2) AS margin_pct
FROM agent_sms
WHERE margin < 0
  AND sent_at >= NOW() - INTERVAL '7 days'
ORDER BY margin ASC
LIMIT 10;
```

---

## ⚠️ Points d'Attention

### 1. SMS Existants
Si vous avez des SMS existants dans la table, ils auront :
- `num_segments = 1` (valeur par défaut)
- `cost_per_sms = 0.07€` (valeur par défaut)
- `provider_cost_usd = NULL` → `provider_cost = 0`

**Pour mettre à jour les anciens SMS** (optionnel) :
```sql
-- Exemple : Si vous avez l'info num_segments dans metadata
UPDATE agent_sms
SET
  num_segments = COALESCE((metadata->>'num_segments')::INTEGER, 1),
  provider_cost_usd = COALESCE((metadata->>'price')::NUMERIC, -0.073)
WHERE sent_at < NOW() - INTERVAL '1 day'
  AND num_segments IS NULL;
```

### 2. Taux de Change
Le taux de change USD → EUR est fixé à **0.92** par défaut.

**Pour ajuster** :
```sql
-- Mettre à jour pour les futurs SMS (modifier la colonne)
ALTER TABLE agent_sms
  ALTER COLUMN exchange_rate_usd_eur SET DEFAULT 0.91;

-- Pour les SMS existants, pas besoin de toucher (historique préservé)
```

### 3. Prix Recommandé
Avec **`cost_per_sms = 0.10€`**, vous obtenez une marge de **~27%** :
```
1 segment : 0.10€ - 0.067€ = +0.033€ (27%)
2 segments : 0.20€ - 0.135€ = +0.065€ (27%)
3 segments : 0.30€ - 0.202€ = +0.098€ (27%)
```

Avec **`cost_per_sms = 0.07€`**, vous êtes **en perte** :
```
1 segment : 0.07€ - 0.067€ = +0.003€ (4%)  ⚠️ Marge très faible
2 segments : 0.14€ - 0.135€ = +0.005€ (4%)  ⚠️ Marge très faible
```

---

## 📚 Documentation Complète

Pour plus de détails, consultez :
1. **MAPPING_ANALYSIS_V2.md** - Analyse détaillée des champs
2. **UPGRADE_V2_SUMMARY.md** - Guide de mise à jour n8n
3. **SUPABASE_INSERT_SMS_CONFIG.json** - Config n8n à jour

---

## ✅ Checklist Finale

- [ ] Migration exécutée en production sans erreur
- [ ] Colonne `cost_per_sms` ajoutée à `agent_deployments`
- [ ] Prix configurés pour tous les deployments actifs
- [ ] Test de validation avec SMS réel effectué
- [ ] Queries de monitoring configurées
- [ ] Workflow n8n mis à jour (voir UPGRADE_V2_SUMMARY.md)

---

**Migration validée et prête pour production** ✅

En cas de problème, la migration peut être annulée en restaurant une sauvegarde de la base de données.
