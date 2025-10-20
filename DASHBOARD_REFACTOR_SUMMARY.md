# Dashboard Global - Refactorisation Dynamique

## 🎯 Objectif
Rendre le dashboard principal dynamique en fonction des agents déployés et des droits des utilisateurs, avec des cartes pour les clients et les agents.

## ✅ Modifications Effectuées

### 1. Nouveaux Types TypeScript (`lib/types/dashboard.ts`)

Ajout de deux nouveaux types pour les cartes dynamiques :

```typescript
// Carte client avec métriques agrégées
export interface ClientCardData {
  client_id: string
  client_name: string
  industry: string | null
  total_agents: number
  active_agents: number
  total_calls: number
  answered_calls: number
  appointments_scheduled: number
  answer_rate: number
  conversion_rate: number
  total_cost: number
  last_call_at: string | null
  agent_types: string[]
}

// Carte agent avec métriques agrégées
export interface AgentCardData {
  deployment_id: string
  deployment_name: string
  slug: string
  agent_type_name: 'louis' | 'arthur' | 'alexandra'
  agent_display_name: string
  client_name: string
  total_calls: number
  answered_calls: number
  appointments_scheduled: number
  answer_rate: number
  conversion_rate: number
  avg_duration: number
  total_cost: number
  last_call_at: string | null
  deployment_status: 'active' | 'paused' | 'archived'
}
```

### 2. Nouvelles Queries (`lib/queries/global.ts`)

Ajout de deux fonctions pour récupérer les données des cartes :

- `fetchClientCardsData(filters)` - Récupère les cartes clients avec métriques
- `fetchAgentCardsData(filters)` - Récupère les cartes agents avec métriques

### 3. Nouveaux Hooks (`lib/hooks/useDashboardData.ts`)

Ajout de hooks pour utiliser les queries :

- `useClientCardsData(filters)` - Hook React Query pour les cartes clients
- `useAgentCardsData(filters)` - Hook React Query pour les cartes agents

### 4. Nouveaux Composants

#### `components/dashboard/Cards/ClientCard.tsx`
Carte affichant les métriques d'un client :
- Nom et industrie
- Nombre d'agents (actifs/total)
- Types d'agents déployés (Louis, Arthur, Alexandra)
- Métriques : Appels, Taux de réponse, RDV pris, Conversion

#### `components/dashboard/Cards/AgentCard.tsx`
Carte affichant les métriques d'un agent :
- Nom de l'agent et client
- Type d'agent avec icône et couleur (Louis bleu, Arthur orange, Alexandra vert)
- Statut (Actif, Pause, Archivé)
- Métriques : Appels, Taux de réponse, Conversion, Durée moyenne
- **Cliquable** pour accéder au dashboard spécifique de l'agent

### 5. Nouveau GlobalDashboardClient (`app/dashboard/GlobalDashboardClient.tsx`)

Refonte complète du dashboard global :

