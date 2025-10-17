# Dashboard Arthur - Spécifications Initiales
## Document de Référence pour Génération PRP

**Version** : 2.0
**Date** : 2025-01-17
**Auteur** : Claude Code
**Basé sur** : Analyse approfondie de la base de données et dashboard Louis existant

---

## 1. Contexte Business

### 1.1 Rôle d'Arthur

Arthur est un **agent vocal IA de réactivation** pour les prospects dormants (leads froids/tièdes). Son objectif principal est de relancer des prospects inactifs issus de CRM (Pipedrive) pour générer des rendez-vous qualifiés et réactiver des opportunités commerciales abandonnées.

### 1.2 Différenciateurs vs Louis

| Aspect | Louis | Arthur |
|--------|-------|--------|
| **Type d'appels** | Qualification initiale | Réactivation prospects dormants |
| **Séquences** | Appel unique | Multi-tentatives (configurable par client) |
| **Source prospects** | Direct/API | Import CRM (Pipedrive) |
| **Tables données** | `agent_calls` uniquement | `agent_calls` + `agent_arthur_prospects` + `agent_arthur_prospect_sequences` |
| **IA enrichissement** | Non | GPT-4 analysis (futur) |
| **Gestion callbacks** | Non | Système sophistiqué de rappels planifiés |
| **KPIs focus** | Taux décroché, Durée moyenne | Taux réactivation, Coût par conversion, Performance tentatives |

### 1.3 Infrastructure Technique

- **Base de données** : Supabase PostgreSQL avec RLS
- **Orchestration** : 3 workflows n8n
  - Call planner (planification des appels)
  - Add new deal (ajout de prospects depuis Pipedrive)
  - Tools and call data (gestion des outcomes et callbacks)
- **Plateforme voix** : Dipler/Twilio
- **IA** : GPT-4 pour l'enrichissement futur des prospects (non implémenté actuellement)

### 1.4 État Actuel des Données (2025-01-17)

- **87 prospects** : 64 actifs, 22 perdus, 1 converti
- **87 séquences** : 63 actives, 22 échouées, 1 callback, 1 complétée
- **Configuration actuelle** : `max_attempts = 3` pour tous les clients
- **Appels Arthur** : Aucun appel dans `agent_calls` pour l'instant (prospects créés, séquences initialisées)
- **IA Segmentation** : Non utilisée actuellement (tous les `ai_analysis->>'segment'` sont NULL)

---

## 2. Architecture Base de Données

### 2.1 Tables Impliquées

#### Table Unifiée (Tous Agents)

**`agent_calls`** : Stocke TOUS les appels de TOUS les agents (Louis, Arthur, futurs agents)

Colonnes pertinentes :
- `id` (uuid)
- `deployment_id` (uuid) → Référence `agent_deployments.id`
- `prospect_id` (uuid, nullable) → Référence `agent_arthur_prospects.id` pour Arthur
- `sequence_id` (uuid, nullable) → Référence `agent_arthur_prospect_sequences.id`
- `first_name`, `last_name`, `email` (text)
- `phone_number` (text, NOT NULL)
- `started_at`, `ended_at` (timestamptz)
- `duration_seconds` (integer)
- `outcome` (text) → Valeurs : `voicemail`, `appointment_scheduled`, `appointment_refused`, `too_short`, etc.
- `emotion` (text, nullable)
- `cost` (numeric)
- `transcript`, `transcript_summary` (text)
- `recording_url` (text)
- `metadata` (jsonb) → Contient `appointment_scheduled_at`, `migrated_from`, etc.

**⚠️ IMPORTANT** :
- Pas de colonne `answered` → Dérivé avec `(outcome != 'voicemail')`
- Pas de colonne `call_outcome` → Utiliser `outcome`
- Pas de colonne `appointment_scheduled_at` → Extraire de `metadata->>

'appointment_scheduled_at'`

#### Tables Spécifiques à Arthur

