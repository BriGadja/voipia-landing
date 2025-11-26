# 🚀 Guide des Bonnes Pratiques - Migrations Supabase

**Date** : 2025-11-20
**Pour** : Garder le tableau de migrations synchronisé avec le schéma réel

---

## 🎯 Le Problème

Quand vous exécutez des migrations SQL manuellement via le Dashboard Supabase (SQL Editor), le schéma est modifié **MAIS** la migration n'est pas enregistrée dans `supabase_migrations.schema_migrations`.

**Conséquence** :
- ❌ Le tableau de migrations ne reflète pas la réalité
- ❌ Confusion pour l'équipe sur ce qui a été appliqué
- ❌ Impossible de savoir quelles migrations manquent

---

## ✅ Solution 1 : Utiliser `supabase db push` (RECOMMANDÉ)

### Pourquoi c'est la meilleure méthode ?

- ✅ **Automatique** : Enregistre les migrations automatiquement
- ✅ **Sûr** : Transactionnel, rollback en cas d'erreur
- ✅ **Historique** : Garde une trace complète
- ✅ **Standard** : Méthode officielle Supabase

### Comment ça marche ?

#### Étape 1 : Créer votre fichier de migration

Créez un nouveau fichier dans `supabase/migrations/` :

**Format du nom** : `YYYYMMDDHHMMSS_description.sql`

Exemple : `20251120180000_add_user_preferences.sql`

```sql
-- Migration: Add user preferences table
-- Date: 2025-11-20

CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  theme TEXT DEFAULT 'light',
  language TEXT DEFAULT 'fr',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id
  ON user_preferences(user_id);

-- RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preferences"
  ON user_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
  ON user_preferences
  FOR UPDATE
  USING (auth.uid() = user_id);
```

#### Étape 2 : Lier votre projet (si pas déjà fait)

```powershell
# Pour staging
supabase link --project-ref vmmohjvwtbrotygzjias

# Pour production
supabase link --project-ref tcpecjoeelbnnvdkvgvg
```

#### Étape 3 : Appliquer la migration

```powershell
# Voir les migrations en attente
supabase db diff

# Appliquer toutes les migrations en attente
supabase db push
```

**C'est tout !** La migration est exécutée ET enregistrée automatiquement.

#### Étape 4 : Vérifier

```powershell
# Voir les migrations appliquées
supabase migration list
```

---

## 🔧 Solution 2 : Script SQL Auto-Enregistrant (FALLBACK)