**Fonctionnalités :**
- Affichage dynamique des cartes clients (si l'utilisateur a accès à plusieurs clients)
- Affichage dynamique des cartes agents (tous les agents accessibles)
- Filtres de date
- Export CSV
- KPIs globaux
- États de chargement pour chaque section
- État vide si aucune donnée

**Structure :**
```
Dashboard Global
├── Header (titre + email utilisateur)
├── Filtres (dates + export CSV)
├── KPIs Grid (5 KPIs globaux)
├── Section "Entreprises" (cartes clients dynamiques)
└── Section "Agents déployés" (cartes agents dynamiques)
```

### 6. Script SQL de Migration (`supabase/migrations/20250120_create_dashboard_cards_rpc_functions.sql`)

**⚠️ À EXÉCUTER DANS SUPABASE :**

Le fichier contient deux fonctions RPC :

#### `get_client_cards_data(p_start_date, p_end_date)`
- Récupère les métriques agrégées par client
- Respecte les permissions RLS (l'utilisateur ne voit que ses clients)
- Retourne : métriques d'appels, taux de réponse, conversion, coût, etc.

#### `get_agent_cards_data(p_start_date, p_end_date, p_client_ids)`
- Récupère les métriques agrégées par agent
- Respecte les permissions RLS (l'utilisateur ne voit que ses agents)
- Filtrage optionnel par clients
- Retourne : métriques d'appels, taux de réponse, conversion, durée moyenne, etc.

## 📋 Instructions d'Installation

### Étape 1 : Exécuter le Script SQL

1. Allez dans le dashboard Supabase
2. Ouvrez l'éditeur SQL
3. Copiez-collez le contenu de `supabase/migrations/20250120_create_dashboard_cards_rpc_functions.sql`
4. Exécutez le script

### Étape 2 : Tester en Local

```bash
# Nettoyer le cache Next.js (si problèmes)
rm -rf .next

# Lancer le serveur de développement
npm run dev
```

### Étape 3 : Déployer

```bash
# Build de production
npm run build

# Commit et push vers GitHub
git add .
git commit -m "feat: Refactor dashboard with dynamic client and agent cards"
git push origin main
```

## 🎨 Comportement selon les Profils

### Admin / Multi-clients
Voit :
1. **Section "Entreprises"** avec toutes les cartes clients (Voipia, Norloc, Exotic Design, etc.)
2. **Section "Agents déployés"** avec toutes les cartes agents accessibles

### Utilisateur Simple (1 seul agent)
- Redirection automatique vers le dashboard spécifique de l'agent (`/dashboard/louis` par exemple)

### Utilisateur avec Plusieurs Agents (même client)
Voit :
1. **Section "Agents déployés"** avec les cartes des agents accessibles
2. Pas de section "Entreprises" (car 1 seul client)

## 🔧 Personnalisation

### Ajouter un Nouveau Type d'Agent

1. Dans `lib/types/dashboard.ts`, mettre à jour :
```typescript
agent_type_name: 'louis' | 'arthur' | 'alexandra' | 'nouveau_agent'
```

2. Dans `components/dashboard/Cards/AgentCard.tsx`, ajouter la configuration :
```typescript
const agentConfig = {
  // ...
  nouveau_agent: {
    icon: IconComponent,
    color: 'from-color-500/20 to-color-500/5 border-color-500/30',
    iconColor: 'text-color-400',
    description: 'Description de l\'agent',
  },
}
```

## 🐛 Résolution de Problèmes

### Erreur "RPC function not found"
- Vérifiez que le script SQL a été exécuté dans Supabase
- Vérifiez les permissions avec `GRANT EXECUTE`

### Cartes vides
- Vérifiez que vous avez des données dans la période sélectionnée
- Vérifiez les permissions RLS dans Supabase

### Erreur de build
- Supprimez le dossier `.next` : `rm -rf .next`
- Relancez le build : `npm run build`

## 📊 Métriques Affichées

### Cartes Clients
- Total appels
- Taux de décroché
- RDV pris
- Taux de conversion
- Nombre d'agents (actifs/total)
- Types d'agents déployés

### Cartes Agents
- Total appels
- Taux de décroché
- Taux de conversion
- Durée moyenne d'appel
- Statut de déploiement

## 🚀 Prochaines Étapes Possibles

- [ ] Ajouter des filtres par client dans la section agents
- [ ] Ajouter des graphiques sparkline dans les cartes
- [ ] Implémenter le tri des cartes (par appels, conversion, etc.)
- [ ] Ajouter une vue tableau en option
- [ ] Ajouter des badges de notification pour les agents avec faible performance

## 📝 Notes Techniques

- Les cartes utilisent React Query pour le cache et les mises à jour automatiques (refetch toutes les heures)
- Les requêtes SQL respectent les RLS policies existantes
- Le design utilise les couleurs de marque : Louis (bleu), Arthur (orange), Alexandra (vert)
- Toutes les cartes sont cliquables sauf les cartes clients (pour l'instant)
