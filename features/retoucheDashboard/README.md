# Audit & Refactoring Dashboard Voipia

**Date de l'audit** : 26 Novembre 2025  
**Score initial** : 7.5/10  
**Objectif** : 9/10  

---

## Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Architecture Actuelle](#2-architecture-actuelle)
3. [Points Forts](#3-points-forts)
4. [Problèmes Identifiés](#4-problèmes-identifiés)
5. [Plan d'Action Détaillé](#5-plan-daction-détaillé)
6. [Checklist de Progression](#6-checklist-de-progression)
7. [Fichiers Concernés](#7-fichiers-concernés)
8. [Code Samples & Solutions](#8-code-samples--solutions)

---

## 1. Vue d'Ensemble

### Périmètre de l'Audit

L'audit couvre l'ensemble de la partie dashboard de l'application Voipia :

| Catégorie | Nombre de fichiers | Lignes de code |
|-----------|-------------------|----------------|
| App Routes (`/app/dashboard/`) | 32 fichiers | ~3000 lignes |
| Components (`/components/dashboard/`) | 33 fichiers | ~4000 lignes |
| Data Layer (`/lib/`) | 12+ fichiers | ~1500 lignes |
| **Total** | **77+ fichiers** | **~8500 lignes** |

### Stack Technique

- **Framework** : Next.js 15 (App Router)
- **Language** : TypeScript
- **Styling** : Tailwind CSS + Glassmorphism
- **State** : URL params (nuqs) + React Query
- **Database** : Supabase (PostgreSQL + RPC functions)
- **Charts** : Recharts

---

## 2. Architecture Actuelle

### 2.1 Structure des Dossiers

```
app/dashboard/
├── page.tsx                    # Dashboard global (entry point)
├── layout.tsx                  # Layout partagé avec Sidebar
├── GlobalDashboardClient.tsx   # Client component principal
│
├── louis/                      # Dashboard agent Louis
│   ├── page.tsx
│   └── LouisDashboardClient.tsx
│
├── financial/                  # Dashboard financier
│   ├── page.tsx
│   └── FinancialDashboardClient.tsx
│
├── agents/                     # Liste des agents
│   ├── page.tsx
│   ├── AgentsListClient.tsx
│   └── AgentDeploymentCard.tsx
│
├── clients/                    # Liste des clients
│   ├── page.tsx
│   └── ClientsListClient.tsx
│
├── performance/                # Dashboard performance
│   ├── page.tsx
│   └── PerformanceDashboardClient.tsx
│
├── settings/                   # Paramètres
│   └── page.tsx
│
└── @modal/                     # Parallel routes pour modals
    └── (.)agents/[agentId]/calls/[callId]/
        └── page.tsx
```

### 2.2 Components Dashboard

```
components/dashboard/
├── Cards/
│   ├── KPICard.tsx             # Carte KPI avec animation
│   ├── KPIGrid.tsx             # Grille de KPIs responsive
│   ├── AgentTypeCard.tsx       # Carte type d'agent (Louis/Arthur)
│   ├── ClientCard.tsx          # Carte client
│   └── AgentDeploymentCard.tsx # Carte déploiement agent
│
├── Charts/
│   ├── CallVolumeChart.tsx     # Volume d'appels (Area chart)
│   ├── OutcomeBreakdownChart.tsx # Répartition outcomes (Bar)
│   ├── EmotionDistributionChart.tsx # Distribution émotions (Pie)
│   ├── ConversionFunnelChart.tsx # Funnel conversion
│   └── LatencyTimeSeriesChart.tsx # Latences temps réel
│
├── Filters/
│   ├── DateRangeFilter.tsx     # Filtre période
│   └── ClientAgentFilter.tsx   # Filtre client/agent
│
├── Financial/
│   ├── FinancialKPIGrid.tsx
│   ├── FinancialTimeSeriesChart.tsx
│   ├── CostBreakdownChart.tsx
│   ├── ClientBreakdownTable.tsx
│   ├── ClientDrilldownModal.tsx
│   ├── LeasingKPISection.tsx
│   ├── ConsumptionKPISection.tsx
│   ├── ClientUsageDashboard.tsx
│   └── DeploymentUsageDetails.tsx
│
├── Sidebar/
│   ├── AppSidebar.tsx          # Sidebar principale
│   ├── SidebarConfig.ts        # Configuration menu
│   └── TenantSwitcher.tsx      # Switch client
│
├── DashboardHeader.tsx         # En-tête avec filtres
├── DashboardBreadcrumb.tsx     # Fil d'Ariane
├── DynamicBreadcrumb.tsx       # Breadcrumb dynamique
├── ExportCSVButton.tsx         # Export données
├── Modal.tsx                   # Modal générique
└── PageHeader.tsx              # En-tête de page
```

### 2.3 Data Layer

```
lib/
├── hooks/
│   ├── useDashboardFilters.ts      # Gestion filtres URL
│   ├── useDashboardData.ts         # Hooks React Query
│   ├── useFinancialData.ts         # Hooks données financières
│   ├── useLatencyData.ts           # Hooks latences
│   └── dashboardSearchParams.ts    # Parsers nuqs
│
├── queries/
│   ├── global.ts                   # Queries globales
│   ├── louis.ts                    # Queries Louis spécifiques
│   ├── financial.ts                # Queries financières
│   ├── calls.ts                    # Queries appels détaillés
│   └── dashboard.ts                # Queries dashboard génériques
│
└── types/
    ├── dashboard.ts                # Types dashboard
    ├── financial.ts                # Types financiers
    └── latency.ts                  # Types latences
```

### 2.4 Flux de Données

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                          │
│                    (Click filter, change date)                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      URL QUERY PARAMS                            │
│              Managed by nuqs (dashboardSearchParams.ts)          │
│    ?startDate=2025-10-01&endDate=2025-11-26&clientIds=xxx       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   useDashboardFilters()                          │
│              Parses URL → DashboardFilters object                │
│    { startDate, endDate, clientIds, deploymentId, agentType }   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    React Query Hooks                             │
│         useGlobalKPIs(), useChartData(), useAgentTypes()        │
│              (useDashboardData.ts, useFinancialData.ts)         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Query Functions                              │
│           fetchGlobalKPIs(), fetchChartData(), etc.             │
│                   (lib/queries/*.ts)                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Client                               │
│              RPC calls: get_kpi_metrics, get_chart_data         │
│              Direct queries: agent_calls, clients, etc.         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                          │
│              Views: v_agent_calls_enriched                       │
│              Functions: get_global_kpis, get_louis_kpis, etc.   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UI Components                                 │
│              KPICard, Charts, Tables with data props            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Points Forts

### 3.1 Architecture Solide

| Aspect | Implémentation | Qualité |
|--------|---------------|---------|
| **Server/Client Split** | Pages serveur, *Client components pour interactivité | Excellent |
| **Container/Presentational** | *Client fetch data, components affichent | Très bon |
| **Separation of Concerns** | queries/, hooks/, types/ bien séparés | Excellent |
| **File Organization** | Structure claire et prévisible | Très bon |

### 3.2 State Management Intelligent

```typescript
// URL-based state avec nuqs - Permet partage d'URL et persistance
export function useDashboardFilters() {
  const [startDate, setStartDate] = useQueryState('startDate', startDateParser)
  const [endDate, setEndDate] = useQueryState('endDate', endDateParser)
  const [clientIds, setClientIds] = useQueryState('clientIds', clientIdsParser)
  // ...
}
```

**Avantages** :
- URL bookmarkable et partageable
- Pas de prop drilling
- Historique navigateur fonctionne
- State persistant au refresh

### 3.3 React Query Bien Configuré

```typescript
// Cache et refetch appropriés pour dashboard
const STALE_TIME = 3600000    // 1 heure
const REFETCH_INTERVAL = 3600000  // 1 heure

export function useGlobalKPIs(filters: DashboardFilters) {
  return useQuery({
    queryKey: ['global-kpis', filters],
    queryFn: () => fetchGlobalKPIs(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}
```

### 3.4 TypeScript Complet

Types bien définis pour :
- `DashboardFilters` - Filtres
- `KPIMetrics` - KPIs
- `ChartDataPoint` - Données graphiques
- `FinancialKPIResponse` - Données financières
- `CallDetail` - Détails appels

### 3.5 UI/UX Professionnelle

- Loading states avec skeletons
- Empty states cohérents
- Animations Framer Motion
- Design glassmorphism consistant
- Responsive mobile-first

---

## 4. Problèmes Identifiés

### 4.1 CRITIQUE - Typage Faible CSV Export

**Localisation** : 
- `lib/queries/global.ts` ligne 238
- `lib/queries/louis.ts` ligne 102

**Code Actuel** :
```typescript
// ❌ PROBLÈME : any type = perte de type safety
export async function exportGlobalCallsCSV(filters: DashboardFilters): Promise<string> {
  const { data, error } = await supabase
    .from('agent_calls')
    .select(`
      id,
      started_at,
      // ...
    `)
  
  // ❌ any type ici
  const rows = data.map((call: any) => [
    new Date(call.started_at).toLocaleString('fr-FR'),
    call.agent_deployments?.clients?.name || '',
    call.agent_deployments?.name || '',
    // ...
  ])
  
  return [headers, ...rows].map(row => row.join(',')).join('\n')
}
```

**Impact** :
- Pas d'autocomplétion IDE
- Erreurs silencieuses si schéma DB change
- Bugs runtime potentiels

**Solution** :
```typescript
// ✅ SOLUTION : Créer type dédié
interface CallExportRow {
  id: string
  started_at: string
  duration_seconds: number | null
  outcome: string | null
  answered: boolean
  appointment_scheduled: boolean
  emotion: string | null
  transcript: string | null
  agent_deployments: {
    name: string
    clients: {
      name: string
    } | null
  } | null
}

const rows = data.map((call: CallExportRow) => [
  new Date(call.started_at).toLocaleString('fr-FR'),
  call.agent_deployments?.clients?.name || '',
  // ...
])
```

---

### 4.2 CRITIQUE - Absence d'Error Boundaries

**Localisation** : `app/dashboard/layout.tsx`

**Code Actuel** :
```typescript
// ❌ PROBLÈME : Pas de gestion d'erreur
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <main>
        <Suspense fallback={<Loader2 />}>
          {children}  {/* Si erreur ici → écran blanc */}
        </Suspense>
      </main>
    </SidebarProvider>
  )
}
```

**Impact** :
- Query qui échoue = page entièrement blanche
- Utilisateur sans feedback
- Impossible de récupérer sans refresh

**Solution** :
```typescript
// ✅ SOLUTION : Ajouter Error Boundary
'use client'
import { ErrorBoundary } from 'react-error-boundary'

function DashboardErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div className="flex flex-col items-center justify-center h-screen">
      <AlertTriangle className="w-16 h-16 text-red-500 mb-4" />
      <h2 className="text-xl font-bold text-white mb-2">Une erreur est survenue</h2>
      <p className="text-white/60 mb-4">{error.message}</p>
      <Button onClick={resetErrorBoundary}>Réessayer</Button>
    </div>
  )
}

export default function DashboardLayout({ children }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <main>
        <ErrorBoundary FallbackComponent={DashboardErrorFallback}>
          <Suspense fallback={<Loader2 />}>
            {children}
          </Suspense>
        </ErrorBoundary>
      </main>
    </SidebarProvider>
  )
}
```

---

### 4.3 CRITIQUE - Query Keys avec Objects

**Localisation** : `lib/hooks/useDashboardData.ts`

**Code Actuel** :
```typescript
// ❌ PROBLÈME : Arrays créent nouvelles références
export function useAccessibleAgents(
  clientIds?: string[],
  agentTypeName?: 'louis' | 'arthur' | 'alexandra' | null
) {
  return useQuery({
    queryKey: ['accessible-agents', clientIds, agentTypeName],
    // clientIds = ['a', 'b'] !== ['a', 'b'] (références différentes)
    queryFn: () => fetchAccessibleAgents(clientIds, agentTypeName),
  })
}
```

**Impact** :
- Cache miss à chaque render même si valeurs identiques
- Re-fetch inutiles
- Performance dégradée

**Solution** :
```typescript
// ✅ SOLUTION : Sérialiser les arrays
export function useAccessibleAgents(
  clientIds?: string[],
  agentTypeName?: 'louis' | 'arthur' | 'alexandra' | null
) {
  return useQuery({
    queryKey: ['accessible-agents', clientIds?.sort().join(',') || '', agentTypeName || ''],
    queryFn: () => fetchAccessibleAgents(clientIds, agentTypeName),
  })
}
```

---

### 4.4 MOYEN - Code Dupliqué : formatRelativeTime

**Localisation** :
- `components/dashboard/Cards/AgentTypeCard.tsx` lignes 21-32
- `app/dashboard/agents/AgentDeploymentCard.tsx` lignes 15-33

**Code Dupliqué** :
```typescript
// ❌ PROBLÈME : Même fonction dans 2 fichiers
function formatRelativeTime(date: string): string {
  const now = new Date()
  const then = new Date(date)
  const diffInSeconds = Math.floor((now.getTime() - then.getTime()) / 1000)
  
  if (diffInSeconds < 60) return "À l'instant"
  if (diffInSeconds < 3600) return `Il y a ${Math.floor(diffInSeconds / 60)} min`
  if (diffInSeconds < 86400) return `Il y a ${Math.floor(diffInSeconds / 3600)}h`
  if (diffInSeconds < 604800) return `Il y a ${Math.floor(diffInSeconds / 86400)}j`
  return then.toLocaleDateString('fr-FR')
}
```

**Solution** :
```typescript
// ✅ SOLUTION : Extraire vers lib/utils.ts
// lib/utils.ts
export function formatRelativeTime(date: string | Date): string {
  const now = new Date()
  const then = typeof date === 'string' ? new Date(date) : date
  const diffInSeconds = Math.floor((now.getTime() - then.getTime()) / 1000)
  
  if (diffInSeconds < 60) return "À l'instant"
  if (diffInSeconds < 3600) return `Il y a ${Math.floor(diffInSeconds / 60)} min`
  if (diffInSeconds < 86400) return `Il y a ${Math.floor(diffInSeconds / 3600)}h`
  if (diffInSeconds < 604800) return `Il y a ${Math.floor(diffInSeconds / 86400)}j`
  return then.toLocaleDateString('fr-FR')
}
```

---

### 4.5 MOYEN - Code Dupliqué : Déduplication Arrays

**Localisation** :
- `components/dashboard/Filters/ClientAgentFilter.tsx` lignes 48-65
- `app/dashboard/agents/AgentsListClient.tsx` lignes 13-14

**Code Dupliqué** :
```typescript
// ❌ PROBLÈME : Pattern répété partout
const clients = clientsRaw?.reduce((acc, client) => {
  if (!acc.find((c) => c.client_id === client.client_id)) {
    acc.push(client)
  }
  return acc
}, [] as typeof clientsRaw)

const agents = agentsRaw?.reduce((acc, agent) => {
  if (!acc.find((a) => a.deployment_id === agent.deployment_id)) {
    acc.push(agent)
  }
  return acc
}, [] as typeof agentsRaw)
```

**Solution** :
```typescript
// ✅ SOLUTION : Fonction utilitaire générique
// lib/utils.ts
export function deduplicateBy<T>(array: T[] | undefined, keyFn: (item: T) => string | number): T[] {
  if (!array) return []
  const seen = new Set<string | number>()
  return array.filter(item => {
    const key = keyFn(item)
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

// Usage
const clients = deduplicateBy(clientsRaw, c => c.client_id)
const agents = deduplicateBy(agentsRaw, a => a.deployment_id)
```

---

### 4.6 MOYEN - Code Dupliqué : Export CSV

**Localisation** :
- `lib/queries/global.ts` lignes 215-265
- `lib/queries/louis.ts` lignes 101-145
- `lib/queries/dashboard.ts` pattern similaire

**Problème** : Chaque fichier implémente sa propre logique CSV

**Solution** :
```typescript
// ✅ SOLUTION : Utilitaire CSV builder
// lib/utils/csv.ts
interface CSVColumn<T> {
  header: string
  accessor: (row: T) => string | number | boolean
}

export function buildCSV<T>(data: T[], columns: CSVColumn<T>[]): string {
  const headers = columns.map(c => c.header)
  const rows = data.map(row => 
    columns.map(col => {
      const value = col.accessor(row)
      // Escape commas and quotes
      const str = String(value ?? '')
      return str.includes(',') || str.includes('"') 
        ? `"${str.replace(/"/g, '""')}"` 
        : str
    })
  )
  return [headers, ...rows].map(row => row.join(',')).join('\n')
}

// Usage
const csv = buildCSV(calls, [
  { header: 'Date', accessor: c => new Date(c.started_at).toLocaleString('fr-FR') },
  { header: 'Client', accessor: c => c.agent_deployments?.clients?.name || '' },
  { header: 'Agent', accessor: c => c.agent_deployments?.name || '' },
  // ...
])
```

---

### 4.7 MOYEN - Over-fetching Financial Dashboard

**Localisation** : `app/dashboard/financial/FinancialDashboardClient.tsx` lignes 29-36

**Code Actuel** :
```typescript
// ❌ PROBLÈME : 6 queries parallèles même si pas toutes visibles
function AdminFinancialDashboard() {
  const { data: kpiData, isLoading: kpiLoading } = useFinancialKPIs(filters)
  const { data: leasingData, isLoading: leasingLoading } = useLeasingMetrics(filters)
  const { data: consumptionData, isLoading: consumptionLoading } = useConsumptionMetrics(filters)
  const { data: clientData, isLoading: clientLoading } = useClientBreakdown(filters)
  const { data: timeSeriesData, isLoading: timeSeriesLoading } = useFinancialTimeSeries(filters)
  const { data: costBreakdownData, isLoading: costBreakdownLoading } = useCostBreakdown(filters)
  // ...
}
```

**Impact** :
- 6 requêtes Supabase à chaque changement de filtre
- Bande passante gaspillée
- Charge DB inutile

**Solution** :
```typescript
// ✅ SOLUTION : Lazy loading par tab/section
const [activeTab, setActiveTab] = useState('overview')

// Charger uniquement les données du tab actif
const { data: kpiData } = useFinancialKPIs(filters) // Toujours (header)

const { data: leasingData } = useLeasingMetrics(filters, {
  enabled: activeTab === 'leasing' || activeTab === 'overview'
})

const { data: consumptionData } = useConsumptionMetrics(filters, {
  enabled: activeTab === 'consumption' || activeTab === 'overview'
})
```

---

### 4.8 MOYEN - Charts Sans Memoization

**Localisation** : `components/dashboard/Charts/CallVolumeChart.tsx` lignes 21-32

**Code Actuel** :
```typescript
// ❌ PROBLÈME : Transformation à chaque render
export function CallVolumeChart({ data }: CallVolumeChartProps) {
  // Cette transformation s'exécute à CHAQUE render parent
  const chartData = data.map((item) => ({
    date: new Date(item.date).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
    }),
    'Total appels': item.total_calls,
    'Appels répondus': item.answered_calls,
    'RDV pris': item.appointments,
  }))

  return <ResponsiveContainer>...</ResponsiveContainer>
}
```

**Impact** :
- Re-calcul inutile si parent re-render
- Performance dégradée avec grands datasets
- Recharts re-render complet

**Solution** :
```typescript
// ✅ SOLUTION : Memoization
import { memo, useMemo } from 'react'

export const CallVolumeChart = memo(function CallVolumeChart({ data }: CallVolumeChartProps) {
  const chartData = useMemo(() => 
    data.map((item) => ({
      date: new Date(item.date).toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: 'short',
      }),
      'Total appels': item.total_calls,
      'Appels répondus': item.answered_calls,
      'RDV pris': item.appointments,
    })),
    [data]
  )

  return <ResponsiveContainer>...</ResponsiveContainer>
})
```

---

### 4.9 MOYEN - Alert au lieu de Toast

**Localisation** : `components/dashboard/ExportCSVButton.tsx`

**Code Actuel** :
```typescript
// ❌ PROBLÈME : alert() bloquant et non stylisé
const handleExport = async () => {
  try {
    const csv = await exportFn(filters)
    // ...
  } catch (error) {
    console.error('Error exporting CSV:', error)
    alert('Erreur lors de l\'export des données. Veuillez réessayer.')
  }
}
```

**Impact** :
- UX pauvre (popup navigateur)
- Style non cohérent avec l'app
- Bloque l'interaction

**Solution** :
```typescript
// ✅ SOLUTION : Toast notification
import { toast } from 'sonner' // ou react-hot-toast

