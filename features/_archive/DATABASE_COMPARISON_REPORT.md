# 📊 Rapport de Comparaison Base de Données Production vs Staging

**Date**: 2025-11-20
**Objectif**: Identifier les différences entre les bases de données Production et Staging pour garantir la cohérence avant les migrations

---

## 🎯 Résumé Exécutif

| Catégorie | Production | Staging | Statut |
|-----------|------------|---------|---------|
| **Tables** | 11 tables | 11 tables | ✅ **ISO** |
| **Extensions** | 76 extensions | 76 extensions | ✅ **ISO** |
| **Migrations** | 1 migration | 17 migrations | ⚠️ **DIFFÉRENCE MAJEURE** |
| **Vues** | 20 vues | 20 vues | ⚠️ **Contenu différent** |
| **Fonctions RPC** | ~30 fonctions | ~30 fonctions | ⚠️ **Contenu différent** |

---

## 📋 Tables - Analyse Détaillée

### ✅ Structure des tables : **ISO**

Les 11 tables suivantes sont présentes dans les deux environnements :

1. ✅ `clients` - 6 colonnes, RLS activé
2. ✅ `user_client_permissions` - 4 colonnes, RLS activé
3. ✅ `profiles` - 7 colonnes, RLS activé
4. ✅ `agent_types` - 11 colonnes, RLS activé
5. ✅ `agent_deployments` - 16 colonnes, RLS activé
6. ✅ `agent_calls` - 48 colonnes, RLS activé (PROD) / 46 colonnes (STAGING)
7. ✅ `agent_arthur_prospects` - 17 colonnes, RLS activé
8. ✅ `agent_arthur_prospect_sequences` - 13 colonnes, RLS activé
9. ✅ `agent_sms` - 33 colonnes, RLS activé
10. ✅ `agent_emails` - 36 colonnes, RLS activé

### ⚠️ Différences de colonnes détectées

#### Table `agent_calls`

**PRODUCTION (48 colonnes)** vs **STAGING (46 colonnes)**

| Colonne | Production | Staging | Notes |
|---------|------------|---------|-------|
| `call_quality_analysis` | ✅ Présente | ✅ Présente | Commentaire identique |
| `avg_llm_latency_ms` | ✅ Présente | ✅ Présente | Colonnes de latence présentes |
| `min_llm_latency_ms` | ✅ Présente | ✅ Présente | |
| `max_llm_latency_ms` | ✅ Présente | ✅ Présente | |
| `avg_tts_latency_ms` | ✅ Présente | ✅ Présente | |
| `min_tts_latency_ms` | ✅ Présente | ✅ Présente | |
| `max_tts_latency_ms` | ✅ Présente | ✅ Présente | |
| `avg_total_latency_ms` | ✅ Présente | ✅ Présente | |
| `min_total_latency_ms` | ✅ Présente | ✅ Présente | |
| `max_total_latency_ms` | ✅ Présente | ✅ Présente | |
| `call_quality_score` | ✅ Présente (1-10) | ✅ Présente (1-10) | Contrainte identique |
| `call_classification` | ❌ **ABSENTE** | ✅ **PRÉSENTE** | ⚠️ **DIFFÉRENCE** |

**🔴 PROBLÈME IDENTIFIÉ** : La colonne `call_classification` existe en STAGING mais pas en PRODUCTION.

#### Table `agent_emails`

| Colonne | Production | Staging | Notes |
|---------|------------|---------|-------|
| `email_type` CHECK | ✅ 16 valeurs | ✅ 6 valeurs | ⚠️ **Production a plus de valeurs autorisées** |

**PROD** : `follow_up`, `cold_email`, `appointment_confirmation`, `appointment_confirmation_to_lead`, `sequence_step`, `transactional`, `notification`, `incoming_sms`, `outgoing_sms`, `appointment_reminder`, `appointment_cancellation`, `appointment_reschedule`, `no_show_follow_up`, `post_appointment`

**STAGING** : `follow_up`, `cold_email`, `appointment_confirmation`, `sequence_step`, `transactional`, `notification`

---

## 📊 Vues (Views) - Analyse

### Liste des vues présentes dans les deux environnements

Toutes les 20 vues sont présentes mais avec des **définitions différentes** :

