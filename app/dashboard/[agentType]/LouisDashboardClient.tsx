'use client'

import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useLouisKPIs,
  useLouisChartData,
  useLouisAgentPerformance,
} from '@/lib/hooks/useDashboardData'
import { exportLouisCallsToCSV } from '@/lib/queries/louis'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'

interface LouisDashboardClientProps {
  userEmail: string
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
  const { data: agentPerformance } = useLouisAgentPerformance(filters)

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

  const handleFilterChange = (clientIds: string[], agentIds: string[]) => {
    setClientIds(clientIds)
    setDeploymentId(agentIds.length === 1 ? agentIds[0] : null)
  }

  return (
    <>
      {/* Header */}
      <DashboardHeader userEmail={userEmail} title="Dashboard Louis" />

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Filters Row */}
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
          <div className="flex flex-col sm:flex-row gap-4 w-full lg:w-auto">
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

          <ExportCSVButton
            filters={filters}
            exportFn={exportLouisCallsToCSV}
            filename="louis-dashboard-export.csv"
          />
        </div>

        {/* KPIs Grid */}
        <KPIGrid data={kpiData} isLoading={isLoadingKPIs} agentType="louis" />

        {/* Agent Performance Table */}
        {agentPerformance && agentPerformance.length > 0 && (
          <div className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm overflow-hidden">
            <div className="p-6">
              <h3 className="text-lg font-bold text-white mb-4">
                Performance par agent
              </h3>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-white/10">
                      <th className="text-left text-sm font-medium text-white/60 pb-3">
                        Agent
                      </th>
                      <th className="text-right text-sm font-medium text-white/60 pb-3">
                        Appels
                      </th>
                      <th className="text-right text-sm font-medium text-white/60 pb-3">
                        Taux réponse
                      </th>
                      <th className="text-right text-sm font-medium text-white/60 pb-3">
                        RDV
                      </th>
                      <th className="text-right text-sm font-medium text-white/60 pb-3">
                        Conversion
                      </th>
                      <th className="text-right text-sm font-medium text-white/60 pb-3">
                        Coût/RDV
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {agentPerformance.map((agent) => (
                      <tr
                        key={agent.deployment_id}
                        className="border-b border-white/5 hover:bg-white/5 transition-colors"
                      >
                        <td className="py-3 text-sm text-white">
                          {agent.agent_name}
                          <span className="text-white/40 text-xs ml-2">
                            ({agent.client_name})
                          </span>
                        </td>
                        <td className="py-3 text-sm text-white text-right">
                          {agent.total_calls.toLocaleString()}
                        </td>
                        <td className="py-3 text-sm text-white text-right">
                          {agent.answer_rate.toFixed(1)}%
                        </td>
                        <td className="py-3 text-sm text-white text-right">
                          {agent.appointments}
                        </td>
                        <td className="py-3 text-sm text-white text-right">
                          {agent.conversion_rate.toFixed(1)}%
                        </td>
                        <td className="py-3 text-sm text-white text-right">
                          {agent.cost_per_appointment.toFixed(2)}€
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Charts Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <CallVolumeChart
            data={chartData?.call_volume_by_day || []}
          />
          <OutcomeBreakdown
            data={chartData?.outcome_distribution || []}
          />
          <EmotionDistribution
            data={chartData?.emotion_distribution || []}
          />
        </div>
      </div>
    </>
  )
}
