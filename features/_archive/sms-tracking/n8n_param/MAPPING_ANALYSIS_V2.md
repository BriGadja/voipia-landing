# Analyse du Mapping n8n → agent_sms (V2)

**Date** : 2025-11-13
**Version** : 2.0 - Facturation par segment + Conversion USD/EUR

---

## 🎯 Nouveautés de la V2

### ✅ Facturation par Segment
- **Problème V1** : Prix fixe par SMS (0.07€) quel que soit le nombre de segments
- **Solution V2** : `billed_cost = cost_per_sms × num_segments`
- **Avantage** : Facturation juste basée sur la longueur du message

### ✅ Conversion USD → EUR Automatique
- **Problème V1** : Conversion hardcodée dans n8n (`price * 0.92`)
- **Solution V2** : Stockage du prix USD + taux de change, calcul en DB
- **Avantage** : Traçabilité du taux de change par SMS pour historiques précis

### ✅ Colonnes Calculées Automatiques
- **`provider_cost`** = ABS(provider_cost_usd) × exchange_rate_usd_eur
- **`billed_cost`** = cost_per_sms × num_segments
- **`margin`** = billed_cost - provider_cost
- **Avantage** : Logique centralisée en DB, n8n simplifié

---

## ✅ Champs Correctement Mappés

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

## 🆕 Nouveaux Champs (V2)

### 1. `num_segments` (Nombre de segments SMS)

**Source** : `getSMSInfos.num_segments`
**Mapping n8n** :
```javascript
{
  "fieldId": "num_segments",
  "fieldValue": "={{ parseInt($('getSMSInfos').item.json.num_segments) || 1 }}"
}
```

**Explication** :
- 1 segment = 160 caractères maximum
- 2 segments = 161-306 caractères (1 SMS = 153 chars, 2e SMS = 153 chars)
- 3 segments = 307-459 caractères
- ...

**Impact sur facturation** :
```
Exemple : SMS de 180 caractères (2 segments)
- num_segments = 2
- cost_per_sms = 0.07€
- billed_cost = 0.07 × 2 = 0.14€
```

---

### 2. `cost_per_sms` (Prix par segment)

**Source** : `GetDeployment.cost_per_sms`
**Mapping n8n** :
```javascript
{
  "fieldId": "cost_per_sms",
  "fieldValue": "={{ $('GetDeployment').item.json.cost_per_sms || 0.07 }}"
}
```

**⚠️ IMPORTANT** : Nécessite d'ajouter la node **"GetDeployment"** AVANT l'insertion Supabase :

```
Workflow recommandé :
SetAgentData → [GetDeployment] → getSMSInfos → Supabase Insert
```

**Configuration node "GetDeployment"** :
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

**Valeur par défaut** : Si `cost_per_sms` n'est pas configuré dans le deployment, utilise 0.07€

---

### 3. `provider_cost_usd` (Coût Twilio en USD)

**Source** : `getSMSInfos.price`
**Mapping n8n** :
```javascript
{
  "fieldId": "provider_cost_usd",
  "fieldValue": "={{ parseFloat($('getSMSInfos').item.json.price) }}"
}
```

**Explication** :
- Twilio envoie le prix en **USD négatif** : `-0.15960`
- On stocke la valeur brute (négative) dans `provider_cost_usd`
- La conversion en EUR positif est faite par Postgres avec la colonne GENERATED `provider_cost`

**Pourquoi stocker le prix USD ?**
- Traçabilité : on garde l'information d'origine de Twilio
- Historique précis : si on change de taux de change, on peut recalculer
- Audit : vérification facile avec les factures Twilio

---

### 4. `exchange_rate_usd_eur` (Taux de Change)

**Source** : Hardcodé ou dynamique
**Mapping n8n (simple)** :
```javascript
{
  "fieldId": "exchange_rate_usd_eur",
  "fieldValue": "0.92"
}
```

**Mapping n8n (avancé - taux dynamique)** :
```javascript
{
  "fieldId": "exchange_rate_usd_eur",
  "fieldValue": "={{ $('GetExchangeRate').item.json.rates.EUR || 0.92 }}"
}
```

**Options d'implémentation** :

**Option A : Taux fixe (actuel)** ✅ SIMPLE
- Hardcodé à `0.92` dans n8n
- Acceptable si volumes < 10K SMS/mois
- Facile à maintenir

**Option B : Taux dynamique quotidien** 🔧 PRÉCIS
- Ajouter une node HTTP Request vers API de taux de change (ex: `api.exchangerate.host`)
- Stocker le taux du jour dans une variable
- Utiliser ce taux pour tous les SMS de la journée
- Recommandé si volumes > 10K SMS/mois

**Option C : Taux en temps réel** ⚡ MAXIMUM
- Appel API pour chaque SMS
- Très précis mais ajoute latence
- Coût API à considérer
- Recommandé uniquement si marges très faibles

**Recommandation** : Commencer avec Option A (taux fixe), upgrader vers Option B si nécessaire

---

## 🔄 Colonnes Calculées Automatiquement

