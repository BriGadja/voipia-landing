# Plan de Refonte des Dashboards Voipia

**Statut**: ✅ Prêt pour implémentation

---

## Résumé Exécutif

Refonte complète de la section dashboard pour :
1. **Overview** - Vue agrégée multi-agents avec KPIs comparables
2. **Financial (User)** - Consommation à facturer pour les clients
3. **Admin Financial** - Marges et rentabilité (admin only)
4. **Agent Type** - Redirection intelligente (1 agent → instance, plusieurs → agrégé)
5. **Instance Spécifique** - Dashboard personnalisé par déploiement (custom_kpis JSONB)

---

## Contrainte de Design - Structure Commune

**Référence : Dashboard Louis actuel** (à reproduire sur tous les dashboards)

```
┌─────────────────────────────────────────────────────────────────┐
│  Filtres: [Date Range] [Presets] [Entreprise ▼] [Agent ▼]      │
├─────────────────────────────────────────────────────────────────┤
│  KPIs (6 cartes compactes sur 1 ligne, funnel chronologique)   │
│  [Métrique1] → [Métrique2] → [Métrique3] → [...] → [Métrique6] │
├────────────────────────────┬────────────────────────────────────┤
│  Chart 1 (gauche haut)     │  Chart 2 (droite haut)            │
│                            │                                    │
├────────────────────────────┼────────────────────────────────────┤
│  Chart 3 (gauche bas)      │  Chart 4 (droite bas)             │
│                            │                                    │
└────────────────────────────┴────────────────────────────────────┘
```

**Règles de design :**
- ✅ **No scroll** - Tout visible en une page (viewport)
- ✅ **6 KPIs compacts** - `grid-cols-2 md:grid-cols-3 lg:grid-cols-6` avec `gap-2`
- ✅ **4 charts** - Grille 2×2 (`grid-cols-1 lg:grid-cols-2`)
- ✅ **Filtres en haut** - Date range + presets rapides + dropdowns
- ✅ **Ordre chronologique** - KPIs ordonnés selon le funnel métier

**Dimensions existantes (LouisDashboardClient.tsx) :**
- KPI cards: `compact={true}` mode
- Charts: hauteur fixe adaptée au viewport
- Spacing: `gap-2` pour KPIs, `gap-4` pour charts

---

## Sécurité et Permissions

### Structure des Permissions

```
user_client_permissions
├── user_id (uuid)           # Auth user ID
├── client_id (uuid)         # Client autorisé
└── permission_level (text)  # 'admin' | 'viewer' | etc.
```

### Vues RLS Existantes (à réutiliser)

| Vue | Filtre Automatique | Usage |
|-----|-------------------|-------|
| `v_user_accessible_clients` | `WHERE user_id = auth.uid()` | Liste clients dans filtres |
| `v_user_accessible_agents` | `WHERE user_id = auth.uid()` | Liste agents dans filtres |

### Matrice de Permissions par Dashboard

| Dashboard | Qui peut voir | Filtre Données | Filtre Dropdowns |
|-----------|---------------|----------------|------------------|
| `/overview` | Tous users auth | Agents de ses clients | Ses agents uniquement |
| `/financial` | Tous users auth | Ses agents uniquement | Ses agents uniquement |
| `/admin/financial` | `permission_level = 'admin'` | Tous les clients | Tous les clients |
| `/[agentType]` | Tous users auth | Ses agents du type | Ses agents du type |
| `/agent/[id]` | User avec accès au client | Cet agent uniquement | N/A |

### Implémentation Sécurité

**1. Vérification Admin (layout.tsx)**
```typescript
// Pour /dashboard/admin/*
const isAdmin = await checkIsAdmin() // vérifie permission_level = 'admin'
if (!isAdmin) redirect('/dashboard/overview')
```

**2. Filtrage des Dropdowns (hooks)**
```typescript
// useAccessibleClients() - utilise v_user_accessible_clients
// useAccessibleAgents() - utilise v_user_accessible_agents
// → Retourne UNIQUEMENT les ressources autorisées
```

