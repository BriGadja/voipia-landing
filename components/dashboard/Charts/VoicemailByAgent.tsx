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

interface VoicemailByAgentProps {
  data: Array<{
    agent: string
    rate: number
  }>
}

export function VoicemailByAgent({ data }: VoicemailByAgentProps) {
  const chartData = data
    .map((item) => ({
      agent: item.agent,
      'Taux de messagerie': item.rate,
    }))
    .sort((a, b) => b['Taux de messagerie'] - a['Taux de messagerie'])

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-4">
        Taux de messagerie par agent
      </h3>
      <ResponsiveContainer width="100%" height={320}>
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
          <Bar dataKey="Taux de messagerie" fill="#fb923c" radius={[0, 4, 4, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
