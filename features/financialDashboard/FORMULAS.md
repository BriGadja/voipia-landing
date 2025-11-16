# 🧮 Formules de Calcul - Dashboard Financier

> **Documentation complète des formules et calculs financiers**

## 📐 Formules de Base

### 1. Revenue Total
Le revenue total combine toutes les sources de revenus Voipia :

```
Revenue Total = Call Revenue + SMS Revenue + Email Revenue + Leasing Revenue
```

**Détail par source** :
- **Call Revenue** : Facturation basée sur la durée des appels
- **SMS Revenue** : `billed_cost` (coût facturé au client avec markup)
- **Email Revenue** : `billed_cost` (coût facturé au client avec markup)
- **Leasing Revenue** : Abonnement mensuel pro-raté par jour

---

### 2. Call Revenue

```
Call Revenue = SUM(duration_seconds / 60 × deployment.cost_per_min)
```

**Exemple** :
- Appel de 120 secondes (2 minutes)
- cost_per_min = 0.27€
- Call Revenue = (120 / 60) × 0.27 = 2 × 0.27 = **0.54€**

**Notes** :
- Calculé pour chaque appel individuellement
- Sommé au niveau deployment/jour

---

### 3. SMS Revenue

```
SMS Revenue = SUM(agent_sms.billed_cost)
```

**Structure de coût SMS** :
- `provider_cost` : Coût réel du provider (Twilio/etc.)
- `billed_cost` : Coût facturé au client (avec markup Voipia)
- `margin` : `billed_cost - provider_cost`

**Exemple** :
- Provider cost = 0.05€
- Markup = 40%
- Billed cost = 0.05€ × 1.40 = **0.07€**
- Margin = 0.07€ - 0.05€ = **0.02€**

---

### 4. Email Revenue

```
Email Revenue = SUM(agent_emails.billed_cost)
```

**Structure identique aux SMS** :
- `provider_cost` : Coût réel du provider
- `billed_cost` : Coût facturé au client
- `margin` : `billed_cost - provider_cost`

---

### 5. Leasing Revenue (Pro-rated)

Le leasing est un abonnement mensuel fixe, pro-raté par jour :

```
Leasing Revenue Daily = (deployment.leasing / 30) × nombre_de_jours
```

**Exemple** :
- Leasing mensuel = 190€
- Leasing par jour = 190€ / 30 = **6.33€**
- Pour 7 jours = 6.33€ × 7 = **44.33€**

**Pourquoi pro-rater ?**
- Permet un suivi précis jour par jour
- Facilite la comparaison de périodes de durées différentes
- Simplifie l'agrégation dans la vue

**Notes importantes** :
- Le leasing est divisé par 30 (convention, pas le nombre exact de jours du mois)
- Pas de coût provider associé au leasing (marge = 100%)

---

## 💰 Formules de Marge

### 6. Coûts Provider Total

```
Coûts Provider = Call Provider Cost + SMS Provider Cost + Email Provider Cost
```

**Détail par source** :
- **Call Provider Cost** : `agent_calls.total_cost` (coût VAPI en EUR)
- **SMS Provider Cost** : `agent_sms.provider_cost` (coût Twilio/etc.)
- **Email Provider Cost** : `agent_emails.provider_cost` (coût SendGrid/etc.)

**⚠️ Important** :
- Le leasing n'a **pas** de coût provider (c'est une location d'agent)
- Les coûts provider sont en EUR (déjà convertis si nécessaire)

---

### 7. Marge Totale

```
Marge (€) = Revenue Total - Coûts Provider Total
```

**Exemple complet** :
```
Revenue Total = 100€ (calls) + 10€ (SMS) + 5€ (emails) + 190€ (leasing) = 305€
Coûts Provider = 20€ (calls) + 7€ (SMS) + 3€ (emails) = 30€
Marge = 305€ - 30€ = 275€
```

---

### 8. Marge Pourcentage

```
Marge (%) = (Marge € / Revenue Total) × 100
```

**Exemple** :
```
Marge = 275€
Revenue Total = 305€
Marge % = (275 / 305) × 100 = 90.16%
```

**Seuils recommandés** :
- **> 95%** : Excellent (forte proportion de leasing vs usage)
- **90-95%** : Bon (équilibre leasing/usage)
- **< 90%** : À surveiller (forte utilisation vs leasing)

**Pourquoi le leasing augmente la marge %** :
- Leasing = 100% de marge (pas de coût provider)
- Plus le ratio leasing/usage est élevé, plus la marge % est haute

---

## 📊 Formules d'Agrégation

### 9. Revenue par Client

```
Revenue/Client = SUM(total_revenue) / COUNT(DISTINCT client_id)
```

**Exemple avec 3 clients** :
```
Client A: 500€
Client B: 300€
Client C: 200€
Total = 1000€
Revenue/Client = 1000€ / 3 = 333.33€
```

---

### 10. Marge par Client

```
Marge/Client = SUM(total_margin) / COUNT(DISTINCT client_id)
```

**Utilité** :
- Identifier les clients les plus rentables
- Calculer le Customer Lifetime Value (LTV)
- Optimiser la stratégie commerciale

---

## 📈 Formules de Comparaison

### 11. Changement de Revenue

```
Revenue Change (€) = Revenue Période Actuelle - Revenue Période Précédente
```

---

### 12. Changement de Revenue (%)

```
Revenue Change (%) = ((Revenue Actuel - Revenue Précédent) / Revenue Précédent) × 100
```