const handleExport = async () => {
  try {
    const csv = await exportFn(filters)
    // ...
    toast.success('Export réussi')
  } catch (error) {
    console.error('Error exporting CSV:', error)
    toast.error('Erreur lors de l\'export. Veuillez réessayer.')
  }
}
```

---

### 4.10 MOYEN - Validation Date Range Manquante

**Localisation** : `app/dashboard/financial/FinancialDashboardClient.tsx`

**Code Actuel** :
```typescript
// ❌ PROBLÈME : Pas de validation
<input
  type="date"
  value={filters.startDate}
  onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
/>
<input
  type="date"
  value={filters.endDate}
  onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
/>
```

**Impact** :
- Utilisateur peut mettre startDate > endDate
- Requêtes DB avec range invalide
- Résultats vides/incorrects sans feedback

**Solution** :
```typescript
// ✅ SOLUTION : Validation inline
const handleStartDateChange = (newStart: string) => {
  if (new Date(newStart) > new Date(filters.endDate)) {
    toast.warning('La date de début ne peut pas être après la date de fin')
    return
  }
  setFilters({ ...filters, startDate: newStart })
}

const handleEndDateChange = (newEnd: string) => {
  if (new Date(newEnd) < new Date(filters.startDate)) {
    toast.warning('La date de fin ne peut pas être avant la date de début')
    return
  }
  setFilters({ ...filters, endDate: newEnd })
}
```

---

### 4.11 FAIBLE - Accessibilité Incomplète

**Problèmes identifiés** :

1. **ARIA Labels Manquants**
```typescript
// ❌ Boutons sans label
<button onClick={handleExport}>
  <Download className="w-4 h-4" />
