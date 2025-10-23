# Dashboard Dynamique - Migration et Corrections

## 📋 Résumé

Le dashboard est **déjà structuré pour être dynamique** avec des cartes par entreprise et par agent. Cependant, les fonctions RPC Supabase ne peuvent pas fonctionner car elles référencent des colonnes qui n'existent pas dans la base de données.

## 🔍 Problèmes Identifiés

### 1. Colonnes Manquantes pour les Calculs

Les fonctions RPC `get_client_cards_data` et `get_agent_cards_data` ont besoin de calculer :
- `answered` (BOOLEAN) - Est-ce que l'appel a été répondu ?
- `appointment_scheduled` (BOOLEAN) - Est-ce qu'un RDV a été pris ?

Actuellement, la table `agent_calls` contient uniquement :
- `outcome` (TEXT) - ex: "RDV PRIS", "VOICEMAIL", etc.
- `metadata` (JSONB) - contient `appointment_scheduled_at` pour Louis
- `duration_seconds` (INTEGER)

**Ces données suffisent** pour calculer `answered` et `appointment_scheduled` **sans ajouter de colonnes redondantes** !

### 2. Références de Colonnes Incorrectes

La migration initiale utilisait `ac.call_id` mais la colonne s'appelle `ac.id`.

## ✅ Solution Proposée (SANS modification de table)

### Migration 1: Création d'une Vue Enrichie

**Fichier:** `supabase/migrations/20250120_create_enriched_view.sql`

**Approche** :
- ✅ Crée une **vue SQL** `v_agent_calls_enriched`
- ✅ La vue **calcule dynamiquement** `answered` et `appointment_scheduled`
- ✅ **Aucune modification** de la table `agent_calls`
- ✅ Ajoute des index sur `outcome` et `metadata` pour optimiser les performances

#### Logique de Calcul dans la Vue

**Appel Répondu (`answered = true`)** :
```sql
CASE
  -- Outcomes explicites d'appels répondus
  WHEN outcome IN ('RDV PRIS', 'RDV REFUSÉ', 'CALLBACK', 'NOT_INTERESTED', 'ALREADY_CLIENT', 'TOO_CONF')
    THEN true

  -- Outcomes explicites d'appels non répondus
  WHEN outcome IN ('VOICEMAIL', 'NO_ANSWER', 'BUSY', 'FAILED', 'INVALID_NUMBER')
    THEN false

  -- Pour les autres outcomes, vérifier la durée (conversation réelle > 10s)
  WHEN duration_seconds > 10
    THEN true

  ELSE false
END
```

**RDV Pris (`appointment_scheduled = true`)** :
```sql
CASE
  -- Outcome explicite
  WHEN outcome = 'RDV PRIS'
    THEN true

  -- Vérifier metadata pour Louis (contient appointment_scheduled_at)
  WHEN metadata ? 'appointment_scheduled_at'
    THEN true

  ELSE false
END
```

### Migration 2: Correction des Fonctions RPC

**Fichier:** `supabase/migrations/20250120_fix_rpc_functions.sql`

Cette migration :
1. **Utilise** `v_agent_calls_enriched` au lieu de `agent_calls`
2. **Corrige** les références de colonnes (`ac.id` au lieu de `ac.call_id`)
3. **Ajoute** des filtres NULL pour les agrégations

## 🚀 Instructions d'Exécution

### Étape 1: Connexion à Supabase

```bash
# Via l'interface Supabase Dashboard SQL Editor (recommandé)
# Ouvrir https://app.supabase.com
```

### Étape 2: Appliquer la Migration 1 (Vue Enrichie)

Copiez et exécutez le contenu de :
```
supabase/migrations/20250120_create_enriched_view.sql
```

