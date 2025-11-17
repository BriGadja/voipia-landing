'use client'

import type { ClientFinancialData } from '@/lib/types/financial'
import { formatCurrency, formatPercentage } from '@/lib/queries/financial'
import { InteractiveFinancialTable, ColumnDefinition } from './InteractiveFinancialTable'

interface ClientBreakdownTableV2Props {
  data: ClientFinancialData[] | undefined
  isLoading?: boolean
  onDetailClick?: (client: ClientFinancialData) => void
}

export function ClientBreakdownTableV2({
  data,
  isLoading,
  onDetailClick,
}: ClientBreakdownTableV2Props) {
  // Filter out Voipia from data
  const filteredData = data?.filter(
    (client) => client.client_name.toLowerCase() !== 'voipia'
  ) || []

  // Define columns
  const columns: ColumnDefinition<ClientFinancialData>[] = [
    {
      key: 'client_name',
      label: 'Client',
      sortable: true,
      align: 'left',
      className: 'font-medium text-white',
      width: '200px',
    },
    {
      key: 'total_revenue',
      label: 'Revenue',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="font-semibold text-amber-400">{formatCurrency(value)}</span>
      ),
    },
    {
      key: 'total_provider_cost',
      label: 'Coûts',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="text-red-400">{formatCurrency(value)}</span>
      ),
    },
    {
      key: 'total_margin',
      label: 'Marge',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="font-semibold text-emerald-400">{formatCurrency(value)}</span>
      ),
    },
    {
      key: 'margin_percentage',
      label: 'Marge %',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span
          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold ${
            value >= 95
              ? 'bg-emerald-500/20 text-emerald-400'
              : value >= 90
              ? 'bg-amber-500/20 text-amber-400'
              : 'bg-red-500/20 text-red-400'
          }`}
        >
          {formatPercentage(value)}
        </span>
      ),
    },
    {
      key: 'call_count',
      label: 'Appels',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="text-gray-300">{value.toLocaleString('fr-FR')}</span>
      ),
    },
    {
      key: 'sms_count',
      label: 'SMS',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="text-blue-400">{value.toLocaleString('fr-FR')}</span>
      ),
    },
    {
      key: 'email_count',
      label: 'Emails',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="text-cyan-400">{value.toLocaleString('fr-FR')}</span>
      ),
    },
    {
      key: 'appointments_scheduled',
      label: 'RDV',
      sortable: true,
      align: 'right',
      format: (value) => (
        <span className="text-violet-400 font-medium">{value}</span>
      ),
    },
  ]

  // Calculate summary totals (excluding Voipia)
  const summary = filteredData.reduce(
    (acc, client) => ({
      totalRevenue: acc.totalRevenue + client.total_revenue,
      totalMargin: acc.totalMargin + client.total_margin,
      totalCalls: acc.totalCalls + client.call_count,
      totalSMS: acc.totalSMS + client.sms_count,
      totalEmails: acc.totalEmails + client.email_count,
      totalRDV: acc.totalRDV + client.appointments_scheduled,
    }),
    {
      totalRevenue: 0,
      totalMargin: 0,
      totalCalls: 0,
      totalSMS: 0,
      totalEmails: 0,
      totalRDV: 0,
    }
  )

  return (
    <div className="space-y-4">
      <InteractiveFinancialTable
        data={filteredData}
        columns={columns}
        isLoading={isLoading}
        title="Breakdown par Client"
        showDetailButton={!!onDetailClick}
        onDetailClick={onDetailClick}
        exportFilename="clients_financials.csv"
        emptyMessage="Aucun client disponible pour cette période"
        pageSize={20}
      />

      {/* Summary Stats */}
      {!isLoading && filteredData.length > 0 && (
        <div className="rounded-xl border border-gray-800/50 bg-black/20 backdrop-blur-sm p-6">
          <h4 className="text-sm font-semibold text-gray-400 mb-4">
            Totaux (hors Voipia)
          </h4>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 text-sm">
            <div>
              <p className="text-gray-400 mb-1">Total Revenue</p>
              <p className="text-white font-bold">{formatCurrency(summary.totalRevenue)}</p>
            </div>
            <div>
              <p className="text-gray-400 mb-1">Total Marge</p>
              <p className="text-emerald-400 font-bold">
                {formatCurrency(summary.totalMargin)}
              </p>
            </div>
            <div>
              <p className="text-gray-400 mb-1">Total Appels</p>
              <p className="text-white font-bold">
                {summary.totalCalls.toLocaleString('fr-FR')}
              </p>
            </div>
            <div>
              <p className="text-gray-400 mb-1">Total SMS</p>
              <p className="text-blue-400 font-bold">
                {summary.totalSMS.toLocaleString('fr-FR')}
              </p>
            </div>
            <div>
              <p className="text-gray-400 mb-1">Total Emails</p>
              <p className="text-cyan-400 font-bold">
                {summary.totalEmails.toLocaleString('fr-FR')}
              </p>
            </div>
            <div>
              <p className="text-gray-400 mb-1">Total RDV</p>
              <p className="text-violet-400 font-bold">{summary.totalRDV}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
