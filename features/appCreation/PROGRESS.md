# Progression Refonte App Dashboard

**Document de reference**: `refonte_app.md`
**Derniere mise a jour**: 2025-11-26

---

## Resume de l'avancement

| Phase | Description | Statut | Progression |
|-------|-------------|--------|-------------|
| Phase 1 | Fondations | Termine | 100% |
| Phase 2 | Navigation et UX | Termine | 100% |
| Phase 3 | Dashboards | Termine | 100% |

---

## Phase 1 : Fondations

### Taches completees

- [x] **Structure de routes `/dashboard/*`** - Deja en place, conservee
- [x] **Middleware d'authentification Supabase** - Deja en place (`middleware.ts`)
- [x] **Sidebar shadcn/ui avec groupements** - FAIT
  - Installe composants: `sidebar`, `breadcrumb`, `dropdown-menu`, `separator`, `sheet`, `tooltip`
  - Cree `components/dashboard/Sidebar/AppSidebar.tsx`
  - Cree `components/dashboard/Sidebar/SidebarConfig.ts` avec groupements (Platform, Financier, Administration)
  - Cree `components/dashboard/Sidebar/NavUser.tsx` pour menu utilisateur
  - Integre dans `app/dashboard/layout.tsx`
- [x] **Systeme de permissions RLS** - Deja en place via Supabase
  - UI conditionnelle dans `SidebarConfig.ts` (`adminOnly: true`)

### Taches completees recemment

- [x] **Migration vers nuqs** pour la gestion des filtres URL type-safe - FAIT 2025-11-26
  - Installe `nuqs` package
  - Ajoute `NuqsAdapter` dans `app/layout.tsx`
  - Cree `lib/hooks/dashboardSearchParams.ts` avec parsers partages
  - Mis a jour `lib/hooks/useDashboardFilters.ts` pour utiliser `useQueryStates`
  - API du hook inchangee (retro-compatible)

---

## Phase 2 : Navigation et UX

### Taches completees

- [x] **Breadcrumbs dynamiques** - FAIT
  - Cree `components/dashboard/DynamicBreadcrumb.tsx`
  - Detection automatique des UUIDs pour afficher "Details"
  - Integre dans header du layout
  - Note: Implementation simplifiee (pas de parallel route)

### Taches completees recemment

- [x] **TenantSwitcher pour admins** - FAIT 2025-11-26
  - Cree `components/dashboard/Sidebar/TenantSwitcher.tsx`
  - Dropdown dans le header de la sidebar
  - Affiche "Vue globale" ou nom du client selectionne
  - Stocke la selection dans URL param `?tenant=clientId`
  - Hook `useDashboardFilters` mis a jour pour respecter le tenant

### Taches completees recemment (suite Phase 2)

- [x] **Intercepting routes pour modales** - FAIT 2025-11-26
  - Cree `app/dashboard/@modal/default.tsx` - Slot par defaut
  - Cree `app/dashboard/@modal/(.)agents/[agentId]/calls/[callId]/page.tsx` - Intercepting route
  - Cree `app/dashboard/@modal/(.)agents/[agentId]/calls/[callId]/CallDetailModalContent.tsx`
  - Cree `components/dashboard/Modal.tsx` - Composant modal reutilisable
  - Mis a jour `app/dashboard/layout.tsx` pour inclure le slot `modal`

### Taches restantes

- [ ] **KPI cards cliquables avec drill-through** (optionnel)
  - Les KPIs existent mais ne redirigent pas vers pages detaillees
  - A implementer: navigation avec preservation des filtres

---

## Phase 3 : Dashboards

### Taches completees

- [x] **Dashboard Overview** (`/dashboard`) - REFACTORISE
  - Supprime `DashboardHeader` (doublon avec sidebar)
  - Cree `components/dashboard/PageHeader.tsx`
  - Affiche cards dynamiques (Agents deployes + Entreprises)

- [x] **Pages Agent** - FAIT
  - `/dashboard/agents` - Liste tous les agents accessibles
    - Cree `app/dashboard/agents/page.tsx`
    - Cree `app/dashboard/agents/AgentsListClient.tsx`
    - Cree `app/dashboard/agents/AgentDeploymentCard.tsx`
  - `/dashboard/agents/[agentId]` - Detail d'un agent specifique
    - Cree `app/dashboard/agents/[agentId]/page.tsx`
    - Cree `app/dashboard/agents/[agentId]/AgentDetailClient.tsx`
    - KPIs, graphiques, filtres de date
    - Lien retour vers liste

- [x] **Dashboard Louis** (`/dashboard/louis`) - SIMPLIFIE
  - Converti de route dynamique `[agentType]` vers route statique
  - Arthur et Alexandra en stand-by (code supprime)

### Taches completees recemment

- [x] **Page Performance** (`/dashboard/performance`) - FAIT 2025-11-26
  - Filtres avances (date + client/agent)
  - KPIs globaux avec comparaison periode
  - Graphiques: Volume d'appels, Emotions, Outcomes
  - Comparaison par type d'agent (AgentTypeComparison)
  - Top 10 clients (TopClientsTable)
  - Export CSV

### Taches completees recemment (suite)

- [x] **Section Clients (admin)** (`/dashboard/clients`) - FAIT 2025-11-26
  - Cree `app/dashboard/clients/layout.tsx` - Protection admin-only
  - Cree `app/dashboard/clients/page.tsx` - Liste des clients
  - Cree `app/dashboard/clients/ClientsListClient.tsx` - Composant client avec recherche
  - Cree `app/dashboard/clients/ClientCard.tsx` - Card client avec metriques
  - Cree `app/dashboard/clients/[clientId]/page.tsx` - Detail client
  - Cree `app/dashboard/clients/[clientId]/ClientDetailClient.tsx` - KPIs, graphiques, agents

