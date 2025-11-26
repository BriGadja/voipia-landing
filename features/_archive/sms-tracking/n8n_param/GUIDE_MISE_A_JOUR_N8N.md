# Guide de Mise à Jour n8n - SMS Tracking V2

**Date** : 2025-11-13
**Objectif** : Mettre à jour le workflow n8n pour utiliser la facturation par segment

---

## 📋 Changements à Faire

### ❌ À RETIRER de la node "CreateARow-agent_sms"

**Champ à supprimer** :
```json
{
  "fieldId": "provider_cost",
  "fieldValue": "={{ Math.abs(parseFloat($('getSMSInfos').item.json.price)) * 0.92 }}"
}
```

**Pourquoi ?** Ce champ est maintenant **calculé automatiquement** par PostgreSQL (colonne GENERATED). Si vous l'envoyez depuis n8n, vous aurez une erreur.

---

### ✅ À AJOUTER à la node "CreateARow-agent_sms"

**4 nouveaux champs à ajouter** :

1. **num_segments** (Nombre de segments SMS)
```json
{
  "fieldId": "num_segments",
  "fieldValue": "={{ parseInt($('getSMSInfos').item.json.num_segments) || 1 }}"
}
```

2. **cost_per_sms** (Prix par segment)
```json
{
  "fieldId": "cost_per_sms",
  "fieldValue": "={{ $('GetDeployment').item.json.cost_per_sms || 0.10 }}"
}
```

3. **provider_cost_usd** (Prix Twilio en USD)
```json
{
  "fieldId": "provider_cost_usd",
  "fieldValue": "={{ parseFloat($('getSMSInfos').item.json.price) }}"
}
```

4. **exchange_rate_usd_eur** (Taux de change)
```json
{
  "fieldId": "exchange_rate_usd_eur",
  "fieldValue": "0.92"
}
```

---

## 🔧 Étape 1 : Ajouter la Node "GetDeployment"

**⚠️ CRITIQUE** : Vous devez ajouter une nouvelle node AVANT "CreateARow-agent_sms" pour récupérer `cost_per_sms`.

### Configuration de la Node "GetDeployment"

**Type de node** : Supabase
**Opération** : Get Row
**Nom** : `GetDeployment`

**Paramètres** :
```
Table: agent_deployments
Operation: Get Row

Filter:
- Field: id
- Value: {{ $('SetAgentData').item.json.deploymentId }}
```

**Position dans le workflow** :
```
SetAgentData
    ↓
GetDeployment ← NOUVELLE NODE À AJOUTER ICI
    ↓
SendSMS (Twilio)
    ↓
getSMSInfos
    ↓
CreateARow-agent_sms (à modifier)
```

### Comment Ajouter la Node dans n8n

1. **Ouvrir votre workflow SMS**
2. **Cliquer sur "+" entre** `SetAgentData` et `SendSMS`
3. **Chercher** "Supabase" dans la liste des nodes
4. **Configurer** :
   - Resource: `Row`
   - Operation: `Get`
   - Table: `agent_deployments`
   - Return All: `Désactivé`
   - Filters:
     - Filter 1:
       - Column: `id`
       - Operator: `Equal`
       - Value: `={{ $('SetAgentData').item.json.deploymentId }}`
5. **Nommer la node** : `GetDeployment`
6. **Connecter** : `SetAgentData` → `GetDeployment` → `SendSMS`

---

## 🔧 Étape 2 : Modifier la Node "CreateARow-agent_sms"

### Option A : Modification Manuelle (Recommandée)

1. **Ouvrir la node** "CreateARow-agent_sms"
2. **Supprimer le champ** `provider_cost`
3. **Ajouter les 4 nouveaux champs** (voir ci-dessus)
4. **Sauvegarder**

### Option B : Remplacement Complet (Plus Rapide)

1. **Supprimer** la node "CreateARow-agent_sms" existante
2. **Créer une nouvelle node** Supabase
3. **Copier-coller** la configuration depuis `SUPABASE_NODE_UPDATED_V2.json`
4. **Ajuster** les credentials si nécessaire
5. **Reconnecter** au workflow

---

## 📊 Configuration Complète (Prête à Copier)

Le fichier **`SUPABASE_NODE_UPDATED_V2.json`** contient la configuration complète mise à jour.

**Liste des champs (ordre recommandé)** :
1. ✅ `deployment_id`
2. ✅ `phone_number`
3. ✅ `message_content`
4. ✅ `message_type`
5. ✅ `provider`
6. ✅ `provider_message_sid`
7. ✅ `provider_status`
8. ✅ `status`
9. ✅ `sent_at`
10. ✅ `delivered_at`
11. ✅ `failure_reason`
12. 🆕 `num_segments` ← NOUVEAU
13. 🆕 `cost_per_sms` ← NOUVEAU
14. 🆕 `provider_cost_usd` ← NOUVEAU
15. 🆕 `exchange_rate_usd_eur` ← NOUVEAU
16. ✅ `currency`
17. ✅ `workflow_id`
18. ✅ `workflow_execution_id`
19. ✅ `metadata`