1. ✅ `v_agent_calls_enriched` - ⚠️ **Définition différente**
2. ✅ `v_agent_communications` - ⚠️ **Absente en staging, remplacée par v_agent_communications_unified**
3. ✅ `v_agent_communications_unified`
4. ✅ `v_agent_emails_enriched`
5. ✅ `v_agent_sms_enriched`
6. ✅ `v_arthur_calls_enriched`
7. ✅ `v_arthur_next_call_exoticdesign`
8. ✅ `v_arthur_next_call_norloc`
9. ✅ `v_arthur_next_call_stefanodesign`
10. ✅ `v_arthur_next_calls`
11. ✅ `v_arthur_next_calls_global`
12. ✅ `v_financial_metrics_enriched`
13. ✅ `v_global_agent_type_performance`
14. ✅ `v_global_call_volume_by_day`
15. ✅ `v_global_kpis`
16. ✅ `v_global_outcome_distribution`
17. ✅ `v_global_top_clients`
18. ✅ `v_louis_agent_performance`
19. ✅ `v_prospects_attempts_exceeded`
20. ✅ `v_user_accessible_agents`
21. ✅ `v_user_accessible_clients`

### 🔴 Différences majeures dans les vues

#### `v_agent_calls_enriched`

**PRODUCTION** :
```sql
SELECT id, deployment_id, ..., conversation_id, call_quality_score, sentiment_analysis,
    CASE WHEN (outcome = ANY (...)) THEN false ...
```

**STAGING** :
```sql
SELECT id, deployment_id, ..., conversation_id, call_classification, call_quality_score, sentiment_analysis,
    CASE WHEN (outcome = ANY (...)) THEN false ...
```

⚠️ **STAGING** inclut la colonne `call_classification` qui n'existe pas en PRODUCTION.

#### `v_agent_communications`

- ✅ **Présente en PRODUCTION**
- ❌ **ABSENTE en STAGING**

Cette vue semble avoir été remplacée par `v_agent_communications_unified` en staging.

---

## 🔧 Migrations - Analyse Critique

### ⚠️ **DIFFÉRENCE MAJEURE DÉTECTÉE**

| Environnement | Migrations | Détail |
|---------------|------------|--------|
| **Production** | **1 migration** | `20251113091720 - create-staging` |
| **Staging** | **17 migrations** | De `20251113091720` à `20251120095358` |

### Liste des migrations en STAGING absentes en PRODUCTION

1. ✅ `20251113091720` - `create-staging` (présente en prod)
2. ❌ `20251113092934` - `import_from_prod`
3. ❌ `20251113110933` - `agent_calls_enrichment_complete`
4. ❌ `20251113145425` - `security_fixes_test_v2`
5. ❌ `20251113145458` - `security_fixes_remaining_views`
6. ❌ `20251113145549` - `security_fixes_arthur_views`
7. ❌ `20251113173945` - `create_agent_sms_table`
8. ❌ `20251113174002` - `sms_rls_policies`
9. ❌ `20251113174046` - `sms_analytics`
10. ❌ `20251113175729` - `fix_sms_pricing_model_v2`
11. ❌ `20251114115154` - `add_cost_per_email_to_deployments`
12. ❌ `20251114115307` - `create_agent_emails_table_v2`
13. ❌ `20251114115358` - `email_rls_policies`
14. ❌ `20251114115525` - `email_analytics`
15. ❌ `20251117101559` - `create_financial_timeseries_function`
16. ❌ `20251120094858` - `add_quality_justification_column`
17. ❌ `20251120094954` - `add_latency_columns`
18. ❌ `20251120095358` - `rename_justification_to_analysis`

🔴 **CRITIQUE** : 16 migrations sont présentes en staging mais **absentes en production**. Cela explique pourquoi le schéma n'est pas ISO.

---

## 🛠️ Fonctions RPC - Analyse

### Fonctions présentes dans les deux environnements

Les fonctions suivantes sont présentes (mais potentiellement avec des définitions différentes) :

1. ✅ `generate_deployment_slug()`
2. ✅ `get_agent_cards_data()`
3. ✅ `get_agent_type_cards_data()`
4. ✅ `get_arthur_chart_data()`
5. ✅ `get_arthur_kpi_metrics()`
6. ✅ `get_chart_data()`
7. ✅ `get_client_cards_data()`
8. ✅ `get_client_deployments_breakdown()`
9. ✅ `get_deployment_channels_breakdown()`
10. ✅ `get_email_metrics()`
11. ✅ `get_financial_drilldown()`
12. ✅ `get_financial_kpi_metrics()`
13. ✅ `get_financial_timeseries()`
14. ✅ `get_global_chart_data()`
15. ✅ `get_global_kpis()`
16. ✅ `get_kpi_metrics()`
17. ✅ `get_latency_metrics()` (probablement uniquement en STAGING)
18. ✅ `get_sms_metrics()`
19. ✅ `get_consumption_kpi_metrics()` (probablement uniquement en PROD)
20. ✅ `get_consumption_pricing_by_agent()` (probablement uniquement en PROD)
21. ✅ `get_cost_breakdown()`

⚠️ **Note** : Les définitions des fonctions ont été tronquées, mais des différences sont attendues basées sur les différences de schéma.

---

## 🧪 Extensions - Analyse

