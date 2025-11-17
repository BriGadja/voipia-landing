'use client'

import { useState } from 'react'
import { useFinancialKPIs, useClientBreakdown, useFinancialTimeSeries, useCostBreakdown } from '@/lib/hooks/useFinancialData'
import { getDefaultDateRange } from '@/lib/queries/financial'
import { FinancialKPIGrid } from '@/components/dashboard/Financial/FinancialKPIGrid'
import { ClientBreakdownTableV2 } from '@/components/dashboard/Financial/ClientBreakdownTableV2'
import { FinancialTimeSeriesChart } from '@/components/dashboard/Financial/FinancialTimeSeriesChart'
import { CostBreakdownChart } from '@/components/dashboard/Financial/CostBreakdownChart'
import { ClientDrilldownModal } from '@/components/dashboard/Financial/ClientDrilldownModal'
import type { FinancialFilters, ClientFinancialData } from '@/lib/types/financial'

export function FinancialDashboardClient() {
  // Default to last 30 days
  const defaultRange = getDefaultDateRange()
  const [filters, setFilters] = useState<FinancialFilters>({
    startDate: defaultRange.startDate,
    endDate: defaultRange.endDate,
    clientId: null,
    agentTypeName: null,
    deploymentId: null,
  })

  // Modal state for drill down
  const [selectedClient, setSelectedClient] = useState<ClientFinancialData | null>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)

  // Fetch data
  const { data: kpiData, isLoading: kpiLoading, error: kpiError } = useFinancialKPIs(filters)
  const { data: clientData, isLoading: clientLoading } = useClientBreakdown(filters)
  const { data: timeSeriesData, isLoading: timeSeriesLoading } = useFinancialTimeSeries({
    ...filters,
    granularity: 'day'
  })
  const { data: costBreakdownData, isLoading: costBreakdownLoading } = useCostBreakdown(filters)

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-black">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">
            Dashboard Financier
          </h1>
          <p className="text-gray-400">
            Suivi de la marge Voipia et consommation par client
          </p>
        </div>

        {/* Date Range Filter */}
        <div className="mb-6 flex flex-wrap gap-4">
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-gray-400">Date début:</label>
            <input
              type="date"
              value={filters.startDate}
              onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
              className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
          </div>
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-gray-400">Date fin:</label>
            <input
              type="date"
              value={filters.endDate}
              onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
              className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
          </div>
          <button
            onClick={() => {
              const range = getDefaultDateRange()
              setFilters({ ...filters, ...range })
            }}
            className="px-4 py-2 bg-violet-600 hover:bg-violet-700 text-white text-sm font-medium rounded-lg transition-colors"
          >
            30 derniers jours
          </button>
        </div>

        {/* Error State */}
        {kpiError && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
            <p className="text-red-400 text-sm">
              Erreur de chargement des données: {kpiError.message}
            </p>
          </div>
        )}

        {/* KPI Grid */}
        <FinancialKPIGrid data={kpiData} isLoading={kpiLoading} />

        {/* Time Series Chart */}
        <div className="mb-6">
          <FinancialTimeSeriesChart
            data={timeSeriesData || []}
            isLoading={timeSeriesLoading}
            height={350}
          />
        </div>

        {/* Cost Breakdown Chart */}
        <div className="mb-6">
          <CostBreakdownChart
            data={costBreakdownData}
            isLoading={costBreakdownLoading}
            height={450}
          />
        </div>

        {/* Period Info */}
        {kpiData && !kpiLoading && (
          <div className="mb-6 p-4 bg-gray-800/30 border border-gray-700/30 rounded-lg">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-gray-400 mb-1">Période actuelle</p>
                <p className="text-white font-medium">
                  {new Date(kpiData.period_info.start_date).toLocaleDateString('fr-FR')} -{' '}
                  {new Date(kpiData.period_info.end_date).toLocaleDateString('fr-FR')}
                </p>
                <p className="text-gray-500 text-xs mt-1">
                  {kpiData.period_info.duration_days} jours
                </p>
              </div>
              <div>
                <p className="text-gray-400 mb-1">Période précédente</p>
                <p className="text-white font-medium">
                  {new Date(kpiData.period_info.previous_start_date).toLocaleDateString('fr-FR')} -{' '}
                  {new Date(kpiData.period_info.previous_end_date).toLocaleDateString('fr-FR')}
                </p>
              </div>
              <div>
                <p className="text-gray-400 mb-1">Comparaison</p>
                <p className={`font-medium ${
                  kpiData.comparison.revenue_change_percentage >= 0
                    ? 'text-emerald-400'
                    : 'text-red-400'
                }`}>
                  {kpiData.comparison.revenue_change_percentage >= 0 ? '+' : ''}
                  {kpiData.comparison.revenue_change_percentage.toFixed(1)}% revenue
                </p>
                <p className={`text-xs mt-1 ${
                  kpiData.comparison.margin_change_percentage >= 0
                    ? 'text-emerald-400'
                    : 'text-red-400'
                }`}>
                  {kpiData.comparison.margin_change_percentage >= 0 ? '+' : ''}
                  {kpiData.comparison.margin_change_percentage.toFixed(1)}% marge
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Client Breakdown Table */}
        <ClientBreakdownTableV2
          data={clientData}
          isLoading={clientLoading}
          onDetailClick={(client) => {
            setSelectedClient(client)
            setIsModalOpen(true)
          }}
        />

        {/* Client Drill Down Modal */}
        <ClientDrilldownModal
          client={selectedClient}
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false)
            setSelectedClient(null)
          }}
          startDate={filters.startDate}
          endDate={filters.endDate}
        />

        {/* Footer Note */}
        <div className="mt-8 p-4 bg-gray-800/20 border border-gray-700/20 rounded-lg">
          <p className="text-xs text-gray-500 text-center">
            💡 <span className="font-semibold">Note:</span> Ce dashboard affiche la marge Voipia en temps réel.
            Les coûts provider incluent les appels (VAPI), SMS et emails. Le leasing est pro-raté par jour.
          </p>
        </div>
      </div>
    </div>
  )
}