**3. Filtrage des Données (RPC)**
```typescript
// Toutes les RPC reçoivent p_deployment_ids ou p_client_ids
// → Intersectés avec les IDs autorisés côté serveur
```

**4. Protection Route Agent Spécifique**
```typescript
// /dashboard/agent/[deploymentId]/page.tsx
const hasAccess = await checkDeploymentAccess(deploymentId)
if (!hasAccess) redirect('/dashboard/overview')
```

---

## Architecture Cible

### Structure des Routes

```
app/dashboard/
├── page.tsx                     # Redirect → /overview
├── layout.tsx                   # Auth + Sidebar (inchangé)
│
├── overview/                    # ✨ NOUVEAU - Dashboard agrégé
│   ├── page.tsx
│   └── OverviewDashboardClient.tsx
│
├── financial/                   # 🔄 REFACTO - Vue client consommation
│   ├── page.tsx
│   └── FinancialUserClient.tsx
│
├── admin/                       # ✨ NOUVEAU - Section admin
│   └── financial/
│       ├── page.tsx
│       └── AdminFinancialClient.tsx
│
├── [agentType]/                 # 🔄 REFACTO - Route dynamique
│   ├── page.tsx                 # Logique redirection intelligente
│   └── AgentTypeDashboardClient.tsx
│
└── agent/                       # ✨ NOUVEAU - Instance spécifique
    └── [deploymentId]/
        ├── page.tsx
        └── DeploymentDashboardClient.tsx
```

### Logique de Redirection [agentType]

```typescript
// /dashboard/[agentType]/page.tsx
const deploymentsOfType = await fetchAccessibleAgents(null, agentType)
if (deploymentsOfType.length === 1) {
  redirect(`/dashboard/agent/${deploymentsOfType[0].deployment_id}`)
}
// Sinon: afficher vue agrégée
```

---

## 1. /dashboard/overview - Dashboard Agrégé

### Structure (identique à Louis)
```
[Filtres] Date Range + Presets + Agent (multi-select RLS)
[KPIs]    6 cartes compactes sur 1 ligne
[Charts]  2×2 grille
```

### KPIs Universels (6 cartes, ordre funnel)

| Position | KPI | Formule | Format |
|----------|-----|---------|--------|
| 1 | Total Appels | `COUNT(*)` | number |
| 2 | Taux Décroché | `answered / total * 100` | percentage |
| 3 | Durée Moyenne | `AVG(duration_seconds)` | duration |
| 4 | Sentiment Positif | `% emotion = 'positive'` | percentage |
| 5 | Latence Moyenne | `AVG(avg_total_latency_ms)` | ms |
| 6 | Coût Total | `SUM(total_cost)` | currency |

### Charts (4, grille 2×2)

| Position | Chart | Type | Description |
|----------|-------|------|-------------|
| Haut-gauche | Volume par jour | Area | Breakdown par agent type (Louis/Arthur/Alexandra) |
| Haut-droite | Distribution émotions | Donut | Positif/Neutre/Négatif |
| Bas-gauche | Performance par type | Bar | Comparatif Louis vs Arthur vs Alexandra |
| Bas-droite | Latence infrastructure | Line | Évolution LLM + STT |

### Fichiers à créer
- `app/dashboard/overview/page.tsx`
- `app/dashboard/overview/OverviewDashboardClient.tsx`

---

## 2. /dashboard/financial - Vue Finance Utilisateur

### Objectif
Montrer au client **sa consommation à facturer** (pas de marge visible)

### Structure (identique à Louis)
```
[Filtres] Mois (défaut: en cours) + Agent (optionnel)
[KPIs]    6 cartes compactes sur 1 ligne
[Charts]  2×2 grille
```

### KPIs Financiers (6 cartes, ordre logique)

