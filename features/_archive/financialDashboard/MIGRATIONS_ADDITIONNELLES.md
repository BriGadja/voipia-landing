# 🔧 Migrations Additionnelles - Dashboard Financier

**Date**: 2025-01-17 (16:30)
**Statut**: ⚠️ CRITIQUE - 3 fonctions RPC cassées en production
**Version**: v4 (Correctifs additionnels)

---

## 📊 Problème Détecté

Après le push en production, le Dashboard Financier affiche le graphique "Évolution Financière" ✅ mais lance plusieurs erreurs dans la console:

```
Error fetching leasing metrics: column "leasing_monthly_price" does not exist
Error fetching cost breakdown: column "call_sit_cost" does not exist
Error fetching consumption metrics: column "consumption_revenue" does not exist
```

### Analyse

Les 3 fonctions suivantes tentent d'accéder à des colonnes qui n'existent PAS dans `v_financial_metrics_enriched`:

1. **`get_cost_breakdown`** - Cherche `call_stt_cost`, `call_tts_cost`, `call_llm_cost`, `call_telecom_cost`, `call_dipler_commission`
2. **`get_consumption_kpi_metrics`** - Cherche `consumption_revenue`, `consumption_provider_cost`, `consumption_margin`
3. **`get_leasing_kpi_metrics`** - Cherche `leasing_margin_daily`

### Colonnes Disponibles vs Requises

**✅ Colonnes qui EXISTENT dans v_financial_metrics_enriched:**
- `call_revenue`
- `call_provider_cost` (total agrégé)
- `sms_revenue`
- `sms_provider_cost`
- `email_revenue`
- `email_provider_cost`
- `leasing_revenue_daily`
- `total_revenue`
- `total_provider_cost`
- `total_margin`

**❌ Colonnes qui N'EXISTENT PAS:**
- `call_stt_cost`, `call_tts_cost`, `call_llm_cost`, `call_telecom_cost`, `call_dipler_commission`
- `consumption_revenue`, `consumption_provider_cost`, `consumption_margin`
- `leasing_margin_daily`

---

## 🔄 Migrations Correctives

### Migration 1: Fix get_cost_breakdown

**Fichier**: `supabase/migrations/20250117_fix_cost_breakdown_function.sql`

**Problème**: Fonction tente d'accéder à des colonnes de coûts détaillés qui n'existent pas

**Solution**:
- Simplifier pour utiliser uniquement `call_provider_cost` (total agrégé)
- Retirer les références à STT, TTS, LLM, Telecom, Dipler commission
- Ajouter une section `revenue` pour plus de contexte

**Impact**: Le dashboard affichera les coûts totaux par canal au lieu de la décomposition détaillée

---

### Migration 2: Fix get_consumption_kpi_metrics

**Fichier**: `supabase/migrations/20250117_fix_consumption_kpi_metrics_function.sql`

**Problème**: Fonction cherche `consumption_revenue` qui n'existe pas

**Solution**:
- Calculer consumption_revenue = call_revenue + sms_revenue + email_revenue
- Calculer consumption_provider_cost = call_provider_cost + sms_provider_cost + email_provider_cost
- Calculer consumption_margin = consumption_revenue - consumption_provider_cost

**Logique**: Consumption = tout sauf le leasing (calls + SMS + emails)

**Impact**: Les métriques de consommation s'afficheront correctement

---

### Migration 3: Fix get_leasing_kpi_metrics

**Fichier**: `supabase/migrations/20250117_fix_leasing_kpi_metrics_function.sql`

**Problème**: Fonction cherche `leasing_margin_daily` qui n'existe pas

**Solution**:
- Calculer leasing_margin = leasing_revenue_daily (marge 100%)
- Logique: Le leasing est une souscription pure, pas de coût fournisseur

**Impact**: Les métriques de leasing s'afficheront correctement avec marge à 100%

---

## 🚀 Comment Appliquer

### Option 1: Supabase Dashboard (Recommandé)