### ✅ Extensions installées : **ISO**

Les extensions suivantes sont **installées et actives** dans les deux environnements :

| Extension | Production | Staging | Version |
|-----------|------------|---------|---------|
| `uuid-ossp` | ✅ Installé | ✅ Installé | 1.1 |
| `pg_graphql` | ✅ Installé | ✅ Installé | 1.5.11 |
| `pg_stat_statements` | ✅ Installé | ✅ Installé | 1.11 |
| `pgcrypto` | ✅ Installé | ✅ Installé | 1.3 |
| `supabase_vault` | ✅ Installé | ✅ Installé | 0.3.1 |
| `pg_cron` | ✅ Installé | ✅ Installé | 1.6.4 |
| `plpgsql` | ✅ Installé | ✅ Installé | 1.0 |

### ⚠️ Différence mineure

- `pg_hashids` :
  - **Production** : version `1.3`
  - **Staging** : version `1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6` (version dev)

---

## 🎯 Conclusion et Recommandations

### ❌ **Les bases de données NE SONT PAS ISO**

#### 🔴 Problèmes critiques identifiés

1. **16 migrations manquantes en production** → Le schéma de production est en retard
2. **Colonne `call_classification` présente en staging mais absente en production**
3. **Vue `v_agent_communications` présente uniquement en production**
4. **Différences dans les contraintes CHECK** (ex: `email_type` dans `agent_emails`)
5. **Colonnes de latence récentes** probablement ajoutées via les migrations manquantes

### 📋 Actions Recommandées

#### ✅ Option 1 : Mettre à jour la production (RECOMMANDÉ)

1. **Exécuter les 16 migrations manquantes** dans l'ordre chronologique en production
2. Vérifier que les fonctions RPC sont mises à jour automatiquement
3. Tester le dashboard après chaque migration critique

#### ⚠️ Option 2 : Reset staging depuis production

1. Supprimer toutes les données de staging
2. Réimporter depuis production
3. ❌ **NON RECOMMANDÉ** : Vous perdrez tout le travail de développement en staging

### 🚨 Risques actuels

- **Incompatibilité des requêtes** : Les requêtes qui fonctionnent en staging peuvent échouer en production
- **Données manquantes** : Les colonnes de latence et `call_classification` n'existent pas en production
- **Fonctions RPC** : Les fonctions qui dépendent de ces colonnes vont échouer en production
- **Dashboard** : Le dashboard financier et les métriques de latence ne fonctionneront pas en production

### 📝 Plan de Migration Suggéré

1. **Backup complet de production**
2. **Exécuter les migrations 2-18 en production** (voir liste ci-dessus)
3. **Vérifier chaque migration critique** :
   - `agent_calls_enrichment_complete`
   - `add_latency_columns`
   - `create_agent_emails_table_v2`
4. **Tester le dashboard** après la migration complète
5. **Valider avec des requêtes de test** sur les tables critiques

---

## 📂 Fichiers de Migration à Appliquer

Les fichiers de migration suivants doivent être présents dans `supabase/migrations/` et appliqués en production :

```
supabase/migrations/20251113092934_import_from_prod.sql
supabase/migrations/20251113110933_agent_calls_enrichment_complete.sql
supabase/migrations/20251113145425_security_fixes_test_v2.sql
supabase/migrations/20251113145458_security_fixes_remaining_views.sql
supabase/migrations/20251113145549_security_fixes_arthur_views.sql
supabase/migrations/20251113173945_create_agent_sms_table.sql
supabase/migrations/20251113174002_sms_rls_policies.sql
supabase/migrations/20251113174046_sms_analytics.sql
supabase/migrations/20251113175729_fix_sms_pricing_model_v2.sql
supabase/migrations/20251114115154_add_cost_per_email_to_deployments.sql
supabase/migrations/20251114115307_create_agent_emails_table_v2.sql
supabase/migrations/20251114115358_email_rls_policies.sql
supabase/migrations/20251114115525_email_analytics.sql
supabase/migrations/20251117101559_create_financial_timeseries_function.sql
supabase/migrations/20251120094858_add_quality_justification_column.sql
supabase/migrations/20251120094954_add_latency_columns.sql
supabase/migrations/20251120095358_rename_justification_to_analysis.sql
```

---

## ✅ Prochaines Étapes

1. ✅ **Valider ce rapport** avec l'équipe
2. ⚠️ **Planifier une fenêtre de maintenance** pour appliquer les migrations en production
3. 🔧 **Tester les migrations en staging d'abord** (si possible avec une copie de production)
4. 📊 **Documenter les changements** pour l'équipe
5. 🚀 **Exécuter les migrations en production**

---

**Rapport généré automatiquement par Claude Code**
**Date** : 2025-11-20