**`agent_arthur_prospects`** : Informations sur les prospects Arthur

Colonnes :
- `id` (uuid)
- `deployment_id` (uuid) → Référence `agent_deployments.id`
- `first_name`, `last_name` (text)
- `email` (text)
- `phone_number` (text, NOT NULL) ⚠️ Pas `phone`
- `company_name` (text) ⚠️ Pas `company`
- `external_source` (text, default: 'pipedrive')
- `external_deal_id` (text, NOT NULL)
- `external_user_id` (text)
- `client_slug` (text, NOT NULL)
- `status` (text, default: 'active') → Valeurs : `active`, `converted`, `lost`, `blacklisted`
- `lost_reason` (text)
- `converted_at` (timestamptz)
- `ai_analysis` (jsonb) → Structure future : `{segment, score, reason}` (actuellement vide)
- `metadata` (jsonb)
- `created_at`, `updated_at` (timestamptz)

**`agent_arthur_prospect_sequences`** : Gestion des séquences multi-tentatives

Colonnes :
- `id` (uuid)
- `prospect_id` (uuid) → Référence `agent_arthur_prospects.id`
- `deployment_id` (uuid)
- `sequence_number` (integer, default: 1)
- `max_attempts` (integer, default: 3) ⚠️ **Configurable par client**
- `current_attempt` (integer, default: 0)
- `status` (text, default: 'active') → Valeurs : `active`, `completed`, `failed`, `callback`, `paused`
- `outcome` (text)
- `next_action_at` (timestamptz)
- `started_at`, `completed_at`, `paused_at` (timestamptz)
- `metadata` (jsonb)
- `created_at`, `updated_at` (timestamptz)

#### Tables de Référence

**`agent_deployments`** : Lie un `agent_type` à un `client`

Colonnes :
- `id` (uuid)
- `client_id` (uuid) → Référence `clients.id`
- `agent_type_id` (uuid) → Référence `agent_types.id` ⚠️ **Pas `agent_id`**
- `name`, `slug` (text)
- `custom_kpis`, `custom_charts`, `settings` (jsonb)
- `status` (text)
- `deployed_at`, `created_at`, `updated_at` (timestamptz)

**`agent_types`** : Définition des types d'agents (Louis, Arthur, etc.)

Colonnes :
- `id` (uuid)
- `name` (text, NOT NULL) → Ex: 'louis', 'arthur'
- `display_name` (text) → Ex: 'Louis', 'Arthur'
- `description`, `icon_url` (text)
- `default_kpis`, `default_charts` (jsonb)
- `status` (text)
- `version` (integer)
- `created_at`, `updated_at` (timestamptz)

**`clients`** : Informations clients

Colonnes :
- `id` (uuid)
- `name` (text)
- `industry`, `webhook_url` (text)
- `created_at`, `updated_at` (timestamptz)

### 2.2 Relations Clés

```
agent_types (name = 'arthur')
    ↓
agent_deployments (agent_type_id, client_id)
    ↓
agent_calls (deployment_id, prospect_id, sequence_id)
    ↓
agent_arthur_prospects (id, status, ai_analysis)
    ↓
agent_arthur_prospect_sequences (prospect_id, current_attempt, max_attempts)
```

### 2.3 Vues SQL Créées

Les migrations suivantes ont été appliquées avec succès :

1. **`v_arthur_kpis_dashboard`** : Agrège les KPIs période actuelle vs précédente (30j)
2. **`v_arthur_calls_enriched`** : Jointure complète de toutes les tables pour requêtes riches
3. **`v_arthur_funnel_conversion`** : Taux de conversion par tentative (dynamique selon max_attempts)
4. **`v_arthur_sequences_actives`** : Séquences actives avec urgence et prochaine action
5. **`v_arthur_outcome_analysis`** : Distribution des outcomes pour donut chart

### 2.4 Fonctions RPC Créées