| Position | KPI | Formule | Format |
|----------|-----|---------|--------|
| 1 | Mensualité | `SUM(leasing)` des agents | currency |
| 2 | Minutes | `SUM(duration_seconds) / 60` | number + "min" |
| 3 | Coût Minutes | `minutes × cost_per_min` | currency |
| 4 | SMS Envoyés | `COUNT(sms)` | number |
| 5 | Coût SMS | `sms × cost_per_sms` | currency |
| 6 | **TOTAL** | Mensualité + Consommation | currency (highlight) |

### Charts (4, grille 2×2)

| Position | Chart | Type | Description |
|----------|-------|------|-------------|
| Haut-gauche | Évolution consommation | Area | Par jour: minutes + SMS |
| Haut-droite | Répartition par agent | Donut | % du total par agent |
| Bas-gauche | Détail par agent | Table | Agent / Leasing / Min / SMS / Total |
| Bas-droite | Historique mensuel | Bar | Comparatif M-1, M-2, M-3 |

### Calcul
```
Total = Σ (leasing + (minutes × cost_per_min) + (sms × cost_per_sms))
```

### Fichiers à créer
- `app/dashboard/financial/FinancialUserClient.tsx` (refacto)
- `components/dashboard/Financial/UserBillingKPIGrid.tsx`
- `components/dashboard/Financial/ConsumptionAreaChart.tsx`

---

## 3. /dashboard/admin/financial - Vue Admin Marges

### Objectif
Vue complète des marges pour l'admin Voipia (toi uniquement)

### Structure (identique à Louis)
```
[Filtres] Date Range + Presets + Client (optionnel)
[KPIs]    6 cartes compactes sur 1 ligne
[Charts]  2×2 grille
```

### KPIs Admin (6 cartes, ordre P&L)

| Position | KPI | Formule | Format |
|----------|-----|---------|--------|
| 1 | Revenue Total | leasing + consommation facturée | currency |
| 2 | Coût Fournisseur | Σ(stt + tts + llm + telecom + commission) | currency |
| 3 | Marge Totale | Revenue - Coût | currency |
| 4 | Marge % | (Marge / Revenue) × 100 | percentage |
| 5 | MRR | Σ(leasing) agents actifs | currency |
| 6 | Clients Actifs | COUNT(DISTINCT client_id) | number |

### Charts (4, grille 2×2)

| Position | Chart | Type | Description |
|----------|-------|------|-------------|
| Haut-gauche | Évolution P&L | Area | Revenue / Coût / Marge par jour |
| Haut-droite | Répartition coûts | Donut | STT / TTS / LLM / Telecom / Commission |
| Bas-gauche | Marge par client | Bar horizontal | Top clients par marge |
| Bas-droite | Marge par agent type | Bar | Louis vs Arthur vs Alexandra |

### Drill-down (click sur chart)
- Click client → Modal détail par agent de ce client
- Click agent type → Modal détail par déploiement

### Permissions
- `isAdmin` vérifié dans layout
- Route protégée `/dashboard/admin/*`

### Fichiers à créer
- `app/dashboard/admin/financial/page.tsx`
- `app/dashboard/admin/financial/AdminFinancialClient.tsx`
- `components/dashboard/Financial/MarginByClientChart.tsx`

---

## 4. /dashboard/[agentType] - Vue Agrégée par Type

### Logique de Redirection Intelligente

```
User a 1 seul Louis → redirect /dashboard/agent/[id]
User a 2+ Louis     → affiche vue agrégée Louis
```

### KPIs Spécifiques par Type

| Louis (Setter) | Arthur (Reactivation) | Alexandra (Support) |
|----------------|----------------------|---------------------|
| Total Appels | Prospects Totaux | Tickets Résolus |
| Taux Décroché | Séquences Actives | Résolution 1er appel |
| RDV Pris | Taux Reactivation | Satisfaction |
| Conversion | Tentatives Moyennes | Durée Moyenne |
| Callbacks | Coût/Conversion | Transferts |
| Latence | Latence | Latence |