**Exemple** :
```
Revenue Actuel = 1200€
Revenue Précédent = 1000€
Change = ((1200 - 1000) / 1000) × 100 = 20%
```

**Interprétation** :
- **> 0** : Croissance (vert)
- **< 0** : Décroissance (rouge)
- **≈ 0** : Stable (neutre)

---

### 13. Changement de Marge

```
Margin Change (€) = Marge Actuelle - Marge Précédente

Margin Change (%) = ((Marge Actuelle - Marge Précédente) / Marge Précédente) × 100
```

---

## 🔍 Formules de Breakdown

### 14. Breakdown par Client

Pour chaque client, agréger toutes les métriques :

```sql
SELECT
  client_id,
  client_name,
  SUM(call_revenue + sms_revenue + email_revenue + leasing_revenue_daily) as total_revenue,
  SUM(call_provider_cost + sms_provider_cost + email_provider_cost) as total_provider_cost,
  SUM(total_revenue) - SUM(total_provider_cost) as total_margin,
  (SUM(total_margin) / SUM(total_revenue)) × 100 as margin_percentage,
  SUM(call_count) as call_count,
  SUM(appointments_scheduled) as appointments_scheduled
FROM v_financial_metrics_enriched
WHERE metric_date BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY client_id, client_name
ORDER BY total_revenue DESC
```

---

### 15. Breakdown par Agent Type

Même logique mais groupé par `agent_type_name` :

```sql
SELECT
  agent_type_name,
  SUM(total_revenue) as total_revenue,
  SUM(total_margin) as total_margin,
  COUNT(DISTINCT client_id) as unique_clients,
  SUM(call_count) as total_calls
FROM v_financial_metrics_enriched
WHERE metric_date BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY agent_type_name
ORDER BY total_revenue DESC
```

**Utile pour** :
- Comparer Louis vs Arthur vs Alexandra
- Identifier l'agent le plus rentable
- Optimiser la stratégie produit

---

### 16. Breakdown par Canal

Agréger les revenus et coûts par canal :

```sql
SELECT
  'calls' as channel,
  SUM(call_revenue) as revenue,
  SUM(call_provider_cost) as provider_cost,
  SUM(call_revenue) - SUM(call_provider_cost) as margin,
  SUM(call_count) as volume
FROM v_financial_metrics_enriched
WHERE metric_date BETWEEN '2025-01-01' AND '2025-01-31'

UNION ALL

SELECT
  'sms' as channel,
  SUM(sms_revenue) as revenue,
  SUM(sms_provider_cost) as provider_cost,
  SUM(sms_revenue) - SUM(sms_provider_cost) as margin,
  SUM(sms_count) as volume
FROM v_financial_metrics_enriched
WHERE metric_date BETWEEN '2025-01-01' AND '2025-01-31'

-- ... (idem pour email et leasing)
```

---

## 🧪 Cas d'Usage & Exemples

### Exemple Complet : Calcul pour 1 Journée

**Données d'entrée** :
- **Deployment** : Louis pour client "Norloc"
  - Leasing : 190€/mois
  - cost_per_min : 0.27€
  - cost_per_sms : 0.07€

- **Activité du jour** :
  - 10 appels, durée totale 600 secondes (10 min)
  - 5 SMS envoyés
  - 0 emails

**Calculs** :

```
1. Call Revenue = (600 / 60) × 0.27 = 10 × 0.27 = 2.70€
2. Call Provider Cost = 0.50€ (from agent_calls.total_cost)
3. SMS Revenue = 5 × 0.07 = 0.35€
4. SMS Provider Cost = 5 × 0.05 = 0.25€
5. Leasing Revenue Daily = 190 / 30 = 6.33€
6. Total Revenue = 2.70 + 0.35 + 6.33 = 9.38€
7. Total Provider Cost = 0.50 + 0.25 = 0.75€
8. Total Margin = 9.38 - 0.75 = 8.63€
9. Margin % = (8.63 / 9.38) × 100 = 92.0%
```

**Résultat** :
- ✅ Marge de 92% : Bon
- ✅ Leasing représente 67% du revenue (6.33€ / 9.38€)
- ✅ Coûts provider très faibles (0.75€)

---

## ⚠️ Pièges à Éviter

### 1. Division par Zéro
Toujours vérifier avant de diviser :

```sql
CASE
  WHEN total_revenue > 0 THEN (total_margin / total_revenue) * 100
  ELSE 0
END as margin_percentage
```

### 2. Agréger les Marges %
❌ **FAUX** :
```sql
AVG(margin_percentage)  -- Moyenne des % de chaque ligne
```

✅ **CORRECT** :
```sql
(SUM(total_margin) / SUM(total_revenue)) * 100  -- Marge globale
```

### 3. Pro-rating du Leasing
❌ **FAUX** :
```sql
leasing × nombre_de_jours  -- Multiplie le leasing mensuel !
```

✅ **CORRECT** :
```sql
(leasing / 30) × nombre_de_jours  -- Divise d'abord, multiplie ensuite
```

### 4. Conversion USD → EUR
Les coûts VAPI sont parfois en USD, vérifier la conversion :

```sql
vapi_cost_usd * 0.92  -- Taux de change approximatif
```

---

## 📚 Références

- **Vue principale** : `v_financial_metrics_enriched`
- **Fonction KPI** : `get_financial_kpi_metrics()`
- **Fonction Drilldown** : `get_financial_drilldown()`

---

**Version**: 1.0.0
**Date**: 2025-11-16
**Auteur**: Claude (Financial Dashboard Implementation)