</button>

// ✅ Avec ARIA
<button onClick={handleExport} aria-label="Exporter les données en CSV">
  <Download className="w-4 h-4" />
</button>
```

2. **Charts Dépendants des Couleurs**
- Pas de patterns/textures alternatives
- Daltoniens ne peuvent pas distinguer les séries

3. **Navigation Clavier Incomplète**
- Dropdowns ne supportent pas Arrow keys
- Focus trap manquant dans modals

---

### 4.12 FAIBLE - Empty States Non Factorisés

**Code Répété** dans plusieurs composants :
```typescript
// ❌ Pattern répété partout
<div className="flex flex-col items-center justify-center py-16 space-y-4">
  <div className="p-4 rounded-full bg-white/5">
    <Icon className="w-12 h-12 text-white/20" />
  </div>
  <div className="text-center space-y-2">
    <p className="text-lg font-semibold text-white">Aucune donnée</p>
    <p className="text-sm text-white/60">Message contextuel</p>
  </div>
</div>
```

**Solution** :
```typescript
// ✅ Composant réutilisable
// components/ui/EmptyState.tsx
interface EmptyStateProps {
  icon: LucideIcon
  title: string
  description?: string
  action?: {
    label: string
    onClick: () => void
  }
}

export function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 space-y-4">
      <div className="p-4 rounded-full bg-white/5">
        <Icon className="w-12 h-12 text-white/20" />
      </div>
      <div className="text-center space-y-2">
        <p className="text-lg font-semibold text-white">{title}</p>
        {description && <p className="text-sm text-white/60">{description}</p>}
      </div>
      {action && (
        <Button variant="outline" onClick={action.onClick}>
          {action.label}
        </Button>
      )}
    </div>
  )
}
```

---

### 4.13 FAIBLE - ESLint Disable Sans Fix

**Localisation** : `components/dashboard/Filters/ClientAgentFilter.tsx` ligne 65

**Code Actuel** :
```typescript
// ❌ PROBLÈME : Désactivation sans résolution
useEffect(() => {
  if (selectedClientIds.length > 0 && agents) {
    const validAgentIds = agents.map((a) => a.deployment_id)
    const newAgentIds = selectedAgentIds.filter((id) => validAgentIds.includes(id))
    if (newAgentIds.length !== selectedAgentIds.length) {
      onChange(selectedClientIds, newAgentIds)
    }
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [selectedClientIds, agents])
```

**Problème** : 
- `onChange` et `selectedAgentIds` manquent dans deps
- Peut causer bugs avec stale closures

**Solution** :
```typescript
// ✅ SOLUTION : useCallback pour stabiliser onChange
const stableOnChange = useCallback(
  (clientIds: string[], agentIds: string[]) => {
    onChange(clientIds, agentIds)
  },
  [onChange]
)

useEffect(() => {
  if (selectedClientIds.length > 0 && agents) {
    const validAgentIds = agents.map((a) => a.deployment_id)
    const newAgentIds = selectedAgentIds.filter((id) => validAgentIds.includes(id))
    if (newAgentIds.length !== selectedAgentIds.length) {
      stableOnChange(selectedClientIds, newAgentIds)
    }
  }
}, [selectedClientIds, agents, selectedAgentIds, stableOnChange])
```

---

## 5. Plan d'Action Détaillé

### Phase 1 : Quick Wins (Effort: 1-2h)

| # | Tâche | Fichier(s) | Priorité |
|---|-------|-----------|----------|
| 1.1 | Créer type `CallExportRow` | `lib/types/dashboard.ts` | HAUTE |
| 1.2 | Appliquer type aux exports CSV | `lib/queries/global.ts`, `louis.ts` | HAUTE |
| 1.3 | Sérialiser query keys (arrays → strings) | `lib/hooks/useDashboardData.ts` | HAUTE |
| 1.4 | Extraire `formatRelativeTime` vers utils | `lib/utils.ts` | MOYENNE |
| 1.5 | Extraire `deduplicateBy` vers utils | `lib/utils.ts` | MOYENNE |
| 1.6 | Mettre à jour imports dans composants | `AgentTypeCard.tsx`, `ClientAgentFilter.tsx`, etc. | MOYENNE |

### Phase 2 : Robustesse (Effort: 2-4h)

| # | Tâche | Fichier(s) | Priorité |
|---|-------|-----------|----------|
| 2.1 | Créer composant `DashboardErrorFallback` | `components/dashboard/DashboardErrorFallback.tsx` | HAUTE |
| 2.2 | Ajouter Error Boundary dans layout | `app/dashboard/layout.tsx` | HAUTE |
| 2.3 | Installer et configurer toast library | `package.json`, `app/layout.tsx` | MOYENNE |
| 2.4 | Remplacer alert() par toast | `ExportCSVButton.tsx` | MOYENNE |
| 2.5 | Ajouter validation date range | `DateRangeFilter.tsx` ou composants concernés | MOYENNE |
| 2.6 | Wrapper Charts avec memo | `CallVolumeChart.tsx`, `OutcomeBreakdownChart.tsx`, etc. | MOYENNE |
| 2.7 | Ajouter useMemo pour transformations data | Tous les Charts | MOYENNE |

### Phase 3 : Optimisation (Effort: 4-8h)

| # | Tâche | Fichier(s) | Priorité |
|---|-------|-----------|----------|
| 3.1 | Créer CSV builder utility | `lib/utils/csv.ts` | MOYENNE |
| 3.2 | Refactorer exports CSV avec utility | `lib/queries/*.ts` | MOYENNE |
| 3.3 | Implémenter lazy loading Financial | `FinancialDashboardClient.tsx` | MOYENNE |
| 3.4 | Créer composant `EmptyState` | `components/ui/EmptyState.tsx` | BASSE |
| 3.5 | Remplacer empty states dupliqués | Tous les dashboards | BASSE |
| 3.6 | Fix ESLint disable avec useCallback | `ClientAgentFilter.tsx` | BASSE |

### Phase 4 : Accessibilité (Effort: 2-4h)

| # | Tâche | Fichier(s) | Priorité |
|---|-------|-----------|----------|
| 4.1 | Ajouter ARIA labels aux boutons | Tous les composants avec boutons icon-only | BASSE |
| 4.2 | Améliorer contrast ratios si nécessaire | CSS global | BASSE |
| 4.3 | Ajouter keyboard navigation aux dropdowns | `ClientAgentFilter.tsx` | BASSE |
| 4.4 | Focus trap dans modals | `Modal.tsx`, `ClientDrilldownModal.tsx` | BASSE |

---

## 6. Checklist de Progression

### Phase 1 : Quick Wins (COMPLETE)
- [x] 1.1 Type `CallExportRow` créé
- [x] 1.2 Types appliqués aux exports CSV
- [x] 1.3 Query keys sérialisés
- [x] 1.4 `formatRelativeTime` extrait
- [x] 1.5 `deduplicateBy` extrait
- [x] 1.6 Imports mis à jour

### Phase 2 : Robustesse
- [ ] 2.1 `DashboardErrorFallback` créé
- [ ] 2.2 Error Boundary ajouté
- [ ] 2.3 Toast library configurée
- [ ] 2.4 `alert()` remplacés
- [ ] 2.5 Validation dates ajoutée
- [ ] 2.6 Charts wrapped avec memo
- [ ] 2.7 useMemo ajoutés

### Phase 3 : Optimisation
- [ ] 3.1 CSV builder créé
- [ ] 3.2 Exports refactorés
- [ ] 3.3 Lazy loading Financial
- [ ] 3.4 `EmptyState` créé
- [ ] 3.5 Empty states remplacés
- [ ] 3.6 ESLint disable fixé

### Phase 4 : Accessibilité
- [ ] 4.1 ARIA labels ajoutés
- [ ] 4.2 Contrast vérifié
- [ ] 4.3 Keyboard nav dropdowns
- [ ] 4.4 Focus trap modals

---

## 7. Fichiers Concernés

### Par ordre de priorité

| Fichier | Problèmes | Priorité |
|---------|-----------|----------|
| `lib/queries/global.ts` | any type (ligne 238) | HAUTE |
| `lib/queries/louis.ts` | any type (ligne 102) | HAUTE |
| `lib/hooks/useDashboardData.ts` | Query keys objects | HAUTE |
| `app/dashboard/layout.tsx` | No Error Boundary | HAUTE |
| `lib/utils.ts` | Fonctions à ajouter | MOYENNE |
| `components/dashboard/Cards/AgentTypeCard.tsx` | Code dupliqué | MOYENNE |
| `app/dashboard/agents/AgentDeploymentCard.tsx` | Code dupliqué | MOYENNE |
| `components/dashboard/Filters/ClientAgentFilter.tsx` | Duplication, ESLint | MOYENNE |
| `components/dashboard/ExportCSVButton.tsx` | alert() | MOYENNE |
| `app/dashboard/financial/FinancialDashboardClient.tsx` | Over-fetching | MOYENNE |
| `components/dashboard/Charts/CallVolumeChart.tsx` | No memo | MOYENNE |
| `components/dashboard/Charts/OutcomeBreakdownChart.tsx` | No memo | MOYENNE |
| `components/dashboard/Charts/EmotionDistributionChart.tsx` | No memo | MOYENNE |

### Nouveaux fichiers à créer

| Fichier | Description |
|---------|-------------|
| `components/dashboard/DashboardErrorFallback.tsx` | Error boundary fallback UI |
| `lib/utils/csv.ts` | CSV builder utility |
| `components/ui/EmptyState.tsx` | Composant empty state réutilisable |
| `lib/types/exports.ts` | Types pour exports (optionnel) |

---

## 8. Code Samples & Solutions

### 8.1 Type CallExportRow Complet

```typescript
// lib/types/dashboard.ts (à ajouter)

export interface CallExportRow {
  id: string
  started_at: string
  ended_at: string | null
  duration_seconds: number | null
  outcome: string | null
  answered: boolean
  appointment_scheduled: boolean
  emotion: string | null
  emotion_score: number | null
  transcript: string | null
  summary: string | null
  recording_url: string | null
  call_quality_score: number | null
  cost: number | null
  phone_number: string | null
  agent_deployments: {
    id: string
    name: string
    agent_types: {
      name: string
      display_name: string
    } | null
    clients: {
      id: string
      name: string
    } | null
  } | null
}
```

### 8.2 DashboardErrorFallback Complet

```typescript
// components/dashboard/DashboardErrorFallback.tsx

'use client'

import { AlertTriangle, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/Button'

interface DashboardErrorFallbackProps {
  error: Error
  resetErrorBoundary: () => void
}

export function DashboardErrorFallback({ 
  error, 
  resetErrorBoundary 
}: DashboardErrorFallbackProps) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] p-8">
      <div className="p-4 rounded-full bg-red-500/10 mb-6">
        <AlertTriangle className="w-12 h-12 text-red-500" />
      </div>
      
      <h2 className="text-xl font-bold text-white mb-2">
        Une erreur est survenue
      </h2>
      
      <p className="text-white/60 text-center max-w-md mb-2">
        Nous n'avons pas pu charger les données du dashboard.
      </p>
      
      {process.env.NODE_ENV === 'development' && (
        <pre className="text-xs text-red-400 bg-red-500/10 p-3 rounded-lg mb-4 max-w-lg overflow-auto">
          {error.message}
        </pre>
      )}
      
      <div className="flex gap-3">
        <Button 
          variant="outline" 
          onClick={() => window.location.reload()}
        >
          Rafraîchir la page
        </Button>
        <Button onClick={resetErrorBoundary}>
          <RefreshCw className="w-4 h-4 mr-2" />
          Réessayer
        </Button>
      </div>
    </div>
  )
}
```

### 8.3 CSV Builder Utility Complet

```typescript
// lib/utils/csv.ts

export interface CSVColumn<T> {
  header: string
  accessor: (row: T) => string | number | boolean | null | undefined
}

/**
 * Build a CSV string from data and column definitions
 */
export function buildCSV<T>(data: T[], columns: CSVColumn<T>[]): string {
  const headers = columns.map(c => escapeCSVValue(c.header))
  
  const rows = data.map(row => 
    columns.map(col => {
      const value = col.accessor(row)
      return escapeCSVValue(String(value ?? ''))
    })
  )
  
  return [headers, ...rows].map(row => row.join(',')).join('\n')
}

/**
 * Escape CSV value (handle commas, quotes, newlines)
 */
function escapeCSVValue(value: string): string {
  if (value.includes(',') || value.includes('"') || value.includes('\n')) {
    return `"${value.replace(/"/g, '""')}"`
  }
  return value
}

/**
 * Trigger CSV download in browser
 */
export function downloadCSV(csv: string, filename: string): void {
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}
```

### 8.4 Fonctions Utilitaires à Ajouter

```typescript
// lib/utils.ts (à ajouter aux fonctions existantes)

/**
 * Format relative time in French
 */
export function formatRelativeTime(date: string | Date): string {
  const now = new Date()
  const then = typeof date === 'string' ? new Date(date) : date
  const diffInSeconds = Math.floor((now.getTime() - then.getTime()) / 1000)
  
  if (diffInSeconds < 0) return 'Dans le futur'
  if (diffInSeconds < 60) return "À l'instant"
  if (diffInSeconds < 3600) {
    const mins = Math.floor(diffInSeconds / 60)
    return `Il y a ${mins} min`
  }
  if (diffInSeconds < 86400) {
    const hours = Math.floor(diffInSeconds / 3600)
    return `Il y a ${hours}h`
  }
  if (diffInSeconds < 604800) {
    const days = Math.floor(diffInSeconds / 86400)
    return `Il y a ${days}j`
  }
  
  return then.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'short',
    year: then.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
  })
}

