# Correction du Modèle de Pricing SMS

**Date**: 2025-11-13
**Statut**: ✅ Corrigé et testé en staging

---

## 🔴 Problème Identifié

Le modèle de pricing initial ne correspondait pas au business model réel de Voipia.

### ❌ Ancien Modèle (Incorrect)

**Structure** :
```
provider_cost (input) + voipia_margin (input) = billed_cost (calculé)
```

**Problème** :
- Marge **fixe** par SMS (ex: 0.02€)
- Prix facturé au client **variable** (dépend du coût provider)
- ❌ **Incompatible avec le modèle tarifaire client** : Les clients ont un prix fixe, pas une marge fixe

**Exemple** :
```
SMS France:
  provider_cost: 0.05€
  voipia_margin: 0.02€ (fixe)
  billed_cost: 0.07€ (calculé)

SMS USA:
  provider_cost: 0.065€
  voipia_margin: 0.02€ (fixe)
  billed_cost: 0.085€ (calculé)
```

⚠️ **Problème** : Le client paie un prix **différent** selon la destination, ce qui est **inacceptable**.

---

## ✅ Nouveau Modèle (Correct)

### Structure

```
billed_cost (input, FIXE) - provider_cost (input, VARIABLE) = margin (calculé)
```

**Avantages** :
- ✅ Prix **fixe** facturé au client (ex: 0.07€ par SMS, peu importe la destination)
- ✅ Coût provider **variable** (dépend de Twilio)
- ✅ Marge **calculée automatiquement** (peut être positive OU négative)
- ✅ Détection des SMS **non rentables** (margin < 0)

**Exemple** :
```
SMS France:
  billed_cost: 0.07€ (fixe, prix client)
  provider_cost: 0.0489€ (variable, Twilio)
  margin: +0.0211€ (profit ✅)

SMS USA:
  billed_cost: 0.07€ (fixe, prix client)
  provider_cost: 0.065€ (variable, Twilio)
  margin: +0.005€ (profit faible ⚠️)

SMS Satellite:
  billed_cost: 0.07€ (fixe, prix client)
  provider_cost: 0.85€ (variable, Twilio)
  margin: -0.78€ (PERTE ❌)
```

---

## 🔧 Changements Techniques

### Migration : `20251113_fix_sms_pricing_model_v2.sql`

**Modifications colonnes** :

| Ancienne colonne | Type ancien | Nouvelle colonne | Type nouveau |
|------------------|-------------|------------------|--------------|
| `voipia_margin` | NUMERIC input | ❌ **SUPPRIMÉE** | - |
| `billed_cost` | **GENERATED** | `billed_cost` | **INPUT** (normal column) |
| - | - | `margin` | **GENERATED** (billed - provider) |

**Formule** :
```sql
margin = COALESCE(billed_cost, 0) - COALESCE(provider_cost, 0)
```

---

### Vue `v_agent_sms_enriched`

**Changement** : Remplace `voipia_margin` par `margin`

```sql
-- Avant
SELECT ..., sms.provider_cost, sms.voipia_margin, sms.billed_cost, ...

-- Après
SELECT ..., sms.provider_cost, sms.billed_cost, sms.margin, ...
```

---

### Fonction `get_sms_metrics()`

**Changements KPI** :

