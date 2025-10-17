'use client'

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import type { ArthurConversionFunnelData } from '@/lib/types/arthur'

interface ConversionFunnelChartProps {
  data: ArthurConversionFunnelData[]
}

export function ConversionFunnelChart({ data }: ConversionFunnelChartProps) {
  const chartData = data.map((item) => ({
    attempt: item.attempt_label,
    'Taux de Conversion': item.conversion_rate,
    'Appels Totaux': item.total_calls,
  }))

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3 flex flex-col h-full">
      <h3 className="text-sm font-semibold text-white mb-2 flex-shrink-0">
        Funnel de Conversion par Tentative
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={chartData} layout="vertical">
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis
            type="number"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '12px' }}
          />
          <YAxis
            type="category"
            dataKey="attempt"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '12px' }}
            width={90}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.8)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
              color: '#fff',
            }}
            formatter={(value: number) => `${value}%`}
          />
          <Bar dataKey="Taux de Conversion" fill="#10b981" radius={[0, 4, 4, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