1. **`get_arthur_kpi_metrics(p_start_date, p_end_date, p_client_id, p_agent_type_id)`**
   - Retourne : `jsonb` avec `current_period` et `previous_period`
   - Filtres : Date range + client + agent_type

2. **`get_arthur_chart_data(p_start_date, p_end_date, p_client_id, p_agent_type_id)`**
   - Retourne : `jsonb` avec 4 datasets :
     - `call_volume_by_day`
     - `conversion_funnel`
     - `outcome_distribution`
     - `segment_performance`

⚠️ **Paramètre critique** : `p_agent_type_id` (UUID) - PAS `p_agent_id`

---

## 3. Structure du Dashboard

### 3.1 Layout Global

Le dashboard Arthur suit la **même structure** que Louis pour la cohérence UX :

```
┌─────────────────────────────────────────────────────────────────┐
│ Header                                                          │
│ ├─ Titre : "Dashboard Arthur - Réactivation"                   │
│ ├─ User Info : Email utilisateur connecté                      │
│ └─ Logout Button                                               │
├─────────────────────────────────────────────────────────────────┤
│ Filters                                                         │
│ ├─ DateRangeFilter (7j, 30j, 90j, custom)                      │
│ └─ ClientAgentFilter (Multi-select)                            │
├─────────────────────────────────────────────────────────────────┤
│ KPI Cards (Grid 1x5 sur desktop, stacked sur mobile)           │
│ ├─ Taux de Réactivation (emerald)                              │
│ ├─ Coût par Conversion (blue)                                  │
│ ├─ Durée Moyenne/Tentative (amber)                             │
│ ├─ RDV Planifiés (violet)                                      │
│ └─ Taux Décroché Tentative 1 (blue)                            │
├─────────────────────────────────────────────────────────────────┤
│ Charts Row 1 (Grid 2 colonnes)                                 │
│ ├─ CallVolumeChart (gauche)                                    │
│ └─ ConversionFunnelChart (droite)                              │
├─────────────────────────────────────────────────────────────────┤
│ Charts Row 2 (Grid 2 colonnes)                                 │
│ ├─ OutcomeBreakdownChart (gauche)                              │
│ └─ SegmentPerformanceChart (droite)                            │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 KPI Cards Détaillés

#### KPI 1 : Taux de Réactivation
- **Formule** : `(prospects convertis / prospects contactés) × 100`
- **Format** : Pourcentage (ex: "15.2%")
- **Couleur** : `emerald` (vert)
- **Source RPC** : `current_period.reactivation_rate`
- **Comparaison** : `previous_period.reactivation_rate`
- **Description** : Mesure le succès de réactivation des prospects dormants

#### KPI 2 : Coût par Conversion
- **Formule** : `coût total / nombre de conversions`
- **Format** : Euro avec 2 décimales (ex: "45.80 €")
- **Couleur** : `blue` (bleu)
- **Source RPC** : `current_period.cost_per_conversion`
- **Comparaison** : `previous_period.cost_per_conversion`
- **Description** : ROI de la campagne de réactivation

#### KPI 3 : Durée Moyenne par Tentative
- **Formule** : `somme(durées) / nombre d'appels`
- **Format** : Durée en secondes (ex: "87s") ou minutes si > 60s
- **Couleur** : `amber` (orange/ambre)
- **Source RPC** : `current_period.avg_duration_per_attempt`
- **Comparaison** : `previous_period.avg_duration_per_attempt`
- **Description** : Temps moyen d'engagement par tentative

#### KPI 4 : RDV Planifiés
- **Formule** : `COUNT(DISTINCT calls avec appointment_scheduled_at)`
- **Format** : Nombre entier (ex: "23")
- **Couleur** : `violet` (violet)
- **Source RPC** : `current_period.appointments_scheduled`
- **Comparaison** : `previous_period.appointments_scheduled`
- **Description** : Nombre total de rendez-vous obtenus