| Ancien KPI | Nouveau KPI | Description |
|------------|-------------|-------------|
| `total_cost` | `total_revenue` | Somme des **billed_cost** (ce qu'on facture) |
| `total_provider_cost` | `total_cost` | Somme des **provider_cost** (ce qu'on paie) |
| `total_margin` | `total_margin` | Somme des **margin** (profit/loss) |
| `margin_percentage` | `margin_percentage` | (margin / revenue) × 100 |
| - | `avg_revenue_per_sms` | Moyenne du prix facturé |
| `avg_cost_per_sms` | `avg_cost_per_sms` | Moyenne du coût réel |
| - | `avg_margin_per_sms` | Moyenne de la marge |

**Structure retournée** :
```json
{
  "current_period": {
    "total_revenue": 106.61,     // Ce qu'on facture (NEW)
    "total_cost": 76.15,         // Ce qu'on paie (RENAMED)
    "total_margin": 30.46,       // Profit (NEW)
    "margin_percentage": 28.57,  // Rentabilité (NEW)
    "avg_revenue_per_sms": 0.07, // Prix moyen facturé (NEW)
    "avg_cost_per_sms": 0.05,    // Coût moyen réel (NEW)
    "avg_margin_per_sms": 0.02   // Marge moyenne (NEW)
  }
}
```

---

## 🧪 Tests en Staging

### Scénarios Testés

**4 SMS de test insérés** :

| Scénario | Phone | provider_cost | billed_cost | margin | Résultat |
|----------|-------|---------------|-------------|--------|----------|
| 1. France standard | +33612... | 0.0489€ | 0.0700€ | +0.0211€ | ✅ GOOD MARGIN (30%) |
| 2. USA | +1234... | 0.0650€ | 0.0700€ | +0.0050€ | ⚠️ LOW MARGIN (7%) |
| 3. Satellite | +882... | 0.8500€ | 0.0700€ | **-0.7800€** | ❌ LOSS (-1114%) |
| 4. Break-even | +33687... | 0.0700€ | 0.0700€ | 0.0000€ | 🟡 BREAK-EVEN (0%) |

**Résultats get_sms_metrics()** :
```json
{
  "total_sms": 4,
  "total_revenue": 0.28,      // 4 × 0.07€
  "total_cost": 1.03,         // 0.0489 + 0.065 + 0.85 + 0.07
  "total_margin": -0.75,      // ❌ PERTE globale (SMS satellite)
  "margin_percentage": -269   // Marge négative!
}
```

✅ **Le système détecte correctement la perte causée par le SMS satellite.**

---

## 📋 Impact sur n8n

### Changements Requis

**1. Node "Calculate Costs"** (AVANT Twilio)

```javascript
// AVANT (incorrect)
const providerCost = 0.05;
const voipiaMargin = 0.02;

// APRÈS (correct)
const deployment = $('Get Deployment').item.json;
const billedCost = deployment.cost_per_sms || 0.07; // Prix fixe client
```

**2. Node "Supabase Insert"** (APRÈS Twilio)

```javascript
{
  "data": {
    // AVANT (incorrect)
    "provider_cost": 0.05,
    "voipia_margin": 0.02,
    // billed_cost auto-calculé

    // APRÈS (correct)
    "provider_cost": "{{ $('Twilio').item.json.price * -1 }}", // Coût réel
    "billed_cost": "{{ $('Calculate Costs').item.json.billedCost }}", // Prix fixe
    // margin auto-calculé par DB
  }
}
```

**3. Récupérer coût Twilio**

Twilio retourne le coût dans `price` (valeur **négative**) :

```json
{
  "sid": "SMxxxx",
  "to": "+33612345678",
  "price": "-0.0489",  // ← Négatif! Multiplier par -1
  "price_unit": "EUR"
}
```

n8n :
```javascript
const providerCost = Math.abs($('Twilio').item.json.price);
// ou
const providerCost = $('Twilio').item.json.price * -1;
```

---

## ⚠️ Actions Requises

### Avant Production

1. **✅ Migration appliquée en staging** (testé)
2. **⚠️ Vérifier les 4 migrations dans l'ordre** :
   - `20251113_create_agent_sms_table.sql`
   - `20251113_sms_rls_policies.sql`
   - `20251113_sms_analytics.sql`
   - **`20251113_fix_sms_pricing_model_v2.sql`** ← CRITIQUE

3. **⚠️ Configurer `cost_per_sms` dans deployments** :
```sql
-- Exemple : configurer prix SMS pour tous les déploiements Louis
UPDATE agent_deployments
SET cost_per_sms = 0.0700 -- 7 centimes par SMS
WHERE agent_type_id IN (
    SELECT id FROM agent_types WHERE name = 'louis'
);
```

4. **⚠️ Modifier workflows n8n existants** :
   - Supprimer calcul de `voipia_margin`
   - Ajouter récupération de `deployment.cost_per_sms`
   - Récupérer coût réel depuis Twilio response
   - Ne plus passer `voipia_margin` dans INSERT (colonne n'existe plus)

---

### Après Production

1. **Monitoring** :
```sql
-- Dashboard: SMS non rentables
SELECT
    COUNT(*) FILTER (WHERE margin < 0) AS loss_sms,
    COUNT(*) AS total_sms,
    ROUND(
        COUNT(*) FILTER (WHERE margin < 0)::NUMERIC / COUNT(*) * 100,
        2
    ) AS loss_percentage,
    SUM(margin) AS total_margin
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '7 days';
```

2. **Alertes** :
   - Si `loss_percentage` > 5% → Investiguer destinations
   - Si `total_margin` < 0 → Ajuster pricing ou bloquer destinations chères

3. **Ajustements** :
   - Analyser destinations avec `provider_cost` élevé
   - Configurer blocklist Twilio pour satellites/premium
   - Ajuster `cost_per_sms` si nécessaire

---

## 📚 Documentation

**Documents mis à jour** :

1. ✅ **`PRICING_MODEL.md`** - Guide complet du nouveau modèle
2. ✅ **`README.md`** - Checklist mise à jour
3. ✅ **`PRICING_CORRECTION.md`** - Ce document (changelog)
4. ⚠️ **`N8N_INTEGRATION.md`** - À mettre à jour (section Calculate Costs)
5. ⚠️ **`SCHEMA.md`** - À mettre à jour (colonnes margin/billed_cost)

---

## 🎯 Résumé

### Ce qui a changé

| Élément | Ancien | Nouveau |
|---------|--------|---------|
| **Colonnes** | `voipia_margin` (input) + `billed_cost` (calculated) | `billed_cost` (input) + `margin` (calculated) |
| **Philosophie** | Marge fixe → prix variable | Prix fixe → marge variable ✅ |
| **KPI** | `total_cost`, `total_margin` | `total_revenue`, `total_cost`, `total_margin` |
| **n8n** | Passer `voipia_margin` | Passer `billed_cost` depuis deployment |

### Pourquoi ce changement

✅ **Aligne le modèle technique avec le business model réel**
✅ **Prix fixe pour le client** (prévisibilité)
✅ **Détection des SMS non rentables** (alertes)
✅ **Transparence sur la rentabilité** (dashboard)

---

**Statut** : ✅ **Corrigé et validé en staging**
**Prochaine étape** : Déploiement production + modification workflows n8n
