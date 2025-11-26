# Mise à Jour SMS Tracking V2 - Résumé

**Date** : 2025-11-13
**Version** : 1.0 → 2.0

---

## 🎯 Ce qui a changé

### ✅ Problème 1 Résolu : Facturation par Segment

**Avant (V1)** :
```
SMS 2 segments → Facturé 0.07€ (prix fixe)
→ PERTE de 0.077€ car coût Twilio = 0.147€
```

**Après (V2)** :
```
SMS 2 segments → Facturé 0.07€ × 2 = 0.14€
→ Marge ajustée selon longueur du message
```

### ✅ Problème 2 Résolu : Conversion USD → EUR

**Avant (V1)** :
```
Conversion hardcodée dans n8n
Pas de traçabilité du taux de change
```

**Après (V2)** :
```
Prix USD stocké séparément
Taux de change enregistré par SMS
Conversion automatique en DB
```

---

## 📦 Fichiers Créés/Modifiés

### Nouveau Fichier de Migration
- ✅ `supabase/migrations/20251113_add_segments_and_usd_conversion.sql`

### Fichiers Modifiés
- ✅ `features/sms-tracking/n8n_param/SUPABASE_INSERT_SMS_CONFIG.json`
- ✅ `features/sms-tracking/n8n_param/MAPPING_ANALYSIS_V2.md` (nouveau)

---

## 🚀 Actions Requises (Ordre d'Exécution)

### 1. Base de Données (CRITIQUE - À FAIRE EN PREMIER)

**Appliquer la migration** :
```sql
-- Ouvrir Supabase Dashboard → SQL Editor
-- Copier-coller le contenu de :
supabase/migrations/20251113_add_segments_and_usd_conversion.sql
-- Exécuter

-- Vérifier que tout fonctionne :
SELECT column_name, data_type, is_generated
FROM information_schema.columns
WHERE table_name = 'agent_sms'
  AND column_name IN ('num_segments', 'cost_per_sms', 'provider_cost_usd', 'exchange_rate_usd_eur', 'provider_cost', 'billed_cost', 'margin');
```

**Résultat attendu** :
```
num_segments            | integer | NEVER
cost_per_sms            | numeric | NEVER
provider_cost_usd       | numeric | NEVER
exchange_rate_usd_eur   | numeric | NEVER
provider_cost           | numeric | ALWAYS  ← Calculé automatiquement
billed_cost             | numeric | ALWAYS  ← Calculé automatiquement
margin                  | numeric | ALWAYS  ← Calculé automatiquement
```

### 2. Configuration agent_deployments

**Ajouter cost_per_sms si n'existe pas** :
```sql
-- Vérifier si la colonne existe
SELECT column_name FROM information_schema.columns
WHERE table_name = 'agent_deployments' AND column_name = 'cost_per_sms';

-- Si elle n'existe pas, l'ajouter :
ALTER TABLE agent_deployments
ADD COLUMN cost_per_sms NUMERIC(10, 4) DEFAULT 0.10;

COMMENT ON COLUMN agent_deployments.cost_per_sms IS
  'Prix par segment SMS facturé au client en EUR. Recommandé : 0.10€ pour marge ~27%';
```

**Configurer les prix pour vos deployments** :
```sql
-- Option 1 : Prix unique pour tous (recommandé au démarrage)
UPDATE agent_deployments
SET cost_per_sms = 0.10
WHERE status = 'active';

-- Option 2 : Prix différenciés par client
UPDATE agent_deployments
SET cost_per_sms = 0.10 -- Standard
WHERE client_id = 'client-standard';

UPDATE agent_deployments
SET cost_per_sms = 0.12 -- Premium
WHERE client_id = 'client-premium';
```

### 3. Workflow n8n

**Ajouter node "GetDeployment"** :