#### KPI 5 : Taux Décroché Tentative 1
- **Formule** : `(appels décrochés T1 / total appels T1) × 100`
- **Format** : Pourcentage (ex: "42.5%")
- **Couleur** : `blue` (bleu)
- **Source RPC** : `current_period.answer_rate_attempt_1`
- **Comparaison** : `previous_period.answer_rate_attempt_1`
- **Description** : Efficacité de la première prise de contact

### 3.3 Charts Détaillés

#### Chart 1 : Volume d'Appels par Jour (CallVolumeChart)

- **Type** : `AreaChart` stacked (Tremor)
- **Données** : `call_volume_by_day[]`
  ```typescript
  {
    day: string        // Ex: "2025-01-15"
    attempt_label: string  // Ex: "Tentative 1", "Tentative 2", ...
    count: number
  }
  ```
- **Axe X** : Date (format "Jan 15")
- **Axe Y** : Nombre d'appels
- **Catégories** : **DYNAMIQUES** - Extraites automatiquement de `attempt_label` via `useMemo`
  - Si `max_attempts = 3` → ["Tentative 1", "Tentative 2", "Tentative 3"]
  - Si `max_attempts = 5` → ["Tentative 1", "Tentative 2", "Tentative 3", "Tentative 4", "Tentative 5"]
- **Couleurs** : Array dynamique `["blue", "violet", "amber", "emerald", "rose", "cyan", "orange"]`
  - Utiliser `.slice(0, categories.length)` pour adapter au nombre de tentatives
- **Légende** : Affichée en bas
- **Grid** : Lignes horizontales affichées

**Implémentation React** :
```typescript
const { chartData, categories } = useMemo(() => {
  // Transform data to group by day with dynamic attempt columns
  const transformed = data.reduce((acc, item) => {
    const existingDay = acc.find(d => d.day === item.day)
    if (existingDay) {
      existingDay[item.attempt_label] = item.count
    } else {
      acc.push({
        day: new Date(item.day).toLocaleDateString('fr-FR', { month: 'short', day: 'numeric' }),
        [item.attempt_label]: item.count
      })
    }
    return acc
  }, [] as any[])

  // Dynamically extract unique attempt labels
  const uniqueAttempts = Array.from(
    new Set(data.map(item => item.attempt_label))
  ).sort() // Sort to ensure Tentative 1, 2, 3...

  return { chartData: transformed, categories: uniqueAttempts }
}, [data])
```

#### Chart 2 : Funnel de Conversion par Tentative (ConversionFunnelChart)

- **Type** : `BarChart` horizontal (Tremor)
- **Données** : `conversion_funnel[]`
  ```typescript
  {
    attempt_label: string    // Ex: "Tentative 1"
    current_attempt: number  // Ex: 1
    total_calls: number
    answered_calls: number
    conversions: number
    conversion_rate: number  // %
  }
  ```
- **Axe X** : Taux de conversion (%)
- **Axe Y** : Tentatives (labels)
- **Catégorie** : "Taux de Conversion"
- **Couleur** : `emerald` (vert)
- **Format** : `${value}%`
- **Ordre** : Trié par `current_attempt` ASC (Tentative 1 en haut)
- **Nombre de barres** : **DYNAMIQUE** selon `max_attempts` du client

#### Chart 3 : Distribution des Outcomes (OutcomeBreakdownChart)

- **Type** : `DonutChart` (Tremor)
- **Données** : `outcome_distribution[]`
  ```typescript
  {
    outcome: string  // Catégorie française
    count: number
  }
  ```
- **Catégories d'outcomes** (mappées depuis `agent_calls.outcome`) :
  - **"Converti"** : `outcome = 'appointment_scheduled'` OU `metadata->>'appointment_scheduled_at' IS NOT NULL`
  - **"Callback"** : `outcome = 'callback_requested'`
  - **"Pas intéressé"** : `outcome IN ('not_interested', 'appointment_refused')`
  - **"Ne pas rappeler"** : `outcome = 'do_not_call'`
  - **"Messagerie"** : `outcome = 'voicemail'` OU `(outcome != 'voicemail') = false`
  - **"Autre"** : Tous les autres cas