Si vous devez absolument utiliser le SQL Editor (urgence, pas d'accès CLI, etc.), utilisez le template qui s'auto-enregistre.

### Comment utiliser le template ?

#### Étape 1 : Copier le template

Le fichier `supabase/migrations/TEMPLATE_MIGRATION.sql` contient un template complet.

#### Étape 2 : Modifier les variables

En haut du fichier, modifiez :

```sql
\set migration_version '20251120180000'  -- ⬅️ Timestamp unique
\set migration_name 'add_user_preferences'  -- ⬅️ Description
```

**Comment générer le timestamp** :
```powershell
# PowerShell
Get-Date -Format "yyyyMMddHHmmss"
# Retourne : 20251120180530
```

#### Étape 3 : Ajouter vos modifications SQL

Entre les lignes de séparation, ajoutez votre SQL :

```sql
-- =====================================================
-- VOS MODIFICATIONS ICI
-- =====================================================

CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  theme TEXT DEFAULT 'light',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- FIN DE VOS MODIFICATIONS
-- =====================================================
```

#### Étape 4 : Copier TOUT le fichier dans SQL Editor

1. Ouvrir Dashboard Supabase → SQL Editor
2. Copier **TOUT** le contenu du fichier (y compris la section d'auto-enregistrement)
3. Coller dans SQL Editor
4. Cliquer sur **Run**

**Résultat** :
- ✅ Vos modifications sont appliquées
- ✅ La migration est enregistrée automatiquement dans le tableau
- ✅ Un message de confirmation s'affiche : `✅ Migration 20251120180000 (add_user_preferences) enregistrée avec succès`

#### Étape 5 : Vérifier

Dans SQL Editor :

```sql
SELECT version, name, inserted_at
FROM supabase_migrations.schema_migrations
ORDER BY version DESC
LIMIT 5;
```

Vous devriez voir votre migration dans la liste.

---

## 📊 Comparaison des Deux Méthodes

| Aspect | `supabase db push` | Script Auto-Enregistrant |
|--------|-------------------|-------------------------|
| **Facilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Sécurité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Rollback** | ✅ Automatique | ❌ Manuel |
| **Historique** | ✅ Complet | ✅ Version seulement |
| **Erreurs** | ✅ Rollback auto | ⚠️ Peut être partiel |
| **CI/CD** | ✅ Intégrable | ❌ Difficile |
| **Équipe** | ✅ Standard | ⚠️ Nécessite template |

**Recommandation** : Utilisez `supabase db push` sauf si impossible.

---

## 🚨 Synchroniser les Migrations Existantes

Si vous avez déjà des migrations non enregistrées (comme actuellement), vous pouvez les enregistrer rétroactivement :

```sql
-- Enregistrer les migrations déjà appliquées manuellement
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES
  ('20251113092934', 'import_from_prod'),
  ('20251113173945', 'create_agent_sms_table'),
  ('20251113174002', 'sms_rls_policies'),
  ('20251113174046', 'sms_analytics'),
  ('20251114115154', 'add_cost_per_email_to_deployments'),
  ('20251117101559', 'create_financial_timeseries_function'),
  ('20251120094954', 'add_latency_columns'),
  ('20251120095358', 'rename_justification_to_analysis')
ON CONFLICT (version) DO NOTHING;
```

**⚠️ IMPORTANT** : Cette requête **N'EXÉCUTE PAS** les migrations, elle les **ENREGISTRE** seulement. À utiliser uniquement si les migrations sont déjà appliquées.

---

## 📝 Checklist Migration

Avant chaque migration :

- [ ] **Backup créé** (`supabase db dump`)
- [ ] **Migration testée sur staging**
- [ ] **Nom de fichier correct** (`YYYYMMDDHHMMSS_description.sql`)
- [ ] **Utilisation de IF NOT EXISTS / IF EXISTS** (idempotence)
- [ ] **Transaction BEGIN/COMMIT** (atomicité)
- [ ] **Commentaires clairs** (description, risque)
- [ ] **Vérifications post-migration** incluses

Pendant la migration :

- [ ] **Méthode choisie** (`supabase db push` ou template)
- [ ] **Environnement vérifié** (staging ou production)
- [ ] **Exécution sans erreur**
- [ ] **Migration enregistrée** (vérifier le tableau)

Après la migration :

- [ ] **Tests fonctionnels** (dashboard, API)
- [ ] **Vérification données** (pas de perte)
- [ ] **Monitoring** (logs, performances)
- [ ] **Documentation** (mettre à jour README si nécessaire)

---

## 🔄 Workflow Complet Recommandé

### En Développement (Staging)

```powershell
# 1. Créer la migration
# Créer le fichier : supabase/migrations/20251120180000_ma_feature.sql

# 2. Lier staging
supabase link --project-ref vmmohjvwtbrotygzjias

# 3. Appliquer
supabase db push

# 4. Tester
# Vérifier le dashboard, les fonctions, etc.

# 5. Commit
git add supabase/migrations/20251120180000_ma_feature.sql
git commit -m "feat: add ma_feature migration"
```

### En Production

```powershell
# 1. Backup
supabase db dump -f dbDump/backup_prod_$(Get-Date -Format "yyyyMMdd_HHmmss").sql

# 2. Lier production
supabase link --project-ref tcpecjoeelbnnvdkvgvg

# 3. Appliquer
supabase db push

# 4. Vérifier
# Tester le dashboard en production
# Vérifier les logs

# 5. Monitorer
# Surveiller pendant 24-48h
```

---

## 💡 Conseils Additionnels

### 1. Nommage des Migrations

**Bon** :
- `20251120180000_add_user_preferences_table.sql`
- `20251120180100_add_latency_columns_to_calls.sql`
- `20251120180200_fix_financial_metrics_view.sql`

**Mauvais** :
- `migration.sql`
- `fix.sql`
- `update_2025.sql`

### 2. Taille des Migrations

**Une migration = Une fonctionnalité**

✅ **Bon** :
- Migration 1 : Créer table user_preferences
- Migration 2 : Ajouter colonne theme
- Migration 3 : Créer vue enriched_preferences

❌ **Mauvais** :
- Migration 1 : Créer 10 tables + 5 vues + 3 fonctions

### 3. Idempotence

Toujours utiliser :
- `CREATE TABLE IF NOT EXISTS`
- `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`
- `CREATE INDEX IF NOT EXISTS`
- `DROP ... IF EXISTS` avant `CREATE OR REPLACE`

### 4. Documentation

Chaque migration doit avoir :
```sql
-- Migration: [Description courte]
-- Date: YYYY-MM-DD
-- Author: [Nom]
-- Risk: LOW | MEDIUM | HIGH
-- Dependencies: [Migrations dont celle-ci dépend]
--
-- Description détaillée de ce que fait la migration
-- et pourquoi elle est nécessaire.
```

---

## 🆘 Résolution de Problèmes

### Problème : Migration échoue avec "already exists"

**Cause** : Migration déjà appliquée manuellement

**Solution** :
```sql
-- Enregistrer sans exécuter
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('20251120180000', 'ma_migration')
ON CONFLICT (version) DO NOTHING;
```

### Problème : "Permission denied"

**Cause** : Permissions RLS ou rôle incorrect

**Solution** : Vérifier que vous êtes connecté avec le bon utilisateur :
```sql
SELECT current_user;
-- Devrait retourner 'postgres' ou un compte admin
```

### Problème : Migration partiellement appliquée

**Cause** : Pas de transaction BEGIN/COMMIT

**Solution** : Toujours wrapper dans une transaction :
```sql
BEGIN;
  -- Vos modifications
COMMIT;
```

---

## 📚 Ressources

- **Documentation Supabase** : https://supabase.com/docs/guides/cli/local-development#database-migrations
- **Template de migration** : `supabase/migrations/TEMPLATE_MIGRATION.sql`
- **Guide de backup** : `docs/DATABASE_BACKUP_GUIDE.md`

---

**Créé par** : Claude Code
**Date** : 2025-11-20
**Version** : 1.0
