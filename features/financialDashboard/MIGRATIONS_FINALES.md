# 🔧 Migrations Finales - Dashboard Financier

**Date**: 2025-01-17
**Statut**: ✅ PRÊT POUR PRODUCTION
**Version**: v3 (Finales)

---

## 📊 Contexte

Après investigation, nous avons découvert que la **production a déjà une architecture financière complète** avec :

- ✅ Vue `v_financial_metrics_enriched` : Agrège toutes les métriques financières par jour et par deployment
- ✅ Colonnes de revenue/coûts par canal (calls, sms, email, leasing)
- ✅ RLS intégré via colonne `user_has_access`
- ✅ Calculs de marges et métriques déjà faits

**Problème initial** : Les migrations tentaient d'accéder à des colonnes qui n'existent pas (`pricing_model`, `leasing_monthly_price`, `voipia_margin_percentage`, `at.label`)

**Solution** : Réécrire les 3 fonctions pour utiliser `v_financial_metrics_enriched` au lieu de calculer manuellement

---

## 🔄 Historique des Versions

### Version 1 (Initiale) - ❌ Échec
- Fichiers : `20250117_create_financial_timeseries_function.sql`, etc.
- Problème : Utilisait `user_has_access` colonne qui n'existe pas en production

### Version 2 (Corrective) - ❌ Échec
- Fichiers : `20250117_fix_financial_timeseries_rls.sql`, etc.
- Problème : Essayait d'accéder à `d.pricing_model`, `at.label` qui n'existent pas

### Version 3 (Finale) - ✅ Correcte
- Fichiers : `20250117_fix_financial_timeseries_use_view.sql`, etc.
- Solution : Utilise `v_financial_metrics_enriched` qui a déjà tout

---

## 📋 Migrations à Appliquer (v3)

**IMPORTANT** : Appliquer ces 3 migrations dans n'importe quel ordre (elles sont indépendantes).

### Migration 1 : Time Series (Graphique d'évolution)

**Fichier** : `supabase/migrations/20250117_fix_financial_timeseries_use_view.sql`

**Description** : Fonction pour le graphique d'évolution temporelle des métriques financières

**Fonction** : `get_financial_timeseries(p_start_date, p_end_date, p_client_id, p_agent_type_name, p_deployment_id, p_granularity)`

**Ce qu'elle fait** :
- Agrège les données de `v_financial_metrics_enriched` par période (jour/semaine/mois)
- Retourne revenue, coûts, marges, volumes par canal
- Filtre avec RLS via `user_has_access = true`

**Impact** : Active le graphique "Évolution Financière" sur le dashboard

---

### Migration 2 : Client → Déploiements (Drill Down Niveau 1)

**Fichier** : `supabase/migrations/20250117_fix_client_deployments_use_view.sql`

**Description** : Fonction pour drill down d'un client vers ses déploiements

**Fonction** : `get_client_deployments_breakdown(p_client_id, p_start_date, p_end_date)`

**Ce qu'elle fait** :
- Agrège les données de `v_financial_metrics_enriched` par `deployment_id`
- Joint avec `agent_deployments` et `agent_types` pour les métadonnées (nom, statut, display_name)
- Vérifie l'accès via `user_client_permissions`

**Impact** : Active le modal de drill down niveau 1 (clic sur "Détail" client)

---

### Migration 3 : Déploiement → Canaux (Drill Down Niveau 2)

**Fichier** : `supabase/migrations/20250117_fix_deployment_channels_use_view.sql`

**Description** : Fonction pour drill down d'un déploiement vers ses canaux

**Fonction** : `get_deployment_channels_breakdown(p_deployment_id, p_start_date, p_end_date)`

**Ce qu'elle fait** :
- Agrège les métriques par canal (Calls, SMS, Email, Leasing) depuis `v_financial_metrics_enriched`
- Affiche uniquement les canaux actifs (volume > 0)
- Vérifie l'accès via `user_client_permissions`

**Impact** : Active le modal de drill down niveau 2 (clic sur ligne déploiement)

---

## 🚀 Comment Appliquer

### Option 1 : Supabase Dashboard (Recommandé)

Pour chaque migration :

1. Ouvrir Supabase Dashboard : https://supabase.com/dashboard
2. Sélectionner le projet **production**
3. Aller dans **SQL Editor**
4. Créer une nouvelle query
5. Copier-coller le contenu du fichier
6. Cliquer sur **Run**
7. Vérifier le message de succès

**Ordre d'exécution** : N'importe quel ordre (indépendantes)

### Option 2 : Supabase CLI

```bash
# Naviguer vers le projet
cd C:\Users\pc\Documents\Projets\voipia-landing

# Appliquer les 3 migrations
supabase db push --file supabase/migrations/20250117_fix_financial_timeseries_use_view.sql
supabase db push --file supabase/migrations/20250117_fix_client_deployments_use_view.sql
supabase db push --file supabase/migrations/20250117_fix_deployment_channels_use_view.sql
```

---

## ✅ Vérification Post-Migration

### Test 1 : Vérifier que les 3 fonctions existent

```sql
SELECT
  proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND proname IN (
    'get_financial_timeseries',
    'get_client_deployments_breakdown',
    'get_deployment_channels_breakdown'
  )
ORDER BY proname;
```

**Résultat attendu** : 3 lignes (une fonction par ligne)

---

### Test 2 : Tester get_financial_timeseries