1. Ouvrir votre workflow n8n de gestion SMS
2. Ajouter une node **Supabase** entre `SetAgentData` et `SendSMS`
3. Configuration :
   ```
   Operation: Get Row
   Table: agent_deployments
   Filter Field: id
   Filter Value: {{ $('SetAgentData').item.json.deploymentId }}
   ```
4. Nommer la node : **"GetDeployment"**

**Mettre à jour node "Supabase Insert SMS"** :

1. Ouvrir la node "Supabase Insert SMS" (ou "CreateARow-agent_sms")
2. Aller dans l'onglet "Parameters" → "Fields to Send"
3. **RETIRER** les champs suivants (maintenant calculés automatiquement) :
   - `provider_cost` ❌ SUPPRIMER
   - `billed_cost` ❌ SUPPRIMER
   - `margin` ❌ SUPPRIMER (si présent)

4. **AJOUTER** les nouveaux champs :

**num_segments** :
```javascript
Field: num_segments
Value: {{ parseInt($('getSMSInfos').item.json.num_segments) || 1 }}
```

**cost_per_sms** :
```javascript
Field: cost_per_sms
Value: {{ $('GetDeployment').item.json.cost_per_sms || 0.07 }}
```

**provider_cost_usd** :
```javascript
Field: provider_cost_usd
Value: {{ parseFloat($('getSMSInfos').item.json.price) }}
```

**exchange_rate_usd_eur** :
```javascript
Field: exchange_rate_usd_eur
Value: 0.92
```

5. Sauvegarder et activer le workflow

**Workflow complet (ordre des nodes)** :
```
1. Trigger
   ↓
2. SetAgentData (variables)
   ↓
3. GetDeployment ← NOUVEAU
   ↓
4. SendSMS (Twilio)
   ↓
5. getSMSInfos (HTTP Request)
   ↓
6. Supabase Insert SMS (config V2)
```

---

## 🧪 Tests de Validation

### Test 1 : SMS Court (1 segment)
```
Envoyer un SMS de < 160 caractères
Exemple : "Bonjour, ceci est un test."
```

**Résultat attendu** :
```sql
SELECT
  message_content,
  num_segments,     -- Doit être 1
  cost_per_sms,     -- Doit être 0.10
  provider_cost_usd,-- Doit être ~-0.073
  provider_cost,    -- Doit être ~0.067 (0.073 × 0.92)
  billed_cost,      -- Doit être 0.10 (0.10 × 1)
  margin            -- Doit être ~0.033 (0.10 - 0.067)
FROM agent_sms
ORDER BY created_at DESC
LIMIT 1;
```

### Test 2 : SMS Long (2 segments)
```
Envoyer un SMS de > 160 caractères
Exemple : Votre message de 180 caractères qui sera facturé en 2 segments par Twilio...
```

**Résultat attendu** :
```sql
num_segments = 2
provider_cost_usd = ~-0.147
provider_cost = ~0.135 (0.147 × 0.92)
billed_cost = 0.20 (0.10 × 2)
margin = ~0.065 (0.20 - 0.135) ✅ RENTABLE
```

### Test 3 : Vérifier Ancienne Configuration (Si applicable)
```sql
-- Si vous avez des SMS existants avec l'ancienne structure :
SELECT
  CASE
    WHEN provider_cost IS NULL THEN 'Ancienne structure (à migrer)'
    WHEN num_segments IS NOT NULL THEN 'V2 OK'
    ELSE 'V1 (à migrer)'
  END AS version_status,
  COUNT(*) AS total_sms
FROM agent_sms
GROUP BY version_status;
```

---

## 📊 Monitoring Post-Migration

### Query 1 : Rentabilité Globale
```sql
SELECT
  COUNT(*) AS total_sms,
  AVG(num_segments) AS avg_segments,
  SUM(billed_cost) AS total_revenue,
  SUM(provider_cost) AS total_cost,
  SUM(margin) AS total_margin,
  ROUND(AVG(margin / NULLIF(billed_cost, 0)) * 100, 2) AS avg_margin_pct
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '7 days';
```

