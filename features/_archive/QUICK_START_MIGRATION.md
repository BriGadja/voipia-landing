# ⚡ Guide Rapide - Migrations Production

**Pour les pressés** - Suivez ces étapes simples

---

## 🎯 Résumé : 7 Fichiers à Exécuter

Vous devez copier-coller le contenu de ces 7 fichiers dans le Dashboard Supabase, dans cet ordre :

```
1. supabase/migrations/20251113_create_agent_sms_table.sql
2. supabase/migrations/20251113_sms_rls_policies.sql
3. supabase/migrations/20251113_sms_analytics.sql
4. supabase/migrations/20251113_fix_sms_pricing_model.sql
5. supabase/migrations/20251114_add_cost_per_email_to_deployments.sql
6. supabase/migrations/20250117_create_financial_timeseries_function.sql
7. supabase/migrations/20251120_add_latency_and_quality_columns_PRODUCTION.sql ⭐
```

---

## 📖 Étapes Simples

### Étape 1 : Ouvrir le Dashboard Supabase

1. Aller sur : https://supabase.com/dashboard/project/tcpecjoeelbnnvdkvgvg
2. Se connecter si nécessaire
3. Dans le menu de gauche, cliquer sur **SQL Editor**
4. Cliquer sur **New Query**

---

### Étape 2 : Pour CHAQUE fichier (répéter 7 fois)

#### A. Copier le contenu du fichier

**Dans PowerShell** (dans votre projet) :
```powershell
# Remplacez NOM_DU_FICHIER par le nom du fichier (ex: 20251113_create_agent_sms_table.sql)
Get-Content supabase\migrations\NOM_DU_FICHIER.sql | Set-Clipboard
```

Ou **manuellement** :
1. Ouvrir le fichier avec Notepad/VS Code
2. Sélectionner tout (Ctrl+A)
3. Copier (Ctrl+C)

#### B. Coller dans le Dashboard

1. Dans le SQL Editor du Dashboard Supabase
2. Coller le contenu (Ctrl+V)
3. Cliquer sur **Run** (bouton en haut à droite)
4. Attendre que ça se termine

#### C. Vérifier le résultat

- ✅ **Success** → Passer au fichier suivant
- ❌ **Erreur** → M'envoyer l'erreur, NE PAS continuer

---

### Étape 3 : Après les 7 fichiers - Vérification

**Copier-coller cette requête** dans le SQL Editor :

```sql
-- Vérifier que tout est OK
SELECT
  'Tables créées' as check_name,
  COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('agent_sms', 'agent_calls')

UNION ALL

SELECT
  'Colonnes latence' as check_name,
  COUNT(*) as count
FROM information_schema.columns
WHERE table_name = 'agent_calls'
  AND column_name LIKE '%latency%'

UNION ALL

SELECT
  'Colonne quality_analysis' as check_name,
  COUNT(*) as count
FROM information_schema.columns
WHERE table_name = 'agent_calls'
  AND column_name = 'call_quality_analysis';
```

**Résultats attendus** :
```
Tables créées           | 2  (agent_sms + agent_calls)
Colonnes latence        | 9
Colonne quality_analysis| 1
```

Si c'est bon, **C'EST FINI** ! 🎉

---

## 🔥 Commandes PowerShell Complètes (Copier-Coller)

**Si vous voulez copier TOUS les fichiers d'un coup** :

```powershell
# Fichier 1
Get-Content supabase\migrations\20251113_create_agent_sms_table.sql | Set-Clipboard
Write-Host "✓ Fichier 1 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 2
Get-Content supabase\migrations\20251113_sms_rls_policies.sql | Set-Clipboard
Write-Host "✓ Fichier 2 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 3
Get-Content supabase\migrations\20251113_sms_analytics.sql | Set-Clipboard
Write-Host "✓ Fichier 3 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 4
Get-Content supabase\migrations\20251113_fix_sms_pricing_model.sql | Set-Clipboard
Write-Host "✓ Fichier 4 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 5
Get-Content supabase\migrations\20251114_add_cost_per_email_to_deployments.sql | Set-Clipboard
Write-Host "✓ Fichier 5 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 6
Get-Content supabase\migrations\20250117_create_financial_timeseries_function.sql | Set-Clipboard
Write-Host "✓ Fichier 6 copié - Collez dans Dashboard, puis appuyez sur Entrée pour continuer"
Read-Host

# Fichier 7 (LE PLUS IMPORTANT)
Get-Content supabase\migrations\20251120_add_latency_and_quality_columns_PRODUCTION.sql | Set-Clipboard
Write-Host "✓ Fichier 7 copié (DERNIER) - Collez dans Dashboard"
Read-Host

Write-Host "✅ TOUS LES FICHIERS ONT ÉTÉ COPIÉS !" -ForegroundColor Green
```

**Comment utiliser ce script** :
1. Copier TOUT le bloc ci-dessus
2. Coller dans PowerShell
3. Appuyer sur Entrée
4. Le script copiera automatiquement chaque fichier
5. Après chaque fichier, coller dans le Dashboard Supabase et cliquer sur Run
6. Revenir dans PowerShell et appuyer sur Entrée pour le fichier suivant

---

## ⚠️ Important

- **Exécuter sur PRODUCTION** uniquement (pas sur staging)
- **Dans l'ordre** (1 → 2 → 3 → 4 → 5 → 6 → 7)
- **Vérifier après chaque fichier** qu'il n'y a pas d'erreur
- Le fichier 7 est le plus important (latence + qualité)

---

## 🆘 En Cas d'Erreur

**Si un fichier échoue** :
1. Noter le numéro du fichier (1 à 7)
2. Copier le message d'erreur complet
3. Faire une capture d'écran
4. M'envoyer tout ça

**Ne pas continuer** si une migration échoue.

---

## ✅ C'est Tout !

Après les 7 fichiers + vérification, votre production sera ISO avec staging ! 🎉

**Temps estimé** : 10-15 minutes

---

**Créé par** : Claude Code
**Date** : 2025-11-20
