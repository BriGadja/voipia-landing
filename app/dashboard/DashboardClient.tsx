'use client'

import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { subDays } from 'date-fns'
import { Download, User } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { fetchKPIMetrics, fetchChartData, exportCallsToCSV } from '@/lib/queries/dashboard'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPICard } from '@/components/dashboard/KPICard'
import { CallVolumeChart } from '@/components/dashboard/Charts/CallVolumeChart'
import { EmotionDistribution } from '@/components/dashboard/Charts/EmotionDistribution'
import { OutcomeBreakdown } from '@/components/dashboard/Charts/OutcomeBreakdown'
import { VoicemailByAgent } from '@/components/dashboard/Charts/VoicemailByAgent'
import { LogoutButton } from '@/components/auth/LogoutButton'

export function DashboardClient() {
  const [userEmail, setUserEmail] = useState<string>('')
  const supabase = createClient()

  useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        setUserEmail(user.email || '')
      }
    }
    getUser()
  }, [])
  const [startDate, setStartDate] = useState(subDays(new Date(), 30))
  const [endDate, setEndDate] = useState(new Date())
  const [selectedClientIds, setSelectedClientIds] = useState<string[]>([])
  const [selectedAgentIds, setSelectedAgentIds] = useState<string[]>([])
  const [isExporting, setIsExporting] = useState(false)

  const { data: kpiData, isLoading: isLoadingKPIs } = useQuery({
    queryKey: ['kpi-metrics', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchKPIMetrics(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      ),
    refetchInterval: 3600000, // 1 hour
    staleTime: 3600000,
  })

  const { data: chartData, isLoading: isLoadingCharts } = useQuery({
    queryKey: ['chart-data', startDate, endDate, selectedClientIds, selectedAgentIds],
    queryFn: () =>
      fetchChartData(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      ),
    refetchInterval: 3600000, // 1 hour
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
      const csv = await exportCallsToCSV(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      )

      // Create and download file
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      link.href = URL.createObjectURL(blob)
      link.download = `voipia-calls-export-${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('Error exporting data:', error)
      alert('Erreur lors de l\'export des données')
    } finally {
      setIsExporting(false)
    }
  }

  return (
    <main className="min-h-screen p-3 max-w-[1600px] mx-auto">
      {/* Header */}
      <div className="mb-2.5 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
        <div>
          <h1 className="text-2xl font-bold text-white mb-0.5">
            Dashboard Analytics
          </h1>
          <div className="flex items-center gap-2 text-white/60">
            <User className="w-3.5 h-3.5" />
            <p className="text-xs">
              Connecté en tant que <span className="text-white/80 font-medium">{userEmail}</span>
            </p>
          </div>
        </div>
        <LogoutButton />
      </div>

      {/* Filters */}
      <div className="mb-2.5 p-2.5 bg-black/20 border border-white/20 rounded-xl backdrop-blur-sm">
        <div className="flex flex-col lg:flex-row gap-2.5 items-start lg:items-center justify-between">
          <DateRangeFilter
            startDate={startDate}
            endDate={endDate}
            onChange={handleDateChange}
          />
          <ClientAgentFilter
            selectedClientIds={selectedClientIds}
            selectedAgentIds={selectedAgentIds}
            onChange={handleFilterChange}
          />
        </div>
      </div>

      {/* KPI Cards */}
      {isLoadingKPIs ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-2.5">
          {[...Array(5)].map((_, i) => (
            <div
              key={i}
              className="h-24 bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : kpiData ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-2.5">
          <KPICard
            label="Total Appels"
            value={kpiData.current_period.total_calls}
            previousValue={kpiData.previous_period.total_calls || undefined}
            format="number"
            decorationColor="blue"
            delay={0}
          />
          <KPICard
            label="Taux de Décroché"
            value={kpiData.current_period.answer_rate}
            previousValue={kpiData.previous_period.answer_rate || undefined}
            format="percentage"
            decorationColor="emerald"
            delay={0.05}
          />
          <KPICard
            label="Durée Moyenne"
            value={kpiData.current_period.avg_duration}
            previousValue={kpiData.previous_period.avg_duration || undefined}
            format="duration"
            decorationColor="amber"
            delay={0.1}
          />
          <KPICard
            label="RDV Pris"
            value={kpiData.current_period.appointments_scheduled}
            previousValue={kpiData.previous_period.appointments_scheduled || undefined}
            format="number"
            decorationColor="violet"
            delay={0.15}
          />
          <KPICard
            label="Taux de Conversion"
            value={kpiData.current_period.conversion_rate}
            previousValue={kpiData.previous_period.conversion_rate || undefined}
            format="percentage"
            decorationColor="blue"
            delay={0.2}
          />
        </div>
      ) : null}

      {/* Charts */}
      {isLoadingCharts ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5 mb-2.5">
          {[...Array(4)].map((_, i) => (
            <div
              key={i}
              className="h-64 bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : chartData ? (
        <>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5 mb-2.5">
            <CallVolumeChart data={chartData.call_volume_by_day || []} />
            <EmotionDistribution data={chartData.emotion_distribution || []} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5">
            <OutcomeBreakdown data={chartData.outcome_distribution || []} />
            <VoicemailByAgent data={chartData.voicemail_by_agent || []} />
          </div>
        </>
      ) : null}
    </main>
  )
}