### Fichiers à modifier
- `app/dashboard/[agentType]/page.tsx` (route dynamique)
- Réutiliser `LouisDashboardClient.tsx` comme base

---

## 5. /dashboard/agent/[deploymentId] - Instance Spécifique

### Objectif
Dashboard personnalisé par client utilisant les colonnes JSONB

### Configuration JSONB (agent_deployments)

```jsonc
// custom_kpis
{
  "additional_kpis": [
    {
      "id": "geographic_routing",
      "label": "Routage Géo",
      "format": "percentage",
      "query": "SELECT ... FROM agent_calls WHERE ..."
    }
  ]
}

// custom_charts
{
  "additional_charts": [
    {
      "id": "owner_performance",
      "type": "bar",
      "label": "Performance par Expert",
      "config": {...}
    }
  ]
}
```

### Affichage Dynamique
1. KPIs de base du type (Louis/Arthur/Alexandra)
2. \+ KPIs custom depuis `custom_kpis`
3. Charts de base
4. \+ Charts custom depuis `custom_charts`

### Exemple Nestenn (Louis immobilier)
- KPI: Taux d'assignation par commune
- KPI: Performance par owner/expert
- Chart: Heatmap géographique des communes

### Fichiers à créer
- `app/dashboard/agent/[deploymentId]/page.tsx`
- `app/dashboard/agent/[deploymentId]/DeploymentDashboardClient.tsx`
- `components/dashboard/DynamicKPIRenderer.tsx`
- `components/dashboard/DynamicChartRenderer.tsx`

---

## Fonctions RPC Supabase à Créer

### 1. get_overview_kpis

```sql
CREATE OR REPLACE FUNCTION get_overview_kpis(
  p_start_date DATE,
  p_end_date DATE,
  p_deployment_ids UUID[] DEFAULT NULL
) RETURNS JSONB
```

### 2. get_user_billing

```sql
CREATE OR REPLACE FUNCTION get_user_billing(
  p_start_date DATE,
  p_end_date DATE
) RETURNS JSONB
-- Retourne: total_leasing, total_minutes, total_sms, total_billable, agents[]
```

### 3. get_deployment_dashboard_config

```sql
CREATE OR REPLACE FUNCTION get_deployment_dashboard_config(
  p_deployment_id UUID
) RETURNS JSONB
-- Retourne: custom_kpis, custom_charts, base_kpis, base_charts
```

---

## Hooks React Query à Ajouter

```typescript
// lib/hooks/useDashboardData.ts

// Overview
export function useOverviewKPIs(filters): UseQueryResult<OverviewKPIMetrics>
export function useOverviewChartData(filters): UseQueryResult<OverviewChartData>

// User Billing
export function useUserBilling(filters): UseQueryResult<UserBillingData>

// Deployment-specific
export function useDeploymentConfig(deploymentId): UseQueryResult<DeploymentConfig>
export function useDeploymentKPIs(deploymentId, filters): UseQueryResult<KPIMetrics>
```

---

## Types à Ajouter

```typescript
// lib/types/dashboard.ts

interface UserBillingData {
  total_leasing: number
  total_minutes: number
  total_sms: number
  total_emails: number
  total_billable: number
  agents: AgentBillingDetail[]
}

interface AgentBillingDetail {
  deployment_id: string
  deployment_name: string
  agent_type: string
  leasing: number
  minutes_consumed: number
  sms_count: number
  consumption_cost: number
  total_billable: number
}

interface DeploymentConfig {
  deployment_id: string
  name: string
  agent_type: 'louis' | 'arthur' | 'alexandra'
  custom_kpis: CustomKPIConfig[]
  custom_charts: CustomChartConfig[]
}
```

---

## Sidebar Configuration

