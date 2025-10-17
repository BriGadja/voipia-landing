'use client'

import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { subDays } from 'date-fns'
import { Download, User, Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import {
  fetchArthurKPIMetrics,
  fetchArthurChartData,
  exportArthurCallsToCSV,
} from '@/lib/queries/arthur'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ClientAgentFilter } from '@/components/dashboard/Filters/ClientAgentFilter'
import { KPICard } from '@/components/dashboard/KPICard'
import { CallVolumeChart } from '@/components/dashboard-arthur/Charts/CallVolumeChart'
import { ConversionFunnelChart } from '@/components/dashboard-arthur/Charts/ConversionFunnelChart'
import { OutcomeBreakdownChart } from '@/components/dashboard-arthur/Charts/OutcomeBreakdownChart'
import { SegmentPerformanceChart } from '@/components/dashboard-arthur/Charts/SegmentPerformanceChart'
import { LogoutButton } from '@/components/auth/LogoutButton'

export function DashboardArthurClient() {
  const [userEmail, setUserEmail] = useState<string>('')
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    const checkAuth = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        router.push('/login')
        return
      }

      setUserEmail(user.email || '')
      setIsLoading(false)
    }

    checkAuth()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') {
        router.push('/login')
      } else if (event === 'SIGNED_IN' && session?.user) {
        setUserEmail(session.user.email || '')
        setIsLoading(false)
      }
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [supabase, router])

  const [startDate, setStartDate] = useState(subDays(new Date(), 30))
  const [endDate, setEndDate] = useState(new Date())
  const [selectedClientIds, setSelectedClientIds] = useState<string[]>([])
  const [selectedAgentIds, setSelectedAgentIds] = useState<string[]>([])
  const [isExporting, setIsExporting] = useState(false)

  const { data: kpiData, isLoading: isLoadingKPIs } = useQuery({
    queryKey: [
      'arthur-kpi-metrics',
      startDate,
      endDate,
      selectedClientIds,
      selectedAgentIds,
    ],
    queryFn: () =>
      fetchArthurKPIMetrics(
        startDate,
        endDate,
        selectedClientIds[0] || null,
        selectedAgentIds[0] || null
      ),
    refetchInterval: 3600000, // 1 hour
    staleTime: 3600000,
  })

  const { data: chartData, isLoading: isLoadingCharts } = useQuery({
    queryKey: [
      'arthur-chart-data',
      startDate,
      endDate,
      selectedClientIds,
      selectedAgentIds,
    ],
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
      link.href = URL.createObjectURL(blob)
      link.download = `arthur-calls-export-${new Date().toISOString().split('T')[0]}.csv`
      link.click()
    } catch (error) {
      console.error('Error exporting data:', error)
      alert("Erreur lors de l'export des données")
    } finally {
      setIsExporting(false)
    }
  }

  if (isLoading) {
    return (
      <main className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 text-white animate-spin mx-auto mb-4" />
          <p className="text-white/60">
            Vérification de l&apos;authentification...
          </p>
        </div>
      </main>
    )
  }

  return (
    <main className="h-screen p-3 max-w-[1600px] mx-auto flex flex-col overflow-hidden">
      {/* Header */}
      <div className="mb-3 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 flex-shrink-0">
        <div>
          <h1 className="text-2xl font-bold text-white mb-0.5">
            Dashboard Arthur - Réactivation
          </h1>
          <div className="flex items-center gap-2 text-white/60">
            <User className="w-3.5 h-3.5" />
            <p className="text-xs">
              Connecté en tant que{' '}
              <span className="text-white/80 font-medium">{userEmail}</span>
            </p>
          </div>
        </div>
        <LogoutButton />
      </div>

      {/* Filters */}
      <div className="mb-3 p-2.5 bg-black/20 border border-white/20 rounded-xl backdrop-blur-sm flex-shrink-0">
        <div className="flex flex-col lg:flex-row gap-2.5 items-start lg:items-center justify-between">
          <DateRangeFilter
            startDate={startDate}
            endDate={endDate}
            onChange={handleDateChange}
          />
          <div className="flex items-center gap-2.5">
            <ClientAgentFilter
              selectedClientIds={selectedClientIds}
              selectedAgentIds={selectedAgentIds}
              onChange={handleFilterChange}
            />
            <button
              onClick={handleExport}
              disabled={isExporting}
              className="flex items-center gap-2 px-3 py-1.5 text-sm bg-violet-600 hover:bg-violet-700 disabled:opacity-50 text-white rounded-lg transition-colors"
            >
              <Download className="w-4 h-4" />
              {isExporting ? 'Export...' : 'Export CSV'}
            </button>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      {isLoadingKPIs ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-3 flex-shrink-0">
          {[...Array(5)].map((_, i) => (
            <div
              key={i}
              className="h-24 bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : kpiData ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2.5 mb-3 flex-shrink-0">
          <KPICard
            label="Taux de Réactivation"
            value={kpiData.current_period.reactivation_rate}
            previousValue={kpiData.previous_period.reactivation_rate || undefined}
            format="percentage"
            decorationColor="emerald"
            delay={0}
          />
          <KPICard
            label="Coût par Conversion"
            value={kpiData.current_period.cost_per_conversion}
            previousValue={
              kpiData.previous_period.cost_per_conversion || undefined
            }
            format="currency"
            decorationColor="blue"
            delay={0.05}
          />
          <KPICard
            label="Durée Moy./Tentative"
            value={kpiData.current_period.avg_duration_per_attempt}
            previousValue={
              kpiData.previous_period.avg_duration_per_attempt || undefined
            }
            format="duration"
            decorationColor="amber"
            delay={0.1}
          />
          <KPICard
            label="RDV Planifiés"
            value={kpiData.current_period.appointments_scheduled}
            previousValue={
              kpiData.previous_period.appointments_scheduled || undefined
            }
            format="number"
            decorationColor="violet"
            delay={0.15}
          />
          <KPICard
            label="Taux Décroché T1"
            value={kpiData.current_period.answer_rate_attempt_1}
            previousValue={
              kpiData.previous_period.answer_rate_attempt_1 || undefined
            }
            format="percentage"
            decorationColor="blue"
            delay={0.2}
          />
        </div>
      ) : null}

      {/* Charts */}
      {isLoadingCharts ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
          {[...Array(4)].map((_, i) => (
            <div
              key={i}
              className="bg-black/20 border border-white/20 rounded-xl animate-pulse"
            />
          ))}
        </div>
      ) : chartData ? (
        <div className="flex-1 min-h-0 flex flex-col gap-3">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
            <CallVolumeChart data={chartData.call_volume_by_day || []} />
            <ConversionFunnelChart data={chartData.conversion_funnel || []} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 flex-1 min-h-0">
            <OutcomeBreakdownChart
              data={chartData.outcome_distribution || []}
            />
            <SegmentPerformanceChart
              data={chartData.segment_performance || []}
            />
          </div>
        </div>
      ) : null}
    </main>
  )
}