- **Couleurs** : `["emerald", "blue", "amber", "red", "gray"]`
- **Label** : Pourcentage affiché sur le donut
- **Taille** : `h-64` (hauteur fixe 256px)

#### Chart 4 : Performance par Segment IA (SegmentPerformanceChart)

- **Type** : `BarChart` vertical (Tremor)
- **Données** : `segment_performance[]`
  ```typescript
  {
    segment: string          // Ex: "Chaud", "Froid", "Non segmenté"
    total_calls: number
    conversions: number
    conversion_rate: number  // %
  }
  ```
- **Axe X** : Segments
- **Axe Y** : Taux de conversion (%)
- **Catégorie** : "Taux de Conversion"
- **Couleur** : `violet` (violet)
- **Format** : `${value}%`
- **Ordre** : Trié par `conversion_rate DESC` (meilleurs segments en premier)
- **Fallback** : Afficher "Non segmenté" si `ai_analysis->>'segment'` est NULL

⚠️ **NOTE IMPORTANTE** : La segmentation IA n'est pas encore implémentée. Actuellement, tous les prospects ont `ai_segment = NULL`. Le chart affichera une seule barre "Non segmenté" jusqu'à activation de la fonctionnalité GPT-4.

---

## 4. Implémentation Frontend

### 4.1 Structure des Fichiers

```
app/
└── dashboard-arthur/
    ├── page.tsx                    # Server Component wrapper
    └── DashboardArthurClient.tsx   # Client Component principal

components/
└── dashboard-arthur/
    └── Charts/
        ├── CallVolumeChart.tsx
        ├── ConversionFunnelChart.tsx
        ├── OutcomeBreakdownChart.tsx
        └── SegmentPerformanceChart.tsx

lib/
├── types/
│   └── arthur.ts                   # Interfaces TypeScript
└── queries/
    └── arthur.ts                   # Fonctions fetch RPC
```

### 4.2 Interfaces TypeScript

**Fichier** : `lib/types/arthur.ts`

```typescript
// ============================================================================
// KPI Metrics
// ============================================================================

export interface ArthurKPIPeriod {
  reactivation_rate: number           // %
  cost_per_conversion: number         // €
  avg_duration_per_attempt: number    // seconds
  appointments_scheduled: number      // count
  answer_rate_attempt_1: number       // %
}

export interface ArthurKPIMetrics {
  current_period: ArthurKPIPeriod
  previous_period: ArthurKPIPeriod
}

// ============================================================================
// Chart Data Structures
// ============================================================================

export interface ArthurCallVolumeData {
  day: string            // ISO date YYYY-MM-DD
  attempt_label: string  // "Tentative 1", "Tentative 2", ...
  count: number
}

export interface ArthurConversionFunnelData {
  attempt_label: string
  current_attempt: number
  total_calls: number
  answered_calls: number
  conversions: number
  conversion_rate: number  // %
}

export interface ArthurOutcomeDistributionData {
  outcome: string  // "Converti", "Callback", "Pas intéressé", etc.
  count: number
}

export interface ArthurSegmentPerformanceData {
  segment: string              // "Chaud", "Froid", "Non segmenté"
  total_calls: number
  conversions: number
  conversion_rate: number      // %
}

export interface ArthurChartData {
  call_volume_by_day: ArthurCallVolumeData[]
  conversion_funnel: ArthurConversionFunnelData[]
  outcome_distribution: ArthurOutcomeDistributionData[]
  segment_performance: ArthurSegmentPerformanceData[]
}

// ============================================================================
// Enriched Call (pour exports CSV ou détails)
// ============================================================================

export interface ArthurCallEnriched {
  // Call info
  call_id: string
  started_at: string
  ended_at: string
  duration_seconds: number
  cost: number
  answered: boolean
  call_outcome: string
  appointment_scheduled_at: string | null
  call_recording_url: string | null
  transcript: string | null

  // Prospect info
  prospect_id: string
  first_name: string
  last_name: string
  email: string
  phone: string
  company: string
  external_source: string
  external_deal_id: string
  prospect_status: string
  ai_analysis: Record<string, any>

  // Sequence info
  sequence_id: string
  sequence_number: number
  current_attempt: number
  max_attempts: number
  sequence_status: string
  sequence_outcome: string | null
  next_action_at: string | null

  // Agent & Client info
  agent_deployment_id: string
  agent_type_id: string
  client_id: string
  agent_name: string
  client_name: string

  // Derived fields
  derived_status: 'converted' | 'callback' | 'lost' | 'blacklisted' | 'in_progress'
  attempt_label: string
  ai_segment: string | null
  ai_score: string | null
  ai_reason: string | null
}
```

