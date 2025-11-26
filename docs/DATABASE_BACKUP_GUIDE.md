# 🔒 Guide de Backup - Base de Données Supabase Production

**Date de création** : 2025-11-20
**Contexte** : Backup avant application de 16 migrations critiques

---

## 🎯 Objectif

Ce guide vous permet de créer des backups complets de votre base de données Supabase Production avant toute opération critique (migrations, modifications de schéma, etc.).

---

## 📋 Table des Matières

1. [Méthodes de Backup](#méthodes-de-backup)
2. [Backup via Supabase CLI (Recommandé)](#backup-via-supabase-cli-recommandé)
3. [Backup via Dashboard Supabase](#backup-via-dashboard-supabase)
4. [Backup via pg_dump](#backup-via-pg_dump)
5. [Vérification du Backup](#vérification-du-backup)
6. [Restauration](#restauration)
7. [Planification des Backups](#planification-des-backups)

---

## 🛠️ Méthodes de Backup

| Méthode | Avantages | Inconvénients | Recommandation |
|---------|-----------|---------------|----------------|
| **Supabase CLI** | Simple, rapide, fichier SQL propre | Nécessite CLI installé | ⭐ **RECOMMANDÉ** |
| **Dashboard Supabase** | Interface graphique, facile | Backup complet du projet | ✅ Bonne alternative |
| **pg_dump** | Contrôle total, automatisable | Configuration nécessaire | 🔧 Pour utilisateurs avancés |

---

## 🚀 Backup via Supabase CLI (Recommandé)

### Prérequis

1. **Installer Supabase CLI** (si pas encore fait) :
   ```bash
   npm install -g supabase
   ```

2. **Vérifier l'installation** :
   ```bash
   supabase --version
   ```

### Étapes de Backup

**1. Se connecter à votre projet Supabase** :
```bash
supabase login
```

**2. Lier votre projet local au projet de production** :
```bash
supabase link --project-ref <YOUR_PROJECT_REF>
```

Pour trouver votre `project-ref` :
- Aller sur le dashboard Supabase
- Sélectionner votre projet Production
- L'URL contient le ref : `https://supabase.com/dashboard/project/<project-ref>`

**3. Créer le backup** :
```bash
# Backup complet avec horodatage
supabase db dump -f dbDump/backup_prod_$(date +%Y%m%d_%H%M%S).sql

# Ou backup simple
supabase db dump -f dbDump/backup_prod.sql
```

**4. Vérifier le backup** :
```bash
ls -lh dbDump/
```

### Variantes de Backup

**Backup du schéma uniquement** (sans données) :
```bash
supabase db dump --schema-only -f dbDump/schema_prod_$(date +%Y%m%d_%H%M%S).sql
```

**Backup des données uniquement** :
```bash
supabase db dump --data-only -f dbDump/data_prod_$(date +%Y%m%d_%H%M%S).sql
```

**Backup d'une table spécifique** :
```bash
supabase db dump --table=agent_calls -f dbDump/agent_calls_backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## 🖥️ Backup via Dashboard Supabase

### Étapes

1. **Accéder au Dashboard Supabase** :
   - URL : https://supabase.com/dashboard
   - Sélectionner votre projet **Production**

2. **Naviguer vers Database > Backups** :
   - Menu de gauche → Database → Backups

3. **Créer un backup manuel** :
   - Cliquer sur "Create backup"
   - Donner un nom descriptif : `pre_migration_20251120`
   - Cliquer sur "Create"

4. **Télécharger le backup** :
   - Une fois le backup créé, cliquer sur les 3 points → "Download"
   - Sauvegarder dans `dbDump/backup_dashboard_YYYYMMDD.sql`

### Avantages de cette méthode

- ✅ Backup complet du projet (DB + Storage + Auth)
- ✅ Interface graphique simple
- ✅ Backup géré par Supabase (restauration facile)
- ✅ Historique des backups automatique

---

## 🔧 Backup via pg_dump

### Prérequis

1. **Installer PostgreSQL** (pour avoir `pg_dump`) :
   - Windows : https://www.postgresql.org/download/windows/
   - MacOS : `brew install postgresql`
   - Linux : `sudo apt-get install postgresql-client`

2. **Récupérer les credentials de connexion** :
   - Dashboard Supabase → Project Settings → Database
   - Copier : Host, Database name, Port, User, Password

### Commande de Backup

```bash
# Format complet
pg_dump "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  --file=dbDump/backup_prod_$(date +%Y%m%d_%H%M%S).sql \
  --schema=public \
  --no-owner \
  --no-acl \
  --verbose

# Ou format simplifié
pg_dump -h db.[YOUR-PROJECT-REF].supabase.co \
  -U postgres \
  -d postgres \
  -p 5432 \
  -f dbDump/backup_prod_$(date +%Y%m%d_%H%M%S).sql \
  --schema=public \
  --no-owner \
  --no-acl
```

**Note** : Remplacer `[YOUR-PASSWORD]` et `[YOUR-PROJECT-REF]` par vos valeurs.

### Options utiles

- `--schema=public` : Backup uniquement du schéma public
- `--no-owner` : Ne pas inclure les propriétaires
- `--no-acl` : Ne pas inclure les permissions
- `--verbose` : Afficher la progression
- `--clean` : Ajouter DROP commands avant CREATE
- `--if-exists` : Utiliser IF EXISTS dans les DROP commands

---

## ✅ Vérification du Backup

### Vérifications essentielles

**1. Taille du fichier** :
```bash
ls -lh dbDump/backup_prod_*.sql
```
Un backup complet devrait faire **plusieurs MB** (actuellement ~3.4 MB).

**2. Contenu du fichier** :
```bash
# Vérifier les premières lignes
head -n 50 dbDump/backup_prod_YYYYMMDD_HHMMSS.sql

# Vérifier les dernières lignes
tail -n 50 dbDump/backup_prod_YYYYMMDD_HHMMSS.sql

# Compter les tables
grep "CREATE TABLE" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql | wc -l
```
Devrait afficher **11 tables**.

**3. Rechercher des erreurs** :
```bash
grep -i "error\|warning" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql
```
Ne devrait retourner aucun résultat.

**4. Vérifier les tables critiques** :
```bash
grep "CREATE TABLE.*agent_calls" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql
grep "CREATE TABLE.*clients" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql
grep "CREATE TABLE.*agent_deployments" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql
```

**5. Vérifier les données** :
```bash
# Compter les INSERT statements
grep "INSERT INTO" dbDump/backup_prod_YYYYMMDD_HHMMSS.sql | wc -l
```

---

## 🔄 Restauration

### ⚠️ ATTENTION - Avant toute restauration

1. **NE JAMAIS restaurer sur Production sans test**
2. **Toujours tester sur Staging d'abord**
3. **Créer un backup de l'état actuel avant restauration**

### Restauration via Supabase CLI

```bash
# Restaurer sur STAGING pour test
supabase link --project-ref <STAGING_PROJECT_REF>
supabase db reset --db-url postgresql://postgres:[PASSWORD]@db.[STAGING_REF].supabase.co:5432/postgres
psql -h db.[STAGING_REF].supabase.co -U postgres -d postgres -f dbDump/backup_prod_YYYYMMDD_HHMMSS.sql

# Si test OK, restaurer sur PRODUCTION (AVEC EXTRÊME PRÉCAUTION)
supabase link --project-ref <PROD_PROJECT_REF>
psql -h db.[PROD_REF].supabase.co -U postgres -d postgres -f dbDump/backup_prod_YYYYMMDD_HHMMSS.sql
```

### Restauration via Dashboard

1. Dashboard Supabase → Database → Backups
2. Sélectionner le backup à restaurer
3. Cliquer sur "..." → "Restore"
4. Confirmer (⚠️ Cette action est IRRÉVERSIBLE)

---

## 📅 Planification des Backups

### Quand faire un backup ?

**✅ Situations critiques nécessitant un backup** :

1. **Avant toute migration** (comme aujourd'hui)
2. **Avant modification de schéma**
3. **Avant suppression de colonnes/tables**
4. **Avant batch update de données**
5. **Avant changement de RLS policies**

### Fréquence recommandée

- **Backups automatiques Supabase** : Activés par défaut (7 jours de rétention)
- **Backups manuels avant changements** : Systématiques
- **Backups hebdomadaires** : Recommandé pour archivage long terme

### Script de Backup Automatique

Voir le script `scripts/backup-prod.sh` pour automatiser les backups quotidiens.

---

## 📂 Organisation des Backups

### Structure recommandée

```
dbDump/
├── backup_prod_20251120_160000.sql    # Backup avant migration
├── backup_prod_20251113_143900.sql    # Backup précédent
├── schema_prod_20251120_160000.sql    # Schéma uniquement
└── archives/
    ├── backup_prod_20251101.sql       # Archives mensuelles
    └── backup_prod_20251001.sql
```

### Nommage des fichiers

**Format recommandé** :
```
backup_[env]_[YYYYMMDD]_[HHMMSS]_[description].sql
```

**Exemples** :
- `backup_prod_20251120_160000_pre_migration.sql`
- `backup_prod_20251115_120000_weekly.sql`
- `backup_staging_20251120_090000_test.sql`

---

## 🚨 Checklist Pré-Migration

Avant d'appliquer les 16 migrations manquantes :

- [ ] Backup complet créé
- [ ] Backup vérifié (taille, contenu, pas d'erreurs)
- [ ] Backup téléchargé localement
- [ ] Backup testé sur staging (restauration)
- [ ] Équipe informée de la maintenance
- [ ] Fenêtre de maintenance planifiée
- [ ] Plan de rollback préparé
- [ ] Documentation des changements prête

---

## 📝 Notes Importantes

1. **Mot de passe** : Ne JAMAIS commiter les fichiers contenant des credentials
2. **Git** : Les fichiers `.sql` dans `dbDump/` sont ignorés par `.gitignore`
3. **Taille** : Les backups avec données peuvent être volumineux (compresser si nécessaire)
4. **Compression** : Utiliser `gzip` pour réduire la taille :
   ```bash
   gzip dbDump/backup_prod_20251120_160000.sql
   # Crée : backup_prod_20251120_160000.sql.gz
   ```

---

## 🆘 En Cas de Problème

### Backup échoue

1. Vérifier les credentials de connexion
2. Vérifier que vous êtes connecté à Internet
3. Vérifier les permissions du dossier `dbDump/`
4. Essayer une autre méthode de backup

### Backup incomplet

1. Vérifier l'espace disque disponible
2. Vérifier les logs d'erreur
3. Réessayer avec `--verbose` pour voir la progression

### Restauration échoue

1. **NE PAS PANIQUER**
2. Contacter le support Supabase
3. Utiliser le backup automatique Supabase (7 jours)
4. Vérifier l'intégrité du fichier de backup

---

## 📞 Support

- **Documentation Supabase** : https://supabase.com/docs/guides/database/backups
- **Support Supabase** : support@supabase.io
- **Community Discord** : https://discord.supabase.com

---

**Créé par** : Claude Code
**Dernière mise à jour** : 2025-11-20
