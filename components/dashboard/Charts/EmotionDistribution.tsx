'use client'

import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'

interface EmotionDistributionProps {
  data: Array<{
    emotion: string
    count: number
  }>
}

const emotionLabels: Record<string, string> = {
  positive: 'Positive',
  neutral: 'Neutre',
  negative: 'Négative',
  unknown: 'Inconnue',
}

const emotionColors: Record<string, string> = {
  positive: '#84cc16',
  neutral: '#fbbf24',
  negative: '#fb7185',
  unknown: '#94a3b8',
}

export function EmotionDistribution({ data }: EmotionDistributionProps) {
  const chartData = data.map((item) => ({
    name: emotionLabels[item.emotion] || emotionLabels.unknown,
    value: item.count,
    color: emotionColors[item.emotion] || emotionColors.unknown,
  }))

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-4">
        Distribution des émotions
      </h3>
      <ResponsiveContainer width="100%" height={320}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={100}
            paddingAngle={2}
            dataKey="value"
            label={({ name, value }) => `${name}: ${value}`}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.8)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
              color: '#fff',
            }}
            formatter={(value: number) => `${value} appels`}
          />
          <Legend wrapperStyle={{ color: '#fff' }} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