### 4.3 Queries RPC

**Fichier** : `lib/queries/arthur.ts`

```typescript
import { createClient } from '@/lib/supabase/client'
import type { ArthurKPIMetrics, ArthurChartData } from '@/lib/types/arthur'

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
    p_agent_type_id: agentTypeId || null,  // ⚠️ PAS p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur KPI metrics:', error)
    throw error
  }

  return data as ArthurKPIMetrics
}

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
    p_agent_type_id: agentTypeId || null,  // ⚠️ PAS p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur chart data:', error)
    throw error
  }

  return data as ArthurChartData
}

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

  const rows = data.map((call: any) => [
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

### 4.4 Client Component Principal

**Fichier** : `app/dashboard-arthur/DashboardArthurClient.tsx`

**Structure identique à** : `app/dashboard/DashboardClient.tsx`

**Adaptations clés** :
- Import `fetchArthurKPIMetrics`, `fetchArthurChartData` depuis `@/lib/queries/arthur`
- Import des 4 composants charts Arthur
- Titre : `"Dashboard Arthur - Réactivation"`
- Query keys : `['arthur-kpi-metrics', ...]` et `['arthur-chart-data', ...]`
- KPI Cards : 5 cartes avec les métriques Arthur et couleurs spécifiées
- Charts : 4 charts Arthur dans layout 2x2

**Points d'attention** :
- Utiliser `agentTypeId` au lieu de `agentId` pour les filtres
- Réutiliser `DateRangeFilter` et `ClientAgentFilter` existants (composants déjà créés pour Louis)
- Réutiliser `KPICard` existant avec nouvelles props
- Configuration TanStack Query : `refetchInterval: 3600000` (1 heure), `staleTime: 3600000`

### 4.5 Charts Components

#### CallVolumeChart.tsx

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
  const { chartData, categories } = useMemo(() => {
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
    const uniqueAttempts = Array.from(
      new Set(data.map(item => item.attempt_label))
    ).sort() // Ensures Tentative 1, 2, 3... order

    return {
      chartData: transformed,
      categories: uniqueAttempts
    }
  }, [data])

  // Dynamic colors (supports up to 7 attempts)
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

#### ConversionFunnelChart.tsx

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

#### OutcomeBreakdownChart.tsx

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
          colors={["emerald", "blue", "amber", "red", "gray"]}
          valueFormatter={(value) => value.toString()}
          className="h-64"
          showLabel={true}
        />
      </div>
    </Card>
  )
}
```

#### SegmentPerformanceChart.tsx

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

---

## 5. Validation et Tests

### 5.1 Tests SQL (Déjà Validés ✅)

Les migrations ont été appliquées avec succès. Requêtes de validation :

```sql
-- Test v_arthur_calls_enriched
SELECT COUNT(*) FROM v_arthur_calls_enriched;

-- Test RPC get_arthur_kpi_metrics
SELECT get_arthur_kpi_metrics(
  (CURRENT_DATE - INTERVAL '30 days')::timestamptz,
  CURRENT_DATE::timestamptz,
  NULL,
  NULL
);

-- Test RPC get_arthur_chart_data
SELECT get_arthur_chart_data(
  (CURRENT_DATE - INTERVAL '30 days')::timestamptz,
  CURRENT_DATE::timestamptz,
  NULL,
  NULL
);
```

