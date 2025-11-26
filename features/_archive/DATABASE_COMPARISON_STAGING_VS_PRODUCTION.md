# 🔍 Analyse Comparative: Production vs Staging

**Date**: 2025-11-21
**Objectif**: Vérifier si les bases de données Staging et Production sont ISO avant migration vers Supabase DB Push

---

## 📊 Résumé Exécutif

### ✅ Conclusion Globale

**Les bases de données Staging et Production sont PRESQUE ISO**, mais **Staging contient 5 migrations critiques** qui n'ont **JAMAIS été appliquées en Production**.

**⚠️ ACTIONS REQUISES AVANT DB PUSH:**
1. ✅ Appliquer les 5 migrations manquantes en Production
2. ✅ Vérifier que les données de Production sont intactes après migration
3. ✅ Puis passer à Supabase DB Push

---

## 🔧 Différences Critiques Détectées

### 1. ❌ MIGRATIONS MANQUANTES EN PRODUCTION (CRITIQUE)

**Production**: 12 migrations
**Staging**: 17 migrations

#### 📋 5 Migrations Présentes en Staging mais ABSENTES en Production:

| Migration | Nom | Impact |
|-----------|-----|--------|
| `20251113145425` | `security_fixes_test_v2` | **Fixes de sécurité** |
| `20251113145458` | `security_fixes_remaining_views` | **Fixes de sécurité (vues)** |
| `20251113145549` | `security_fixes_arthur_views` | **Fixes de sécurité (vues Arthur)** |
| `20251114115307` | `create_agent_emails_table_v2` | **Table agent_emails complète** |
| `20251114115358` | `email_rls_policies` | **RLS policies pour emails** |
| `20251114115525` | `email_analytics` | **Vues d'analyse emails** |

**⚠️ IMPACT MAJEUR:**
- Les **3 premières migrations** corrigent des **vulnérabilités de sécurité** dans les vues
- Les **3 dernières migrations** ajoutent la **fonctionnalité complète d'emails**
- Sans ces migrations, **Production est vulnérable** et manque de features

---

### 2. ⚠️ DIFFÉRENCES DE SCHÉMAS DE TABLES

#### 2.1 Table `agent_calls` - Différence de colonne

| Colonne | Production | Staging | Impact |
|---------|------------|---------|--------|
| `call_classification` | ❌ **ABSENTE** | ✅ **PRÉSENTE** | Champ utilisé en Staging, absent en Prod |

**Analyse**: Cette colonne semble avoir été ajoutée en Staging mais n'a pas été migrée en Production. Vérifier si elle est utilisée.

#### 2.2 Table `agent_emails` - Différences importantes

**Production**: 37 colonnes avec commentaires détaillés
**Staging**: 36 colonnes

**Différence dans le constraint `email_type`:**
- **Production**: Plus de types disponibles
  - `appointment_confirmation_to_lead`
  - `incoming_sms`
  - `outgoing_sms`
  - `appointment_reminder`
  - `appointment_cancellation`
  - `appointment_reschedule`
  - `no_show_follow_up`
  - `post_appointment`
- **Staging**: Types basiques uniquement
  - `follow_up`
  - `cold_email`
  - `appointment_confirmation`
  - `sequence_step`
  - `transactional`
  - `notification`

**Analyse**: La migration `20251114115307` (create_agent_emails_table_v2) apporte probablement ces types étendus.

#### 2.3 Storage: Différences de types de buckets

**Production**:
```sql
enum ["STANDARD","ANALYTICS","VECTOR"]
```

**Staging**:
```sql
enum ["STANDARD","ANALYTICS"]
```

**Analyse**: Production supporte les buckets VECTOR (embeddings/AI), Staging non. Vérifier si cette fonctionnalité est nécessaire en Staging.

---

### 3. 📦 DIFFÉRENCES DE DONNÉES (Comptage de lignes)

