# Modèle de Pricing SMS - Documentation

**Date**: 2025-11-13
**Version**: 2.0 (Corrigée)

---

## 🎯 Modèle de Pricing (CORRECT)

### Philosophie

Le pricing SMS suit le modèle **"Prix fixe facturé, marge calculée"** :

```
Prix fixe client (billed_cost) - Coût variable fournisseur (provider_cost) = Marge (margin)
```

**Pourquoi ce modèle ?**
- ✅ **Prévisibilité pour le client** : Prix fixe par SMS (ex: 0.07€), facile à budgéter
- ✅ **Flexibilité opérationnelle** : Absorbe les variations de coûts Twilio
- ✅ **Visibilité sur rentabilité** : Marge calculée automatiquement, peut être positive OU négative
- ✅ **Alertes possibles** : Détection des SMS non rentables (destinations chères)

---

## 📊 Structure des Colonnes

### 1. `provider_cost` (INPUT - VARIABLE)

**Type** : `NUMERIC(10, 4)`
**Source** : Twilio (coût réel par SMS)
**Nature** : **VARIABLE** selon :
- Pays de destination
- Longueur du message (1 segment = 160 chars, 2 segments = 306+ chars)
- Type de numéro (mobile, landline, premium)
- Opérateur télécom

**Exemples de coûts Twilio** :
- 🇫🇷 France mobile : ~0.0489€
- 🇺🇸 USA mobile : ~0.0650€
- 🇧🇷 Brésil mobile : ~0.1200€
- 🛰️ Satellite/Premium : 0.50€ - 2.00€

**Important** : À récupérer depuis Twilio après envoi (via API response ou webhooks)

---

### 2. `billed_cost` (INPUT - FIXE)

**Type** : `NUMERIC(10, 4)` (colonne normale, PAS GENERATED)
**Source** : `agent_deployments.cost_per_sms` (configuré par client)
**Nature** : **FIXE** - Prix facturé au client

**Configuration** :
```sql
-- Configurer le prix SMS pour un deployment
UPDATE agent_deployments
SET cost_per_sms = 0.0700 -- 7 centimes par SMS
WHERE id = 'deployment-uuid';
```

**Workflow n8n** :
```javascript
// Lors de l'envoi SMS, copier le prix depuis deployment
const deployment = $('Get Deployment').item.json;
const billedCost = deployment.cost_per_sms || 0.07; // Default 7 centimes
```

**Stratégie de pricing** :
- **Basique** : 0.05€ - 0.07€ (destinations standards)
- **Premium** : 0.10€ - 0.15€ (destinations multiples, volume faible)
- **Enterprise** : Négocié selon volume

---

### 3. `margin` (OUTPUT - CALCULÉ)

**Type** : `NUMERIC(10, 4) GENERATED ALWAYS AS (billed_cost - provider_cost) STORED`
**Nature** : **AUTO-CALCULÉ** par PostgreSQL
**Lecture seule** : Impossible à modifier manuellement

**Interprétation** :
- ✅ **margin > 0** : Profitable (bon!)
- ⚠️ **margin < 0** : Perte (attention!)
- 🟡 **margin = 0** : Break-even

**Cas d'usage** :
```sql
-- Trouver les SMS non rentables
SELECT
    phone_number,
    provider_cost,
    billed_cost,
    margin,
    CONCAT(ROUND((margin / billed_cost) * 100, 2), '%') AS margin_pct
FROM agent_sms
WHERE margin < 0
ORDER BY margin ASC
LIMIT 10;
```

---

## 🔢 Exemples Concrets

### Exemple 1 : SMS France Standard (Rentable ✅)

```
provider_cost = 0.0489€  (coût Twilio France)
billed_cost   = 0.0700€  (prix facturé client)
margin        = 0.0211€  (bénéfice)
margin_%      = 30.14%   (marge bénéficiaire)
```

**Verdict** : ✅ SMS rentable, marge correcte

---

### Exemple 2 : SMS USA (Marge faible ⚠️)

```
provider_cost = 0.0650€  (coût Twilio USA)
billed_cost   = 0.0700€  (prix facturé client)
margin        = 0.0050€  (bénéfice faible)
margin_%      = 7.14%    (marge réduite)
```

