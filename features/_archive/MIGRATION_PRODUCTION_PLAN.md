# 🚀 Plan de Migration Production - Synchronisation avec Staging

**Date** : 2025-11-20
**Objectif** : Appliquer les migrations manquantes en production pour être ISO avec staging
**Backup créé** : ✅ `dbDump/backup_prod_20251120.sql` (234 KB)

---

## ⚠️ AVANT DE COMMENCER

### Checklist Pré-Migration

- [x] **Backup créé et vérifié**
- [ ] **Fenêtre de maintenance planifiée** (si possible)
- [ ] **Utilisateurs informés** (si temps d'arrêt prévu)
- [ ] **Accès au Dashboard Supabase** (https://supabase.com/dashboard/project/tcpecjoeelbnnvdkvgvg)

### ⚠️ IMPORTANT

- **NE PAS** exécuter ces migrations sur staging (elles y sont déjà)
- **Exécuter uniquement sur PRODUCTION**
- **Tester chaque migration une par une**
- **Vérifier les erreurs après chaque étape**

---

## 📋 Migrations à Appliquer (7 fichiers)

### Groupe 1 : Tables SMS (3 migrations)

Ces migrations créent la table `agent_sms` et ses politiques RLS.

#### 1️⃣ Créer la table agent_sms
**Fichier** : `supabase/migrations/20251113_create_agent_sms_table.sql`
**Statut** : ✅ Fichier existe
**Description** : Crée la table pour stocker les SMS envoyés par les agents
**Risque** : 🟢 FAIBLE (création de table)

#### 2️⃣ Ajouter les politiques RLS pour SMS
**Fichier** : `supabase/migrations/20251113_sms_rls_policies.sql`
**Statut** : ✅ Fichier existe
**Description** : Ajoute les politiques de sécurité Row Level Security
**Risque** : 🟢 FAIBLE

#### 3️⃣ Créer les vues analytiques SMS
**Fichier** : `supabase/migrations/20251113_sms_analytics.sql`
**Statut** : ✅ Fichier existe
**Description** : Crée les vues et fonctions pour analyser les SMS
**Risque** : 🟢 FAIBLE

---

### Groupe 2 : Corrections SMS & Emails (2 migrations)

#### 4️⃣ Corriger le modèle de pricing SMS
**Fichier** : `supabase/migrations/20251113_fix_sms_pricing_model.sql`
**Statut** : ✅ Fichier existe
**Description** : Corrige le calcul des coûts SMS
**Risque** : 🟡 MOYEN (modifie des vues)

#### 5️⃣ Ajouter le coût par email aux déploiements
**Fichier** : `supabase/migrations/20251114_add_cost_per_email_to_deployments.sql`
**Statut** : ✅ Fichier existe
**Description** : Ajoute une colonne `cost_per_email` à la table `agent_deployments`
**Risque** : 🟢 FAIBLE (ajout de colonne)

---

### Groupe 3 : Dashboard Financier (1 migration)

#### 6️⃣ Créer la fonction de séries temporelles financières
**Fichier** : `supabase/migrations/20250117_create_financial_timeseries_function.sql`
**Statut** : ✅ Fichier existe
**Description** : Fonction RPC pour le dashboard financier
**Risque** : 🟢 FAIBLE (création de fonction)

---

### Groupe 4 : Latence & Qualité (1 migration consolidée)

#### 7️⃣ **MIGRATION CONSOLIDÉE** - Latence + Qualité
**Fichier** : `supabase/migrations/20251120_add_latency_and_quality_columns_PRODUCTION.sql`
**Statut** : ✅ Fichier existe ⭐ **PRÊT POUR PRODUCTION**
**Description** : Migration consolidée qui ajoute :
  - 9 colonnes de latence (LLM, TTS, Total)
  - Colonne `call_quality_analysis`
  - Fonction RPC `get_latency_metrics()`
  - Indices pour optimiser les requêtes
  - Backfill automatique des données depuis metadata

**Risque** : 🟡 MOYEN (ajoute 10 colonnes à `agent_calls`)

**⚠️ Cette migration combine 3 migrations de staging** :
- `20251120094858_add_quality_justification_column`
- `20251120094954_add_latency_columns`
- `20251120095358_rename_justification_to_analysis`

---

## 🎯 Ordre d'Exécution Recommandé

```
1. 20251113_create_agent_sms_table.sql
2. 20251113_sms_rls_policies.sql
3. 20251113_sms_analytics.sql
4. 20251113_fix_sms_pricing_model.sql
5. 20251114_add_cost_per_email_to_deployments.sql
6. 20250117_create_financial_timeseries_function.sql
7. 20251120_add_latency_and_quality_columns_PRODUCTION.sql ⭐
```

---

## 📖 Comment Exécuter les Migrations

### Méthode 1 : Supabase Dashboard (RECOMMANDÉ)

**Pour chaque fichier** :

1. **Ouvrir le Dashboard Supabase Production**
   - URL : https://supabase.com/dashboard/project/tcpecjoeelbnnvdkvgvg
   - Se connecter si nécessaire

2. **Aller dans SQL Editor**
   - Menu gauche → SQL Editor
   - Cliquer sur "New Query"

3. **Copier le contenu du fichier**
   ```powershell
   # Dans PowerShell, pour copier le contenu d'un fichier :
   Get-Content supabase\migrations\20251113_create_agent_sms_table.sql | clip
   ```

4. **Coller dans l'éditeur SQL** et cliquer sur "Run"

5. **Vérifier les erreurs**
   - Si succès : passer au fichier suivant
   - Si erreur : prendre note et me contacter

6. **Répéter pour chaque fichier** dans l'ordre

---

### Méthode 2 : Supabase CLI

**⚠️ Plus rapide mais moins de contrôle**

```powershell
# Se connecter au projet production
supabase link --project-ref tcpecjoeelbnnvdkvgvg

# Appliquer toutes les migrations manquantes
supabase db push
```

**ATTENTION** : Cette commande appliquera **TOUTES** les migrations manquantes d'un coup. Préférez la méthode 1 pour plus de contrôle.

---

## ✅ Vérifications Post-Migration

### Après CHAQUE migration

Vérifier dans le Dashboard Supabase :
- SQL Editor → Aucune erreur affichée
- Database → Tables → Vérifier les nouvelles tables/colonnes

### Après TOUTES les migrations

#### 1. Vérifier les tables créées
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('agent_sms', 'agent_emails')
ORDER BY table_name;
```
Devrait retourner : `agent_sms` (si agent_emails existe aussi, c'est bon)

#### 2. Vérifier les colonnes de latence
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agent_calls'
  AND column_name LIKE '%latency%'
ORDER BY column_name;
```
Devrait retourner 9 colonnes.

#### 3. Vérifier la colonne call_quality_analysis
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'agent_calls'
  AND column_name = 'call_quality_analysis';
```
Devrait retourner 1 ligne.

#### 4. Tester la fonction get_latency_metrics
```sql
SELECT *
FROM get_latency_metrics(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  NULL, NULL, 'louis'
)
LIMIT 5;
```
Devrait retourner des données (ou vide si pas de données de latence).

#### 5. Comparer avec staging
Après toutes les migrations, comparez à nouveau avec staging :
```powershell
# Se reconnecter au staging
supabase link --project-ref vmmohjvwtbrotygzjias

# Lister les migrations staging
supabase migration list
```

Puis reconnectez-vous à la prod et comparez.

---

## 🚨 En Cas de Problème

### Migration échoue

1. **NE PAS PANIQUER**
2. **Noter le message d'erreur complet**
3. **Ne pas continuer avec les migrations suivantes**
4. **Me contacter avec** :
   - Le nom du fichier qui a échoué
   - Le message d'erreur complet
   - Une capture d'écran si possible

### Restaurer le backup (en dernier recours)

Si quelque chose se passe très mal :

1. **Dashboard Supabase** → Database → Backups
2. Sélectionner le backup automatique ou créer une restauration
3. **OU** utiliser le fichier `dbDump/backup_prod_20251120.sql`

---

## 📊 État Actuel

### Migrations présentes en Staging (18 migrations)
- ✅ Toutes les migrations sont appliquées

### Migrations présentes en Production (1 migration)
- ✅ `20251113091720_create-staging`

### Migrations à appliquer (7 fichiers)
- ⏳ SMS : 3 fichiers
- ⏳ Corrections : 2 fichiers
- ⏳ Dashboard financier : 1 fichier
- ⏳ Latence & Qualité : 1 fichier consolidé

---

## 📝 Notes Importantes

### Pourquoi seulement 7 fichiers au lieu de 16 ?

1. **Certaines migrations de staging ne sont pas nécessaires** :
   - `import_from_prod` - Déjà fait initialement
   - `agent_calls_enrichment_complete` - Déjà présent
   - `security_fixes_*` - Déjà appliqués

2. **Certaines migrations ont été consolidées** :
   - Les 3 migrations de latence/qualité sont regroupées dans 1 seul fichier

3. **Certaines migrations concernent les emails** :
   - Les migrations email ne sont pas listées car la table `agent_emails` semble déjà exister en production

### Migrations manquantes (non trouvées dans supabase/migrations/)

Si ces migrations sont importantes, il faudra les recréer :
- `20251113092934_import_from_prod.sql` - Peut être ignorée
- `20251113110933_agent_calls_enrichment_complete.sql` - À vérifier
- `20251113145425_security_fixes_test_v2.sql` - À vérifier
- `20251113145458_security_fixes_remaining_views.sql` - À vérifier
- `20251113145549_security_fixes_arthur_views.sql` - À vérifier
- `20251114115307_create_agent_emails_table_v2.sql` - À vérifier si agent_emails existe
- `20251114115358_email_rls_policies.sql` - À vérifier
- `20251114115525_email_analytics.sql` - À vérifier

---

## ✅ Checklist de Validation Finale

Après toutes les migrations :

- [ ] Toutes les 7 migrations ont été exécutées sans erreur
- [ ] Les vérifications SQL retournent les résultats attendus
- [ ] Le dashboard fonctionne (https://votre-site.com/dashboard)
- [ ] Les métriques de latence sont disponibles (si données présentes)
- [ ] La fonction `get_latency_metrics()` fonctionne
- [ ] Aucune régression sur les fonctionnalités existantes

---

## 🎯 Prochaines Étapes

1. **Exécuter les migrations** (suivre ce guide)
2. **Valider les résultats**
3. **Tester le dashboard**
4. **Monitorer les logs** pendant 24-48h
5. **Documenter les changements**

---

**Créé par** : Claude Code
**Date** : 2025-11-20
**Version** : 1.0
