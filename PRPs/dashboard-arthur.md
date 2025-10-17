# PRP : Dashboard Arthur - Agent de Réactivation

**Version** : 1.0
**Date** : 2025-01-17
**Auteur** : Claude Code
**Basé sur** : INITIAL_dashboard_arthur.md (1063 lignes)
**Confidence Score** : 9/10

---

## 1. Purpose & Goal

### 1.1 Objectif Principal

Créer un dashboard analytics complet pour l'agent vocal Arthur, spécialisé dans la réactivation de prospects dormants. Le dashboard permettra de :

- **Suivre 5 KPIs critiques** : Taux de réactivation, Coût par conversion, Durée moyenne par tentative, RDV planifiés, Taux décroché 1ère tentative
- **Visualiser 4 graphiques dynamiques** : Volume d'appels par jour, Funnel de conversion, Distribution des outcomes, Performance par segment IA
- **Filtrer les données** : Par période (7j/30j/90j/custom) et par client/agent
- **Exporter les données** : CSV avec BOM Excel-compatible

### 1.2 Valeur Business

- **Visibilité temps réel** sur les performances des campagnes de réactivation
- **Optimisation ROI** via le suivi du coût par conversion
- **Amélioration stratégique** grâce aux données de performance par tentative
- **Prise de décision data-driven** pour les équipes commerciales

### 1.3 Différenciateurs vs Dashboard Louis

| Aspect | Dashboard Louis | Dashboard Arthur |
|--------|----------------|------------------|
| KPIs focus | Appels, Décroché, Durée, RDV, Conversion | Réactivation, Coût/Conv, Durée/Tentative, RDV, Décroché T1 |
| Charts | Volume, Émotions, Outcomes, Voicemail | Volume **dynamique multi-tentatives**, Funnel, Outcomes, Segments IA |
| Séquences | Appel unique | Multi-tentatives (3-7 selon client) |
| Tables | `agent_calls` | `agent_calls` + `agent_arthur_prospects` + `agent_arthur_prospect_sequences` |
| Dynamisme | Statique | **Graphiques adaptatifs selon `max_attempts`** |

### 1.4 Contraintes Techniques Critiques

⚠️ **IMPORTANT** : Ce dashboard doit gérer le **nombre dynamique de tentatives** par client :
- Client A peut avoir `max_attempts = 3`
- Client B peut avoir `max_attempts = 5`
- Client C peut avoir `max_attempts = 7`

❌ **INTERDIT** : Hard-coder "Tentative 1/2/3" dans les charts ou les catégories.
✅ **REQUIS** : Extraire dynamiquement les catégories depuis les données avec `useMemo`.

---

## 2. Context & References

### 2.1 Fichiers Existants à Réutiliser

```yaml
- file: app/dashboard/DashboardClient.tsx
  why: Structure générale du dashboard Louis (Server/Client Components, TanStack Query, Layout)
  pattern: Suivre la même architecture pour cohérence UX

- file: lib/queries/dashboard.ts
  why: Pattern de queries RPC Supabase pour KPIs et charts
  pattern: Adapter les fonctions avec nouveaux paramètres (p_agent_type_id au lieu de p_agent_id)

- file: components/dashboard/KPICard.tsx
  why: Composant KPI avec animations Framer Motion, comparaisons, couleurs dynamiques
  pattern: Réutiliser directement avec nouvelles props

- file: components/dashboard/Filters/DateRangeFilter.tsx
  why: Filtre de plage de dates avec presets (7j, 30j, 90j, custom)
  pattern: Réutiliser tel quel

- file: components/dashboard/Filters/ClientAgentFilter.tsx
  why: Filtre client/agent avec cascade et TanStack Query
  pattern: **ADAPTER** pour utiliser `agentTypeId` au lieu de `agentId`

- file: lib/types/database.ts
  why: Interfaces TypeScript existantes (KPIMetrics, ChartData, Client, Agent)
  pattern: Créer nouvelles interfaces Arthur dans lib/types/arthur.ts

- file: INITIAL_dashboard_arthur.md
  why: Spécifications complètes (1063 lignes) avec schéma BDD, KPIs, charts, interfaces TypeScript
  pattern: Document de référence PRINCIPAL pour toutes les décisions d'implémentation

- file: supabase/migrations/20250117_create_arthur_dashboard_views.sql
  why: 5 vues SQL déjà créées et validées ✅
  note: Migration appliquée avec succès, ne PAS régénérer

- file: supabase/migrations/20250117_create_arthur_dashboard_rpc_functions.sql
  why: 2 fonctions RPC déjà créées (get_arthur_kpi_metrics, get_arthur_chart_data) ✅
  note: Migration appliquée avec succès, ne PAS régénérer
```

### 2.2 Documentation Externe