Pour chaque migration (dans n'importe quel ordre):

1. Ouvrir Supabase Dashboard : https://supabase.com/dashboard
2. Sélectionner le projet **production**
3. Aller dans **SQL Editor**
4. Créer une nouvelle query
5. Copier-coller le contenu du fichier
6. Cliquer sur **Run**
7. Vérifier le message de succès

**Ordre d'exécution**: N'importe quel ordre (indépendantes)

### Option 2: Supabase CLI

```bash
# Naviguer vers le projet
cd C:\Users\pc\Documents\Projets\voipia-landing

# Appliquer les 3 migrations
supabase db push --file supabase/migrations/20250117_fix_cost_breakdown_function.sql
supabase db push --file supabase/migrations/20250117_fix_consumption_kpi_metrics_function.sql
supabase db push --file supabase/migrations/20250117_fix_leasing_kpi_metrics_function.sql
```

---

## ✅ Vérification Post-Migration

### Test 1: Vérifier que les fonctions existent

```sql
SELECT
  proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND proname IN (
    'get_cost_breakdown',
    'get_consumption_kpi_metrics',
    'get_leasing_kpi_metrics'
  )
ORDER BY proname;
```

**Résultat attendu**: 3 lignes (une fonction par ligne)

---

### Test 2: Tester get_cost_breakdown

```sql
SELECT jsonb_pretty(
  get_cost_breakdown(
    CURRENT_DATE - 30,
    CURRENT_DATE,
    NULL,  -- tous les clients
    NULL,  -- tous les agent types
    NULL   -- tous les déploiements
  )
);
```

**Résultat attendu**: JSONB avec `call_costs`, `sms_costs`, `email_costs`, `total_costs`, `volume`, `revenue`

---

### Test 3: Tester get_consumption_kpi_metrics

```sql
SELECT jsonb_pretty(
  get_consumption_kpi_metrics(
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

**Résultat attendu**: JSONB avec métriques de consommation (consumption_revenue, consumption_margin, etc.)

---

### Test 4: Tester get_leasing_kpi_metrics

```sql
SELECT jsonb_pretty(
  get_leasing_kpi_metrics(
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

**Résultat attendu**: JSONB avec métriques de leasing (total_leasing_revenue, mrr, leasing_margin_pct: 100.0, etc.)

---

## 🧪 Test Frontend

Une fois les migrations appliquées:

1. **Recharger le Dashboard Financier** (`/dashboard/financial`)
2. **Ouvrir la console navigateur** (F12)
3. **Vérifier qu'il n'y a PLUS d'erreurs** `column does not exist`
4. **Vérifier que tous les graphiques et KPIs s'affichent**:
   - ✅ Onglet "Leasing" - Affiche les métriques
   - ✅ Onglet "Consommation" - Affiche les métriques
   - ✅ Graphique "Évolution Financière" - Continue à fonctionner
   - ✅ Drill down niveau 1 (Client → Déploiements) - Continue à fonctionner
   - ✅ Drill down niveau 2 (Déploiement → Canaux) - Continue à fonctionner

---

## 📝 Checklist d'Application

- [ ] **Migration 1**: Appliquer `20250117_fix_cost_breakdown_function.sql`
- [ ] **Migration 1**: Tester la fonction avec query SQL
- [ ] **Migration 2**: Appliquer `20250117_fix_consumption_kpi_metrics_function.sql`
- [ ] **Migration 2**: Tester la fonction avec query SQL
- [ ] **Migration 3**: Appliquer `20250117_fix_leasing_kpi_metrics_function.sql`
- [ ] **Migration 3**: Tester la fonction avec query SQL
- [ ] **Frontend**: Recharger dashboard et vérifier console sans erreurs
- [ ] **Frontend**: Vérifier onglet Leasing fonctionne
- [ ] **Frontend**: Vérifier onglet Consommation fonctionne

---

## 🎯 Résultat Attendu

Après application des 3 migrations:

- ✅ Plus d'erreurs `column does not exist` dans la console
- ✅ Onglet "Leasing" affiche les métriques correctement
- ✅ Onglet "Consommation" affiche les métriques correctement
- ✅ Tous les graphiques et drill-downs continuent à fonctionner
- ✅ Dashboard Financier 100% fonctionnel

---

## ⏱️ Temps Estimé

- **Application des 3 migrations**: ~5 minutes
- **Tests SQL**: ~5 minutes
- **Tests Frontend**: ~3 minutes
- **Total**: ~13 minutes

---

## 🔄 Rollback (si nécessaire)

Si les migrations causent des problèmes, tu peux rollback:

```sql
-- Restaurer les anciennes versions depuis la production
-- (Les anciennes fonctions sont conservées dans l'historique)
```

Note: Il vaut mieux laisser les nouvelles versions car les anciennes sont cassées de toute façon.

---

**Priorité**: 🔴 **URGENT** - Le dashboard affiche des erreurs en production

**Date de création**: 2025-01-17 16:30
**Auteur**: Claude (Financial Dashboard Team)
**Version**: 4.0 (Correctifs additionnels)
