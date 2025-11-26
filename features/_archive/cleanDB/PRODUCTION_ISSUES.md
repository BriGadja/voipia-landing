# Issues Rencontrés en Production & Hotfixes

**Date**: 2025-01-13
**Statut**: 🚨 **EN COURS - NÉCESSITE ACTION**

---

## 🔴 Vue d'ensemble

Après l'exécution des migrations de nettoyage en production, **2 problèmes critiques** ont été identifiés et nécessitent des hotfixes.

### Résumé des Problèmes

| # | Problème | Sévérité | Statut | Hotfix |
|---|----------|----------|--------|--------|
| 1 | Erreur `column ac.cost does not exist` | ⚠️ Mineur | ✅ Résolu | Correction FINAL_cleandb.sql |
| 2 | Dashboard filters non fonctionnels | 🔴 **CRITIQUE** | ⚠️ **En attente** | HOTFIX_restore_function_grants.sql |

---

## Problème 1: Erreur Column 'ac.cost' Does Not Exist

### Symptômes

Lors de l'exécution de `FINAL_cleandb.sql` en production:
```
ERROR: 42703: column ac.cost does not exist
LINE 113: ac.duration_seconds, ac.cost, ac.outcome, ...
```

### Cause Racine

La vue `v_agent_calls_enriched` dans le fichier `FINAL_cleandb.sql` utilisait un alias `ac` et référençait une colonne `cost` qui n'existe pas. La colonne correcte est `total_cost`.

Cette erreur n'était **pas présente** dans les fichiers `01_security_fixes.sql`, `02_rls_optimization.sql`, `03_index_cleanup.sql` qui ont été testés en staging.

### Solution Appliquée

✅ **Fichier corrigé**: `migrations/FINAL_cleandb.sql`

**Changement**:
```sql
-- AVANT (incorrect)
SELECT ac.id, ac.deployment_id, ac.started_at, ac.ended_at,
       ac.duration_seconds, ac.cost, ac.outcome, ...

-- APRÈS (correct)
SELECT id, deployment_id, first_name, last_name, email, phone_number,
       started_at, ended_at, duration_seconds, outcome, emotion,
       total_cost, transcript, ...
FROM agent_calls;
```

**Recommandation**: Utiliser les 3 fichiers séparés (01, 02, 03) plutôt que FINAL_cleandb.sql pour éviter ce type de problème.

**Durée**: 10 minutes
**Impact**: ✅ Résolu complètement

---

## Problème 2: Dashboard Filters Non Fonctionnels 🔴 CRITIQUE

### Symptômes

Après l'exécution réussie des migrations:
- ❌ Les filtres des dashboards ne fonctionnent plus
- ❌ Le dashboard Louis ne peut plus filtrer par client/agent/date
- ❌ Les dropdowns de filtres sont vides ou ne chargent pas de données
- ❌ Les KPIs ne s'affichent pas correctement

### Investigation Complète (2 heures)

#### Étape 1: Vérification des Vues ✅ OK

**Test**: Les vues existent et retournent des données?

```sql
SELECT * FROM v_user_accessible_clients LIMIT 5;
-- Résultat: 6 clients ✅

SELECT * FROM v_user_accessible_agents LIMIT 5;
-- Résultat: 10 agents ✅

SELECT COUNT(*) FROM v_agent_calls_enriched;
-- Résultat: 331 appels ✅
```

**Conclusion**: Les vues fonctionnent correctement avec SECURITY INVOKER.

---

#### Étape 2: Vérification des Policies RLS ✅ OK

**Test**: Les policies RLS sont en place?

```sql
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';
-- Résultat: 13 policies consolidées ✅
```

**Conclusion**: RLS fonctionne correctement, données bien filtrées.

---

#### Étape 3: Vérification GRANT SELECT sur Vues ❌ PROBLÈME

**Test**: Les vues ont des permissions SELECT?

```sql
SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name LIKE 'v_%'
  AND grantee IN ('authenticated', 'anon');
-- Résultat: VIDE ❌
```

**Conclusion**: Les GRANT SELECT manquent sur toutes les vues!

**Hotfix créé**: `migrations/HOTFIX_restore_grants.sql`
- Restaure GRANT SELECT sur 16 vues
- Pour les rôles authenticated et anon

**Application**: ✅ Hotfix appliqué par l'utilisateur

**Résultat**: ❌ **Les filtres ne fonctionnent toujours pas**

---

