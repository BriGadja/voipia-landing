'use client'

import Link from 'next/link'
import { Users, Target, Sparkles, ArrowRight } from 'lucide-react'
import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useGlobalKPIs,
  useGlobalChartData,
  useAgentTypePerformance,
} from '@/lib/hooks/useDashboardData'
import { exportGlobalCallsToCSV } from '@/lib/queries/global'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { cn } from '@/lib/utils'

interface GlobalDashboardClientProps {
  userEmail: string
}

/**
 * Global Dashboard Client Component
 * Displays aggregated analytics across all agents and clients
 * Allows filtering by client, agent type, and date range
 */
export function GlobalDashboardClient({ userEmail }: GlobalDashboardClientProps) {
  // URL-based filters
  const { filters, setClientIds, setAgentTypeName, setDateRange } =
    useDashboardFilters()

  // Fetch global metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useGlobalKPIs(filters)
  const { data: chartData, isLoading: isLoadingCharts } =
    useGlobalChartData(filters)
  const { data: agentTypePerformance } = useAgentTypePerformance(filters)

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

  const handleFilterChange = (clientIds: string[], _agentIds: string[]) => {
    setClientIds(clientIds)
  }

  // Agent type stats
  const agentTypeStats = [
    {
      type: 'louis' as const,
      name: 'Louis',
      icon: Users,
      color: 'from-blue-500/20 to-blue-500/5 border-blue-500/30',
      iconColor: 'text-blue-400',
      description: 'Rappel de leads',
      performance: agentTypePerformance?.find((p) => p.agent_type === 'louis'),
    },
    {
      type: 'arthur' as const,
      name: 'Arthur',
      icon: Target,
      color: 'from-orange-500/20 to-orange-500/5 border-orange-500/30',
      iconColor: 'text-orange-400',
      description: 'Prospection active',
      performance: agentTypePerformance?.find((p) => p.agent_type === 'arthur'),
    },
    {
      type: 'alexandra' as const,
      name: 'Alexandra',
      icon: Sparkles,
      color: 'from-green-500/20 to-green-500/5 border-green-500/30',
      iconColor: 'text-green-400',
      description: 'SAV & Support',
      performance: agentTypePerformance?.find((p) => p.agent_type === 'alexandra'),
    },
  ]

  return (
    <>
      {/* Header */}
      <DashboardHeader userEmail={userEmail} title="Dashboard Global" />

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
              selectedAgentIds={[]}
              onChange={handleFilterChange}
            />
          </div>

          <ExportCSVButton
            filters={filters}
            exportFn={exportGlobalCallsToCSV}
            filename="global-dashboard-export.csv"
          />
        </div>

        {/* KPIs Grid */}
        <KPIGrid data={kpiData} isLoading={isLoadingKPIs} agentType="global" />

        {/* Agent Type Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {agentTypeStats.map((agent) => {
            const perf = agent.performance

            return (
              <Link
                key={agent.type}
                href={`/dashboard/${agent.type}`}
                className={cn(
                  'group relative overflow-hidden rounded-xl border bg-gradient-to-br backdrop-blur-sm transition-all hover:scale-[1.02]',
                  agent.color
                )}
              >
                <div className="p-6 space-y-4">
                  {/* Header */}
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div
                        className={cn(
                          'p-3 rounded-lg bg-white/10',
                          agent.iconColor
                        )}
                      >
                        <agent.icon className="w-6 h-6" />
                      </div>
                      <div>
                        <h3 className="text-lg font-bold text-white">
                          {agent.name}
                        </h3>
                        <p className="text-sm text-white/60">
                          {agent.description}
                        </p>
                      </div>
                    </div>
                    <ArrowRight className="w-5 h-5 text-white/40 group-hover:text-white/80 transition-colors" />
                  </div>

                  {/* Stats */}
                  {perf && (
                    <div className="grid grid-cols-2 gap-4 pt-4 border-t border-white/10">
                      <div>
                        <p className="text-xs text-white/60 mb-1">Appels</p>
                        <p className="text-xl font-bold text-white">
                          {perf.total_calls.toLocaleString()}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-white/60 mb-1">
                          Taux réponse
                        </p>
                        <p className="text-xl font-bold text-white">
                          {perf.answer_rate.toFixed(1)}%
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-white/60 mb-1">
                          Conversion
                        </p>
                        <p className="text-xl font-bold text-white">
                          {perf.conversion_rate.toFixed(1)}%
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-white/60 mb-1">Clients</p>
                        <p className="text-xl font-bold text-white">
                          {perf.total_clients}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </Link>
            )
          })}
        </div>

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