**Résultat attendu** :
- `v_arthur_calls_enriched` : 0 lignes actuellement (aucun appel Arthur)
- RPC functions : JSONB avec structure correcte et valeurs à 0

### 5.2 Checklist Frontend

Une fois implémenté, valider :

- [ ] **Navigation** : Accès à `/dashboard-arthur` fonctionne
- [ ] **Auth** : Redirection vers `/login` si non authentifié
- [ ] **Header** : Email utilisateur affiché, bouton logout fonctionne
- [ ] **Filtres Date** : Presets 7j/30j/90j fonctionnent, custom date picker opérationnel
- [ ] **Filtres Client/Agent** : Multi-select fonctionne, cascade si nécessaire
- [ ] **KPI Cards** :
  - 5 cartes affichées
  - Animations au chargement
  - Comparaisons période précédente avec flèches ↑↓
  - Formats corrects (%, €, s)
- [ ] **CallVolumeChart** :
  - Catégories dynamiques extraites
  - Couleurs adaptées au nombre de tentatives
  - Légende affichée
  - Grid visible
- [ ] **ConversionFunnelChart** :
  - Barres horizontales
  - Ordre correct (Tentative 1 en haut)
  - Pourcentages affichés
- [ ] **OutcomeBreakdownChart** :
  - Donut affiché
  - 5+ catégories si données suffisantes
  - Labels avec pourcentages
- [ ] **SegmentPerformanceChart** :
  - Barres verticales
  - "Non segmenté" affiché si pas de segments
  - Ordre décroissant par performance
- [ ] **Export CSV** : Téléchargement fonctionne, BOM présent, format correct
- [ ] **Responsive** : Layout adapté mobile/tablette/desktop
- [ ] **Performance** : Chargement < 2s, pas de lag lors du changement de filtres
- [ ] **Console** : Aucune erreur JavaScript

### 5.3 Tests avec Données Réelles

**Actuellement** : Dashboard affichera des valeurs à 0 car aucun appel Arthur n'existe.

**Après premiers appels** :
- Vérifier que les données s'affichent correctement
- Valider les calculs de KPIs
- Tester les filtres avec plusieurs clients
- Vérifier le comportement avec `max_attempts > 3`

---

## 6. Points d'Attention Critiques

### ⚠️ Erreurs Courantes à Éviter

1. **Colonnes** :
   - ❌ `ac.answered` n'existe pas → ✅ Utiliser `(ac.outcome != 'voicemail')`
   - ❌ `ac.call_outcome` n'existe pas → ✅ Utiliser `ac.outcome`
   - ❌ `ac.appointment_scheduled_at` n'existe pas → ✅ Utiliser `(ac.metadata->>'appointment_scheduled_at')`
   - ❌ `aap.phone` n'existe pas → ✅ Utiliser `aap.phone_number`
   - ❌ `aap.company` n'existe pas → ✅ Utiliser `aap.company_name`

2. **Jointures** :
   - ❌ `agent_deployments.agent_id` n'existe pas → ✅ Utiliser `agent_deployments.agent_type_id`
   - ❌ Joindre `agents` depuis deployments → ✅ Joindre `agent_types`

3. **Filtres** :
   - ❌ Paramètre `p_agent_id` → ✅ Utiliser `p_agent_type_id`

4. **Dynamisme** :
   - Ne JAMAIS hard-coder le nombre de tentatives
   - Utiliser `useMemo` pour extraire les catégories dynamiques
   - Adapter les couleurs au nombre réel de tentatives

### 📊 État Actuel vs Futur