#### Étape 4: Vérification GRANT EXECUTE sur Fonctions RPC ❌ VRAI PROBLÈME 🎯

**Test**: Les fonctions RPC ont des permissions EXECUTE?

```sql
SELECT r.routine_name, p.grantee, p.privilege_type
FROM information_schema.routines r
LEFT JOIN information_schema.routine_privileges p
  ON r.routine_name = p.routine_name
WHERE r.routine_schema = 'public'
  AND r.routine_name LIKE 'get_%'
  AND p.grantee IN ('authenticated', 'anon', 'public');
-- Résultat: VIDE ❌
```

**Conclusion**: 🔴 **AUCUNE fonction RPC n'a de permissions EXECUTE!**

### Fonctions RPC Affectées (9 fonctions)

| Fonction | Usage | Impact |
|----------|-------|--------|
| `get_kpi_metrics` | KPIs Dashboard Louis | 🔴 Dashboard Louis cassé |
| `get_chart_data` | Charts Dashboard Louis | 🔴 Charts Louis cassés |
| `get_arthur_kpi_metrics` | KPIs Dashboard Arthur | 🔴 Dashboard Arthur cassé |
| `get_arthur_chart_data` | Charts Dashboard Arthur | 🔴 Charts Arthur cassés |
| `get_global_kpis` | KPIs Dashboard Global | 🔴 Dashboard Global cassé |
| `get_global_chart_data` | Charts Dashboard Global | 🔴 Charts Global cassés |
| `get_agent_cards_data` | Cards par agent | 🔴 Cards agent cassées |
| `get_agent_type_cards_data` | Cards par type | 🔴 Cards type cassées |
| `get_client_cards_data` | Cards par client | 🔴 Cards client cassées |

### Cause Racine

**Changement de modèle de sécurité**:
```
SECURITY DEFINER → SECURITY INVOKER
```

- **SECURITY DEFINER**: Les vues s'exécutent avec les permissions du créateur (bypass RLS)
- **SECURITY INVOKER**: Les vues s'exécutent avec les permissions de l'appelant (respecte RLS + nécessite grants)

**Conséquence**: Avec SECURITY INVOKER, **tous les grants doivent être explicites**:
- ✅ GRANT SELECT sur les vues
- ✅ GRANT EXECUTE sur les fonctions RPC
- ✅ RLS policies configurées

La migration a converti les vues mais **n'a pas ajouté les GRANT EXECUTE sur les fonctions**.

### Solution: HOTFIX_restore_function_grants.sql 🎯

**Fichier créé**: `migrations/HOTFIX_restore_function_grants.sql`

**Contenu**:
```sql
-- Restaure GRANT EXECUTE sur les 9 fonctions RPC

-- Louis Dashboard
GRANT EXECUTE ON FUNCTION get_kpi_metrics(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_chart_data(...) TO authenticated, anon;

-- Arthur Dashboard
GRANT EXECUTE ON FUNCTION get_arthur_kpi_metrics(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_arthur_chart_data(...) TO authenticated, anon;

-- Global Dashboard
GRANT EXECUTE ON FUNCTION get_global_kpis(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_global_chart_data(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_agent_cards_data(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_agent_type_cards_data(...) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_client_cards_data(...) TO authenticated, anon;
```

**Vérifications incluses**:
```sql
-- Vérifie que les 9 fonctions ont bien 2 grantees (authenticated + anon)
SELECT r.routine_name, p.grantee, p.privilege_type
FROM information_schema.routines r
JOIN information_schema.routine_privileges p
  ON r.routine_name = p.routine_name
WHERE r.routine_schema = 'public'
  AND r.routine_name LIKE 'get_%'
  AND p.grantee IN ('authenticated', 'anon');
-- Devrait retourner 18 lignes (9 fonctions × 2 grantees)
```

---

## 🔧 Procédure d'Application du Hotfix

### Prérequis

- Accès Supabase production
- Éditeur SQL Supabase ouvert

### Étapes

1. **Télécharger le fichier hotfix**:
   ```
   features/cleanDB/migrations/HOTFIX_restore_function_grants.sql
   ```

2. **Ouvrir l'éditeur SQL Supabase**:
   - Se connecter à Supabase Dashboard
   - Aller dans "SQL Editor"
   - Créer une nouvelle query

3. **Copier-coller le contenu du hotfix**

4. **Exécuter le script**:
   - Cliquer sur "Run"
   - Durée: < 10 secondes

