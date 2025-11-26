# 🔄 Guide Simplifié : Migration Production → Staging (via Supabase CLI)

**Date** : 2025-11-21
**Objectif** : Cloner Production vers Staging pour repartir sur des bases ISO
**Workflow cible** : Dev en Staging → Migration vers Production via Supabase DB Push
**Forfait** : Compatible Free Plan (pas de backup UI requis)

---

## 📊 Contexte

Suite à l'analyse comparative, nous avons découvert que **Production est plus avancée que Staging** :
- Production a des features manquantes en Staging (types d'emails étendus, support VECTOR, etc.)
- Staging a 5 migrations qui n'ont jamais été appliquées en Production
- Les schémas ne sont pas synchronisés

**Solution** : Cloner Production → Staging pour avoir un environnement ISO

---

## ⚠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ Accès administrateur aux deux projets Supabase (Production + Staging)
- ✅ Connexion Internet stable
- ✅ Espace disque suffisant pour les dumps (~200-500MB)
- ✅ **Supabase CLI installé** (`npm install -g supabase`)
- ✅ Vos credentials de connexion Supabase pour Production et Staging

**⚠️ Note Importante** : Ce guide ne crée PAS de backup de Staging car :
- Vous êtes en forfait Free (pas de backup automatique UI)
- Nous allons **tout écraser** de toute façon avec les données de Production
- Si vous avez des données importantes en Staging, faites un backup manuel avant

---

## 🚀 Étape 1 : Dump de Production (via Supabase CLI)

**Objectif** : Exporter l'intégralité du schéma et des données de Production via Supabase CLI

### 1.1 Vérifier l'Installation de Supabase CLI

```bash
# Vérifier que Supabase CLI est installé
supabase --version

# Si pas installé :
npm install -g supabase

# Se connecter à Supabase
supabase login
```

### 1.2 Récupérer les Connection Strings

**Pour Production** :
1. Dashboard Supabase → Projet **Production**
2. **Settings** → **Database**
3. Copiez la **Connection string** (section "Connection string")
4. Format : `postgresql://postgres:[PASSWORD]@db.[project-ref].supabase.co:5432/postgres`

**Pour Staging** :
1. Dashboard Supabase → Projet **Staging**
2. **Settings** → **Database**
3. Copiez la **Connection string**

**⚠️ Important** : Remplacez `[PASSWORD]` par votre mot de passe réel dans les commandes ci-dessous

### 1.3 Créer le Dump de Production avec Supabase CLI

```bash
# Créer le dossier pour les dumps (si nécessaire)
mkdir -p dbDump

# Dump de Production via Supabase CLI
supabase db dump \
  --db-url "postgresql://postgres:[PASSWORD]@db.[prod-project-ref].supabase.co:5432/postgres" \
  --file dbDump/production_dump_$(date +%Y%m%d_%H%M%S).sql

# Alternative avec variables d'environnement (plus sécurisé)
export PROD_DB_URL="postgresql://postgres:[PASSWORD]@db.[prod-project-ref].supabase.co:5432/postgres"

supabase db dump \
  --db-url "$PROD_DB_URL" \
  --file dbDump/production_dump_$(date +%Y%m%d_%H%M%S).sql
```

**Sur Windows (PowerShell)** :
```powershell
# Créer le dossier
New-Item -ItemType Directory -Force -Path dbDump

# Dump de Production
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
supabase db dump `
  --db-url "postgresql://postgres:[PASSWORD]@db.[prod-project-ref].supabase.co:5432/postgres" `
  --file "dbDump/production_dump_$timestamp.sql"
```

### 1.4 Vérifier le Contenu du Dump

```bash
# Vérifier que le fichier a été créé
ls -lh dbDump/

# Compter le nombre de lignes (doit être > 10,000)
wc -l dbDump/production_dump_*.sql

# Vérifier la présence des objets principaux
grep -c "CREATE TABLE" dbDump/production_dump_*.sql
grep -c "CREATE VIEW" dbDump/production_dump_*.sql
grep -c "CREATE FUNCTION" dbDump/production_dump_*.sql
```

**Sur Windows** :
```powershell
# Vérifier le fichier
Get-ChildItem dbDump/

# Compter les lignes
(Get-Content dbDump/production_dump_*.sql | Measure-Object -Line).Lines

# Compter les objets
(Select-String -Path "dbDump/production_dump_*.sql" -Pattern "CREATE TABLE").Count
(Select-String -Path "dbDump/production_dump_*.sql" -Pattern "CREATE VIEW").Count
(Select-String -Path "dbDump/production_dump_*.sql" -Pattern "CREATE FUNCTION").Count
```

**Résultat attendu** :
- ✅ Fichier de plusieurs MB (~50-200MB)
- ✅ ~10,000-20,000+ lignes
- ✅ ~40-50 CREATE TABLE
- ✅ ~20-25 CREATE VIEW
- ✅ ~40+ CREATE FUNCTION

---

## 🧹 Étape 2 : Reset de Staging

**Objectif** : Nettoyer complètement Staging avant d'importer le dump de Production

### 2.1 Option A : Reset via Dashboard Supabase (Recommandé si disponible)

**⚠️ ATTENTION** : Cette action est **IRRÉVERSIBLE** et supprime TOUTES les données de Staging

1. Allez sur le dashboard Supabase du projet **Staging**
2. **Settings** → **Database** → scrollez jusqu'à **"Database Settings"**
3. Cherchez l'option **"Reset Database Password"** ou section similaire
4. **Note** : Sur le forfait Free, il n'y a peut-être pas d'option "Reset Database" complète

**Si cette option n'existe pas** → Passez à l'Option B

### 2.2 Option B : Nettoyer via Supabase CLI (Alternative)

```bash
# Se connecter au projet Staging
supabase link --project-ref [staging-project-ref]

# Voir les migrations actuelles
supabase migration list

# Reset de la base de données locale (si vous utilisez supabase local)
# Note : Cela ne fonctionne que pour une instance locale
supabase db reset
```

**⚠️ Note** : `supabase db reset` ne fonctionne que pour les bases locales. Pour reset une base remote, utilisez l'Option C.

### 2.3 Option C : Nettoyer via SQL (Solution universelle)

Exécutez ce script dans **SQL Editor de Staging** (Dashboard Supabase) :

```sql
-- ⚠️ DANGER : Supprime TOUTES les données du schéma public en Staging
-- Exécuter dans Supabase SQL Editor (Staging uniquement)

-- 1. Supprimer toutes les vues (dépendent des tables)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
    ) LOOP
        EXECUTE 'DROP VIEW IF EXISTS public.' || quote_ident(r.table_name) || ' CASCADE';
    END LOOP;
END $$;

-- 2. Supprimer toutes les fonctions
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT routine_name, routine_schema
        FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_type = 'FUNCTION'
    ) LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.routine_name) || ' CASCADE';
    END LOOP;
END $$;

-- 3. Supprimer toutes les tables
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- 4. Vérifier que tout est nettoyé
SELECT 'Tables restantes' as type, COUNT(*)::text as count
FROM pg_tables WHERE schemaname = 'public'
UNION ALL
SELECT 'Vues restantes', COUNT(*)::text
FROM information_schema.views WHERE table_schema = 'public'
UNION ALL
SELECT 'Fonctions restantes', COUNT(*)::text
FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

**Résultat attendu** : Tous les comptages doivent être `0`

---

## 📥 Étape 3 : Restaurer Production en Staging

**Objectif** : Importer le dump de Production dans Staging (maintenant vide)

### 3.1 Restaurer via psql (Méthode Standard)

```bash
# Restaurer le dump en Staging
psql "postgresql://postgres:[PASSWORD]@db.[staging-project-ref].supabase.co:5432/postgres" \
  -f dbDump/production_dump_[timestamp].sql

# Ou avec variable d'environnement
export STAGING_DB_URL="postgresql://postgres:[PASSWORD]@db.[staging-project-ref].supabase.co:5432/postgres"

psql "$STAGING_DB_URL" -f dbDump/production_dump_[timestamp].sql
```

**Sur Windows** :
```powershell
# Trouver le chemin de psql (installé avec PostgreSQL ou Supabase CLI)
# Généralement : C:\Program Files\PostgreSQL\16\bin\psql.exe

$env:STAGING_DB_URL = "postgresql://postgres:[PASSWORD]@db.[staging-project-ref].supabase.co:5432/postgres"

& "C:\Program Files\PostgreSQL\16\bin\psql.exe" $env:STAGING_DB_URL -f "dbDump/production_dump_[timestamp].sql"
```

**⚠️ Attendu pendant l'import** (5-15 minutes selon la taille) :
- Messages `CREATE TABLE`, `CREATE VIEW`, `CREATE FUNCTION`
- Messages `INSERT INTO` pour les données
- Messages `ALTER TABLE` pour les contraintes
- **Warnings normaux** :
  - `role "postgres" does not exist` → Ignorez
  - `schema "auth" does not exist` → Ignorez (géré par Supabase)
  - `permission denied on schema storage` → Ignorez

**Erreurs à surveiller** :
- ❌ `ERROR: relation already exists` → Étape 2 (nettoyage) incomplète
- ❌ `ERROR: syntax error` → Fichier dump corrompu, refaire l'étape 1

### 3.2 Alternative : Restaurer via Supabase CLI (si disponible)

```bash
# Restaurer le dump via Supabase CLI
supabase db push \
  --db-url "postgresql://postgres:[PASSWORD]@db.[staging-project-ref].supabase.co:5432/postgres" \
  --file dbDump/production_dump_[timestamp].sql
```

**Note** : Cette commande peut ne pas fonctionner pour des dumps complets. Privilégiez `psql`.

---

## ✅ Étape 4 : Vérification Post-Migration

**Objectif** : Confirmer que Staging est maintenant un clone exact de Production

### 4.1 Vérifier les Migrations (SQL Editor Staging)

```sql
-- Vérifier les migrations enregistrées
SELECT version, name, executed_at
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

**Résultat attendu** :
- ✅ Exactement **12 migrations** (même nombre que Production avant la migration)
- ✅ Pas les 5 migrations "extra" qui étaient en Staging avant (`security_fixes_*`, `email_*`)

### 4.2 Vérifier les Tables

```sql
-- Compter les tables du schéma public
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
```

**Résultat attendu** : `44 tables`

### 4.3 Vérifier les Vues

```sql
-- Compter les vues
SELECT COUNT(*) as view_count
FROM information_schema.views
WHERE table_schema = 'public';
```

**Résultat attendu** : `21 vues`

### 4.4 Vérifier les Fonctions RPC

```sql
-- Compter les fonctions
SELECT COUNT(*) as function_count
FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

**Résultat attendu** : `~40-45 fonctions`

### 4.5 Vérifier les Données (Volumes)

```sql
-- Vérifier les volumes de données copiées
SELECT
    'agent_calls' as table_name, COUNT(*) as row_count
FROM agent_calls
UNION ALL
SELECT 'agent_sms', COUNT(*) FROM agent_sms
UNION ALL
SELECT 'agent_emails', COUNT(*) FROM agent_emails
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'agent_deployments', COUNT(*) FROM agent_deployments
UNION ALL
SELECT 'agent_types', COUNT(*) FROM agent_types
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT 'user_client_permissions', COUNT(*) FROM user_client_permissions
ORDER BY table_name;
```

**Résultat attendu** (doit correspondre à Production) :
| table_name | row_count |
|------------|-----------|
| agent_calls | 811 |
| agent_deployments | 8 |
| agent_emails | 31 |
| agent_sms | 79 |
| agent_types | 2 |
| clients | 5 |
| profiles | 7 |
| user_client_permissions | 8 |

### 4.6 Vérifier les Schémas Spécifiques

**Vérifier la colonne `call_classification`** (doit être ABSENTE comme en Prod) :
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'agent_calls' AND column_name = 'call_classification';
```
**Résultat attendu** : `0 lignes` (colonne n'existe pas)

**Vérifier les types d'emails** :
```sql
-- Lister les valeurs enum pour email_type
SELECT
    t.typname as enum_name,
    e.enumlabel as enum_value,
    e.enumsortorder as sort_order
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE t.typname LIKE '%email_type%'
ORDER BY e.enumsortorder;
```

**Résultat attendu** : 14 types d'emails (Production) :
- `follow_up`
- `cold_email`
- `appointment_confirmation`
- `appointment_confirmation_to_lead`
- `sequence_step`
- `transactional`
- `notification`
- `incoming_sms`
- `outgoing_sms`
- `appointment_reminder`
- `appointment_cancellation`
- `appointment_reschedule`
- `no_show_follow_up`
- `post_appointment`

### 4.7 Tester une Vue et une Fonction RPC

```sql
-- Tester une vue enrichie
SELECT
    id,
    client_name,
    agent_name,
    outcome,
    answered,
    appointment_scheduled
FROM v_agent_calls_enriched
LIMIT 5;

-- Résultat attendu : 5 lignes avec données enrichies

-- Tester une fonction RPC
SELECT * FROM get_kpi_metrics(
    p_start_date := '2024-01-01'::date,
    p_end_date := CURRENT_DATE,
    p_agent_type_name := 'louis'
);

-- Résultat attendu : KPIs de Louis
```

---

## 🔧 Étape 5 : Configuration pour Supabase DB Push

**Objectif** : Préparer votre workflow pour utiliser Supabase DB Push à partir de maintenant

### 5.1 Lier le Projet Staging avec Supabase CLI

```bash
# Se placer dans le dossier du projet
cd C:\Users\pc\Documents\Projets\voipia-landing

# Lier le projet Staging
supabase link --project-ref [staging-project-ref]

# Le CLI va vous demander le mot de passe de la base
# Entrez le mot de passe de Staging

# Vérifier que le lien est actif
supabase projects list
```

### 5.2 Générer les Migrations Locales depuis Staging

```bash
# Créer un backup des anciennes migrations locales (au cas où)
mkdir -p supabase/migrations_backup
cp supabase/migrations/*.sql supabase/migrations_backup/ 2>/dev/null || true

# Supprimer les anciennes migrations locales
rm -f supabase/migrations/*.sql

# Générer les migrations depuis Staging (maintenant ISO avec Production)
supabase db pull

# Vérifier les migrations générées
ls -la supabase/migrations/
```

**Sur Windows** :
```powershell
# Backup des anciennes migrations
New-Item -ItemType Directory -Force -Path supabase\migrations_backup
Copy-Item "supabase\migrations\*.sql" "supabase\migrations_backup\" -ErrorAction SilentlyContinue

# Supprimer les anciennes migrations
Remove-Item "supabase\migrations\*.sql" -ErrorAction SilentlyContinue

# Générer depuis Staging
supabase db pull

# Vérifier
Get-ChildItem supabase\migrations\
```

**Résultat attendu** :
- ✅ Un fichier de migration avec timestamp récent (ex: `20251121120000_remote_schema.sql`)
- ✅ Contenu : Tout le schéma de Staging (= Production maintenant)

### 5.3 Tester le Workflow DB Push

```bash
# Test 1 : Créer une migration de test
supabase migration new test_db_push_workflow

# Éditer le fichier créé et ajouter :
cat > supabase/migrations/[timestamp]_test_db_push_workflow.sql << 'EOF'
-- Test DB Push workflow
-- Ajouter une colonne de test dans la table clients
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS test_column text DEFAULT 'test_value';

-- Vérification
COMMENT ON COLUMN clients.test_column IS 'Colonne de test pour vérifier DB Push';
EOF

# Test 2 : Pousser vers Staging
supabase db push

# Test 3 : Vérifier dans Staging (SQL Editor)
# SELECT column_name, data_type, column_default
# FROM information_schema.columns
# WHERE table_name = 'clients' AND column_name = 'test_column';

# Test 4 : Supprimer la colonne de test
supabase migration new remove_test_column
cat > supabase/migrations/[nouveau_timestamp]_remove_test_column.sql << 'EOF'
-- Supprimer la colonne de test
ALTER TABLE clients DROP COLUMN IF EXISTS test_column;
EOF

# Test 5 : Pousser à nouveau
supabase db push
```

**Si tout fonctionne** : ✅ Votre workflow DB Push est opérationnel !

---

## 🎯 Workflow Recommandé Post-Migration

Une fois la migration complétée et DB Push configuré :

### Pour Chaque Nouvelle Feature ou Modification de Base

```
1. Développement Local (optionnel)
   └─ supabase start (Docker requis)
   └─ Tester localement

2. Créer Migration
   ├─ supabase migration new ma_feature
   ├─ Éditer supabase/migrations/[timestamp]_ma_feature.sql
   └─ Écrire le SQL (CREATE TABLE, ALTER, etc.)

3. Tester en Staging
   ├─ supabase db push (lié à Staging)
   ├─ Vérifier dans l'app sur Staging
   └─ Tester les fonctionnalités

4. Validation et Merge
   ├─ Commit + Push Git
   ├─ Créer PR
   ├─ Code review
   └─ Merge vers main

5. Déploiement Production
   ├─ supabase link --project-ref [prod-ref] (changer de projet)
   ├─ supabase db push
   └─ Vérifier en Production
```

### Commandes Supabase CLI Essentielles

```bash
# Voir les différences entre local et remote
supabase db diff --linked

# Créer une nouvelle migration
supabase migration new nom_migration

# Appliquer les migrations vers remote
supabase db push

# Récupérer le schéma remote vers local
supabase db pull

# Voir l'historique des migrations
supabase migration list

# Changer de projet lié
supabase link --project-ref [autre-project-ref]

# Voir quel projet est lié actuellement
supabase projects list
```

### Exemple : Ajouter une Colonne

```bash
# 1. Créer la migration
supabase migration new add_priority_to_clients

# 2. Éditer le fichier
# supabase/migrations/[timestamp]_add_priority_to_clients.sql
cat > supabase/migrations/[timestamp]_add_priority_to_clients.sql << 'EOF'
-- Add priority column to clients table
ALTER TABLE clients
ADD COLUMN priority text
CHECK (priority IN ('low', 'medium', 'high', 'critical'))
DEFAULT 'medium';

-- Add index for performance
CREATE INDEX idx_clients_priority ON clients(priority);

-- Update existing clients
UPDATE clients SET priority = 'high' WHERE id IN (1, 2);

COMMENT ON COLUMN clients.priority IS 'Client priority level for support';
EOF

# 3. Pousser vers Staging (assurez-vous d'être lié à Staging)
supabase link --project-ref [staging-ref]
supabase db push

# 4. Tester en Staging
# (Vérifier dans votre app)

# 5. Pousser vers Production
supabase link --project-ref [prod-ref]
supabase db push
```

---

## 📋 Checklist Finale

Avant de considérer la migration complète, vérifiez :

### Phase 1 : Dump et Reset
- [ ] Supabase CLI installé et connecté (`supabase login`)
- [ ] Dump de Production créé via `supabase db dump` (> 10,000 lignes)
- [ ] Staging nettoyé complètement (Option A, B ou C)

### Phase 2 : Restauration
- [ ] Dump restauré en Staging sans erreurs critiques
- [ ] Warnings normaux ignorés (auth, storage, postgres role)

### Phase 3 : Vérifications
- [ ] Migrations synchronisées : 12 migrations identiques
- [ ] Tables synchronisées : 44 tables
- [ ] Vues synchronisées : 21 vues
- [ ] Fonctions synchronisées : ~40-45 fonctions
- [ ] Données copiées : Volumes identiques à Production
- [ ] Schéma `call_classification` : Colonne ABSENTE (comme Production)
- [ ] Email types : 14 types présents (comme Production)
- [ ] Vues testées : `v_agent_calls_enriched` retourne des données
- [ ] Fonctions testées : `get_kpi_metrics()` fonctionne

### Phase 4 : Configuration DB Push
- [ ] Projet Staging lié dans Supabase CLI
- [ ] Migrations locales générées via `supabase db pull`
- [ ] Test DB Push effectué avec succès
- [ ] Colonne de test créée et supprimée avec succès

### Phase 5 : Documentation
- [ ] Workflow Dev → Staging → Prod documenté
- [ ] Équipe informée du nouveau workflow
- [ ] Projet Production lié dans CLI (pour déploiements futurs)

---

## 🚨 Troubleshooting

### Problème 1 : "psql: command not found"

**Cause** : PostgreSQL client pas installé

**Solution Windows** :
```powershell
# Télécharger et installer PostgreSQL depuis :
# https://www.postgresql.org/download/windows/
# OU utiliser Supabase CLI qui inclut psql

# Vérifier l'installation
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" --version
```

**Solution Mac/Linux** :
```bash
# Mac
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Vérifier
psql --version
```

### Problème 2 : "ERROR: relation already exists"

**Cause** : Staging n'a pas été nettoyé correctement

**Solution** : Recommencer l'Étape 2 (Reset de Staging) avec l'Option C (SQL)

### Problème 3 : "Password authentication failed"

**Cause** : Mot de passe incorrect dans la connection string

**Solution** :
1. Vérifiez le mot de passe dans le Dashboard Supabase
2. Attention aux caractères spéciaux (encodez-les : `@` → `%40`, `#` → `%23`)
3. Utilisez des guillemets autour de l'URL : `"postgresql://..."`

### Problème 4 : "supabase db push" ne fonctionne pas

**Cause** : Projet pas lié ou mauvais projet lié

**Solution** :
```bash
# Vérifier quel projet est lié
supabase projects list

# Se lier au bon projet
supabase link --project-ref [staging-ref]

# Réessayer
supabase db push
```

### Problème 5 : Dump très lent ou timeout

**Cause** : Connexion lente ou base volumineuse

**Solution** :
```bash
# Augmenter le timeout (via psql directement)
PGCONNECT_TIMEOUT=600 psql "$STAGING_DB_URL" -f dbDump/production_dump_*.sql
```

---

## 💡 Conseils Pro

1. **Timing** : Faites cette migration pendant une période de faible activité (week-end, soirée)

2. **Communication** : Prévenez votre équipe que Staging sera indisponible 30-60 minutes

3. **Tests** : Testez l'application sur Staging immédiatement après la migration

4. **Monitoring** : Surveillez les logs Supabase (Dashboard → Logs) après la migration

5. **Documentation** : Ajoutez une note dans votre CHANGELOG ou notes de release

6. **Git** : Commitez les nouvelles migrations générées par `supabase db pull`
   ```bash
   git add supabase/migrations/
   git commit -m "chore: sync migrations after prod→staging clone"
   git push
   ```

7. **Cleanup** : Après 7 jours de validation, vous pouvez supprimer le dump :
   ```bash
   rm dbDump/production_dump_*.sql
   ```

---

## 🎓 Ressources Supplémentaires

- [Supabase CLI Documentation](https://supabase.com/docs/guides/cli)
- [Supabase CLI - Database Migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [Supabase CLI - db dump](https://supabase.com/docs/reference/cli/supabase-db-dump)
- [Supabase CLI - db push](https://supabase.com/docs/reference/cli/supabase-db-push)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)

---

## ✅ Conclusion

Une fois cette migration complétée avec succès :

✅ **Staging = Clone exact de Production** (schéma + données)
✅ **Workflow DB Push opérationnel** (Dev → Staging → Prod)
✅ **Migrations sous contrôle de version** (Git)
✅ **Incohérences éliminées** (plus de drift entre environnements)
✅ **Prêt pour le développement** (modifications sécurisées en Staging)

**Durée estimée** : 30-60 minutes (dump + restore + vérifications)

**Prochaine étape** : Commencer par l'Étape 1 (Dump de Production via Supabase CLI)

---

**Questions ou problèmes ?** Consultez la section Troubleshooting ou demandez de l'assistance !