Ces colonnes sont **GENERATED** par PostgreSQL, vous **NE DEVEZ PAS** les envoyer depuis n8n :

### `provider_cost` (Coût Twilio en EUR)

**Formule PostgreSQL** :
```sql
GENERATED ALWAYS AS (
  ROUND(ABS(COALESCE(provider_cost_usd, 0)) * COALESCE(exchange_rate_usd_eur, 0.92), 4)
) STORED
```

**Exemple** :
```
provider_cost_usd = -0.15960
exchange_rate_usd_eur = 0.92
provider_cost = ABS(-0.15960) × 0.92 = 0.1468€
```

---

### `billed_cost` (Prix facturé au client)

**Formule PostgreSQL** :
```sql
GENERATED ALWAYS AS (
  ROUND(COALESCE(cost_per_sms, 0) * COALESCE(num_segments, 1), 4)
) STORED
```

**Exemple** :
```
num_segments = 2
cost_per_sms = 0.07€
billed_cost = 0.07 × 2 = 0.14€
```

---

### `margin` (Marge Voipia)

**Formule PostgreSQL** :
```sql
GENERATED ALWAYS AS (
  ROUND(
    (COALESCE(cost_per_sms, 0) * COALESCE(num_segments, 1)) -
    (ABS(COALESCE(provider_cost_usd, 0)) * COALESCE(exchange_rate_usd_eur, 0.92)),
    4
  )
) STORED
```

**Exemple** :
```
billed_cost = 0.14€
provider_cost = 0.1468€
margin = 0.14 - 0.1468 = -0.0068€ (PERTE !)
```

---

## 💰 Analyse de Rentabilité : Avant/Après

### Exemple avec vos données (SMS 2 segments)

**V1 (Prix fixe)** :
```
Message : 180 caractères (2 segments Twilio)
Provider cost (Twilio) : 0.1468€
Billed cost (fixe)     : 0.07€
Margin                 : 0.07 - 0.1468 = -0.0768€
→ PERTE de 7.68 centimes ❌
```

**V2 (Prix par segment)** :
```
Message : 180 caractères (2 segments Twilio)
Provider cost (Twilio) : 0.1468€
Billed cost (segment)  : 0.07 × 2 = 0.14€
Margin                 : 0.14 - 0.1468 = -0.0068€
→ PERTE de 0.68 centime ⚠️
```

**Scénarios de Rentabilité** :

| Segments | Coût Twilio | Facturé V1 | Marge V1 | Facturé V2 | Marge V2 |
|----------|-------------|------------|----------|------------|----------|
| 1        | ~0.073€     | 0.07€      | **-0.003€** ⚠️ | 0.07€ | **-0.003€** ⚠️ |
| 2        | ~0.147€     | 0.07€      | **-0.077€** ❌ | 0.14€ | **-0.007€** ⚠️ |
| 3        | ~0.220€     | 0.07€      | **-0.150€** ❌ | 0.21€ | **-0.010€** ⚠️ |

**Conclusion** :
- ⚠️ **Attention** : Avec `cost_per_sms = 0.07€`, vous êtes en **PERTE sur tous les SMS**
- Le coût Twilio France est ~0.073€ par segment
- **Prix minimum recommandé** : `cost_per_sms = 0.08€` (marge ~9%)
- **Prix avec marge confortable** : `cost_per_sms = 0.10€` (marge ~27%)

---

## 📊 Calcul du Prix Optimal

**Pour être rentable sur SMS France** :

```
Coût unitaire Twilio : 0.073€/segment (prix 2025)
Marge souhaitée      : 30%
Prix optimal         : 0.073 ÷ 0.70 = 0.104€/segment

Recommandation : cost_per_sms = 0.10€
```

**Simulation avec 0.10€/segment** :

| Segments | Coût Twilio | Facturé | Marge | Marge % |
|----------|-------------|---------|-------|---------|
| 1        | 0.073€      | 0.10€   | **+0.027€** ✅ | **27%** |
| 2        | 0.147€      | 0.20€   | **+0.053€** ✅ | **27%** |
| 3        | 0.220€      | 0.30€   | **+0.080€** ✅ | **27%** |

---

## 🔧 Workflow n8n Complet (V2)

```
1. Trigger (Webhook / Schedule)
    ↓
2. SetAgentData (Variables: deploymentId, phone, etc.)
    ↓
3. GetDeployment (Supabase: Récupère cost_per_sms) ← NOUVEAU
    ↓
4. SendSMS (Twilio: Envoie le SMS)
    ↓
5. getSMSInfos (HTTP Request: Récupère détails Twilio avec price, num_segments)
    ↓
6. Supabase Insert SMS (Config fournie - V2)
    ↓ (Postgres calcule automatiquement provider_cost, billed_cost, margin)
7. [Optionnel] Error Handler
```

---

## 📝 Configuration Complète node GetDeployment

