'use client'

import { useMemo } from 'react'
import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useLouisNestennKPIs,
  useLouisNestennChartData,
} from '@/lib/hooks/useDashboardData'
import { useLatencyMetrics } from '@/lib/hooks/useLatencyData'
import { exportLouisCallsToCSV } from '@/lib/queries/louis'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { LatencyTimeSeriesChart } from '@/components/dashboard/Charts/LatencyTimeSeriesChart'
import { FunnelChart } from '@/components/dashboard/Charts/FunnelChart'
import { DurationByOutcomeChart } from '@/components/dashboard/Charts/DurationByOutcomeChart'
import { NestennOutcomeChart } from '@/components/dashboard/Charts/NestennOutcomeChart'

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

interface LouisNestennDashboardClientProps {
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
  archived: 'Archive',
}

/**
 * Louis-Nestenn Dashboard Client Component
 * Specialized dashboard for Louis agents doing lead qualification (not RDV booking)
 *
 * Features:
 * - 6 KPIs: Total Appels, Taux Contact, Transferts Demandes, Taux Qualification, Rappels, SMS
 * - Funnel Chart: Total -> Contactes -> Decroches -> Qualifies
 * - Outcome Distribution: With Nestenn-specific labels
 * - Duration by Outcome: Shows correlation between call duration and success
 * - Emotion Distribution: Only for answered calls
 * - Latency Chart: Infrastructure performance
 */
export function LouisNestennDashboardClient({
  deployment,
  userEmail,
}: LouisNestennDashboardClientProps) {
  // URL-based filters with deployment pre-set
  const { filters, setDateRange } = useDashboardFilters()

  // Create filters with deployment locked
  const filtersWithDeployment = useMemo(() => ({
    ...filters,
    deploymentId: deployment.deployment_id,
    clientIds: [deployment.client_id],
    agentTypeName: deployment.agent_type_name,
  }), [filters, deployment])

  // Fetch Nestenn-specific metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useLouisNestennKPIs(filtersWithDeployment)
  const { data: chartData, isLoading: isLoadingCharts } = useLouisNestennChartData(filtersWithDeployment)

  // Fetch latency metrics
  const { data: latencyData, isLoading: isLoadingLatencies } = useLatencyMetrics({
    startDate: filters.startDate,
    endDate: filters.endDate,
    deploymentId: deployment.deployment_id,
    clientId: deployment.client_id,
    agentTypeName: deployment.agent_type_name,
  })

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

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
            <span className="px-2 py-0.5 rounded-full text-[10px] font-medium border border-emerald-500/30 bg-emerald-500/20 text-emerald-400">
              Qualification
            </span>
          </div>
          <span className="text-xs text-white/40">
            {deployment.agent_display_name} - Mode Nestenn
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
            filename={`${deployment.slug}-nestenn-export.csv`}
          />
        </div>

        {/* KPIs Grid - Nestenn specific (6 KPIs) */}
        <div className="flex-shrink-0">
          <KPIGrid
            data={kpiData}
            isLoading={isLoadingKPIs}
            agentType="louis-nestenn"
          />
        </div>

        {/* Charts Grid - 2x3 layout for Nestenn */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-1.5 flex-1 min-h-0 overflow-hidden">
          {/* Row 1: Funnel + Outcome Distribution */}
          <div className="h-full min-h-[180px] overflow-hidden">
            <FunnelChart data={chartData?.funnel_data} />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <NestennOutcomeChart data={chartData?.outcome_distribution} />
          </div>

          {/* Row 2: Call Volume + Duration by Outcome */}
          <div className="h-full min-h-[180px] overflow-hidden">
            <CallVolumeChart
              data={chartData?.call_volume_by_day || []}
            />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <DurationByOutcomeChart data={chartData?.duration_by_outcome} />
          </div>

          {/* Row 3: Emotion Distribution + Latency */}
          <div className="h-full min-h-[180px] overflow-hidden">
            <EmotionDistribution
              data={chartData?.emotion_distribution || []}
            />
          </div>
          <div className="h-full min-h-[180px] overflow-hidden">
            <LatencyTimeSeriesChart
              data={latencyData || []}
              isLoading={isLoadingLatencies}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