- **Tremor Charts** : https://www.tremor.so/docs/visualizations/overview
  - AreaChart (stacked pour volume d'appels)
  - BarChart (horizontal pour funnel, vertical pour segments)
  - DonutChart (distribution outcomes)

- **TanStack Query v5** : https://tanstack.com/query/latest/docs/framework/react/overview
  - Configuration : `refetchInterval: 3600000` (1h), `staleTime: 3600000`
  - Query keys : `['arthur-kpi-metrics', startDate, endDate, clientId, agentTypeId]`

- **Supabase RPC** : https://supabase.com/docs/reference/javascript/rpc
  - Appel fonction : `supabase.rpc('get_arthur_kpi_metrics', { p_start_date, p_end_date, p_client_id, p_agent_type_id })`

- **Next.js App Router** : https://nextjs.org/docs/app
  - Server Component : `app/dashboard-arthur/page.tsx`
  - Client Component : `app/dashboard-arthur/DashboardArthurClient.tsx`

### 2.3 État Actuel des Données (2025-01-17)

```
Prospects Arthur : 87 (64 actifs, 22 perdus, 1 converti)
Séquences : 87 (63 actives, 22 échouées, 1 callback, 1 complétée)
Appels Arthur : 0 (prospects créés, mais aucun appel encore)
max_attempts : 3 pour tous les clients actuellement
IA Segmentation : Non utilisée (tous les ai_analysis->>'segment' sont NULL)
```

⚠️ **Implication** : Le dashboard affichera des valeurs à 0 initialement, mais toute l'architecture est prête pour recevoir les premières données.

---

## 3. Implementation Blueprint

### 3.1 Architecture de Fichiers

```
app/
└── dashboard-arthur/
    ├── page.tsx                    # ✅ À créer - Server Component wrapper
    └── DashboardArthurClient.tsx   # ✅ À créer - Client Component principal

components/
└── dashboard-arthur/
    └── Charts/
        ├── CallVolumeChart.tsx             # ✅ À créer
        ├── ConversionFunnelChart.tsx       # ✅ À créer
        ├── OutcomeBreakdownChart.tsx       # ✅ À créer
        └── SegmentPerformanceChart.tsx     # ✅ À créer

lib/
├── types/
│   └── arthur.ts                   # ✅ À créer - Interfaces TypeScript
└── queries/
    └── arthur.ts                   # ✅ À créer - Fonctions fetch RPC

(Existants - Réutiliser)
components/dashboard/
├── KPICard.tsx                     # ♻️ Réutiliser tel quel
└── Filters/
    ├── DateRangeFilter.tsx         # ♻️ Réutiliser tel quel
    └── ClientAgentFilter.tsx       # ⚠️ Potentiellement adapter pour agentTypeId
```

### 3.2 Phase 1 : Types TypeScript (lib/types/arthur.ts)

**Durée estimée** : 30 min

```typescript
// ============================================================================
// KPI Metrics - Retour de get_arthur_kpi_metrics()
// ============================================================================

export interface ArthurKPIPeriod {
  reactivation_rate: number           // % - (conversions / prospects) * 100
  cost_per_conversion: number         // € - coût total / conversions
  avg_duration_per_attempt: number    // seconds - moyenne durée appels
  appointments_scheduled: number      // count - nb RDV planifiés
  answer_rate_attempt_1: number       // % - taux décroché 1ère tentative
}

export interface ArthurKPIMetrics {
  current_period: ArthurKPIPeriod
  previous_period: ArthurKPIPeriod
}

// ============================================================================
// Chart Data Structures - Retour de get_arthur_chart_data()
// ============================================================================

export interface ArthurCallVolumeData {
  day: string            // ISO date YYYY-MM-DD - Ex: "2025-01-15"
  attempt_label: string  // Ex: "Tentative 1", "Tentative 2", ...
  count: number          // Nombre d'appels
}

export interface ArthurConversionFunnelData {
  attempt_label: string    // Ex: "Tentative 1"
  current_attempt: number  // Ex: 1
  total_calls: number
  answered_calls: number
  conversions: number
  conversion_rate: number  // % - (conversions / total_calls) * 100
}

export interface ArthurOutcomeDistributionData {
  outcome: string  // Catégorie française : "Converti", "Callback", "Pas intéressé", etc.
  count: number
}

export interface ArthurSegmentPerformanceData {
  segment: string              // Ex: "Chaud", "Froid", "Non segmenté"
  total_calls: number
  conversions: number
  conversion_rate: number      // % - (conversions / total_calls) * 100
}

export interface ArthurChartData {
  call_volume_by_day: ArthurCallVolumeData[]
  conversion_funnel: ArthurConversionFunnelData[]
  outcome_distribution: ArthurOutcomeDistributionData[]
  segment_performance: ArthurSegmentPerformanceData[]
}

// ============================================================================
// Enriched Call - Pour exports CSV (utilise v_arthur_calls_enriched)
// ============================================================================

export interface ArthurCallEnriched {
  // Call info
  call_id: string
  started_at: string
  ended_at: string
  duration_seconds: number
  cost: number
  answered: boolean                      // Dérivé : (outcome != 'voicemail')
  call_outcome: string                   // agent_calls.outcome
  appointment_scheduled_at: string | null // metadata->>'appointment_scheduled_at'
  call_recording_url: string | null
  transcript: string | null

  // Prospect info
  prospect_id: string
  first_name: string
  last_name: string
  email: string
  phone: string                          // agent_arthur_prospects.phone_number
  company: string                        // agent_arthur_prospects.company_name
  external_source: string                // Ex: 'pipedrive'
  external_deal_id: string
  prospect_status: string                // 'active', 'converted', 'lost', 'blacklisted'
  ai_analysis: Record<string, any>       // JSONB - {segment, score, reason}

  // Sequence info
  sequence_id: string
  sequence_number: number
  current_attempt: number
  max_attempts: number
  sequence_status: string                // 'active', 'completed', 'failed', etc.
  sequence_outcome: string | null
  next_action_at: string | null

  // Agent & Client info
  agent_deployment_id: string
  agent_type_id: string                  // ⚠️ agent_types.id (PAS agent_id)
  client_id: string
  agent_name: string                     // agent_types.display_name
  client_name: string

  // Derived fields
  derived_status: 'converted' | 'callback' | 'lost' | 'blacklisted' | 'in_progress'
  attempt_label: string                  // Ex: "Tentative 3"
  ai_segment: string | null              // ai_analysis->>'segment'
  ai_score: string | null
  ai_reason: string | null
}
```

**Validation** :
- Toutes les interfaces correspondent EXACTEMENT aux structures JSONB retournées par les RPC functions
- Les commentaires documentent les dérivations et les champs JSONB

### 3.3 Phase 2 : Queries RPC (lib/queries/arthur.ts)

**Durée estimée** : 1h

```typescript
import { createClient } from '@/lib/supabase/client'
import type { ArthurKPIMetrics, ArthurChartData, ArthurCallEnriched } from '@/lib/types/arthur'

/**
 * Fetch Arthur KPI metrics with current and previous period comparison
 *
 * @param startDate - Start of current period
 * @param endDate - End of current period
 * @param clientId - Optional client filter (UUID)
 * @param agentTypeId - Optional agent_type filter (UUID) ⚠️ NOT agentId
 * @returns Promise<ArthurKPIMetrics>
 */
export async function fetchArthurKPIMetrics(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<ArthurKPIMetrics> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_arthur_kpi_metrics', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_type_id: agentTypeId || null,  // ⚠️ CRITICAL: p_agent_type_id, NOT p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur KPI metrics:', error)
    throw error
  }

  return data as ArthurKPIMetrics
}

/**
 * Fetch Arthur chart data (4 datasets)
 *
 * @param startDate - Start date
 * @param endDate - End date
 * @param clientId - Optional client filter (UUID)
 * @param agentTypeId - Optional agent_type filter (UUID) ⚠️ NOT agentId
 * @returns Promise<ArthurChartData>
 */
export async function fetchArthurChartData(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<ArthurChartData> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_arthur_chart_data', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_type_id: agentTypeId || null,  // ⚠️ CRITICAL: p_agent_type_id, NOT p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur chart data:', error)
    throw error
  }

  return data as ArthurChartData
}

/**
 * Export Arthur calls to CSV with BOM for Excel compatibility
 *
 * @param startDate - Start date
 * @param endDate - End date
 * @param clientId - Optional client filter
 * @param agentTypeId - Optional agent_type filter
 * @returns Promise<string> CSV content with BOM
 */
export async function exportArthurCallsToCSV(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<string> {
  const supabase = createClient()

  let query = supabase
    .from('v_arthur_calls_enriched')
    .select('*')
    .gte('started_at', startDate.toISOString())
    .lte('started_at', endDate.toISOString())
    .order('started_at', { ascending: false })

  if (clientId) {
    query = query.eq('client_id', clientId)
  }

  if (agentTypeId) {
    query = query.eq('agent_type_id', agentTypeId)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching Arthur calls for export:', error)
    throw error
  }

  // Convert to CSV
  const headers = [
    'Date',
    'Client',
    'Prospect',
    'Entreprise',
    'Téléphone',
    'Email',
    'Tentative',
    'Durée (s)',
    'Coût (€)',
    'Outcome',
    'Statut Séquence',
    'RDV Planifié',
    'Segment IA',
  ]

  const rows = (data as ArthurCallEnriched[]).map((call) => [
    new Date(call.started_at).toLocaleString('fr-FR'),
    call.client_name || '',
    `${call.first_name} ${call.last_name}`,
    call.company || '',
    call.phone || '',
    call.email || '',
    call.attempt_label || '',
    call.duration_seconds || '',
    call.cost ? call.cost.toFixed(2) : '',
    call.call_outcome || '',
    call.sequence_status || '',
    call.appointment_scheduled_at
      ? new Date(call.appointment_scheduled_at).toLocaleString('fr-FR')
      : '',
    call.ai_segment || 'Non segmenté',
  ])

  const csv = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n')

  // Add BOM for Excel compatibility
  return '\ufeff' + csv
}
```

**Points d'attention** :
- ⚠️ **CRITICAL** : Utiliser `p_agent_type_id` et NON `p_agent_id` (erreur fréquente)
- Export CSV utilise la vue `v_arthur_calls_enriched` (déjà créée)
- BOM (`\ufeff`) requis pour compatibilité Excel avec caractères français

**Validation** :
```bash
# Tester avec TypeScript strict
npx tsc --noEmit
```

### 3.4 Phase 3 : Charts Components

#### 3.4.1 CallVolumeChart.tsx (components/dashboard-arthur/Charts/)

**Durée estimée** : 1h

**Spécifications** :
- Type : `AreaChart` stacked (Tremor)
- Axe X : Dates (format "Jan 15")
- Axe Y : Nombre d'appels
- Catégories : **DYNAMIQUES** - Extraites via `useMemo` depuis `attempt_label`
- Couleurs : Array de 7 couleurs, slicé selon nombre de tentatives
- Légende : Affichée en bas
- Grid : Lignes horizontales visibles

**Code complet** :

```typescript
'use client'

import { Card } from '@/components/ui/card'
import { AreaChart } from '@tremor/react'
import type { ArthurCallVolumeData } from '@/lib/types/arthur'
import { useMemo } from 'react'

interface CallVolumeChartProps {
  data: ArthurCallVolumeData[]
}

export function CallVolumeChart({ data }: CallVolumeChartProps) {
  // ⚠️ CRITICAL: Dynamic category extraction based on actual data
  const { chartData, categories } = useMemo(() => {
    // Transform data: group by day, create columns for each attempt
    const transformed = data.reduce((acc, item) => {
      const existingDay = acc.find(d => d.day === item.day)
      if (existingDay) {
        existingDay[item.attempt_label] = item.count
      } else {
        acc.push({
          day: new Date(item.day).toLocaleDateString('fr-FR', {
            month: 'short',
            day: 'numeric'
          }),
          [item.attempt_label]: item.count
        })
      }
      return acc
    }, [] as any[])

    // Dynamically extract all unique attempt labels
    // This ensures the chart adapts to max_attempts (3, 5, 7, etc.)
    const uniqueAttempts = Array.from(
      new Set(data.map(item => item.attempt_label))
    ).sort() // Sort to ensure "Tentative 1", "Tentative 2", "Tentative 3"...

    return {
      chartData: transformed,
      categories: uniqueAttempts
    }
  }, [data])

  // Dynamic colors: supports up to 7 attempts
  // Will be sliced to match actual number of attempts
  const colors = ["blue", "violet", "amber", "emerald", "rose", "cyan", "orange"]

  return (
    <Card className="p-4 bg-black/20 border-white/20 backdrop-blur-sm h-full flex flex-col">
      <h3 className="text-lg font-semibold text-white mb-4">
        Volume d'Appels par Jour
      </h3>
      <div className="flex-1 min-h-0">
        <AreaChart
          data={chartData}
          index="day"
          categories={categories}
          colors={colors.slice(0, categories.length)}
          valueFormatter={(value) => value.toString()}
          yAxisWidth={40}
          className="h-full"
          showLegend={true}
          showGridLines={true}
        />
      </div>
    </Card>
  )
}
```

**Validation** :
- Tester avec `max_attempts = 3` : Doit afficher 3 catégories (Tentative 1, 2, 3)
- Tester avec `max_attempts = 5` : Doit afficher 5 catégories automatiquement
- Vérifier que les couleurs s'adaptent (slice du tableau)

#### 3.4.2 ConversionFunnelChart.tsx

**Durée estimée** : 45 min

**Spécifications** :
- Type : `BarChart` horizontal (Tremor)
- Axe X : Taux de conversion (%)
- Axe Y : Tentatives (labels)
- Couleur : `emerald` (vert)
- Format : `${value}%`
- Ordre : Tentative 1 en haut, ordre croissant

```typescript
'use client'

import { Card } from '@/components/ui/card'
import { BarChart } from '@tremor/react'
import type { ArthurConversionFunnelData } from '@/lib/types/arthur'

interface ConversionFunnelChartProps {
  data: ArthurConversionFunnelData[]
}

export function ConversionFunnelChart({ data }: ConversionFunnelChartProps) {
  const chartData = data.map(item => ({
    attempt: item.attempt_label,
    'Taux de Conversion': item.conversion_rate,
    'Appels Totaux': item.total_calls
  }))

  return (
    <Card className="p-4 bg-black/20 border-white/20 backdrop-blur-sm h-full flex flex-col">
      <h3 className="text-lg font-semibold text-white mb-4">
        Funnel de Conversion par Tentative
      </h3>
      <div className="flex-1 min-h-0">
        <BarChart
          data={chartData}
          index="attempt"
          categories={["Taux de Conversion"]}
          colors={["emerald"]}
          valueFormatter={(value) => `${value}%`}
          yAxisWidth={50}
          className="h-full"
          layout="vertical"
          showLegend={false}
        />
      </div>
    </Card>
  )
}
```

#### 3.4.3 OutcomeBreakdownChart.tsx

**Durée estimée** : 30 min

**Spécifications** :
- Type : `DonutChart` (Tremor)
- Catégories : "Converti", "Callback", "Pas intéressé", "Ne pas rappeler", "Messagerie", "Autre"
- Couleurs : `["emerald", "blue", "amber", "red", "gray", "slate"]`
- Label : Pourcentage sur le donut
- Taille : `h-64` (hauteur fixe 256px)

```typescript
'use client'

import { Card } from '@/components/ui/card'
import { DonutChart } from '@tremor/react'
import type { ArthurOutcomeDistributionData } from '@/lib/types/arthur'

interface OutcomeBreakdownChartProps {
  data: ArthurOutcomeDistributionData[]
}

export function OutcomeBreakdownChart({ data }: OutcomeBreakdownChartProps) {
  const chartData = data.map(item => ({
    name: item.outcome,
    value: item.count
  }))

  return (
    <Card className="p-4 bg-black/20 border-white/20 backdrop-blur-sm h-full flex flex-col">
      <h3 className="text-lg font-semibold text-white mb-4">
        Distribution des Outcomes
      </h3>
      <div className="flex-1 min-h-0 flex items-center justify-center">
        <DonutChart
          data={chartData}
          category="value"
          index="name"
          colors={["emerald", "blue", "amber", "red", "gray", "slate"]}
          valueFormatter={(value) => value.toString()}
          className="h-64"
          showLabel={true}
        />
      </div>
    </Card>
  )
}
```

#### 3.4.4 SegmentPerformanceChart.tsx

**Durée estimée** : 30 min

**Spécifications** :
- Type : `BarChart` vertical (Tremor)
- Axe X : Segments ("Chaud", "Froid", "Non segmenté")
- Axe Y : Taux de conversion (%)
- Couleur : `violet`
- Format : `${value}%`
- Ordre : Décroissant par `conversion_rate`
- ⚠️ **Note** : Actuellement affichera "Non segmenté" uniquement (IA pas active)

```typescript
'use client'

import { Card } from '@/components/ui/card'
import { BarChart } from '@tremor/react'
import type { ArthurSegmentPerformanceData } from '@/lib/types/arthur'

interface SegmentPerformanceChartProps {
  data: ArthurSegmentPerformanceData[]
}

export function SegmentPerformanceChart({ data }: SegmentPerformanceChartProps) {
  const chartData = data.map(item => ({
    segment: item.segment,
    'Taux de Conversion': item.conversion_rate,
    'Conversions': item.conversions
  }))

  return (
    <Card className="p-4 bg-black/20 border-white/20 backdrop-blur-sm h-full flex flex-col">
      <h3 className="text-lg font-semibold text-white mb-4">
        Performance par Segment IA
      </h3>
      <div className="flex-1 min-h-0">
        <BarChart
          data={chartData}
          index="segment"
          categories={["Taux de Conversion"]}
          colors={["violet"]}
          valueFormatter={(value) => `${value}%`}
          yAxisWidth={100}
          className="h-full"
          showLegend={false}
        />
      </div>
    </Card>
  )
}
```

### 3.5 Phase 4 : Dashboard Client Component

**Fichier** : `app/dashboard-arthur/DashboardArthurClient.tsx`
**Durée estimée** : 2h

**Structure basée sur** : `app/dashboard/DashboardClient.tsx`

**Différences clés** :
1. Import queries Arthur : `fetchArthurKPIMetrics`, `fetchArthurChartData`, `exportArthurCallsToCSV`
2. Import 4 charts Arthur
3. Titre : "Dashboard Arthur - Réactivation"
4. Query keys : `['arthur-kpi-metrics', ...]`, `['arthur-chart-data', ...]`
5. **5 KPI Cards** (au lieu de 5) avec nouvelles métriques
6. **4 Charts** en layout 2x2

**Code complet** (pseudo-code annoté) :

```typescript
'use client'

import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { subDays } from 'date-fns'
import { Download, User, Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { fetchArthurKPIMetrics, fetchArthurChartData, exportArthurCallsToCSV } from '@/lib/queries/arthur'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPICard } from '@/components/dashboard/KPICard'
import { CallVolumeChart } from '@/components/dashboard-arthur/Charts/CallVolumeChart'
import { ConversionFunnelChart } from '@/components/dashboard-arthur/Charts/ConversionFunnelChart'
import { OutcomeBreakdownChart } from '@/components/dashboard-arthur/Charts/OutcomeBreakdownChart'
import { SegmentPerformanceChart } from '@/components/dashboard-arthur/Charts/SegmentPerformanceChart'
import { LogoutButton } from '@/components/auth/LogoutButton'

export function DashboardArthurClient() {
  const [userEmail, setUserEmail] = useState<string>('')
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()
  const router = useRouter()

  // Auth check (identique à Louis)
  useEffect(() => {
    const checkAuth = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        router.push('/login')
        return
      }
      setUserEmail(user.email || '')
      setIsLoading(false)
    }
    checkAuth()

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        router.push('/login')
      } else if (event === 'SIGNED_IN' && session?.user) {
        setUserEmail(session.user.email || '')
        setIsLoading(false)
      }
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [supabase, router])

  // Filters state
  const [startDate, setStartDate] = useState(subDays(new Date(), 30))
  const [endDate, setEndDate] = useState(new Date())
  const [selectedClientIds, setSelectedClientIds] = useState<string[]>([])
  const [selectedAgentIds, setSelectedAgentIds] = useState<string[]>([]) // ⚠️ Devient agentTypeIds en réalité
  const [isExporting, setIsExporting] = useState(false)

  // KPI Metrics Query
  const { data: kpiData, isLoading: isLoadingKPIs } = useQuery({
    queryKey: ['arthur-kpi-metrics', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchArthurKPIMetrics(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null  // ⚠️ Passé à p_agent_type_id
      ),
    refetchInterval: 3600000, // 1 hour
    staleTime: 3600000,
  })

  // Chart Data Query
  const { data: chartData, isLoading: isLoadingCharts } = useQuery({
    queryKey: ['arthur-chart-data', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchArthurChartData(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null  // ⚠️ Passé à p_agent_type_id
      ),
    refetchInterval: 3600000,
    staleTime: 3600000,
  })

  // Handlers (identiques à Louis)
  const handleDateChange = (start: Date, end: Date) => {
    setStartDate(start)
    setEndDate(end)
  }

  const handleFilterChange = (clientIds: string[], agentIds: string[]) => {
    setSelectedClientIds(clientIds)
    setSelectedAgentIds(agentIds)
  }

  const handleExport = async () => {
    try {
      setIsExporting(true)
      const csv = await exportArthurCallsToCSV(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      )

      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      link.download = `arthur-calls-export-${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('Error exporting data:', error)
      alert('Erreur lors de l\'export des données')
    } finally {
      setIsExporting(false)
    }
  }

  if (isLoading) {
    return (
      <main className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 text-white animate-spin mx-auto mb-4" />
          <p className="text-white/60">Vérification de l&apos;authentification...</p>
        </div>
      </main>
    )
  }

  return (
    <main className="h-screen p-3 max-w-[1600px] mx-auto flex flex-col overflow-hidden">
      {/* Header */}
      <div className="mb-3 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 flex-shrink-0">
        <div>
          <h1 className="text-2xl font-bold text-white mb-0.5">
            Dashboard Arthur - Réactivation
          </h1>
          <div className="flex items-center gap-2 text-white/60">
            <User className="w-3.5 h-3.5" />
            <p className="text-xs">
              Connecté en tant que <span className="text-white/80 font-medium">{userEmail}</span>
            </p>
          </div>
        </div>
        <LogoutButton />
      </div>

      {/* Filters */}
      <div className="mb-3 p-2.5 bg-black/20 border border-white/20 rounded-xl backdrop-blur-sm flex-shrink-0">
        <div className="flex flex-col lg:flex-row gap-2.5 items-start lg:items-center justify-between">
          <DateRangeFilter
            startDate={startDate}
            endDate={endDate}
            onChange={handleDateChange}
          />
          <ClientAgentFilter
            selectedClientIds={selectedClientIds}
            selectedAgentIds={selectedAgentIds}
            onChange={handleFilterChange}
          />
          <button
            onClick={handleExport}
            disabled={isExporting}
            className="flex items-center gap-2 px-3 py-1.5 text-sm bg-violet-600 hover:bg-violet-700 disabled:opacity-50 text-white rounded-lg transition-colors"
          >
            <Download className="w-4 h-4" />
            {isExporting ? 'Export...' : 'Export CSV'}
          </button>
        </div>
      </div>

      {/* KPI Cards - 5 cartes */}
      {isLoadingKPIs ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-3 flex-shrink-0">
          {[...Array(5)].map((_, i) => (
            <div
              key={i}
              className="h-24 bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : kpiData ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-3 flex-shrink-0">
          <KPICard
            label="Taux de Réactivation"
            value={kpiData.current_period.reactivation_rate}
            previousValue={kpiData.previous_period.reactivation_rate || undefined}
            format="percentage"
            decorationColor="emerald"
            delay={0}
          />
          <KPICard
            label="Coût par Conversion"
            value={kpiData.current_period.cost_per_conversion}
            previousValue={kpiData.previous_period.cost_per_conversion || undefined}
            format="currency"
            decorationColor="blue"
            delay={0.05}
          />
          <KPICard
            label="Durée Moy./Tentative"
            value={kpiData.current_period.avg_duration_per_attempt}
            previousValue={kpiData.previous_period.avg_duration_per_attempt || undefined}
            format="duration"
            decorationColor="amber"
            delay={0.1}
          />
          <KPICard
            label="RDV Planifiés"
            value={kpiData.current_period.appointments_scheduled}
            previousValue={kpiData.previous_period.appointments_scheduled || undefined}
            format="number"
            decorationColor="violet"
            delay={0.15}
          />
          <KPICard
            label="Taux Décroché T1"
            value={kpiData.current_period.answer_rate_attempt_1}
            previousValue={kpiData.previous_period.answer_rate_attempt_1 || undefined}
            format="percentage"
            decorationColor="blue"
            delay={0.2}
          />
        </div>
      ) : null}

      {/* Charts - 4 graphiques en 2x2 */}
      {isLoadingCharts ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
          {[...Array(4)].map((_, i) => (
            <div
              key={i}
              className="bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : chartData ? (
        <div className="flex-1 min-h-0 flex flex-col gap-3">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
            <CallVolumeChart data={chartData.call_volume_by_day || []} />
            <ConversionFunnelChart data={chartData.conversion_funnel || []} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
            <OutcomeBreakdownChart data={chartData.outcome_distribution || []} />
            <SegmentPerformanceChart data={chartData.segment_performance || []} />
          </div>
        </div>
      ) : null}
    </main>
  )
}
```

**Points d'attention** :
- Réutiliser `KPICard`, `DateRangeFilter`, `ClientAgentFilter`, `LogoutButton` existants
- Le `ClientAgentFilter` passe `agentIds` mais en réalité ce sont des `agentTypeIds` (adapt si nécessaire)
- Layout identique à Louis pour cohérence UX
- Bouton Export CSV ajouté dans la barre de filtres

### 3.6 Phase 5 : Server Component Page

**Fichier** : `app/dashboard-arthur/page.tsx`
**Durée estimée** : 15 min

```typescript
import { DashboardArthurClient } from './DashboardArthurClient'

export const metadata = {
  title: 'Dashboard Arthur - Réactivation | Voipia',
  description: 'Dashboard analytics pour l\'agent vocal Arthur spécialisé en réactivation de prospects',
}

export default function DashboardArthurPage() {
  return <DashboardArthurClient />
}
```

**Validation** :
- Vérifier que l'auth middleware protège `/dashboard-arthur` automatiquement
- Tester l'accès à `http://localhost:3000/dashboard-arthur`

---

## 4. Validation Loops

### 4.1 Build & Lint Validation

```bash
# 1. TypeScript compilation check
npx tsc --noEmit

# 2. ESLint code quality
npm run lint

# 3. Build verification
npm run build

# Expected: All commands should pass with 0 errors
```

### 4.2 Development Testing

```bash
# Start development server
npm run dev

# Navigate to http://localhost:3000/dashboard-arthur
```

### 4.3 Browser Testing (MCP Playwright)

**IMPORTANT** : Utiliser le serveur MCP Playwright pour vérifier visuellement.

```typescript
// Sequence de tests avec MCP Playwright
1. Navigate to http://localhost:3000/dashboard-arthur
2. Take snapshot - Verify auth redirect if not logged in
3. Login if needed
4. Navigate to http://localhost:3000/dashboard-arthur again
5. Take snapshot - Verify dashboard loaded with 5 KPIs and 4 charts
6. Resize browser to mobile (375x667)
7. Take snapshot - Verify responsive layout
8. Resize browser to tablet (768x1024)
9. Take snapshot - Verify responsive layout
10. Resize browser to desktop (1920x1080)
11. Take snapshot - Verify full layout
```

**Checklist visuel** :
- [ ] Header affiche "Dashboard Arthur - Réactivation" et email utilisateur
- [ ] Filtres de date avec presets fonctionnels
- [ ] 5 KPI Cards affichées avec couleurs correctes (emerald, blue, amber, violet, blue)
- [ ] Animations au chargement des KPIs (stagger delay)
- [ ] CallVolumeChart affiche aires empilées avec légende
- [ ] ConversionFunnelChart affiche barres horizontales
- [ ] OutcomeBreakdownChart affiche donut avec labels
- [ ] SegmentPerformanceChart affiche barres verticales
- [ ] Bouton Export CSV présent et cliquable
- [ ] Layout responsive sur mobile/tablet/desktop
- [ ] Aucune erreur console

### 4.4 Functional Testing

**Tests filtres** :
```bash
1. Changer date range à "7 derniers jours"
   - Vérifier que les queries se relancent
   - Vérifier que les données changent

2. Sélectionner un client spécifique
   - Vérifier que les KPIs se mettent à jour
   - Vérifier que les charts se mettent à jour

3. Cliquer sur Export CSV
   - Vérifier téléchargement du fichier
   - Ouvrir dans Excel : Vérifier encodage français (accents)
```

**Tests avec données mockées (si 0 appels)** :
```sql
-- Insérer des appels de test dans agent_calls pour Arthur
-- (À exécuter dans Supabase SQL Editor si besoin de tester visuellement)
```

### 4.5 Performance Check

```bash
# Check bundle size impact
npm run build
# Verify bundle size increase is reasonable (< 50KB pour les nouveaux composants)

# Check lighthouse score (optional)
# - Performance > 90
# - Accessibility > 95
# - Best Practices > 90
```

---

## 5. Anti-patterns to Avoid

### ❌ Anti-pattern 1 : Hard-coder le Nombre de Tentatives

```typescript
// ❌ WRONG - Hard-coded categories
const categories = ["Tentative 1", "Tentative 2", "Tentative 3"]

// ✅ CORRECT - Dynamic extraction
const categories = useMemo(() =>
  Array.from(new Set(data.map(item => item.attempt_label))).sort(),
  [data]
)
```

### ❌ Anti-pattern 2 : Utiliser p_agent_id au lieu de p_agent_type_id

```typescript
// ❌ WRONG
const { data, error } = await supabase.rpc('get_arthur_kpi_metrics', {
  p_agent_id: agentId  // Cette colonne n'existe pas
})

// ✅ CORRECT
const { data, error } = await supabase.rpc('get_arthur_kpi_metrics', {
  p_agent_type_id: agentTypeId
})
```

### ❌ Anti-pattern 3 : Assumer des Colonnes qui N'existent Pas

```sql
-- ❌ WRONG
SELECT ac.answered FROM agent_calls ac  -- Colonne n'existe pas

-- ✅ CORRECT
SELECT (ac.outcome != 'voicemail') AS answered FROM agent_calls ac
```

### ❌ Anti-pattern 4 : Créer de Nouveaux Fichiers Inutiles

```typescript
// ❌ WRONG - Créer un nouveau KPICard spécifique à Arthur
// components/dashboard-arthur/KPICardArthur.tsx

// ✅ CORRECT - Réutiliser le composant existant
import { KPICard } from '@/components/dashboard/KPICard'
```

### ❌ Anti-pattern 5 : Ignorer le BOM dans l'Export CSV

```typescript
// ❌ WRONG - Sans BOM
return csv

// ✅ CORRECT - Avec BOM pour Excel français
return '\ufeff' + csv
```

### ❌ Anti-pattern 6 : Ne Pas Tester la Responsivité

```bash
# ❌ WRONG - Tester uniquement sur desktop

# ✅ CORRECT - Tester sur 3 breakpoints
- Mobile: 375x667
- Tablet: 768x1024
- Desktop: 1920x1080
```

---

## 6. Success Criteria

### Critères Fonctionnels

- [ ] **Navigation** : `/dashboard-arthur` accessible après login
- [ ] **Auth** : Redirection `/login` si non authentifié
- [ ] **KPIs** : 5 cartes affichées avec données correctes
- [ ] **Charts** : 4 graphiques fonctionnels avec données RPC
- [ ] **Filtres** : Date et Client fonctionnels, queries réactives
- [ ] **Export** : CSV téléchargeable avec BOM, compatible Excel
- [ ] **Responsive** : Layout adapté mobile/tablet/desktop
- [ ] **Animations** : KPI Cards avec stagger delay, transitions fluides

### Critères Techniques

- [ ] **TypeScript** : Aucune erreur `npx tsc --noEmit`
- [ ] **Lint** : Aucune erreur `npm run lint`
- [ ] **Build** : Succès `npm run build`
- [ ] **Console** : Aucune erreur JavaScript en runtime
- [ ] **Performance** : Chargement < 2s, pas de lag filtres
- [ ] **Bundle** : Augmentation < 50KB pour nouveaux composants

### Critères de Qualité

- [ ] **Dynamisme** : Charts s'adaptent à `max_attempts` (3, 5, 7)
- [ ] **Cohérence** : UI identique au dashboard Louis
- [ ] **Accessibilité** : Labels ARIA, contraste couleurs
- [ ] **Documentation** : Commentaires dans le code pour points critiques

---

## 7. Deployment Checklist

### Avant Merge

- [ ] Tous les tests de validation passent
- [ ] Browser snapshots validés sur 3 breakpoints
- [ ] Code review (si applicable)
- [ ] Aucune donnée sensible hard-codée
- [ ] Migrations SQL déjà appliquées (✅ Fait)

### Après Merge

- [ ] Vérifier en staging/production
- [ ] Tester avec premiers appels Arthur réels
- [ ] Monitorer les performances Supabase (RPC functions)
- [ ] Vérifier les logs d'erreurs

---

## 8. Future Enhancements

### Phase 2 (Après premiers appels)

1. **Notifications** : Alertes si taux de réactivation < seuil
2. **Drill-down** : Clic sur KPI pour voir détails
3. **Comparaisons** : Multi-clients sur un même écran
4. **Temps réel** : WebSocket pour updates live

### Phase 3 (Après IA Segmentation active)

1. **Segment Performance** : Chart vraiment utilisé avec segments GPT-4
2. **Prédictions** : ML pour prédire meilleure heure d'appel
3. **A/B Testing** : Comparer performance scripts différents

---

## 9. Confidence Score: 9/10

**Raisons du score élevé** :
- ✅ Migrations SQL déjà validées et appliquées
- ✅ Document INITIAL très détaillé (1063 lignes)
- ✅ Composants existants (Louis) comme référence exacte
- ✅ Schéma BDD complet et vérifié
- ✅ Interfaces TypeScript complètes fournies
- ✅ Code charts fourni avec implémentation dynamique

**Raisons du -1 point** :
- ⚠️ Incertitude sur `ClientAgentFilter` : Peut nécessiter adaptation pour `agentTypeId` vs `agentId`
- ⚠️ Dashboard affichera valeurs à 0 initialement (pas d'appels Arthur encore)
- ⚠️ Besoin de tester avec données réelles après premiers appels

---

## 10. Execution Plan

### Ordre d'Implémentation Recommandé

```
1. lib/types/arthur.ts (30 min)
2. lib/queries/arthur.ts (1h)
3. Valider avec TypeScript strict (15 min)
4. components/dashboard-arthur/Charts/CallVolumeChart.tsx (1h)
5. components/dashboard-arthur/Charts/ConversionFunnelChart.tsx (45 min)
6. components/dashboard-arthur/Charts/OutcomeBreakdownChart.tsx (30 min)
7. components/dashboard-arthur/Charts/SegmentPerformanceChart.tsx (30 min)
8. app/dashboard-arthur/DashboardArthurClient.tsx (2h)
9. app/dashboard-arthur/page.tsx (15 min)
10. Tests Browser avec MCP Playwright (1h)
11. Tests filtres et export (30 min)
12. Validation finale et documentation (30 min)

Total estimé: 8h
```

### Dépendances Bloquantes

- ✅ Migrations SQL (déjà fait)
- ✅ Types de base (Agent, Client) déjà existants
- ⚠️ Besoin de Tremor Charts installé (vérifier package.json)
- ⚠️ Besoin de TanStack Query v5 (déjà utilisé par Louis)

---

**🎯 Ce PRP est prêt pour exécution avec `/execute-prp PRPs/dashboard-arthur.md`**