### Taches completees recemment (suite Phase 3)

- [x] **Historique des appels** - FAIT 2025-11-26
  - Cree `lib/queries/calls.ts` - Fonctions de requete pour les appels
  - Cree `app/dashboard/agents/[agentId]/calls/page.tsx` - Server component liste
  - Cree `app/dashboard/agents/[agentId]/calls/CallsListClient.tsx` - Client component avec pagination
  - Cree `app/dashboard/agents/[agentId]/calls/[callId]/page.tsx` - Server component detail
  - Cree `app/dashboard/agents/[agentId]/calls/[callId]/CallDetailClient.tsx` - Detail complet avec player audio

### Taches restantes (optionnelles)

---

## Travaux additionnels realises

### Nettoyage code

- [x] **Suppression code Arthur dashboard**
  - Supprime: `lib/queries/arthur.ts`
  - Supprime: `lib/types/arthur.ts`
  - Supprime: Routes Arthur dans `[agentType]`
  - Conserve: Landing pages Arthur (`/arthur`, `/agents/arthur`)

- [x] **Suppression code Alexandra dashboard**
  - Confirme: Aucun code dashboard Alexandra existant
  - Conserve: Landing page Alexandra (`/alexandra`)

- [x] **Simplification routing**
  - Supprime: `app/dashboard/[agentType]/` (route dynamique)
  - Cree: `app/dashboard/louis/` (route statique)
  - Raison: Seul Louis actif, Arthur/Alexandra en stand-by

---

## Fichiers crees/modifies

### Nouveaux fichiers

```
components/dashboard/Sidebar/
  - AppSidebar.tsx
  - SidebarConfig.ts
  - NavUser.tsx
  - index.ts

components/dashboard/
  - DynamicBreadcrumb.tsx
  - PageHeader.tsx

app/dashboard/louis/
  - page.tsx
  - LouisDashboardClient.tsx

app/dashboard/agents/
  - page.tsx
  - AgentsListClient.tsx
  - AgentDeploymentCard.tsx
  - [agentId]/
    - page.tsx
    - AgentDetailClient.tsx

app/dashboard/clients/
  - layout.tsx
  - page.tsx
  - ClientsListClient.tsx
  - ClientCard.tsx
  - [clientId]/
    - page.tsx
    - ClientDetailClient.tsx

app/dashboard/performance/
  - page.tsx
  - PerformanceClient.tsx
  - TopClientsTable.tsx
  - AgentTypeComparison.tsx

app/dashboard/agents/[agentId]/calls/
  - page.tsx
  - CallsListClient.tsx
  - [callId]/
    - page.tsx
    - CallDetailClient.tsx

app/dashboard/@modal/
  - default.tsx
  - (.)agents/[agentId]/calls/[callId]/
    - page.tsx
    - CallDetailModalContent.tsx

components/dashboard/Sidebar/
  - TenantSwitcher.tsx

components/dashboard/
  - Modal.tsx

lib/hooks/
  - dashboardSearchParams.ts (parsers nuqs partages)

lib/queries/
  - calls.ts (fetchAgentCalls, fetchCallById)
```

### Fichiers modifies

```
app/dashboard/layout.tsx          - Integre Sidebar + DynamicBreadcrumb
app/dashboard/GlobalDashboardClient.tsx - Utilise PageHeader
app/layout.tsx                    - Ajoute NuqsAdapter wrapper
lib/hooks/useDashboardFilters.ts  - Migre vers nuqs useQueryStates
components/ui/                    - Composants shadcn ajoutes
```

### Fichiers supprimes

```
lib/queries/arthur.ts
lib/types/arthur.ts
app/dashboard/[agentType]/        - Remplace par /louis statique
```

---

## Prochaines etapes recommandees

1. ~~**Page Performance** - Creer `/dashboard/performance` avec filtres avances~~ FAIT
2. ~~**TenantSwitcher** - Pour basculer entre vue admin/client~~ FAIT
3. ~~**Section Clients** - CRUD clients pour admins~~ FAIT
4. ~~**Migration nuqs** - Remplacer gestion filtres URL actuelle~~ FAIT
5. ~~**Intercepting routes** - Modales pour details d'appels~~ FAIT
6. ~~**Historique des appels** - Page avec tableau pagine~~ FAIT

### Toutes les taches principales sont terminees!

---

## Notes techniques

### Build status
- Dernier build: OK (2025-11-26)
- Routes actives:
  - `/dashboard` - Vue d'ensemble
  - `/dashboard/agents` - Liste agents
  - `/dashboard/agents/[agentId]` - Detail agent
  - `/dashboard/agents/[agentId]/calls` - Historique des appels
  - `/dashboard/agents/[agentId]/calls/[callId]` - Detail d'un appel
  - `/dashboard/louis` - Dashboard Louis global
  - `/dashboard/financial` - Dashboard financier
  - `/dashboard/performance` - Page Performance avec filtres avances
  - `/dashboard/clients` - Liste clients (admin only)
  - `/dashboard/clients/[clientId]` - Detail client (admin only)
- Intercepting routes (modales):
  - `/dashboard/@modal/(.)agents/[agentId]/calls/[callId]` - Modal detail appel

### Dependances ajoutees
```json
{
  "@radix-ui/react-collapsible": "latest",
  "@radix-ui/react-tooltip": "latest",
  "nuqs": "latest"
}
```