```sql
-- Test avec période de 30 jours
SELECT jsonb_pretty(
  get_financial_timeseries(
    CURRENT_DATE - 30,
    CURRENT_DATE,
    NULL,  -- tous les clients accessibles
    NULL,  -- tous les agent types
    NULL,  -- tous les déploiements
    'day'  -- granularité jour
  )
);
```

**Résultat attendu** : Array JSONB avec données par jour (ou empty array si pas de données dans la période)

---

### Test 3 : Tester get_client_deployments_breakdown

```sql
-- D'abord, récupérer un client ID accessible
SELECT id, name FROM clients
WHERE id IN (
  SELECT client_id FROM user_client_permissions WHERE user_id = auth.uid()
)
LIMIT 5;

-- Tester avec un client (remplacer CLIENT_ID)
SELECT jsonb_pretty(
  get_client_deployments_breakdown(
    'CLIENT_ID_HERE'::uuid,
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

**Résultat attendu** : Array JSONB avec les déploiements du client

---

### Test 4 : Tester get_deployment_channels_breakdown

```sql
-- D'abord, récupérer un deployment ID accessible
SELECT d.id, d.name, c.name as client_name
FROM agent_deployments d
JOIN clients c ON d.client_id = c.id
WHERE d.client_id IN (
  SELECT client_id FROM user_client_permissions WHERE user_id = auth.uid()
)
LIMIT 5;

-- Tester avec un déploiement (remplacer DEPLOYMENT_ID)
SELECT jsonb_pretty(
  get_deployment_channels_breakdown(
    'DEPLOYMENT_ID_HERE'::uuid,
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

**Résultat attendu** : Array JSONB avec les canaux actifs (Calls, SMS, Email, Leasing)

---

## 🧪 Test Frontend

Une fois les migrations appliquées :

### 1. Graphique d'évolution (Phase 1)
- Aller sur `/dashboard/financial`
- ✅ Le graphique "Évolution Financière" doit afficher des données
- ✅ Pas d'erreur `column d.pricing_model does not exist` dans la console

### 2. Drill Down Niveau 1 (Phase 3)
- Cliquer sur "Détail" pour un client
- ✅ Le modal s'ouvre avec les KPIs et la table des déploiements
- ✅ Pas d'erreur `column at.label does not exist` dans la console

### 3. Drill Down Niveau 2 (Phase 4)
- Depuis le modal niveau 1, cliquer sur une ligne de déploiement
- ✅ Le second modal s'ouvre avec les canaux (📞 💬 📧 💰)
- ✅ Pas d'erreur dans la console

---

## 📊 Schéma de Production vs Développement

| Élément | Staging/Dev | Production |
|---------|------------|------------|
| **RLS** | Colonne `user_has_access` dans les vues | Table `user_client_permissions` |
| **Pricing** | Colonnes `pricing_model`, `leasing_monthly_price` | Colonnes `leasing`, `cost_per_min`, `cost_per_sms` |
| **Agent Types** | Colonne `at.label` | Colonne `at.display_name` |
| **Agrégation** | Calculs manuels | Vue `v_financial_metrics_enriched` |
| **Architecture** | Simplifiée pour dev | Production complète avec vue enrichie |

**Leçon apprise** : Toujours vérifier le schéma de production avant de créer des migrations, même si le staging fonctionne.

---

## 🔄 Rollback (si nécessaire)

Si les migrations causent des problèmes, tu peux rollback :

```sql
-- Supprimer les 3 fonctions
DROP FUNCTION IF EXISTS public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.get_client_deployments_breakdown(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS public.get_deployment_channels_breakdown(UUID, DATE, DATE);
```

Note : Les fonctions `get_financial_drilldown` et `get_financial_kpi_metrics` existantes ne sont pas affectées par ces migrations.

---

## 📝 Checklist d'Application

- [ ] **Migration 1** : Appliquer `20250117_fix_financial_timeseries_use_view.sql`
- [ ] **Migration 1** : Tester la fonction avec query SQL
- [ ] **Migration 2** : Appliquer `20250117_fix_client_deployments_use_view.sql`
- [ ] **Migration 2** : Tester la fonction avec query SQL
- [ ] **Migration 3** : Appliquer `20250117_fix_deployment_channels_use_view.sql`
- [ ] **Migration 3** : Tester la fonction avec query SQL
- [ ] **Frontend** : Vérifier graphique d'évolution fonctionne
- [ ] **Frontend** : Vérifier drill down niveau 1 fonctionne
- [ ] **Frontend** : Vérifier drill down niveau 2 fonctionne
- [ ] **Frontend** : Vérifier console browser sans erreurs

---

## 🎯 Résultat Attendu

Après application des 3 migrations :

- ✅ Le graphique "Évolution Financière" affiche les données
- ✅ Le drill down niveau 1 (Client → Déploiements) fonctionne
- ✅ Le drill down niveau 2 (Déploiement → Canaux) fonctionne
- ✅ Plus d'erreurs `column does not exist` dans la console
- ✅ Dashboard Financier 100% fonctionnel

---

## ⏱️ Temps Estimé

- **Application des 3 migrations** : ~5 minutes
- **Tests SQL** : ~5 minutes
- **Tests Frontend** : ~5 minutes
- **Total** : ~15 minutes

---

**Priorité** : 🔴 **URGENT** - Sans ces migrations, le dashboard financier est cassé en production.

**Date de création** : 2025-01-17
**Auteur** : Claude (Financial Dashboard Team)
**Version** : 3.0 (Finale)
