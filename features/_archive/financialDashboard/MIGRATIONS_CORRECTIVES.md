# 🔧 Migrations Correctives - RLS Fix

**Date**: 2025-01-17
**Statut**: ⚠️ URGENT - À appliquer en production

---

## 🚨 Problème Identifié

Les 3 fonctions SQL précédemment appliquées **ne fonctionnent pas en production** car elles référencent une colonne `user_has_access` qui n'existe pas.

**Erreur observée**:
```
ERROR: P0001: column ac.user_has_access does not exist
```

**Cause**: Les migrations ont été développées en staging avec une colonne RLS `user_has_access`, mais la production utilise la table `user_client_permissions` pour gérer les permissions.

---

## ✅ Solution

3 migrations correctives ont été créées pour remplacer les fonctions avec la bonne logique RLS basée sur `user_client_permissions`.

---

## 📋 Ordre d'Application des Migrations

**IMPORTANT**: Appliquer ces 3 migrations dans n'importe quel ordre, elles sont indépendantes.

### Migration 1: Fix Time Series (Phase 1)
**Fichier**: `supabase/migrations/20250117_fix_financial_timeseries_rls.sql`

**Ce qu'elle fait**:
- Supprime la fonction `get_financial_timeseries` défectueuse
- Crée une nouvelle version avec RLS basé sur `user_client_permissions`
- Filtre les données par `auth.uid()` et `client_id`

**Impact**: Réactive le graphique "Évolution Financière"

---

### Migration 2: Fix Client → Deployments (Phase 3)
**Fichier**: `supabase/migrations/20250117_fix_client_deployments_breakdown_rls.sql`

**Ce qu'elle fait**:
- Supprime la fonction `get_client_deployments_breakdown` défectueuse
- Crée une nouvelle version avec RLS basé sur `user_client_permissions`
- Vérifie l'accès via `user_client_permissions` avant de retourner les données

**Impact**: Réactive le drill down niveau 1 (Client → Déploiements)

---

### Migration 3: Fix Deployment → Channels (Phase 4)
**Fichier**: `supabase/migrations/20250117_fix_deployment_channels_breakdown_rls.sql`

**Ce qu'elle fait**:
- Supprime la fonction `get_deployment_channels_breakdown` défectueuse
- Crée une nouvelle version avec RLS basé sur `user_client_permissions`
- Récupère le `client_id` via la relation `deployment → client` puis vérifie l'accès

**Impact**: Réactive le drill down niveau 2 (Déploiement → Canaux)

---

## 🚀 Comment Appliquer

### Via Supabase Dashboard (Recommandé)

1. Ouvrir Supabase Dashboard: https://supabase.com/dashboard
2. Sélectionner le projet **production**
3. Aller dans **SQL Editor**
4. Pour chaque migration:
   - Créer une nouvelle query
   - Copier-coller le contenu du fichier
   - Cliquer sur **Run**
   - Vérifier le message de succès

### Via Supabase CLI

```bash
# Appliquer toutes les migrations en attente
supabase db push

# Ou appliquer une migration spécifique
supabase db push --file supabase/migrations/20250117_fix_financial_timeseries_rls.sql
supabase db push --file supabase/migrations/20250117_fix_client_deployments_breakdown_rls.sql
supabase db push --file supabase/migrations/20250117_fix_deployment_channels_breakdown_rls.sql
```

---

## ✅ Vérification Post-Migration

Après avoir appliqué les 3 migrations, vérifier que tout fonctionne :

### Test 1: Vérifier que les fonctions existent

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

**Résultat attendu**: 3 lignes (une par fonction)

---

### Test 2: Tester get_financial_timeseries

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

**Résultat attendu**: Array JSONB avec données par jour

---

### Test 3: Tester get_client_deployments_breakdown