**Total** : 19 champs (15 existants + 4 nouveaux - 1 supprimé)

---

## ⚠️ Attention : Configuration agent_deployments

**Avant de tester**, assurez-vous que la colonne `cost_per_sms` existe dans `agent_deployments` :

```sql
-- Vérifier si la colonne existe
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'agent_deployments'
  AND column_name = 'cost_per_sms';

-- Si elle n'existe pas, l'ajouter :
ALTER TABLE agent_deployments
ADD COLUMN cost_per_sms NUMERIC(10, 4) DEFAULT 0.10;

-- Configurer les prix pour vos deployments
UPDATE agent_deployments
SET cost_per_sms = 0.10
WHERE status = 'active';
```

---

## 🧪 Test du Workflow

### Test 1 : Vérifier GetDeployment

1. **Exécuter le workflow** jusqu'à la node `GetDeployment`
2. **Vérifier la sortie** : Doit contenir `cost_per_sms`
3. **Exemple de sortie attendue** :
```json
{
  "id": "cb776a7a-0857-4304-817d-9a4242ae903d",
  "name": "Louis - Norloc",
  "cost_per_sms": 0.10,
  "client_id": "...",
  "agent_type_id": "..."
}
```

### Test 2 : Vérifier CreateARow-agent_sms

1. **Envoyer un SMS de test**
2. **Vérifier dans Supabase** :
```sql
SELECT
  phone_number,
  num_segments,
  cost_per_sms,
  provider_cost_usd,
  exchange_rate_usd_eur,
  provider_cost,    -- Calculé automatiquement
  billed_cost,      -- Calculé automatiquement
  margin            -- Calculé automatiquement
FROM agent_sms
ORDER BY created_at DESC
LIMIT 1;
```

**Résultat attendu** :
```
num_segments: 1 ou 2 (selon longueur SMS)
cost_per_sms: 0.10
provider_cost_usd: -0.073 (environ)
exchange_rate_usd_eur: 0.92
provider_cost: 0.0672 (calculé: 0.073 × 0.92)
billed_cost: 0.10 ou 0.20 (calculé: 0.10 × segments)
margin: ~0.0328 (calculé: billed_cost - provider_cost)
```

---

## 🚨 Erreurs Courantes

### Erreur 1 : "Column 'provider_cost' is generated"

**Cause** : Vous essayez d'envoyer `provider_cost` depuis n8n
**Solution** : Supprimer le champ `provider_cost` de la node Supabase

### Erreur 2 : "Node 'GetDeployment' not found"

**Cause** : Vous référencez `$('GetDeployment')` mais la node n'existe pas
**Solution** : Ajouter la node "GetDeployment" AVANT "CreateARow-agent_sms"

### Erreur 3 : "cost_per_sms is null"

**Cause** : La colonne `cost_per_sms` n'existe pas dans `agent_deployments`
**Solution** : Exécuter le SQL pour ajouter la colonne (voir section "Configuration agent_deployments")

### Erreur 4 : "Cannot read property 'cost_per_sms' of undefined"

**Cause** : GetDeployment ne retourne aucune donnée
**Solution** : Vérifier que `deploymentId` est correct dans SetAgentData

---

## 📊 Comparaison Avant/Après

### Avant (V1)
```json
{
  "provider_cost": "={{ Math.abs(parseFloat(...)) * 0.92 }}"
}
```
- Calcul manuel dans n8n
- Pas de facturation par segment
- Prix fixe par SMS

### Après (V2)
```json
{
  "num_segments": "={{ parseInt(...) || 1 }}",
  "cost_per_sms": "={{ $('GetDeployment')... || 0.10 }}",
  "provider_cost_usd": "={{ parseFloat(...) }}",
  "exchange_rate_usd_eur": "0.92"
}
```
- Calcul automatique en DB (GENERATED)
- Facturation par segment
- Traçabilité du taux de change

---

## ✅ Checklist de Migration n8n

- [ ] Node "GetDeployment" ajoutée entre SetAgentData et SendSMS
- [ ] Colonne `cost_per_sms` ajoutée à `agent_deployments`
- [ ] Prix configurés pour tous les deployments (0.10€ recommandé)
- [ ] Champ `provider_cost` RETIRÉ de CreateARow-agent_sms
- [ ] Champ `num_segments` AJOUTÉ
- [ ] Champ `cost_per_sms` AJOUTÉ
- [ ] Champ `provider_cost_usd` AJOUTÉ
- [ ] Champ `exchange_rate_usd_eur` AJOUTÉ
- [ ] Workflow testé avec SMS réel
- [ ] Vérification dans Supabase : calculs automatiques OK

---

## 📚 Fichiers de Référence

1. **SUPABASE_NODE_UPDATED_V2.json** - Configuration complète (ce fichier)
2. **MAPPING_ANALYSIS_V2.md** - Détails techniques
3. **MIGRATION_TESTED.md** - Guide migration SQL
4. **UPGRADE_V2_SUMMARY.md** - Vue d'ensemble

---

**Besoin d'aide ?** Consultez `MAPPING_ANALYSIS_V2.md` pour plus de détails sur chaque champ.
