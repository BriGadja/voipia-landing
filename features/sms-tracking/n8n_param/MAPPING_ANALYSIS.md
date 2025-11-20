# Analyse du Mapping n8n → agent_sms

**Date** : 2025-11-13

---

## ✅ Champs Correctement Mappés

Les champs suivants sont disponibles dans vos payloads et correctement mappés :

| Champ `agent_sms` | Source | Valeur Exemple | Notes |
|-------------------|--------|----------------|-------|
| `deployment_id` | `SetAgentData.deploymentId` | `cb776a7a-0857-4304-817d-9a4242ae903d` | ✅ FK valide |
| `phone_number` | `getSMSInfos.to` | `+33766497427` | ✅ Format E.164 |
| `message_content` | `getSMSInfos.body` | `"Bonjour Aboubakar !..."` | ✅ Contenu SMS |
| `provider_message_sid` | `getSMSInfos.sid` | `SM419ebcde783093e657be0673e1887f21` | ✅ Unique Twilio |
| `provider_status` | `getSMSInfos.status` | `delivered` | ✅ Status détaillé |
| `sent_at` | `getSMSInfos.date_sent` | `2025-11-14T04:30:49Z` | ✅ ISO 8601 |
| `delivered_at` | `getSMSInfos.date_updated` (si delivered) | `2025-11-14T04:30:56Z` | ✅ Conditionnel |
| `failure_reason` | `getSMSInfos.error_message` | `null` (si pas d'erreur) | ✅ |
| `workflow_id` | `$workflow.id` | Auto | ✅ |
| `workflow_execution_id` | `$execution.id` | Auto | ✅ |

---

## ⚠️ Champs avec Conversion/Calcul

### 1. `provider_cost` (Coût réel Twilio)

**Source** : `getSMSInfos.price`
**Problème** : Valeur en **USD** (`-0.15960`) et **négative**
**Solution appliquée** :
```javascript
Math.abs(parseFloat($('getSMSInfos').item.json.price)) * 0.92
```

**Explication** :
- `Math.abs()` → Retire le signe négatif : `0.15960`
- `* 0.92` → Convertit USD → EUR (taux approximatif)
- Résultat : `~0.1468€` (14.68 centimes)

⚠️ **Attention** : Le taux de change USD/EUR est approximatif (0.92). Pour plus de précision :
- Utiliser une API de taux de change (ex: `exchangerate-api.com`)
- OU configurer un taux fixe dans les paramètres du workflow
- OU stocker le prix en USD et convertir dans le dashboard

**Note importante** : Ce SMS coûte **0.1468€** (2 segments) alors que le prix facturé sera probablement **0.07€** → **PERTE de 0.0768€** !

---

### 2. `status` (Status simplifié pour KPIs)

**Source** : `getSMSInfos.status`
**Mapping** :
```javascript
$('getSMSInfos').item.json.status === 'delivered' ? 'delivered' :
  ($('getSMSInfos').item.json.status === 'failed' ||
   $('getSMSInfos').item.json.status === 'undelivered' ? 'failed' :
   'sent')
```

**Mapping Twilio → agent_sms** :
| Twilio Status | agent_sms.status |
|---------------|------------------|
| `delivered` | `delivered` |
| `failed`, `undelivered` | `failed` |
| `sent`, `queued`, `sending` | `sent` |

---

### 3. `metadata` (JSONB avec infos supplémentaires)

**Contenu** :
```json
{
  "workspaceId": "01K9W29VR7A8Q9PV12R35NG429",
  "companyId": "01K3NAXD42A3YDWCW3X246BT04",
  "agentId": "01K9W2DZ0FPRHRBR3762ZNAD0G",
  "dealId": "4401",
  "fromPhoneNumber": "+33757598940",
  "num_segments": "2",
  "price_unit": "USD",
  "account_sid": "REDACTED_TWILIO_ACCOUNT_SID"
}
```

✅ **Utile pour** : Traçabilité, debugging, analytics avancés

---

## ❌ Informations Manquantes

### 1. `first_name` et `last_name` ❌

**Statut** : **NON DISPONIBLES** dans les payloads fournis
**Impact** : Champs optionnels dans la table, mais utiles pour analytics

**Solutions possibles** :

**Option A** : Les laisser NULL (acceptable)
```javascript
{
  "fieldId": "first_name",
  "fieldValue": null
},
{
  "fieldId": "last_name",
  "fieldValue": null
}
```

**Option B** : Récupérer depuis le deal (si dealId disponible)
- Ajouter une node **"Get Deal from Dipler/CRM"** AVANT l'insertion
- Récupérer contact.firstName et contact.lastName
- Mapper dans Supabase Insert

**Option C** : Parser depuis le contenu du SMS (peu fiable)
```javascript
// Dans le SMS : "Bonjour Aboubakar ! Je suis Louis..."
// Parser "Aboubakar" comme first_name
// PAS RECOMMANDÉ (peu fiable)
```

**Recommandation** : Option B (récupérer depuis le deal) OU Option A (laisser NULL)

---

### 2. `billed_cost` (Prix facturé au client) ⚠️ CRITIQUE

**Statut** : **MANQUANT** - Doit être récupéré depuis `agent_deployments.cost_per_sms`
**Impact** : **BLOQUANT** - Sans ce champ, impossible de calculer la marge

**Solution REQUISE** : Ajouter une node Supabase **AVANT** l'insertion

**Workflow à mettre en place** :

```
SetAgentData
    ↓
[NEW] Get Deployment Info ← AJOUTER CETTE NODE
    ↓
getSMSInfos
    ↓
Supabase Insert SMS
```

**Configuration node "Get Deployment Info"** :
```json
{
  "parameters": {
    "resource": "getRow",
    "tableId": "agent_deployments",
    "filter": {
      "fieldName": "id",
      "fieldValue": "={{ $('SetAgentData').item.json.deploymentId }}"
    }
  },
  "name": "GetDeployment"
}
```

**Puis dans Supabase Insert** :
```javascript
{
  "fieldId": "billed_cost",
  "fieldValue": "={{ $('GetDeployment').item.json.cost_per_sms || 0.07 }}"
}
```

⚠️ **Si `cost_per_sms` est NULL dans agent_deployments** : Utiliser une valeur par défaut (0.07€)

---

### 3. `message_type` (Type de SMS) 🟡

**Statut** : Valeur **hardcodée** à `'notification'` dans la config fournie
**Impact** : Acceptable, mais peut être amélioré

**Options** :
- **Actuel** : `"notification"` (hardcodé) ✅
- **Amélioration** : Détecter selon le contexte
  - Si lié à un appel → `"appointment_reminder"`
  - Si après un formulaire → `"notification"`
  - Si campagne marketing → `"marketing"`

**Solution** : Ajouter une variable dans SetAgentData
```javascript
{
  "fieldId": "message_type",
  "fieldValue": "={{ $('SetAgentData').item.json.smsType || 'notification' }}"
}
```

---

### 4. `call_id` (Lien vers un appel) 🟡

**Statut** : **NULL** (pas dans vos payloads)
**Impact** : Optionnel, mais utile pour tracker les SMS de follow-up

**Quand l'utiliser** :
- Si le SMS est envoyé **après un appel** (ex: confirmation RDV)
- Si vous avez l'ID de l'appel dans agent_calls

**Solution** : Si disponible dans SetAgentData, mapper :
```javascript
{
  "fieldId": "call_id",
  "fieldValue": "={{ $('SetAgentData').item.json.callId || null }}"
}
```

---

## 📊 Résumé : Checklist d'Implémentation

### ✅ Prêt à l'emploi
- [x] deployment_id
- [x] phone_number
- [x] message_content
- [x] provider_message_sid
- [x] provider_status
- [x] status (avec mapping)
- [x] sent_at
- [x] delivered_at (conditionnel)
- [x] failure_reason
- [x] provider_cost (avec conversion USD → EUR)
- [x] workflow_id
- [x] workflow_execution_id
- [x] metadata (JSONB)

### ⚠️ À ajouter AVANT production

1. **🔴 CRITIQUE** : Node "Get Deployment" pour récupérer `billed_cost`
   ```
   Sans ce champ, margin ne peut pas être calculé → Bloquant
   ```

2. **🟡 OPTIONNEL** : Récupérer first_name/last_name depuis deal
   ```
   Améliore les analytics, mais pas bloquant (peut être NULL)
   ```

3. **🟡 OPTIONNEL** : Améliorer detection de message_type
   ```
   Permet de différencier notification/reminder/marketing
   ```

4. **🟡 OPTIONNEL** : Mapper call_id si SMS de follow-up
   ```
   Permet de tracker SMS après appels
   ```

---

## 🔧 Workflow n8n Complet Recommandé

```
1. Trigger (Envoi SMS)
    ↓
2. SetAgentData (Set variables)
    ↓
3. GetDeployment (Supabase: Get agent_deployments) ← À AJOUTER
    ↓
4. SendSMS (Twilio: Send SMS)
    ↓
5. getSMSInfos (HTTP Request: Get SMS details from Twilio)
    ↓
6. Supabase Insert SMS (Insert dans agent_sms) ← Config fournie
    ↓
7. [Optionnel] Error Handler (Si insertion échoue)
```

---

## 💰 Alerte Importante : Coût vs Prix

**Exemple avec vos données** :

```
SMS envoyé : 2 segments (160+ caractères)

provider_cost (Twilio) : 0.1468€ (converti depuis -0.15960 USD)
billed_cost (client)   : 0.0700€ (prix fixe depuis deployment)
margin                 : 0.0700 - 0.1468 = -0.0768€

→ PERTE de 7.68 centimes ! ⚠️
```

**Actions recommandées** :
1. ✅ Configurer `cost_per_sms` à un prix plus élevé pour SMS longs (2+ segments)
2. ✅ OU limiter les SMS à 1 segment (160 chars)
3. ✅ OU ajouter une alerte si margin < 0

**Calcul pour être rentable** :
```
Pour un SMS à 2 segments coûtant 0.1468€ :
Prix minimum à facturer : 0.1468€ + marge (ex: 30%) = 0.19€
```

---

## 📝 Notes Techniques

### Taux de Conversion USD → EUR

**Actuel dans la config** : `0.92` (approximatif)

**Options** :
1. **Taux fixe** : Simple, mais imprécis si taux varie
2. **API de conversion** : Précis, mais ajoute une node HTTP
3. **Stocker en USD** : Convertir dans le dashboard (pas recommandé)

**Recommandation** : Garder taux fixe `0.92` SAUF si volumes très élevés (>10K SMS/mois)

---

### Gestion des Erreurs

**Si getSMSInfos échoue** :
- Twilio n'a pas encore les infos (délai)
- SMS SID invalide
- API Twilio en erreur

**Solution** : Ajouter un retry avec délai
```
getSMSInfos
    ↓
[IF] Error?
    YES → Wait 5 seconds → Retry (max 3x)
    NO → Continue to Supabase Insert
```

---

## 🎯 Prochaines Étapes

1. **Immédiat** : Ajouter node "GetDeployment" pour récupérer `cost_per_sms`
2. **Court terme** : Tester avec vos données réelles
3. **Moyen terme** : Ajouter récupération first_name/last_name depuis deal
4. **Long terme** : Améliorer détection message_type selon contexte

---

**Fichiers créés** :
- ✅ `SUPABASE_INSERT_SMS_CONFIG.json` - Config complète de la node
- ✅ `MAPPING_ANALYSIS.md` - Ce document d'analyse
