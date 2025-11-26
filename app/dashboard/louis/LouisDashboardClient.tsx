'use client'

import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useLouisKPIs,
  useLouisChartData,
} from '@/lib/hooks/useDashboardData'
import { useLatencyMetrics } from '@/lib/hooks/useLatencyData'
import { exportLouisCallsToCSV } from '@/lib/queries/louis'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { LatencyTimeSeriesChart } from '@/components/dashboard/Charts/LatencyTimeSeriesChart'

interface LouisDashboardClientProps {
  userEmail?: string
}

/**
 * Louis Dashboard Client Component
 * Specialized dashboard for Louis (setter/appointment booking) agents
 * Displays Louis-specific KPIs and metrics
 */
export function LouisDashboardClient({ userEmail }: LouisDashboardClientProps) {
  // URL-based filters
  const { filters, setClientIds, setDeploymentId, setDateRange } =
    useDashboardFilters()

  // Fetch Louis metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useLouisKPIs(filters)
  const { data: chartData, isLoading: isLoadingCharts } =
    useLouisChartData(filters)

  // Fetch latency metrics
  const { data: latencyData, isLoading: isLoadingLatencies } = useLatencyMetrics({
    startDate: filters.startDate,
    endDate: filters.endDate,
    deploymentId: filters.deploymentId,
    clientId: filters.clientIds.length === 1 ? filters.clientIds[0] : null,
    agentTypeName: 'louis',
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

  const handleFilterChange = (clientIds: string[], agentIds: string[]) => {
    setClientIds(clientIds)
    setDeploymentId(agentIds.length === 1 ? agentIds[0] : null)
  }

  return (
    <div className="p-4 space-y-4">
      {/* Filters Row with Export */}
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center">
          <DateRangeFilter
            startDate={new Date(filters.startDate)}
            endDate={new Date(filters.endDate)}
            onChange={handleDateChange}
          />
          <ClientAgentFilter
            selectedClientIds={filters.clientIds}
            selectedAgentIds={filters.deploymentId ? [filters.deploymentId] : []}
            onChange={handleFilterChange}
            agentType="louis"
          />
        </div>
        <ExportCSVButton
          filters={filters}
          exportFn={exportLouisCallsToCSV}
          filename="louis-dashboard-export.csv"
        />
      </div>

      {/* KPIs Grid */}
      <KPIGrid
        data={kpiData}
        isLoading={isLoadingKPIs}
        agentType="louis"
        avgLatency={avgTotalLatency}
      />

      {/* Charts Grid - 2x2 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <div className="h-[260px]">
          <CallVolumeChart
            data={chartData?.call_volume_by_day || []}
          />
        </div>
        <div className="h-[260px]">
          <EmotionDistribution
            data={chartData?.emotion_distribution || []}
          />
        </div>
        <div className="h-[260px]">
          <OutcomeBreakdown
            data={chartData?.outcome_distribution || []}
          />
        </div>
        <div className="h-[260px]">
          <LatencyTimeSeriesChart
            data={latencyData || []}
            isLoading={isLoadingLatencies}
          />
        </div>
      </div>
    </div>
  )
}