**Résultat attendu avec cost_per_sms = 0.10€** :
```
avg_margin_pct ≈ 25-30%
```

### Query 2 : Identifier SMS Non Rentables
```sql
SELECT
  deployment_id,
  message_content,
  num_segments,
  billed_cost,
  provider_cost,
  margin
FROM agent_sms
WHERE margin < 0
  AND sent_at >= NOW() - INTERVAL '7 days'
ORDER BY margin ASC
LIMIT 10;
```

**Si cette query retourne des résultats** :
→ Augmenter `cost_per_sms` dans agent_deployments

### Query 3 : Performance par Deployment
```sql
SELECT
  ad.name AS deployment_name,
  c.name AS client_name,
  COUNT(sms.id) AS total_sms,
  ROUND(AVG(sms.margin), 4) AS avg_margin,
  ROUND(SUM(sms.margin), 2) AS total_margin
FROM agent_sms sms
JOIN agent_deployments ad ON sms.deployment_id = ad.id
JOIN clients c ON ad.client_id = c.id
WHERE sms.sent_at >= NOW() - INTERVAL '30 days'
GROUP BY ad.name, c.name
ORDER BY total_margin DESC;
```

---

## ⚠️ Points d'Attention

### 1. Taux de Change USD → EUR

**Actuel** : Fixé à `0.92` (hardcodé)
**Impact** : Si taux réel varie de ±5%, impact sur marge

**Solutions** :
- ✅ **Court terme** : Garder 0.92 fixe (acceptable < 10K SMS/mois)
- 🔧 **Moyen terme** : Mettre à jour manuellement chaque mois
- ⚡ **Long terme** : Ajouter node HTTP Request vers API taux de change

### 2. Prix Minimum Recommandé

**Calcul** :
```
Coût Twilio France : ~0.073€ / segment
Marge souhaitée    : 30%
Prix optimal       : 0.073 ÷ 0.70 = 0.104€

Recommandation : cost_per_sms = 0.10€
```

**Si vous facturez moins de 0.08€/segment** :
→ Vous êtes probablement EN PERTE

### 3. Migration des Données Existantes

**Si vous avez des SMS existants dans la table** :

```sql
-- Option 1 : Supprimer (si données de test)
DELETE FROM agent_sms
WHERE workflow_id LIKE 'test_%';

-- Option 2 : Backfill avec valeurs par défaut
UPDATE agent_sms
SET
  num_segments = 1,
  cost_per_sms = 0.07,
  provider_cost_usd = -0.073,
  exchange_rate_usd_eur = 0.92
WHERE num_segments IS NULL;
```

---

## 📚 Documentation Complète

Pour plus de détails, consultez :

1. **Analyse détaillée** : `features/sms-tracking/n8n_param/MAPPING_ANALYSIS_V2.md`
2. **Config n8n complète** : `features/sms-tracking/n8n_param/SUPABASE_INSERT_SMS_CONFIG.json`
3. **Migration SQL** : `supabase/migrations/20251113_add_segments_and_usd_conversion.sql`
4. **Schéma DB** : `features/sms-tracking/documentation/SCHEMA.md`

---

## ✅ Checklist Finale

- [ ] Migration SQL appliquée en production
- [ ] Colonne `cost_per_sms` ajoutée à `agent_deployments`
- [ ] Prix configurés pour tous les deployments actifs (0.10€ recommandé)
- [ ] Node "GetDeployment" ajoutée au workflow n8n
- [ ] Config Supabase Insert mise à jour (V2)
- [ ] Test SMS 1 segment validé
- [ ] Test SMS 2 segments validé
- [ ] Monitoring queries configurées
- [ ] Dashboard rentabilité créé (optionnel)

---

**Questions ?** Consultez `MAPPING_ANALYSIS_V2.md` pour tous les détails techniques.

**Support** : Pour toute question sur cette migration, référez-vous aux fichiers dans `features/sms-tracking/`.
