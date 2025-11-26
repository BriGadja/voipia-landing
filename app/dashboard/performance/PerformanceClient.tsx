'use client'

import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useGlobalKPIs,
  useGlobalChartData,
  useAgentTypePerformance,
  useTopClients,
} from '@/lib/hooks/useDashboardData'
import { exportGlobalCallsToCSV } from '@/lib/queries/global'
import { PageHeader } from '@/components/dashboard/PageHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { TopClientsTable } from './TopClientsTable'
import { AgentTypeComparison } from './AgentTypeComparison'

/**
 * Performance Dashboard Client Component
 * Advanced analytics view with multiple charts and filters
 */
export function PerformanceClient() {
  // URL-based filters
  const { filters, setClientIds, setDeploymentId, setDateRange, setAgentTypeName } =
    useDashboardFilters()

  // Fetch global metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useGlobalKPIs(filters)
  const { data: chartData, isLoading: isLoadingCharts } = useGlobalChartData(filters)
  const { data: agentTypeData, isLoading: isLoadingAgentTypes } = useAgentTypePerformance(filters)
  const { data: topClients, isLoading: isLoadingTopClients } = useTopClients(filters, 10)

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

  const handleFilterChange = (clientIds: string[], agentIds: string[]) => {
    setClientIds(clientIds)
    setDeploymentId(agentIds.length === 1 ? agentIds[0] : null)
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header with Export */}
      <PageHeader
        title="Performance"
        description="Analyse detaillee des performances globales"
      >
        <ExportCSVButton
          filters={filters}
          exportFn={exportGlobalCallsToCSV}
          filename="performance-export.csv"
        />
      </PageHeader>

      {/* Filters Row */}
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
        />
      </div>

      {/* KPIs Grid */}
      <KPIGrid
        data={kpiData}
        isLoading={isLoadingKPIs}
        agentType="global"
      />

      {/* Main Charts - 2 columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="lg:col-span-2 h-[350px]">
          <CallVolumeChart
            data={chartData?.call_volume_by_day || []}
          />
        </div>
        <div className="h-[300px]">
          <EmotionDistribution
            data={chartData?.emotion_distribution || []}
          />
        </div>
        <div className="h-[300px]">
          <OutcomeBreakdown
            data={chartData?.outcome_distribution || []}
          />
        </div>
      </div>

      {/* Secondary Analysis - 2 columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Agent Type Comparison */}
        <div className="bg-black/20 border border-white/10 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Performance par type d&apos;agent
          </h3>
          <AgentTypeComparison
            data={agentTypeData || []}
            isLoading={isLoadingAgentTypes}
          />
        </div>

        {/* Top Clients */}
        <div className="bg-black/20 border border-white/10 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Top 10 clients
          </h3>
          <TopClientsTable
            data={topClients || []}
            isLoading={isLoadingTopClients}
          />
        </div>
      </div>
    </div>
  )
}