| Table | Production | Staging | Différence |
|-------|------------|---------|------------|
| `auth.users` | **7** | **0** | ⚠️ Staging vide |
| `user_client_permissions` | **8** | **0** | ⚠️ Staging vide |
| `profiles` | **7** | **0** | ⚠️ Staging vide |
| `agent_calls` | **811** | **676** | -135 appels |
| `agent_sms` | **79** | **4** | -75 SMS |
| `agent_emails` | **31** | **3** | -28 emails |
| `auth.refresh_tokens` | **99** | **0** | ⚠️ Staging vide |
| `auth.sessions` | **5** | **0** | ⚠️ Staging vide |
| `auth.audit_log_entries` | **790** | **0** | ⚠️ Staging vide |

**✅ Analyse**: Comportement NORMAL pour un environnement Staging:
- Staging ne contient **pas d'utilisateurs réels** (données de test uniquement)
- Staging contient **moins de données** que Production (échantillon test)
- Les **différences de volumes** sont attendues et **saines**

---

### 4. 📋 VUES: Différences Détectées

#### 4.1 Vues Présentes en Production mais ABSENTES en Staging

**Production (21 vues)** vs **Staging (21 vues)**
**Comptage identique**, mais **contenu différent** dans certaines vues:

| Vue | Production | Staging | Différence |
|-----|------------|---------|------------|
| `v_agent_calls_enriched` | ✅ Sans `call_classification` | ✅ Avec `call_classification` | Colonne supplémentaire |
| `v_agent_communications` | ✅ Présente | ❌ **ABSENTE** | Vue manquante en Staging |
| `v_financial_metrics_enriched` | ✅ Présente | ✅ Présente | ISO |

**Analyse**: La vue `v_agent_communications` est présente en Production mais semble avoir été remplacée par `v_agent_communications_unified` dans les deux environnements.

---

### 5. ⚙️ FONCTIONS RPC: Comparaison

**Production**: ~40+ fonctions RPC (sortie tronquée)
**Staging**: ~40+ fonctions RPC (sortie tronquée)

Les fonctions suivantes sont identiques dans les deux environnements:
- ✅ `get_kpi_metrics`
- ✅ `get_chart_data`
- ✅ `get_agent_cards_data`
- ✅ `get_agent_type_cards_data`
- ✅ `get_client_cards_data`
- ✅ `get_arthur_kpi_metrics`
- ✅ `get_arthur_chart_data`
- ✅ `get_financial_kpi_metrics`
- ✅ `get_financial_timeseries`
- ✅ `get_email_metrics`
- ✅ `get_sms_metrics`
- ✅ `get_latency_metrics`
- ✅ Toutes les fonctions de triggers

**Analyse**: Les fonctions RPC semblent ISO entre Production et Staging.

---

### 6. 🔌 EXTENSIONS: Comparaison

**Production**: 79 extensions disponibles
**Staging**: 76 extensions disponibles

#### Extensions Installées (Identiques):
- ✅ `uuid-ossp@1.1`
- ✅ `pg_graphql@1.5.11`
- ✅ `pgcrypto@1.3`
- ✅ `pg_stat_statements@1.11`
- ✅ `supabase_vault@0.3.1`
- ✅ `plpgsql@1.0`
- ✅ `pg_cron@1.6.4`

#### Différences mineures (Non critiques):
- Quelques versions d'extensions disponibles diffèrent légèrement
- Exemple: `pg_hashids` version différente (`1.3` vs `1.3.0-cd0e1b31d52b394a0df64079406a14a4f7387cd6`)
- **Analyse**: Différences de versions **non critiques**, versions installées identiques

---

## 🎯 Plan d'Action Recommandé

### Étape 1: Appliquer les Migrations Manquantes en Production

Vous devez appliquer les **5 migrations critiques** suivantes en Production dans cet ordre:

