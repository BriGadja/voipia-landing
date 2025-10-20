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
  too_short: 'TOO_CONF',
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
  'TOO_CONF': '#10b981',      // emerald
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
      outcome: outcomeLabels[item.outcome] || item.outcome,
      Appels: item.count,
    }))
    .sort((a, b) => b.Appels - a.Appels)

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-3 flex flex-col h-full">
      <h3 className="text-sm font-semibold text-white mb-2 flex-shrink-0">
        Résultats d&apos;appels
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis
            dataKey="outcome"
            stroke="rgba(255,255,255,0.6)"
            style={{ fontSize: '11px' }}
            angle={-45}
            textAnchor="end"
            height={100}
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
          <Bar dataKey="Appels" radius={[4, 4, 0, 0]}>
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={outcomeColors[entry.outcome] || colors[index % colors.length]} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
