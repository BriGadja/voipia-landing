'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { subDays } from 'date-fns'
import { Download, Loader2 } from 'lucide-react'
import { fetchArthurKPIMetrics, fetchArthurChartData, exportArthurCallsToCSV } from '@/lib/queries/arthur'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPICard } from '@/components/dashboard/KPICard'

interface ArthurDashboardClientProps {
  userEmail: string
}

/**
 * Arthur Dashboard Client Component
 * Specialized dashboard for Arthur (prospecting/reactivation) agents
 * Displays Arthur-specific KPIs and metrics
 */
export function ArthurDashboardClient({ userEmail }: ArthurDashboardClientProps) {
  const [startDate, setStartDate] = useState(subDays(new Date(), 30))
  const [endDate, setEndDate] = useState(new Date())
  const [selectedClientIds, setSelectedClientIds] = useState<string[]>([])
  const [selectedAgentIds, setSelectedAgentIds] = useState<string[]>([])
  const [isExporting, setIsExporting] = useState(false)

  // Fetch Arthur KPI metrics
  const { data: kpiData, isLoading: isLoadingKPIs } = useQuery({
    queryKey: ['arthur-kpis', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchArthurKPIMetrics(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      ),
    refetchInterval: 3600000,
    staleTime: 3600000,
  })

  // Fetch Arthur chart data
  const { data: chartData, isLoading: isLoadingCharts } = useQuery({
    queryKey: ['arthur-charts', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchArthurChartData(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      ),
    refetchInterval: 3600000,
    staleTime: 3600000,
  })

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
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `arthur-dashboard-${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      URL.revokeObjectURL(url)
    } catch (error) {
      console.error('Error exporting CSV:', error)
      alert('Erreur lors de l\'export des données. Veuillez réessayer.')
    } finally {
      setIsExporting(false)
    }
  }

  return (
    <>
      {/* Header */}
      <DashboardHeader
        userEmail={userEmail}
        title="Dashboard Arthur"
        backLink="/dashboard"
        backLabel="Dashboard Global"
      />

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Filters Row */}
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
          <div className="flex flex-col sm:flex-row gap-4 w-full lg:w-auto">
            <DateRangeFilter
              startDate={startDate}
              endDate={endDate}
              onChange={handleDateChange}
            />
            <ClientAgentFilter
              selectedClientIds={selectedClientIds}
              selectedAgentIds={selectedAgentIds}
              onChange={handleFilterChange}
              agentType="arthur"
            />
          </div>

          <button
            onClick={handleExport}
            disabled={isExporting}
            className="flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-purple-600/50 disabled:cursor-not-allowed rounded-lg text-white font-medium transition-colors"
          >
            {isExporting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Export en cours...</span>
              </>
            ) : (
              <>
                <Download className="w-4 h-4" />
                <span className="hidden sm:inline">Exporter CSV</span>
                <span className="sm:hidden">CSV</span>
              </>
            )}
          </button>
        </div>

        {/* KPIs Grid */}
        {isLoadingKPIs ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {Array.from({ length: 5 }).map((_, i) => (
              <div
                key={i}
                className="h-32 rounded-xl bg-white/5 border border-white/10 animate-pulse"
              />
            ))}
          </div>
        ) : kpiData ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <KPICard
              label="Rendez-vous planifiés"
              value={kpiData.current_period.appointments_scheduled}
              previousValue={kpiData.previous_period.appointments_scheduled}
              format="number"
              decorationColor="amber"
            />
            <KPICard
              label="Taux de réactivation"
              value={kpiData.current_period.reactivation_rate}
              previousValue={kpiData.previous_period.reactivation_rate}
              format="percentage"
              decorationColor="emerald"
            />
            <KPICard
              label="Coût par conversion"
              value={kpiData.current_period.cost_per_conversion}
              previousValue={kpiData.previous_period.cost_per_conversion}
              format="currency"
              decorationColor="red"
            />
            <KPICard
              label="Durée moyenne"
              value={kpiData.current_period.avg_duration_per_attempt}
              previousValue={kpiData.previous_period.avg_duration_per_attempt}
              format="duration"
              decorationColor="blue"
            />
            <KPICard
              label="Taux réponse T1"
              value={kpiData.current_period.answer_rate_attempt_1}
              previousValue={kpiData.previous_period.answer_rate_attempt_1}
              format="percentage"
              decorationColor="violet"
            />
          </div>
        ) : null}

        {/* Charts Grid - À venir */}
        <div className="grid grid-cols-1 gap-6">
          <div className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm p-12 text-center">
            <h3 className="text-lg font-bold text-white mb-2">
              Graphiques spécifiques Arthur
            </h3>
            <p className="text-white/60">
              Les graphiques d&apos;analyse de performance Arthur seront bientôt disponibles
            </p>
          </div>
        </div>
      </div>
    </>
  )
}
