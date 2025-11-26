# 🚀 Créer un Backup de Production MAINTENANT

**Date** : 2025-11-20
**Objectif** : Backup avant l'application des 16 migrations manquantes

---

## ⚡ Commandes Rapides

### Option 1 : Script Automatisé (RECOMMANDÉ) ⭐

**Sur Git Bash / Linux / Mac** :
```bash
./scripts/backup-prod.sh
```

**Sur Windows PowerShell** :
```powershell
.\scripts\backup-prod.ps1
```

---

### Option 2 : Supabase CLI Manuel

**1. Vérifier que Supabase CLI est installé** :
```bash
supabase --version
```

Si pas installé :
```bash
npm install -g supabase
```

**2. Se connecter à Supabase** :
```bash
supabase login
```

**3. Créer le backup** :
```bash
# Backup avec horodatage
supabase db dump -f dbDump/backup_prod_$(date +%Y%m%d_%H%M%S).sql

# Ou backup simple
supabase db dump -f dbDump/backup_prod_pre_migration.sql
```

**4. Vérifier le backup** :
```bash
ls -lh dbDump/
```

Vous devriez voir un fichier de **plusieurs MB** (actuellement ~3.4 MB).

---

## ✅ Vérification du Backup

### Vérifier que le backup contient les 11 tables :
```bash
grep "CREATE TABLE" dbDump/backup_prod_*.sql | wc -l
```
Devrait afficher : **11**

### Vérifier qu'il n'y a pas d'erreurs :
```bash
grep -i "error" dbDump/backup_prod_*.sql
```
Ne devrait rien retourner.

### Vérifier la taille du fichier :
```bash
ls -lh dbDump/backup_prod_*.sql
```
Devrait être **> 3 MB**.

---

## 🎯 Que Faire Après le Backup ?

### ✅ Une fois le backup créé et vérifié :

1. **Confirmer le succès** : Vérifier que le fichier existe et a une taille correcte
2. **Passer à la migration** : Appliquer les 16 migrations manquantes
3. **Suivre la documentation** : Voir `DATABASE_COMPARISON_REPORT.md` pour la liste des migrations

### 📋 Plan de Migration Suggéré :

1. ✅ **Backup créé et vérifié** ← VOUS ÊTES ICI
2. ⏭️ **Appliquer les migrations** une par une
3. ⏭️ **Tester après chaque migration critique**
4. ⏭️ **Valider le dashboard** après toutes les migrations
5. ⏭️ **Vérifier les fonctions RPC**

---

## 🔄 En Cas de Problème

### Le backup échoue ?

**Problème** : `supabase: command not found`
```bash
npm install -g supabase
```

**Problème** : `Error: Not logged in`
```bash
supabase login
```

**Problème** : `Error: Project not linked`
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

Pour trouver votre `project-ref` :
- Dashboard Supabase → Project Settings → General
- Ou dans l'URL : `https://supabase.com/dashboard/project/<project-ref>`

---

## 📞 Aide Supplémentaire

### Documentation Complète :
- **Guide de Backup** : `docs/DATABASE_BACKUP_GUIDE.md`
- **Rapport de Comparaison** : `DATABASE_COMPARISON_REPORT.md`
- **Scripts de Backup** : `scripts/README.md`

### Support Supabase :
- Documentation : https://supabase.com/docs/guides/database/backups
- Discord : https://discord.supabase.com

---

## ⚠️ Rappel Important

**AVANT d'appliquer les migrations en production** :

- ✅ Backup créé et vérifié
- ✅ Backup téléchargé localement (en dehors du projet)
- ✅ Backup testé sur staging (optionnel mais recommandé)
- ✅ Équipe informée de la maintenance
- ✅ Fenêtre de maintenance planifiée

---

**Prêt à créer le backup ?** Lancez :

```bash
# Git Bash / Linux / Mac
./scripts/backup-prod.sh

# Windows PowerShell
.\scripts\backup-prod.ps1
```

---

**Créé par** : Claude Code
**Date** : 2025-11-20
