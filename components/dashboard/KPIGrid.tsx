'use client'

import { KPICard } from './KPICard'
import type { KPIMetrics } from '@/lib/types/dashboard'

interface KPIGridProps {
  data: KPIMetrics | undefined
  isLoading: boolean
  agentType?: 'global' | 'louis' | 'arthur' | 'alexandra'
}

/**
 * KPI Grid Component
 * Displays a responsive grid of KPI cards with period comparison
 * Adapts KPI display based on agent type (global, louis, arthur)
 */
export function KPIGrid({ data, isLoading, agentType = 'global' }: KPIGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {Array.from({ length: 8 }).map((_, i) => (
          <div
            key={i}
            className="h-32 rounded-xl bg-white/5 border border-white/10 animate-pulse"
          />
        ))}
      </div>
    )
  }

  if (!data) {
    return (
      <div className="text-center text-white/60 py-12">
        Aucune donnée disponible pour la période sélectionnée
      </div>
    )
  }

  const { current_period, previous_period } = data

  // Louis Original Dashboard - 5 KPIs specifiques
  const louisOriginalKPIs = [
    {
      label: 'Total Appels',
      value: current_period.total_calls,
      previousValue: previous_period.total_calls,
      format: 'number' as const,
      decorationColor: 'blue' as const, // cyan #06b6d4
    },
    {
      label: 'Taux de Décroché',
      value: current_period.answer_rate,
      previousValue: previous_period.answer_rate,
      format: 'percentage' as const,
      decorationColor: 'teal' as const, // teal #14b8a6
    },
    {
      label: 'Durée Moyenne',
      value: current_period.avg_duration,
      previousValue: previous_period.avg_duration,
      format: 'duration' as const,
      decorationColor: 'amber' as const, // amber #f59e0b
    },
    {
      label: 'RDV Pris',
      value: current_period.appointments_scheduled,
      previousValue: previous_period.appointments_scheduled,
      format: 'number' as const,
      decorationColor: 'violet' as const, // violet #8b5cf6
    },
    {
      label: 'Taux de Conversion',
      value: current_period.conversion_rate,
      previousValue: previous_period.conversion_rate,
      format: 'percentage' as const,
      decorationColor: 'blue' as const, // cyan #06b6d4
    },
  ]

  // Core KPIs (all dashboards)
  const coreKPIs = [
    {
      label: 'Appels totaux',
      value: current_period.total_calls,
      previousValue: previous_period.total_calls,
      format: 'number' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: 'Appels répondus',
      value: current_period.answered_calls,
      previousValue: previous_period.answered_calls,
      format: 'number' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: 'Taux de réponse',
      value: current_period.answer_rate,
      previousValue: previous_period.answer_rate,
      format: 'percentage' as const,
      decorationColor: 'violet' as const,
    },
    {
      label: 'RDV planifiés',
      value: current_period.appointments_scheduled,
      previousValue: previous_period.appointments_scheduled,
      format: 'number' as const,
      decorationColor: 'amber' as const,
    },
    {
      label: 'Taux de conversion',
      value: current_period.conversion_rate,
      previousValue: previous_period.conversion_rate,
      format: 'percentage' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: 'Durée moyenne',
      value: current_period.avg_duration,
      previousValue: previous_period.avg_duration,
      format: 'duration' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: 'Coût total',
      value: current_period.total_cost,
      previousValue: previous_period.total_cost,
      format: 'currency' as const,
      decorationColor: 'red' as const,
    },
    {
      label: 'Coût par RDV',
      value: current_period.cost_per_appointment,
      previousValue: previous_period.cost_per_appointment,
      format: 'currency' as const,
      decorationColor: 'amber' as const,
    },
  ]

  // Louis-specific KPIs
  const louisKPIs = current_period.refused_appointments !== undefined ? [
    {
      label: 'RDV refusés',
      value: current_period.refused_appointments,
      previousValue: previous_period.refused_appointments,
      format: 'number' as const,
      decorationColor: 'red' as const,
    },
    {
      label: 'Taux d\'acceptation',
      value: current_period.acceptance_rate || 0,
      previousValue: previous_period.acceptance_rate,
      format: 'percentage' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: 'Rappels demandés',
      value: current_period.callbacks_requested || 0,
      previousValue: previous_period.callbacks_requested,
      format: 'number' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: 'Leads qualifiés',
      value: current_period.qualified_leads || 0,
      previousValue: previous_period.qualified_leads,
      format: 'number' as const,
      decorationColor: 'violet' as const,
    },
  ] : []

  // Arthur-specific KPIs
  const arthurKPIs = current_period.total_prospects !== undefined ? [
    {
      label: 'Prospects totaux',
      value: current_period.total_prospects,
      previousValue: previous_period.total_prospects,
      format: 'number' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: 'Séquences actives',
      value: current_period.active_sequences || 0,
      previousValue: previous_period.active_sequences,
      format: 'number' as const,
      decorationColor: 'violet' as const,
    },
    {
      label: 'Taux de réactivation',
      value: current_period.reactivation_rate || 0,
      previousValue: previous_period.reactivation_rate,
      format: 'percentage' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: 'Tentatives moyennes',
      value: current_period.avg_attempts || 0,
      previousValue: previous_period.avg_attempts,
      format: 'number' as const,
      decorationColor: 'amber' as const,
    },
    {
      label: 'Coût par conversion',
      value: current_period.cost_per_conversion || 0,
      previousValue: previous_period.cost_per_conversion,
      format: 'currency' as const,
      decorationColor: 'red' as const,
    },
  ] : []

  // Global-specific KPIs
  const globalKPIs = current_period.active_agents !== undefined ? [
    {
      label: 'Agents actifs',
      value: current_period.active_agents,
      previousValue: previous_period.active_agents,
      format: 'number' as const,
      decorationColor: 'violet' as const,
    },
    {
      label: 'Agents appelés aujourd\'hui',
      value: current_period.agents_called_today || 0,
      previousValue: previous_period.agents_called_today,
      format: 'number' as const,
      decorationColor: 'blue' as const,
    },
  ] : []

  // Combine KPIs based on agent type
  const allKPIs = agentType === 'louis'
    ? louisOriginalKPIs  // Use simplified 5 KPIs for Louis
    : [
        ...coreKPIs,
        ...(agentType === 'arthur' ? arthurKPIs : []),
        ...(agentType === 'global' ? globalKPIs : []),
      ]

  // Grid columns: 5 for Louis (5 KPIs), 4 for others
  const gridCols = agentType === 'louis'
    ? 'grid-cols-1 md:grid-cols-3 lg:grid-cols-5'
    : 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4'

  return (
    <div className={`grid ${gridCols} gap-6`}>
      {allKPIs.map((kpi, index) => (
        <KPICard
          key={kpi.label}
          label={kpi.label}
          value={kpi.value}
          previousValue={kpi.previousValue}
          format={kpi.format}
          decorationColor={kpi.decorationColor}
          delay={index * 0.05}
        />
      ))}
    </div>
  )
}