/**
 * Deduplicate array by key
 */
export function deduplicateBy<T>(
  array: T[] | undefined | null, 
  keyFn: (item: T) => string | number
): T[] {
  if (!array) return []
  const seen = new Set<string | number>()
  return array.filter(item => {
    const key = keyFn(item)
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

/**
 * Serialize array for query key (stable string)
 */
export function serializeQueryKey(arr: string[] | undefined): string {
  if (!arr || arr.length === 0) return ''
  return [...arr].sort().join(',')
}
```

---

## Notes Finales

### Commandes de Vérification

```bash
# Build pour vérifier les types
npm run build

# Lint pour vérifier le code
npm run lint

# Tester le dashboard
npm run dev
# Naviguer vers http://localhost:3000/dashboard
```

### Critères de Succès

1. **Build sans erreur** - `npm run build` passe
2. **Lint sans warning** - `npm run lint` propre
3. **Pas de `any` types** dans les exports CSV
4. **Error boundaries fonctionnels** - Tester en coupant le réseau
5. **Performance améliorée** - Vérifier avec React DevTools Profiler
6. **UX améliorée** - Toast au lieu d'alert

### Estimation Totale

| Phase | Effort | Impact |
|-------|--------|--------|
| Phase 1 | 1-2h | Score +0.5 |
| Phase 2 | 2-4h | Score +1.0 |
| Phase 3 | 4-8h | Score +0.5 |
| Phase 4 | 2-4h | Score +0.5 |
| **Total** | **9-18h** | **Score 10/10** |

---

**Document créé le** : 26 Novembre 2025  
**Dernière mise à jour** : 26 Novembre 2025  
**Auteur** : Claude Code Assistant