**Vérification :**
```sql
-- Vérifier que la vue existe
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND viewname = 'v_agent_calls_enriched';

-- Tester la vue avec quelques enregistrements
SELECT
  id,
  outcome,
  duration_seconds,
  answered,
  appointment_scheduled
FROM v_agent_calls_enriched
LIMIT 10;

-- Vérifier la distribution des valeurs calculées
SELECT
  answered,
  appointment_scheduled,
  COUNT(*) as count
FROM v_agent_calls_enriched
GROUP BY answered, appointment_scheduled;
```

### Étape 3: Appliquer la Migration 2 (RPC Functions)

Copiez et exécutez le contenu de :
```
supabase/migrations/20250120_fix_rpc_functions.sql
```

**Vérification :**
```sql
-- Tester get_client_cards_data
SELECT * FROM get_client_cards_data(
  '2025-01-01'::DATE,
  '2025-01-31'::DATE
);

-- Tester get_agent_cards_data
SELECT * FROM get_agent_cards_data(
  '2025-01-01'::DATE,
  '2025-01-31'::DATE,
  NULL
);

-- Vérifier les fonctions existantes
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%card%';
```

## 🎨 Architecture du Dashboard Dynamique

### Structure Actuelle

Le dashboard est déjà conçu pour être dynamique :

#### 1. **Cartes Entreprises** (`ClientCard.tsx`)
- Affichées pour les utilisateurs admin
- Données récupérées via `useClientCardsData(filters)`
- Basées sur `v_user_accessible_clients` (RLS)

**Indicateurs affichés :**
- Nombre d'agents (actifs/total)
- Types d'agents déployés (Louis, Arthur, Alexandra)
- Total appels
- Taux de réponse
- RDV pris
- Taux de conversion
- Coût total
- Coût par RDV

#### 2. **Cartes Agents** (`AgentCard.tsx`)
- Affichées pour tous les utilisateurs selon leurs droits
- Données récupérées via `useAgentCardsData(filters)`
- Basées sur `v_user_accessible_agents` (RLS)
- Lien cliquable vers le dashboard spécifique de l'agent

**Indicateurs affichés :**
- Total appels
- Taux de réponse
- Conversion
- Durée moyenne
- Coût total
- Coût par appel
- Dernière activité (temps relatif)

### Système de Permissions

Le dashboard utilise **Row Level Security (RLS)** avec :

1. **Table `user_client_permissions`**
   - `user_id` : UUID de l'utilisateur
   - `client_id` : UUID de l'entreprise
   - `permission_level` : 'read', 'write', 'admin'

2. **Vues RLS**
   - `v_user_accessible_clients` : Clients accessibles par l'utilisateur
   - `v_user_accessible_agents` : Agents accessibles par l'utilisateur

3. **Vue Enrichie (NOUVEAU)**
   - `v_agent_calls_enriched` : agent_calls avec colonnes calculées

4. **Fonctions RPC avec `SECURITY DEFINER`**
   - `get_client_cards_data()` : Filtre automatiquement par droits
   - `get_agent_cards_data()` : Filtre automatiquement par droits

### Comportement par Rôle

**Admin (accès à 2+ clients ou 2+ agents)** :
- Voit le dashboard global avec :
  - Section "Entreprises" avec cartes par client (Voipia, Norloc, etc.)
  - Section "Agents déployés" avec cartes par agent (Louis, Arthur, etc.)

**Utilisateur Standard (1 client, 1 agent)** :
- Redirigé automatiquement vers le dashboard de son agent spécifique

**Utilisateur Multi-Agents (1 client, plusieurs agents)** :
- Voit le dashboard global avec :
  - Section "Agents déployés" uniquement

## 📊 Avantages de cette Approche

### ✅ Pas de Modification de Table
- La table `agent_calls` reste intacte
- Aucun risque d'impact non anticipé
- Facilite les rollbacks si nécessaire

### ✅ Vue SQL Performante
- Les calculs sont effectués par PostgreSQL (optimisé)
- Index ajoutés sur `outcome` et `metadata` pour accélérer les requêtes
- Les vues sont mises en cache par Postgres