```sql
-- D'abord, récupérer un client ID accessible
SELECT id, name FROM clients LIMIT 5;

-- Tester avec un client (remplacer CLIENT_ID)
SELECT jsonb_pretty(
  get_client_deployments_breakdown(
    'CLIENT_ID_HERE'::uuid,
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

**Résultat attendu**: Array JSONB avec les déploiements du client

---

### Test 4: Tester get_deployment_channels_breakdown

```sql
-- D'abord, récupérer un deployment ID accessible
SELECT d.id, d.name, c.name as client_name
FROM agent_deployments d
JOIN clients c ON d.client_id = c.id
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

**Résultat attendu**: Array JSONB avec les canaux (Calls, Leasing)

---

## 🧪 Test Frontend

Une fois les migrations appliquées, tester dans l'interface :

1. **Aller sur** `/dashboard/financial`
2. **Vérifier** que le graphique "Évolution Financière" affiche des données
3. **Cliquer** sur "Détail" pour un client
   - ✅ Le modal doit s'ouvrir avec la table des déploiements
   - ✅ Pas d'erreur dans la console
4. **Cliquer** sur une ligne de déploiement
   - ✅ Le second modal doit s'ouvrir avec la table des canaux
   - ✅ Pas d'erreur dans la console

---

## 📊 Différences Clés entre Staging et Production

| Aspect | Staging | Production |
|--------|---------|-----------|
| RLS Column | `user_has_access` | N/A |
| RLS Table | N/A | `user_client_permissions` |
| Access Check | `WHERE user_has_access = true` | `JOIN user_client_permissions` |
| User ID | Hardcoded in view | `auth.uid()` |

**Note**: En production, le RLS est plus robuste car il utilise une table de permissions centralisée.

---

## 🔄 Rollback (si nécessaire)

Si les migrations correctives causent des problèmes, tu peux rollback :

```sql
-- Supprimer les 3 fonctions
DROP FUNCTION IF EXISTS public.get_financial_timeseries(DATE, DATE, UUID, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS public.get_client_deployments_breakdown(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS public.get_deployment_channels_breakdown(UUID, DATE, DATE);
```

Puis réappliquer les migrations originales (mais elles ne fonctionneront pas sans la colonne `user_has_access`).

---

## 📝 Checklist d'Application

- [ ] **Migration 1**: `20250117_fix_financial_timeseries_rls.sql` appliquée
- [ ] **Migration 1**: Fonction testée avec succès
- [ ] **Migration 2**: `20250117_fix_client_deployments_breakdown_rls.sql` appliquée
- [ ] **Migration 2**: Fonction testée avec succès
- [ ] **Migration 3**: `20250117_fix_deployment_channels_breakdown_rls.sql` appliquée
- [ ] **Migration 3**: Fonction testée avec succès
- [ ] **Frontend**: Graphique d'évolution fonctionne
- [ ] **Frontend**: Drill down niveau 1 fonctionne (Client → Deployments)
- [ ] **Frontend**: Drill down niveau 2 fonctionne (Deployment → Channels)
- [ ] **Frontend**: Pas d'erreurs dans la console browser

---

## ⏱️ Temps Estimé

- **Application des 3 migrations**: ~5 minutes
- **Tests SQL**: ~5 minutes
- **Tests Frontend**: ~5 minutes
- **Total**: ~15 minutes

---

## 🎯 Résultat Attendu

Après application des 3 migrations correctives :
- ✅ Le graphique "Évolution Financière" affiche les données
- ✅ Le drill down niveau 1 fonctionne (clic sur "Détail" client)
- ✅ Le drill down niveau 2 fonctionne (clic sur ligne déploiement)
- ✅ Plus d'erreurs SQL dans la console
- ✅ Dashboard Financier 100% fonctionnel

---

**Priorité**: 🔴 **URGENT** - Sans ces migrations, le dashboard financier est partiellement cassé en production.

**Date de création**: 2025-01-17
**Auteur**: Claude (Financial Dashboard Team)
