'use client'

import {
  PieChart,
  Pie,
  Tooltip,
  ResponsiveContainer,
  Cell,
  Legend,
} from 'recharts'

interface OutcomeBreakdownProps {
  data: Array<{
    outcome: string
    count: number
  }>
}

const outcomeLabels: Record<string, string> = {
  appointment_scheduled: 'RDV PRIS',
  appointment_refused: 'RDV refusé',
  not_interested: 'Pas intéressé',
  callback_requested: 'Rappel demandé',
  voicemail: 'Messagerie',
  too_short: 'Non significatifs',
  no_answer: 'Pas de réponse',
  busy: 'Occupé',
  invalid_number: 'Numéro invalide',
  call_failed: 'Appel échoué',
  do_not_call: 'Ne pas appeler',
}

// Couleurs spécifiques pour chaque résultat (Louis Dashboard)
const outcomeColors: Record<string, string> = {
  'Messagerie': '#06b6d4',    // cyan
  'RDV refusé': '#8b5cf6',    // violet
  'Non significatifs': '#10b981',      // emerald
  'RDV PRIS': '#f59e0b',      // amber/orange
}

// Fallback colors for other outcomes
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

export function OutcomeBreakdown({ data }: OutcomeBreakdownProps) {
  // Filter to show only 4 specific outcomes for Louis dashboard
  const specificOutcomes = ['voicemail', 'appointment_refused', 'too_short', 'appointment_scheduled']

  const chartData = data
    .filter((item) => specificOutcomes.includes(item.outcome))
    .map((item) => ({
      name: outcomeLabels[item.outcome] || item.outcome,
      value: item.count,
      color: outcomeColors[outcomeLabels[item.outcome]] || colors[0],
    }))
    .sort((a, b) => b.value - a.value)

  // Calculate total for percentages
  const total = chartData.reduce((sum, item) => sum + item.value, 0)

  // Custom label renderer with external labels and connecting lines
  const renderCustomLabel = (props: any) => {
    const { cx, cy, midAngle, outerRadius, name, value } = props
    const RADIAN = Math.PI / 180
    const radius = outerRadius + 30 // Distance from pie to label
    const x = cx + radius * Math.cos(-midAngle * RADIAN)
    const y = cy + radius * Math.sin(-midAngle * RADIAN)

    const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0

    return (
      <text
        x={x}
        y={y}
        fill="#fff"
        textAnchor={x > cx ? 'start' : 'end'}
        dominantBaseline="central"
        className="text-xs font-medium"
      >
        {`${name} : ${value} (${percentage}%)`}
      </text>
    )
  }

  // Custom legend formatter with percentages
  const renderLegend = (props: any) => {
    const { payload } = props
    return (
      <ul className="flex flex-col gap-2 text-sm text-white">
        {payload.map((entry: any, index: number) => {
          const percentage = total > 0 ? ((entry.payload.value / total) * 100).toFixed(1) : 0
          return (
            <li key={`legend-${index}`} className="flex items-center gap-2">
              <span
                className="w-3 h-3 rounded-full flex-shrink-0"
                style={{ backgroundColor: entry.color }}
              />
              <span className="whitespace-nowrap">
                {entry.value} : {percentage}%
              </span>
            </li>
          )
        })}
      </ul>
    )
  }

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3 flex flex-col h-full">
      <h3 className="text-sm font-semibold text-white mb-2 flex-shrink-0">
        Résultats d&apos;appels
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="40%"
            cy="50%"
            innerRadius={50}
            outerRadius={80}
            paddingAngle={2}
            dataKey="value"
            label={renderCustomLabel}
            labelLine={{
              stroke: 'rgba(255,255,255,0.3)',
              strokeWidth: 1,
            }}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(0,0,0,0.95)',
              border: '1px solid rgba(255,255,255,0.3)',
              borderRadius: '8px',
              padding: '8px 12px',
            }}
            labelStyle={{
              color: '#fff',
              fontWeight: 'bold',
              marginBottom: '4px',
            }}
            itemStyle={{
              color: '#fff',
            }}
            separator=" : "
            formatter={(value: number) => {
              const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
              return `${value} appels (${percentage}%)`
            }}
          />
          <Legend
            layout="vertical"
            align="right"
            verticalAlign="middle"
            content={renderLegend}
            wrapperStyle={{ paddingLeft: '20px' }}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