### ✅ Logique Centralisée
- La logique de calcul est dans **un seul endroit** (la vue)
- Facile à modifier si nécessaire
- Cohérence garantie dans toute l'application

### ✅ Facilement Extensible
- Pour ajouter de nouveaux calculs, il suffit de modifier la vue
- Aucune migration de données nécessaire

## 🧪 Tests Recommandés

### 1. Test de la Vue Enrichie

```sql
-- Vérifier que tous les appels ont une valeur calculée
SELECT
  COUNT(*) FILTER (WHERE answered IS NULL) as null_answered,
  COUNT(*) FILTER (WHERE appointment_scheduled IS NULL) as null_appointments,
  COUNT(*) as total
FROM v_agent_calls_enriched;

-- Comparer avec la table de base
SELECT COUNT(*) FROM agent_calls;
SELECT COUNT(*) FROM v_agent_calls_enriched;
-- Les deux devraient être identiques

-- Vérifier la logique pour différents outcomes
SELECT
  outcome,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE answered = true) as answered_count,
  COUNT(*) FILTER (WHERE appointment_scheduled = true) as rdv_count
FROM v_agent_calls_enriched
GROUP BY outcome
ORDER BY total DESC;
```

### 2. Test des Fonctions RPC

```sql
-- Tester avec une période récente
SELECT * FROM get_client_cards_data(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE
);

-- Vérifier que les totaux sont cohérents
SELECT
  SUM(total_calls) as all_calls,
  SUM(answered_calls) as all_answered,
  SUM(appointments_scheduled) as all_appointments
FROM get_client_cards_data(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE
);
```

### 3. Test de Performance

```sql
-- Analyser le plan d'exécution
EXPLAIN ANALYZE SELECT * FROM get_client_cards_data(
  '2025-01-01'::DATE,
  '2025-01-31'::DATE
);

EXPLAIN ANALYZE SELECT * FROM get_agent_cards_data(
  '2025-01-01'::DATE,
  '2025-01-31'::DATE,
  NULL
);
```

## 🔧 Développement Local

### Tester le Dashboard

```bash
# 1. Démarrer le serveur de développement
npm run dev

# 2. Ouvrir http://localhost:3000/dashboard

# 3. Vérifier dans la console les requêtes RPC
```

### Vérifier les Cartes Dynamiques

1. Ouvrir les DevTools (F12)
2. Onglet Network → Filter "RPC"
3. Observer les appels :
   - `get_client_cards_data`
   - `get_agent_cards_data`
4. Vérifier les réponses JSON

## 📝 Prochaines Étapes Suggérées

1. ✅ **Appliquer les migrations** sur Supabase
2. **Tester le dashboard** avec différents comptes utilisateurs
3. **Vérifier les performances** avec les requêtes EXPLAIN ANALYZE
4. **Ajouter des filtres** par entreprise/agent dans la barre de filtres
5. **Implémenter des graphiques** dans les cartes (mini sparklines)

## ❓ Questions Fréquentes

### Q: Pourquoi une vue et pas des colonnes dans la table ?
**R:** Pour éviter les données redondantes. Les valeurs `answered` et `appointment_scheduled` peuvent être calculées à partir de `outcome`, `metadata` et `duration_seconds`. Une vue évite la duplication et garde une source de vérité unique.

### Q: La vue est-elle performante ?
**R:** Oui ! PostgreSQL optimise les vues et les index ajoutés sur `outcome` et `metadata` accélèrent les calculs. De plus, les RPC functions utilisent des CTEs qui sont également optimisées.

### Q: Puis-je modifier la logique de calcul ?
**R:** Oui, il suffit de modifier la vue avec `CREATE OR REPLACE VIEW`. Aucune migration de données nécessaire.

### Q: Les données sont-elles en temps réel ?
**R:** Les calculs sont effectués à la volée. Chaque fois qu'un appel est inséré dans `agent_calls`, la vue le calcule automatiquement.

---

**Auteur:** Claude
**Date:** 2025-01-20
**Version:** 2.0 (Sans modification de table)
