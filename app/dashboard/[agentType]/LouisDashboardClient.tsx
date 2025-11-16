'use client'

import { useState, useEffect } from 'react'
import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useLouisKPIs,
  useLouisChartData,
} from '@/lib/hooks/useDashboardData'
import { exportLouisCallsToCSV } from '@/lib/queries/louis'
import { checkIsAdmin } from '@/lib/queries/global'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPIGrid } from '@/components/dashboard/KPIGrid'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { VoicemailByAgent } from '@/components/dashboard/Charts/VoicemailByAgent'

interface LouisDashboardClientProps {
  userEmail: string
}

/**
 * Louis Dashboard Client Component
 * Specialized dashboard for Louis (setter/appointment booking) agents
 * Displays Louis-specific KPIs and metrics
 */
export function LouisDashboardClient({ userEmail }: LouisDashboardClientProps) {
  // Admin status
  const [isAdmin, setIsAdmin] = useState(false)

  // URL-based filters
  const { filters, setClientIds, setDeploymentId, setDateRange } =
    useDashboardFilters()

  // Fetch Louis metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useLouisKPIs(filters)
  const { data: chartData, isLoading: isLoadingCharts } =
    useLouisChartData(filters)

  // Check admin status on mount
  useEffect(() => {
    checkIsAdmin().then(setIsAdmin)
  }, [])

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
      <DashboardHeader
        userEmail={userEmail}
        title="Dashboard Louis"
        backLink="/dashboard"
        backLabel="Dashboard Global"
        isAdmin={isAdmin}
      />

      {/* Main Content */}
      <div className="container mx-auto px-4 py-4 space-y-4">
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
        <KPIGrid data={kpiData} isLoading={isLoadingKPIs} agentType="louis" />

        {/* Charts Grid - 2x2 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div className="h-[300px]">
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
          <div className="h-[300px]">
            <VoicemailByAgent
              data={chartData?.voicemail_by_agent || []}
            />
          </div>
        </div>
      </div>
    </>
  )
}
