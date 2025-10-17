'use client'

import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import type { ArthurOutcomeDistributionData } from '@/lib/types/arthur'

interface OutcomeBreakdownChartProps {
  data: ArthurOutcomeDistributionData[]
}

const COLORS = ['#10b981', '#06b6d4', '#f59e0b', '#ef4444', '#6b7280', '#64748b']

export function OutcomeBreakdownChart({ data }: OutcomeBreakdownChartProps) {
  const chartData = data.map((item) => ({
    name: item.outcome,
    value: item.count,
  }))

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3 flex flex-col h-full">
      <h3 className="text-sm font-semibold text-white mb-2 flex-shrink-0">
        Distribution des Outcomes
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={100}
            fill="#8884d8"
            dataKey="value"
            label
          >
            {chartData.map((_, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.8)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
              color: '#fff',
            }}
          />
          <Legend wrapperStyle={{ color: '#fff' }} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
