'use client'

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts'

interface VoicemailByAgentProps {
  data: Array<{
    agent: string
    rate: number
  }>
}

// Palette de couleurs distinctes pour chaque agent
const colors = [
  '#06b6d4', // cyan
  '#8b5cf6', // violet
  '#10b981', // emerald
  '#f59e0b', // amber
  '#ef4444', // red
  '#ec4899', // pink
  '#14b8a6', // teal
  '#f97316', // orange
  '#6366f1', // indigo
  '#84cc16', // lime
  '#a855f7', // purple
]

export function VoicemailByAgent({ data }: VoicemailByAgentProps) {
  const chartData = data
    .map((item) => ({
      agent: item.agent,
      'Taux de messagerie': item.rate,
    }))
    .sort((a, b) => b['Taux de messagerie'] - a['Taux de messagerie'])

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3">
      <h3 className="text-sm font-semibold text-white mb-2">
        Taux de messagerie par agent
      </h3>
      <ResponsiveContainer width="100%" height={210}>
        <BarChart data={chartData} layout="vertical">
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis
            type="number"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '12px' }}
            tickFormatter={(value) => `${value}%`}
          />
          <YAxis
            type="category"
            dataKey="agent"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '12px' }}
            width={120}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.8)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
              color: '#fff',
            }}
            formatter={(value: number) => `${value.toFixed(1)}%`}
          />
          <Bar dataKey="Taux de messagerie" radius={[0, 4, 4, 0]}>
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
