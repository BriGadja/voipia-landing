'use client'

import { useMemo } from 'react'
import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useLouisKPIs,
  useLouisChartData,
} from '@/lib/hooks/useDashboardData'
import { useLatencyMetrics } from '@/lib/hooks/useLatencyData'
import { exportLouisCallsToCSV } from '@/lib/queries/louis'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { LatencyTimeSeriesChart } from '@/components/dashboard/Charts/LatencyTimeSeriesChart'
import { LouisNestennDashboardClient } from '@/components/dashboard/LouisNestennDashboardClient'

type AgentTypeName = 'louis' | 'arthur' | 'alexandra'

interface DeploymentInfo {
  deployment_id: string
  deployment_name: string
  slug: string
  client_id: string
  client_name: string
  agent_type_id: string
  agent_type_name: AgentTypeName
  agent_display_name: string
  deployment_status: 'active' | 'paused' | 'archived'
  custom_kpis: Record<string, unknown> | null
  custom_charts: Record<string, unknown> | null
}

interface DeploymentDashboardClientProps {
  deployment: DeploymentInfo
  userEmail?: string
}

// Status badge colors
const statusColors: Record<string, string> = {
  active: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  paused: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  archived: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
}

// Status display names
const statusLabels: Record<string, string> = {
  active: 'Actif',
  paused: 'En pause',
  archived: 'Archivé',
}

/**
 * Check if a deployment uses Louis-Nestenn mode (qualification, not RDV booking)
 * Detection methods:
 * 1. custom_kpis.mode === 'nestenn' or 'qualification'
 * 2. slug contains 'nestenn'
 */
function isNestennDeployment(deployment: DeploymentInfo): boolean {
  // Check custom_kpis mode
  if (deployment.custom_kpis) {
    const mode = (deployment.custom_kpis as Record<string, unknown>).mode
    if (mode === 'nestenn' || mode === 'qualification') {
      return true
    }
  }
  // Check slug pattern
  if (deployment.slug.toLowerCase().includes('nestenn')) {
    return true
  }
  return false
}

/**
 * Deployment Dashboard Client Component
 * Dashboard for a specific agent deployment instance
 * Uses the standard Louis dashboard layout (6 KPIs compact, 4 charts 2x2)
 *
 * Features:
 * - Displays base KPIs for the agent type
 * - Can be extended with custom KPIs from custom_kpis JSONB
 * - Can be extended with custom charts from custom_charts JSONB
 * - Supports Louis-Nestenn mode for qualification-focused deployments
 */
export function DeploymentDashboardClient({
  deployment,
  userEmail,
}: DeploymentDashboardClientProps) {
  // Check for Louis-Nestenn mode
  if (deployment.agent_type_name === 'louis' && isNestennDeployment(deployment)) {
    return <LouisNestennDashboardClient deployment={deployment} userEmail={userEmail} />
  }

  // URL-based filters with deployment pre-set
  const { filters, setDateRange } = useDashboardFilters()

  // Create filters with deployment locked
  const filtersWithDeployment = useMemo(() => ({
    ...filters,
    deploymentId: deployment.deployment_id,
    clientIds: [deployment.client_id],
    agentTypeName: deployment.agent_type_name,
  }), [filters, deployment])

  // Fetch metrics for this specific deployment
  const { data: kpiData, isLoading: isLoadingKPIs } = useLouisKPIs(filtersWithDeployment)
  const { data: chartData, isLoading: isLoadingCharts } =
    useLouisChartData(filtersWithDeployment)

  // Fetch latency metrics
  const { data: latencyData, isLoading: isLoadingLatencies } = useLatencyMetrics({
    startDate: filters.startDate,
    endDate: filters.endDate,
    deploymentId: deployment.deployment_id,
    clientId: deployment.client_id,
    agentTypeName: deployment.agent_type_name,
  })

  // Calculate average total latency for KPI
  const avgTotalLatency = latencyData && latencyData.length > 0
    ? Math.round(
        latencyData.reduce((sum, m) => sum + m.avg_total_latency_ms * m.call_count, 0) /
        latencyData.reduce((sum, m) => sum + m.call_count, 0)
      )
    : 0

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

  // Check for custom configurations
  const hasCustomKPIs = deployment.custom_kpis && Object.keys(deployment.custom_kpis).length > 0
  const hasCustomCharts = deployment.custom_charts && Object.keys(deployment.custom_charts).length > 0

  return (
    <div className="h-full p-1.5 overflow-hidden">
      <div className="flex flex-col gap-1.5 h-full">
        {/* Header with deployment info */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 flex-shrink-0">
          <div className="flex items-center gap-2">
            <h2 className="text-sm font-semibold text-white">
              {deployment.deployment_name}
            </h2>
            <span className="text-xs text-white/50">
              {deployment.client_name}
            </span>
            <span
              className={`px-2 py-0.5 rounded-full text-[10px] font-medium border ${
                statusColors[deployment.deployment_status]
              }`}
            >
              {statusLabels[deployment.deployment_status]}
            </span>
          </div>
          <span className="text-xs text-white/40">
            {deployment.agent_display_name}
            {hasCustomKPIs && ' • KPIs personnalisés'}
            {hasCustomCharts && ' • Graphiques personnalisés'}
          </span>
        </div>

        {/* Filters Row with Export */}
        <div className="flex flex-col lg:flex-row gap-1.5 items-start lg:items-center justify-between flex-shrink-0">
          <DateRangeFilter
            startDate={new Date(filters.startDate)}
            endDate={new Date(filters.endDate)}
            onChange={handleDateChange}
          />
          <ExportCSVButton
            filters={filtersWithDeployment}
            exportFn={exportLouisCallsToCSV}
            filename={`${deployment.slug}-export.csv`}
          />
        </div>

        {/* KPIs Grid */}
        <div className="flex-shrink-0">
          <KPIGrid
            data={kpiData}
            isLoading={isLoadingKPIs}
            agentType={deployment.agent_type_name}
            avgLatency={avgTotalLatency}
          />
        </div>

        {/* TODO: Custom KPIs from custom_kpis JSONB */}
        {/* This section can be extended to render dynamic KPIs based on custom_kpis */}

        {/* Charts Grid - 2x2 balanced layout */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-1.5 flex-1 min-h-0 overflow-hidden">
          <div className="h-full min-h-[180px] overflow-hidden">
            <CallVolumeChart
              data={chartData?.call_volume_by_day || []}
            />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <EmotionDistribution
              data={chartData?.emotion_distribution || []}
            />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <OutcomeBreakdown
              data={chartData?.outcome_distribution || []}
            />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <LatencyTimeSeriesChart
              data={latencyData || []}
              isLoading={isLoadingLatencies}
            />
          </div>
        </div>

        {/* TODO: Custom Charts from custom_charts JSONB */}
        {/* This section can be extended to render dynamic charts based on custom_charts */}
      </div>
    </div>
  )
}