5. **Vérifier l'application**:
   - Exécuter la query de vérification à la fin du fichier
   - Devrait retourner 18 lignes (9 fonctions × 2 grantees)

6. **Tester les dashboards**:
   - Ouvrir Dashboard Louis: `/dashboard/louis`
   - Vérifier que les filtres fonctionnent
   - Vérifier que les KPIs s'affichent
   - Vérifier que les charts se chargent

### Résultat Attendu

✅ **Tous les dashboards fonctionnels**:
- Filtres Client/Agent/Date opérationnels
- KPIs affichés correctement
- Charts affichés correctement
- Aucune erreur de permissions

---

## 📋 Ordre d'Exécution des Migrations

### Option 1: Fichiers Séparés (RECOMMANDÉ)

Exécuter dans cet ordre:

1. `migrations/01_security_fixes.sql` ✅
2. `migrations/02_rls_optimization.sql` ✅
3. `migrations/03_index_cleanup.sql` ✅
4. `migrations/HOTFIX_restore_grants.sql` ✅ (si nécessaire)
5. `migrations/HOTFIX_restore_function_grants.sql` ⚠️ **À APPLIQUER**

### Option 2: Fichier Consolidé

Exécuter:

1. `migrations/FINAL_cleandb.sql` (version corrigée) ✅
2. `migrations/HOTFIX_restore_grants.sql` ✅
3. `migrations/HOTFIX_restore_function_grants.sql` ⚠️ **À APPLIQUER**

---

## 🎓 Leçons Apprises

### 1. SECURITY INVOKER Nécessite Grants Explicites

**Problème**: Passage de SECURITY DEFINER à SECURITY INVOKER sans grants

**Solution**: Toujours inclure dans les migrations:
```sql
-- Après CREATE OR REPLACE VIEW
GRANT SELECT ON view_name TO authenticated, anon;

-- Après CREATE OR REPLACE FUNCTION
GRANT EXECUTE ON FUNCTION function_name(...) TO authenticated, anon;
```

### 2. Tester le Frontend en Staging

**Problème**: Migrations testées en staging mais pas l'interface utilisateur

**Solution**: Après migrations staging, toujours:
- Tester les dashboards frontend
- Vérifier tous les filtres
- Tester toutes les fonctionnalités utilisateur

### 3. Vérifier les Grants Après Migration de Sécurité

**Problème**: Grants oubliés après changement de modèle de sécurité

**Solution**: Checklist post-migration:
```sql
-- 1. Vérifier grants sur vues
SELECT COUNT(*) FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND grantee IN ('authenticated', 'anon');

-- 2. Vérifier grants sur fonctions
SELECT COUNT(*) FROM information_schema.routine_privileges
WHERE routine_schema = 'public' AND grantee IN ('authenticated', 'anon');

-- 3. Si count = 0, ajouter les grants manquants
```

### 4. Documenter les Dépendances

**Problème**: Fonctions RPC utilisées par dashboards non documentées

**Solution**: Dans les migrations, documenter:
- Quelles vues sont utilisées par quelles fonctions
- Quelles fonctions sont appelées par le frontend
- Quel impact attendu de chaque changement

---

## 📊 Impact Final

### Problèmes Résolus

| Problème | Statut | Impact |
|----------|--------|--------|
| Column 'ac.cost' does not exist | ✅ Résolu | Migration s'exécute correctement |
| GRANT SELECT manquants sur vues | ✅ Résolu | Vues accessibles |
| GRANT EXECUTE manquants sur fonctions | ⚠️ **En attente** | 🔴 **Dashboards cassés** |

### Après Application du Hotfix

| Métrique | Avant Hotfix | Après Hotfix |
|----------|--------------|--------------|
| Dashboards fonctionnels | 0/3 (0%) | 3/3 (100%) ✅ |
| Fonctions RPC accessibles | 0/9 (0%) | 9/9 (100%) ✅ |
| Filtres opérationnels | ❌ Non | ✅ Oui |
| Erreurs utilisateur | 🔴 Oui | ✅ Non |

---

## ⚡ Action Requise

### Statut Actuel

🔴 **CRITIQUE - ACTION IMMÉDIATE REQUISE**

### Prochaine Étape

**Appliquer le hotfix**: `HOTFIX_restore_function_grants.sql`

**Durée estimée**: < 2 minutes
**Impact**: Restaure 100% fonctionnalité dashboards

---

**Créé le**: 2025-01-13
**Dernière mise à jour**: 2025-01-13
**Statut**: ⚠️ **En attente d'application du hotfix**