**Node Type** : Supabase
**Operation** : Get Row
**Table** : agent_deployments

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
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "position": [800, 300],
  "id": "get-deployment",
  "name": "GetDeployment",
  "credentials": {
    "supabaseApi": {
      "id": "XsVol30xDDqWJuLk",
      "name": "Voipia - Supabase"
    }
  }
}
```

**Output attendu** :
```json
{
  "id": "cb776a7a-0857-4304-817d-9a4242ae903d",
  "name": "Louis - Norloc",
  "cost_per_sms": 0.10,
  "client_id": "...",
  "agent_type_id": "..."
}
```

---

## ✅ Checklist d'Implémentation V2

### Migration Base de Données
- [x] Créer migration `20251113_add_segments_and_usd_conversion.sql`
- [ ] Appliquer migration en production
- [ ] Vérifier colonnes GENERATED fonctionnent
- [ ] Tester avec données d'exemple

### Configuration agent_deployments
- [ ] Ajouter colonne `cost_per_sms NUMERIC(10,4)` si n'existe pas
- [ ] Configurer `cost_per_sms = 0.10€` pour tous les deployments actifs
- [ ] Vérifier que tous les deployments ont une valeur (pas de NULL)

### Workflow n8n
- [ ] Ajouter node "GetDeployment" entre SetAgentData et SendSMS
- [ ] Mettre à jour node "Supabase Insert SMS" avec config V2
- [ ] Retirer calculs manuels de `provider_cost` et `billed_cost`
- [ ] Ajouter mapping `num_segments`, `cost_per_sms`, `provider_cost_usd`, `exchange_rate_usd_eur`
- [ ] Tester workflow avec SMS de différentes longueurs (1, 2, 3 segments)

### Tests de Validation
- [ ] Envoyer SMS 1 segment (< 160 chars) → Vérifier margin positive
- [ ] Envoyer SMS 2 segments (160-306 chars) → Vérifier billed_cost = cost_per_sms × 2
- [ ] Envoyer SMS 3 segments (306-459 chars) → Vérifier margin
- [ ] Vérifier conversion USD → EUR correcte
- [ ] Vérifier metadata JSONB contient num_segments

### Monitoring
- [ ] Query pour identifier SMS à marge négative
- [ ] Alerte si margin < 0 sur plus de 5% des SMS
- [ ] Dashboard KPI : Marge moyenne par client
- [ ] Rapport mensuel : Rentabilité par deployment

---

## 📊 Queries Utiles

### Identifier SMS non rentables
```sql
SELECT
  deployment_name,
  client_name,
  num_segments,
  provider_cost,
  billed_cost,
  margin,
  margin_percentage
FROM v_agent_sms_enriched
WHERE margin < 0
ORDER BY margin ASC
LIMIT 20;
```

### Marge moyenne par deployment
```sql
SELECT
  deployment_name,
  client_name,
  COUNT(*) AS total_sms,
  AVG(num_segments) AS avg_segments,
  SUM(billed_cost) AS total_revenue,
  SUM(provider_cost) AS total_cost,
  SUM(margin) AS total_margin,
  ROUND(AVG(margin_percentage), 2) AS avg_margin_pct
FROM v_agent_sms_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY deployment_name, client_name
ORDER BY total_margin DESC;
```

### Alertes marges négatives
```sql
SELECT
  deployment_name,
  COUNT(*) FILTER (WHERE margin < 0) AS unprofitable_sms,
  COUNT(*) AS total_sms,
  ROUND((COUNT(*) FILTER (WHERE margin < 0)::NUMERIC / COUNT(*)) * 100, 2) AS pct_unprofitable
FROM v_agent_sms_enriched
WHERE sent_at >= NOW() - INTERVAL '7 days'
GROUP BY deployment_name
HAVING COUNT(*) FILTER (WHERE margin < 0) > 0
ORDER BY pct_unprofitable DESC;
```

---

## 🎯 Prochaines Étapes

1. **Immédiat** :
   - Appliquer migration `20251113_add_segments_and_usd_conversion.sql`
   - Configurer `cost_per_sms = 0.10€` dans agent_deployments

2. **Court terme** (cette semaine) :
   - Ajouter node "GetDeployment" dans workflow n8n
   - Mettre à jour config Supabase Insert avec V2
   - Tester avec SMS réels

3. **Moyen terme** (ce mois) :
   - Créer dashboard de rentabilité SMS
   - Mettre en place alertes marges négatives
   - Optimiser prix par client si besoin

4. **Long terme** (trimestre) :
   - Implémenter taux de change dynamique (si volumes > 10K/mois)
   - Analyse prédictive des coûts
   - Tarifs différenciés par destination

---

## 📚 Documentation Complémentaire

- **Schema complet** : `features/sms-tracking/documentation/SCHEMA.md`
- **Intégration n8n** : `features/sms-tracking/documentation/N8N_INTEGRATION.md`
- **Modèle de pricing** : `features/sms-tracking/PRICING_MODEL.md`
- **Config n8n** : `features/sms-tracking/n8n_param/SUPABASE_INSERT_SMS_CONFIG.json`

---

**Version** : 2.0
**Dernière mise à jour** : 2025-11-13
**Auteur** : Claude (Voipia SMS Tracking)
