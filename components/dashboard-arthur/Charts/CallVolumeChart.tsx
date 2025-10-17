'use client'

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'
import type { ArthurCallVolumeData } from '@/lib/types/arthur'
import { useMemo } from 'react'

interface CallVolumeChartProps {
  data: ArthurCallVolumeData[]
}

const ATTEMPT_COLORS = [
  { stroke: '#06b6d4', fill: '#06b6d4', opacity: 0.8 }, // blue - Tentative 1
  { stroke: '#8b5cf6', fill: '#8b5cf6', opacity: 0.7 }, // violet - Tentative 2
  { stroke: '#f59e0b', fill: '#f59e0b', opacity: 0.7 }, // amber - Tentative 3
  { stroke: '#10b981', fill: '#10b981', opacity: 0.6 }, // emerald - Tentative 4
  { stroke: '#f43f5e', fill: '#f43f5e', opacity: 0.6 }, // rose - Tentative 5
  { stroke: '#06b6d4', fill: '#06b6d4', opacity: 0.5 }, // cyan - Tentative 6
  { stroke: '#ea580c', fill: '#ea580c', opacity: 0.5 }, // orange - Tentative 7
]

export function CallVolumeChart({ data }: CallVolumeChartProps) {
  // ⚠️ CRITICAL: Dynamic category extraction based on actual data
  // This ensures the chart adapts to max_attempts (3, 5, 7, etc.)
  const { chartData, categories } = useMemo(() => {
    // Transform data: group by day, create columns for each attempt
    const transformed = data.reduce((acc, item) => {
      const existingDay = acc.find((d) => d.day === item.day)
      if (existingDay) {
        existingDay[item.attempt_label] = item.count
      } else {
        acc.push({
          day: new Date(item.day).toLocaleDateString('fr-FR', {
            month: 'short',
            day: 'numeric',
          }),
          [item.attempt_label]: item.count,
        })
      }
      return acc
    }, [] as any[])

    // Dynamically extract all unique attempt labels
    // This ensures the chart adapts to max_attempts (3, 5, 7, etc.)
    const uniqueAttempts = Array.from(
      new Set(data.map((item) => item.attempt_label))
    ).sort() // Sort to ensure "Tentative 1", "Tentative 2", "Tentative 3"...

    return {
      chartData: transformed,
      categories: uniqueAttempts,
    }
  }, [data])

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3 flex flex-col h-full">
      <h3 className="text-sm font-semibold text-white mb-2 flex-shrink-0">
        Volume d&apos;appels par jour
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={chartData}>
          <defs>
            {categories.map((_, index) => (
              <linearGradient
                key={`gradient-${index}`}
                id={`colorAttempt${index}`}
                x1="0"
                y1="0"
                x2="0"
                y2="1"
              >
                <stop
                  offset="5%"
                  stopColor={ATTEMPT_COLORS[index % ATTEMPT_COLORS.length].fill}
                  stopOpacity={ATTEMPT_COLORS[index % ATTEMPT_COLORS.length].opacity}
                />
                <stop
                  offset="95%"
                  stopColor={ATTEMPT_COLORS[index % ATTEMPT_COLORS.length].fill}
                  stopOpacity={0.1}
                />
              </linearGradient>
            ))}
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis
            dataKey="day"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '12px' }}
          />
          <YAxis stroke="rgba(255,255,255,0.6)" style={{ fontSize: '12px' }} />
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.8)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
              color: '#fff',
            }}
          />
          <Legend wrapperStyle={{ color: '#fff' }} />
          {categories.map((category, index) => (
            <Area
              key={category}
              type="monotone"
              dataKey={category}
              stroke={ATTEMPT_COLORS[index % ATTEMPT_COLORS.length].stroke}
              strokeWidth={2}
              fill={`url(#colorAttempt${index})`}
            />
          ))}
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
