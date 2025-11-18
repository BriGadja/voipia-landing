# 🔄 Refonte Dashboard Financier : Séparation Leasing / Consommation

**Date**: 2025-01-18
**Objectif**: Séparer clairement les revenus/marges du leasing (100% marge, fixe) et de la consommation (marge variable)
**Granularité**: Pricing unitaire par agent individuel

---

## ✅ Phase 1 : SQL / Base de données - TERMINÉE

### Fichiers créés

1. **`get_consumption_pricing_by_agent.sql`** ✅
   - Fonction retournant le pricing unitaire par agent individuel
   - Coûts provider vs prix facturés vs marges unitaires
   - Breakdown par canal (calls, SMS, emails)

2. **`v_financial_metrics_enriched_v2.sql`** ✅
   - Vue mise à jour avec colonnes séparées :
     - `leasing_revenue_daily`, `leasing_margin_daily`
     - `consumption_revenue`, `consumption_provider_cost`, `consumption_margin`
     - `consumption_margin_pct` (séparé de `margin_percentage`)
   - Backward compatible (colonnes totales maintenues)

3. **`get_leasing_kpi_metrics.sql`** ✅
   - Fonction retournant KPI leasing uniquement
   - Métriques : Total revenue, MRR, adoption rate, avg per client

4. **`get_consumption_kpi_metrics.sql`** ✅
   - Fonction retournant KPI consommation uniquement
   - Métriques : Revenue, margin, unit pricing moyens, breakdown par canal

### À faire (Phase 1)

- ⏳ **Modifier `get_client_deployments_breakdown`** : Ajouter colonnes de pricing unitaire

---

## ✅ Phase 2 : Types TypeScript - TERMINÉE

### Types ajoutés dans `lib/types/financial.ts`

1. **`LeasingMetrics`** ✅
   - KPI spécifiques au leasing (MRR, adoption rate, etc.)

2. **`ConsumptionMetrics`** ✅
   - KPI spécifiques à la consommation
   - Unit pricing moyens (par minute, par SMS, par email)
   - Breakdown par canal

3. **`AgentUnitPricing`** ✅
   - Pricing unitaire par agent individuel
   - Sous-interfaces : `AgentChannelMetrics`, `AgentTotalConsumption`

4. **`FinancialViewMode`** ✅
   - Type: `'leasing' | 'consumption'`

5. **`ClientDeploymentDataV2`** ✅
   - Extension de `ClientDeploymentData` avec pricing unitaire

---

## ✅ Phase 3 : Composants UI - EN COURS

### Composants créés

1. **`FinancialViewToggle.tsx`** ✅
   - Toggle animé (Framer Motion)
   - Switch entre Leasing et Consommation
   - Icons : DollarSign (leasing) / TrendingUp (consumption)
   - Badges: "100% marge" (leasing) / "Usage" (consumption)

### À créer (Phase 3)

2. **`LeasingKPIGrid.tsx`** ⏳
   - 4 KPI cards:
     - 💰 Revenu Leasing Total
     - 👥 Clients avec Leasing
     - 📊 Revenu Moyen/Client
     - 📈 MRR (Monthly Recurring Revenue)

3. **`ConsumptionKPIGrid.tsx`** ⏳
   - 6 KPI cards:
     - 💵 Revenu Consommation
     - 💎 Marge Consommation
     - 📊 Marge % Consommation
     - 💸 Coûts Provider
     - 📞 Volume Total (appels + SMS + emails)
     - 💲 Coût Moyen par Unité

4. **Enrichir `ClientBreakdownTableV2`** ⏳
   - Ajouter colonnes selon le mode actif :
     - Mode Leasing : Revenu leasing, MRR, Taux adoption
     - Mode Consommation : Coût/Prix/Marge par unité (calls, SMS, emails)

5. **Enrichir `DeploymentDrilldownModal`** ⏳
   - Ajouter section "Pricing Unitaire"
   - Tableau par agent individuel

---

## ⏳ Phase 4 : Graphiques

### À créer

1. **`ConsumptionPricingChart.tsx`** ⏳
   - Bar chart : Coût provider | Prix facturé | Marge
   - Groupé par agent individuel