**Verdict** : ⚠️ SMS rentable mais marge très faible, envisager d'augmenter le prix

---

### Exemple 3 : SMS Satellite (PERTE ❌)

```
provider_cost = 0.8500€  (coût Twilio satellite)
billed_cost   = 0.0700€  (prix facturé client)
margin        = -0.7800€ (perte!)
margin_%      = -1114%   (perte massive)
```

**Verdict** : ❌ SMS EN PERTE ! Le coût dépasse largement le prix facturé

**Solutions** :
- Bloquer les destinations satellites dans Twilio
- Augmenter `cost_per_sms` pour les déploiements concernés
- Configurer des alertes pour `margin < 0`

---

### Exemple 4 : SMS Break-even

```
provider_cost = 0.0700€  (coût = prix)
billed_cost   = 0.0700€  (prix facturé client)
margin        = 0.0000€  (ni gain ni perte)
margin_%      = 0%
```

**Verdict** : 🟡 Break-even, pas de marge bénéficiaire

---

## 📈 Métriques KPI (Nouveau Modèle)

La fonction `get_sms_metrics()` retourne maintenant :

### Current Period

```json
{
  "current_period": {
    // Volume
    "total_sms": 1523,
    "delivered_sms": 1489,

    // Finances (NOUVEAU)
    "total_revenue": 106.61,      // Somme des billed_cost
    "total_cost": 76.15,          // Somme des provider_cost
    "total_margin": 30.46,        // Somme des margin (revenue - cost)
    "margin_percentage": 28.57,   // (margin / revenue) * 100

    // Moyennes (NOUVEAU)
    "avg_revenue_per_sms": 0.0700,  // Moyenne du prix facturé
    "avg_cost_per_sms": 0.0500,     // Moyenne du coût réel
    "avg_margin_per_sms": 0.0200,   // Moyenne de la marge

    // Par type de message
    "by_message_type": [
      {
        "message_type": "appointment_reminder",
        "count": 789,
        "revenue": 55.23,       // NOUVEAU
        "margin": 15.78,        // NOUVEAU
        "delivery_rate": 97.85
      }
    ]
  }
}
```

---

## 🚨 Alertes & Monitoring

### Alertes Critiques

**1. Marge négative globale**
```sql
-- Alert si marge totale négative sur 24h
SELECT
    SUM(margin) AS total_margin,
    COUNT(*) FILTER (WHERE margin < 0) AS loss_sms,
    COUNT(*) AS total_sms
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '24 hours'
HAVING SUM(margin) < 0;
```

**Action** : Investiguer les destinations coûteuses, ajuster pricing

---

**2. Taux de SMS non rentables élevé**
```sql
-- Alert si > 5% des SMS sont en perte
SELECT
    COUNT(*) FILTER (WHERE margin < 0)::FLOAT / COUNT(*) * 100 AS loss_rate
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '7 days'
HAVING COUNT(*) FILTER (WHERE margin < 0)::FLOAT / COUNT(*) * 100 > 5;
```

**Action** : Revoir stratégie de pricing ou filtrage destinations

---

**3. Destinations satellites/premium**
```sql
-- Identifier SMS avec coût anormalement élevé
SELECT
    phone_number,
    provider_cost,
    billed_cost,
    margin,
    sent_at
FROM agent_sms
WHERE provider_cost > 0.20 -- Seuil : 20 centimes
ORDER BY provider_cost DESC
LIMIT 20;
```

**Action** : Bloquer ces destinations dans Twilio ou ajuster pricing

---

## 🛠️ Configuration n8n

### Node "Calculate Costs" (AVANT envoi Twilio)

```javascript
// Récupérer le prix configuré pour ce deployment
const deployment = $('Get Deployment Info').first().json;
const billedCost = deployment.cost_per_sms || 0.07; // Default 7 centimes

return {
  billed_cost: billedCost,
  deployment_name: deployment.name
};
```

### Node "Supabase Insert" (APRÈS envoi Twilio)

