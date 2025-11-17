'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'
import type { TimeSeriesDataPoint } from '@/lib/types/financial'
import { formatCurrency } from '@/lib/queries/financial'

interface FinancialTimeSeriesChartProps {
  data: TimeSeriesDataPoint[]
  isLoading?: boolean
  height?: number
  showRevenue?: boolean
  showCost?: boolean
  showMargin?: boolean
}

// Custom tooltip component
function CustomTooltip({ active, payload, label }: any) {
  if (!active || !payload || payload.length === 0) return null

  return (
    <div className="bg-gray-900/95 backdrop-blur-sm border border-gray-700 rounded-lg p-4 shadow-xl">
      <p className="text-sm font-semibold text-white mb-2">
        {new Date(label).toLocaleDateString('fr-FR', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
        })}
      </p>
      <div className="space-y-1">
        {payload.map((entry: any, index: number) => (
          <div key={index} className="flex items-center gap-2 text-xs">
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: entry.color }}
            />
            <span className="text-gray-400">{entry.name}:</span>
            <span className="font-semibold text-white">
              {formatCurrency(entry.value as number)}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

export function FinancialTimeSeriesChart({
  data,
  isLoading,
  height = 400,
  showRevenue = true,
  showCost = true,
  showMargin = true,
}: FinancialTimeSeriesChartProps) {
  const [hiddenLines, setHiddenLines] = useState<Set<string>>(new Set())

  // Transform data for Recharts
  const chartData = data.map((point) => ({
    date: point.date,
    revenue: point.revenue.total,
    cost: point.cost.total,
    margin: point.margin.total,
  }))

  // Loading state
  if (isLoading) {
    return (
      <div
        className="rounded-xl border border-gray-800/50 bg-black/20 backdrop-blur-sm overflow-hidden"
        style={{ height }}
      >
        <div className="p-6 h-full flex flex-col">
          <div className="h-8 w-64 bg-gray-800/50 rounded animate-pulse mb-4" />
          <div className="flex-1 bg-gray-800/30 rounded animate-pulse" />
        </div>
      </div>
    )
  }

  // Empty state
  if (!data || data.length === 0) {
    return (
      <div
        className="rounded-xl border border-gray-800/50 bg-black/20 backdrop-blur-sm overflow-hidden flex items-center justify-center"
        style={{ height }}
      >
        <p className="text-gray-400">Aucune donnée disponible pour cette période</p>
      </div>
    )
  }

  // Toggle line visibility
  const handleLegendClick = (dataKey: string) => {
    setHiddenLines((prev) => {
      const newSet = new Set(prev)
      if (newSet.has(dataKey)) {
        newSet.delete(dataKey)
      } else {
        newSet.add(dataKey)
      }
      return newSet
    })
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="rounded-xl border border-gray-800/50 bg-black/20 backdrop-blur-sm overflow-hidden"
    >
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-white">Évolution Financière</h3>
          <div className="flex items-center gap-4 text-xs">
            {showRevenue && (
              <button
                onClick={() => handleLegendClick('revenue')}
                className="flex items-center gap-2 transition-opacity hover:opacity-100"
                style={{
                  opacity: hiddenLines.has('revenue') ? 0.4 : 1,
                }}
              >
                <div className="w-3 h-3 rounded-full bg-amber-500" />
                <span className="text-gray-300">Revenue</span>
              </button>
            )}
            {showCost && (
              <button
                onClick={() => handleLegendClick('cost')}
                className="flex items-center gap-2 transition-opacity hover:opacity-100"
                style={{
                  opacity: hiddenLines.has('cost') ? 0.4 : 1,
                }}
              >
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <span className="text-gray-300">Coûts</span>
              </button>
            )}
            {showMargin && (
              <button
                onClick={() => handleLegendClick('margin')}
                className="flex items-center gap-2 transition-opacity hover:opacity-100"
                style={{
                  opacity: hiddenLines.has('margin') ? 0.4 : 1,
                }}
              >
                <div className="w-3 h-3 rounded-full bg-emerald-500" />
                <span className="text-gray-300">Marge</span>
              </button>
            )}
          </div>
        </div>

        <ResponsiveContainer width="100%" height={height}>
          <LineChart
            data={chartData}
            margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
            <XAxis
              dataKey="date"
              stroke="#9CA3AF"
              tick={{ fill: '#9CA3AF', fontSize: 12 }}
              tickFormatter={(value) =>
                new Date(value).toLocaleDateString('fr-FR', {
                  day: '2-digit',
                  month: 'short',
                })
              }
            />
            <YAxis
              stroke="#9CA3AF"
              tick={{ fill: '#9CA3AF', fontSize: 12 }}
              tickFormatter={(value) =>
                `${(value / 1000).toFixed(0)}k€`
              }
            />
            <Tooltip content={<CustomTooltip />} />

            {/* Revenue Line */}
            {showRevenue && !hiddenLines.has('revenue') && (
              <Line
                type="monotone"
                dataKey="revenue"
                name="Revenue"
                stroke="#F59E0B"
                strokeWidth={3}
                dot={{ fill: '#F59E0B', r: 4 }}
                activeDot={{ r: 6 }}
                animationDuration={800}
              />
            )}

            {/* Cost Line */}
            {showCost && !hiddenLines.has('cost') && (
              <Line
                type="monotone"
                dataKey="cost"
                name="Coûts"
                stroke="#EF4444"
                strokeWidth={2}
                dot={{ fill: '#EF4444', r: 3 }}
                activeDot={{ r: 5 }}
                animationDuration={800}
                strokeDasharray="5 5"
              />
            )}

            {/* Margin Line */}
            {showMargin && !hiddenLines.has('margin') && (
              <Line
                type="monotone"
                dataKey="margin"
                name="Marge"
                stroke="#10B981"
                strokeWidth={3}
                dot={{ fill: '#10B981', r: 4 }}
                activeDot={{ r: 6 }}
                animationDuration={800}
              />
            )}
          </LineChart>
        </ResponsiveContainer>

        {/* Summary Stats */}
        <div className="mt-6 pt-4 border-t border-gray-800/50">
          <div className="grid grid-cols-3 gap-4 text-sm">
            {showRevenue && (
              <div>
                <p className="text-gray-400 mb-1">Revenue Moyen</p>
                <p className="text-amber-400 font-bold">
                  {formatCurrency(
                    chartData.reduce((sum, d) => sum + d.revenue, 0) / chartData.length
                  )}
                </p>
              </div>
            )}
            {showCost && (
              <div>
                <p className="text-gray-400 mb-1">Coût Moyen</p>
                <p className="text-red-400 font-bold">
                  {formatCurrency(
                    chartData.reduce((sum, d) => sum + d.cost, 0) / chartData.length
                  )}
                </p>
              </div>
            )}
            {showMargin && (
              <div>
                <p className="text-gray-400 mb-1">Marge Moyenne</p>
                <p className="text-emerald-400 font-bold">
                  {formatCurrency(
                    chartData.reduce((sum, d) => sum + d.margin, 0) / chartData.length
                  )}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  )
}