2. **Modifier `FinancialTimeSeriesChart`** ⏳
   - Ajouter séries stackées :
     - Leasing (violet)
     - Consommation (cyan)

---

## ⏳ Phase 5 : Query Hooks & API

### À créer dans `lib/hooks/useFinancialData.ts`

1. **`useLeasingMetrics(filters)`** ⏳
2. **`useConsumptionMetrics(filters)`** ⏳
3. **`useAgentUnitPricing(filters)`** ⏳

### À créer dans `lib/queries/financial.ts`

1. **`fetchLeasingMetrics()`** ⏳
2. **`fetchConsumptionMetrics()`** ⏳
3. **`fetchAgentUnitPricing()`** ⏳

---

## ⏳ Phase 6 : Intégration

### À faire

1. **Modifier `FinancialDashboardClient.tsx`** ⏳
   - Ajouter state `viewMode: FinancialViewMode`
   - Intégrer `FinancialViewToggle`
   - Afficher `LeasingKPIGrid` ou `ConsumptionKPIGrid` selon le mode
   - Passer le mode aux composants enfants (tableau, graphiques)

---

## ⏳ Phase 7 : Vérification

### À faire

1. **Test visuel avec Playwright** ⏳
   - Navigate to `http://localhost:3000/dashboard/financial`
   - Snapshot mode Leasing
   - Snapshot mode Consommation
   - Vérifier le toggle fonctionne

---

## ⏳ Phase 8 : Staging & Production

### À faire

1. **Test en staging** ⏳
   - Appliquer migrations en staging
   - Tester avec données réelles
   - Vérifier RLS fonctionne

2. **Générer migrations production** ⏳
   - `20251118_v_financial_metrics_enriched_v2.sql`
   - `20251118_create_get_leasing_kpi_metrics.sql`
   - `20251118_create_get_consumption_kpi_metrics.sql`
   - `20251118_create_get_consumption_pricing_by_agent.sql`

---

## 📊 Résultat attendu

**Avant** (actuel):
- ❌ KPI mixés : Impossible de distinguer la rentabilité leasing vs consommation
- ❌ Marge % gonflée par le leasing (100% marge)
- ❌ Pas de visibilité sur le pricing unitaire

**Après** (refonte):
- ✅ Toggle pour basculer entre vue Leasing et Consommation
- ✅ KPI séparés avec métriques adaptées à chaque modèle
- ✅ Pricing unitaire visible par agent individuel (coût, prix, marge)
- ✅ Tableau enrichi avec colonnes de pricing détaillées
- ✅ Graphiques adaptés au mode sélectionné
- ✅ Vision claire de la rentabilité réelle sur la consommation

---

## 🎯 Exemple concret

**Client "Immo Pro"** avec 3 agents Louis :

### Mode Leasing
- Revenu : 570€/mois (3 × 190€)
- Marge : 100%
- MRR : 570€

### Mode Consommation
- **Agent 1** : 0.08€/min (coût) vs 0.12€/min (facturé) = 0.04€/min marge → 50% marge
- **Agent 2** : 0.09€/SMS (coût) vs 0.15€/SMS (facturé) = 0.06€/SMS marge → 67% marge
- **Agent 3** : 0.05€/email (coût) vs 0.10€/email (facturé) = 0.05€/email marge → 100% marge
- **Marge globale consommation** : 35%

Vs **Marge actuelle mixée** : 92% (leasing + consommation confondus)

---

## 🚀 Prochaines étapes

1. ✅ ~Créer SQL functions~
2. ✅ ~Créer types TypeScript~
3. ✅ ~Créer FinancialViewToggle~
4. ⏳ **En cours** : Créer LeasingKPIGrid
5. ⏳ Créer ConsumptionKPIGrid
6. ⏳ Enrichir tableau avec pricing unitaire
7. ⏳ Créer graphiques
8. ⏳ Créer hooks et queries
9. ⏳ Intégrer dans dashboard
10. ⏳ Test visuel Playwright
11. ⏳ Appliquer en staging puis production

---

**Progression**: 30% (3 phases sur 8 terminées)
**Fichiers créés**: 6 SQL + 1 types TS + 1 composant React
**Fichiers à créer**: ~10 composants + hooks + queries + 4 migrations