```javascript
{
  "operation": "insert",
  "table": "agent_sms",
  "data": {
    "deployment_id": "{{ $('Get Deployment').item.json.id }}",
    "phone_number": "{{ $('Twilio').item.json.to }}",
    "message_content": "{{ $('Twilio').item.json.body }}",
    "sent_at": "{{ $('Twilio').item.json.date_created }}",

    // IMPORTANT: Récupérer coût réel depuis Twilio
    "provider_cost": "{{ $('Twilio').item.json.price * -1 }}",
    // Note: Twilio retourne price en négatif (-0.0489), donc *-1

    // Prix fixe depuis deployment
    "billed_cost": "{{ $('Calculate Costs').item.json.billed_cost }}",

    // margin sera auto-calculé par PostgreSQL

    "provider_message_sid": "{{ $('Twilio').item.json.sid }}",
    "workflow_id": "{{ $workflow.id }}"
  }
}
```

---

## 📋 Comparaison Ancien vs Nouveau Modèle

### ❌ ANCIEN MODÈLE (Incorrect)

```
Colonnes:
- provider_cost (input)
- voipia_margin (input, FIXE par SMS)
- billed_cost (GENERATED = provider + margin)

Problème: Marge fixe par SMS ne reflète pas le business model réel
```

### ✅ NOUVEAU MODÈLE (Correct)

```
Colonnes:
- provider_cost (input, VARIABLE)
- billed_cost (input, FIXE)
- margin (GENERATED = billed - provider)

Avantage: Prix fixe client + marge variable qui reflète la réalité des coûts
```

---

## 🎓 Best Practices

### 1. Pricing par Volume

Configurez `cost_per_sms` selon le volume client :

| Volume mensuel | Prix recommandé | Marge visée |
|----------------|-----------------|-------------|
| < 1000 SMS     | 0.10€ - 0.15€   | 50-80%      |
| 1000 - 10000   | 0.07€ - 0.10€   | 30-50%      |
| > 10000 SMS    | 0.05€ - 0.07€   | 20-30%      |

### 2. Monitoring Destinations

- ✅ Monitorer les destinations avec `provider_cost` élevé
- ✅ Envisager blocklist Twilio pour satellites/premium
- ✅ Négocier tarifs Twilio si volumes élevés

### 3. Ajustement Dynamique

```sql
-- Analyser marge moyenne par deployment
SELECT
    ad.name AS deployment,
    COUNT(*) AS total_sms,
    ROUND(AVG(sms.margin), 4) AS avg_margin,
    ROUND(AVG(sms.margin) / NULLIF(AVG(sms.billed_cost), 0) * 100, 2) AS avg_margin_pct
FROM agent_sms sms
JOIN agent_deployments ad ON sms.deployment_id = ad.id
WHERE sms.sent_at >= NOW() - INTERVAL '30 days'
GROUP BY ad.name
ORDER BY avg_margin_pct ASC;
```

Si marge < 15%, augmenter `cost_per_sms` pour ce deployment.

---

## 🔄 Migration depuis Ancien Modèle

Si vous aviez déjà des données avec l'ancien modèle :

```sql
-- Script de migration des données existantes
UPDATE agent_sms
SET billed_cost = provider_cost + COALESCE(voipia_margin, 0)
WHERE billed_cost IS NULL;

-- Vérifier
SELECT
    COUNT(*) AS migrated_sms,
    AVG(margin) AS avg_new_margin
FROM agent_sms;
```

**Note** : La colonne `voipia_margin` a été supprimée, remplacée par `margin` (auto-calculé).

---

## 📞 Support

**Questions sur le pricing** :
- Analyser les métriques via `get_sms_metrics()`
- Monitorer les SMS avec `margin < 0`
- Ajuster `agent_deployments.cost_per_sms` si nécessaire

**Références** :
- [Twilio SMS Pricing](https://www.twilio.com/sms/pricing)
- [N8N Integration Guide](./documentation/N8N_INTEGRATION.md)
- [Schema Reference](./documentation/SCHEMA.md)

---

**Version** : 2.0 (Modèle corrigé)
**Auteur** : Claude (SMS Tracking Feature)