| Fonctionnalité | État Actuel (2025-01-17) | État Futur |
|----------------|-------------------------|------------|
| Prospects Arthur | 87 créés | Croissance continue |
| Appels Arthur | 0 appels | Appels quotidiens |
| Séquences | 87 initialisées | Évolution active |
| max_attempts | 3 (tous clients) | Variable par client (3-7) |
| IA Segmentation | Non utilisée (NULL) | Segmentation GPT-4 active |
| Dashboard Arthur | À créer | Opérationnel |

---

## 7. Étapes d'Implémentation

### Phase 1 : Types et Queries (2h)
1. Créer `lib/types/arthur.ts` avec toutes les interfaces
2. Créer `lib/queries/arthur.ts` avec les 3 fonctions
3. Valider les types avec TypeScript strict

### Phase 2 : Charts Components (4h)
1. Créer `components/dashboard-arthur/Charts/CallVolumeChart.tsx`
2. Créer `components/dashboard-arthur/Charts/ConversionFunnelChart.tsx`
3. Créer `components/dashboard-arthur/Charts/OutcomeBreakdownChart.tsx`
4. Créer `components/dashboard-arthur/Charts/SegmentPerformanceChart.tsx`
5. Valider chaque chart avec données mockées

### Phase 3 : Dashboard Page (3h)
1. Créer `app/dashboard-arthur/page.tsx` (Server Component)
2. Créer `app/dashboard-arthur/DashboardArthurClient.tsx` (Client Component)
3. Intégrer TanStack Query avec refetch interval
4. Ajouter les 5 KPI Cards
5. Intégrer les 4 charts dans layout 2x2
6. Ajouter bouton export CSV

### Phase 4 : Navigation et Auth (1h)
1. Vérifier que l'auth middleware protège `/dashboard-arthur`
2. Ajouter un lien navigation vers Arthur (optionnel)
3. Tester redirection si non authentifié

### Phase 5 : Tests et Validation (2h)
1. Tests manuels de tous les composants
2. Validation responsive
3. Performance check
4. Console errors check
5. Tests avec filtres

**Durée totale estimée** : 12 heures de développement

---

## 8. Références

### Fichiers Existants à Réutiliser
- `app/dashboard/DashboardClient.tsx` - Structure générale
- `lib/queries/dashboard.ts` - Pattern de queries RPC
- `components/dashboard/Filters/DateRangeFilter.tsx` - Filtre dates
- `components/dashboard/Filters/ClientAgentFilter.tsx` - Filtre client/agent
- `components/dashboard/KPICard.tsx` - Carte KPI avec animations

### Documentation Externe
- Tremor Charts : https://www.tremor.so/docs/visualizations/overview
- TanStack Query v5 : https://tanstack.com/query/latest/docs/framework/react/overview
- Supabase RPC : https://supabase.com/docs/reference/javascript/rpc
- Next.js App Router : https://nextjs.org/docs/app

### Migrations SQL Appliquées
- `supabase/migrations/20250117_create_arthur_dashboard_views.sql` ✅
- `supabase/migrations/20250117_create_arthur_dashboard_rpc_functions.sql` ✅

---

## 9. Notes de Conclusion

### Différence clé avec Louis

Le dashboard Arthur se distingue par :
1. **Séquences multi-tentatives** : Charts dynamiques adaptés à `max_attempts` variable
2. **Focus réactivation** : KPIs orientés conversion et coût d'acquisition
3. **Segmentation IA** : Chart de performance par segment (futur)
4. **3 tables** : Architecture plus complexe avec prospects et séquences

### Prochaines Étapes

1. ✅ Migrations SQL appliquées
2. ⏭️ Générer le PRP avec `/generate-prp` en référençant ce document
3. ⏭️ Exécuter le PRP avec `/execute-prp` pour créer tous les composants
4. ⏭️ Tester le dashboard avec données mockées
5. ⏭️ Valider avec premiers appels Arthur réels

**Ce document est maintenant prêt pour la génération du PRP.**