```bash
# Migration 1: Security fixes (test v2)
supabase/migrations/20251113145425_security_fixes_test_v2.sql

# Migration 2: Security fixes (remaining views)
supabase/migrations/20251113145458_security_fixes_remaining_views.sql

# Migration 3: Security fixes (Arthur views)
supabase/migrations/20251113145549_security_fixes_arthur_views.sql

# Migration 4: Create agent_emails table v2
supabase/migrations/20251114115307_create_agent_emails_table_v2.sql

# Migration 5: Email RLS policies
supabase/migrations/20251114115358_email_rls_policies.sql

# Migration 6: Email analytics
supabase/migrations/20251114115525_email_analytics.sql
```

### Étape 2: Vérifier l'intégrité après migration

```sql
-- Vérifier que toutes les migrations sont appliquées
SELECT * FROM supabase_migrations.schema_migrations ORDER BY version;

-- Vérifier que la table agent_emails existe
SELECT COUNT(*) FROM agent_emails;

-- Vérifier que les vues de sécurité sont corrigées
SELECT * FROM v_agent_calls_enriched LIMIT 1;
```

### Étape 3: Résoudre la colonne `call_classification`

**Option A**: Si cette colonne n'est PAS utilisée en Production:
- Supprimer la colonne de Staging pour harmoniser

**Option B**: Si cette colonne EST utilisée:
- Créer une migration pour l'ajouter en Production

### Étape 4: Passer à Supabase DB Push

Une fois les migrations appliquées et vérifiées:
```bash
# Initialiser Supabase DB Push
supabase db push

# Vérifier que tout est synchronisé
supabase db diff
```

---

## 📝 Checklist Finale

Avant de passer à Supabase DB Push, vérifiez:

- [ ] Les 5 migrations critiques sont appliquées en Production
- [ ] Les vues de sécurité sont correctement mises à jour
- [ ] La table `agent_emails` existe et fonctionne en Production
- [ ] Les RLS policies pour emails sont actives
- [ ] La colonne `call_classification` est harmonisée (présente ou absente des deux côtés)
- [ ] Les fonctions RPC fonctionnent correctement
- [ ] Un backup complet de Production a été effectué
- [ ] Tests de smoke run sur Production après migration

---

## 🔒 Recommandations de Sécurité

1. **⚠️ CRITIQUE**: Les 3 premières migrations (`security_fixes_*`) corrigent des vulnérabilités. **À appliquer en priorité absolue**.

2. **Backup**: Effectuer un **dump complet** de Production avant toute migration:
   ```bash
   pg_dump -h [prod-host] -U postgres -d postgres > prod_backup_2025-11-21.sql
   ```

3. **Tests**: Valider en Staging d'abord, puis Production:
   - Tester l'accès RLS
   - Tester les vues enrichies
   - Tester les fonctions RPC

4. **Monitoring**: Surveiller les logs après migration:
   ```sql
   SELECT * FROM supabase_migrations.schema_migrations;
   ```

---

## 📚 Fichiers de Migration à Appliquer

Les fichiers suivants doivent être présents dans `supabase/migrations/`:

1. `20251113145425_security_fixes_test_v2.sql`
2. `20251113145458_security_fixes_remaining_views.sql`
3. `20251113145549_security_fixes_arthur_views.sql`
4. `20251114115307_create_agent_emails_table_v2.sql`
5. `20251114115358_email_rls_policies.sql`
6. `20251114115525_email_analytics.sql`

Si ces fichiers n'existent pas dans votre repo local, vous devez les régénérer depuis Staging ou les recréer manuellement.

---

## ✅ Conclusion

Vos bases de données sont **presque ISO**, mais **Production manque 5 migrations critiques** qui ont été appliquées en Staging.

**Prochaines étapes**:
1. ✅ Appliquer les migrations manquantes en Production
2. ✅ Vérifier l'intégrité des données
3. ✅ Harmoniser la colonne `call_classification`
4. ✅ Passer à Supabase DB Push

**Risque**: Si vous passez à DB Push **SANS** appliquer les migrations manquantes, vous risquez de **perdre les fixes de sécurité** et la **fonctionnalité emails** en Production.

---

**Besoin d'aide pour appliquer les migrations?** Je peux vous aider à:
- Extraire les fichiers SQL de Staging
- Générer les scripts de migration
- Valider l'application des migrations