```typescript
// components/dashboard/Sidebar/SidebarConfig.ts
{
  label: 'Platform',
  items: [
    { title: 'Vue d\'ensemble', href: '/dashboard/overview', icon: LayoutDashboard },
    { title: 'Agents', href: '/dashboard/agents', icon: Users },
  ],
},
{
  label: 'Mes Agents',
  items: [
    { title: 'Louis', href: '/dashboard/louis', icon: Phone },
    { title: 'Arthur', href: '/dashboard/arthur', icon: RefreshCw },
    { title: 'Alexandra', href: '/dashboard/alexandra', icon: Headphones },
  ],
},
{
  label: 'Financier',
  items: [
    { title: 'Ma Consommation', href: '/dashboard/financial', icon: Receipt },
  ],
},
{
  label: 'Administration',
  adminOnly: true,
  items: [
    { title: 'Marges & Revenue', href: '/dashboard/admin/financial', icon: TrendingUp },
    { title: 'Clients', href: '/dashboard/clients', icon: Building2 },
  ],
}
```

---

## Phases d'Implémentation

### Phase 1: Restructuration Routes (2-3 jours)
- [ ] Créer `/dashboard/overview/`
- [ ] Modifier `/dashboard/page.tsx` → redirect /overview
- [ ] Créer route dynamique `/dashboard/[agentType]/`
- [ ] Tester navigation et permissions

### Phase 2: Vue Finance Utilisateur (2 jours)
- [ ] Créer RPC `get_user_billing`
- [ ] Créer hook `useUserBilling`
- [ ] Créer `FinancialUserClient.tsx`
- [ ] Créer `UserBillingCard` et `AgentBillingTable`

### Phase 3: Vue Admin Marges (2 jours)
- [ ] Créer route `/dashboard/admin/financial/`
- [ ] Créer `AdminFinancialClient.tsx`
- [ ] Créer `MarginByClientTable`
- [ ] Vérification `isAdmin` dans layout

### Phase 4: Overview Dashboard (2 jours)
- [ ] Créer RPC `get_overview_kpis`
- [ ] Créer `OverviewDashboardClient.tsx`
- [ ] Intégrer charts existants
- [ ] Ajouter AgentTypeComparison

### Phase 5: Instance Spécifique (3 jours)
- [ ] Créer route `/dashboard/agent/[deploymentId]/`
- [ ] Créer RPC `get_deployment_dashboard_config`
- [ ] Créer `DynamicKPIRenderer` et `DynamicChartRenderer`
- [ ] Tester avec Nestenn (KPIs custom)

### Phase 6: Sidebar et Polish (1-2 jours)
- [ ] Mettre à jour `SidebarConfig.ts`
- [ ] Tests E2E parcours critiques
- [ ] Vérification permissions RLS

---

## Fichiers Critiques à Modifier

| Fichier | Action |
|---------|--------|
| `app/dashboard/layout.tsx` | Étendre pour section admin |
| `app/dashboard/page.tsx` | Redirect vers /overview |
| `lib/hooks/useDashboardData.ts` | Ajouter nouveaux hooks |
| `lib/queries/financial.ts` | Pattern pour user billing |
| `components/dashboard/Sidebar/SidebarConfig.ts` | Mettre à jour nav |
| `lib/types/dashboard.ts` | Ajouter nouveaux types |

---

## Risques et Mitigations

| Risque | Mitigation |
|--------|------------|
| Régression dashboards existants | Garder anciennes routes pendant migration |
| Performance queries agrégées | Index + vues matérialisées si besoin |
| Complexité JSONB custom | Commencer simple, itérer |
| Permissions incorrectes | Tests exhaustifs multi-profils |

---

## Prêt pour Implémentation ✅

Ce plan couvre :
- ✅ Dashboard Overview avec KPIs comparables
- ✅ Vue Finance Utilisateur (consommation à facturer)
- ✅ Vue Admin Marges (admin only)
- ✅ Redirection intelligente agentType
- ✅ Instance spécifique avec custom_kpis JSONB
- ✅ Filtres par agent accessibles via RLS
