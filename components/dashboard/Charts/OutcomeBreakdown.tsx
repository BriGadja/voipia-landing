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

interface OutcomeBreakdownProps {
  data: Array<{
    outcome: string
    count: number
  }>
}

const outcomeLabels: Record<string, string> = {
  appointment_scheduled: 'RDV pris',
  appointment_refused: 'RDV refusé',
  not_interested: 'Pas intéressé',
  callback_requested: 'Rappel demandé',
  voicemail: 'Messagerie',
  too_short: 'Trop court',
  no_answer: 'Pas de réponse',
  busy: 'Occupé',
  invalid_number: 'Numéro invalide',
  call_failed: 'Appel échoué',
  do_not_call: 'Ne pas appeler',
}

export function OutcomeBreakdown({ data }: OutcomeBreakdownProps) {
  const chartData = data
    .map((item) => ({
      outcome: outcomeLabels[item.outcome] || item.outcome,
      Appels: item.count,
    }))
    .sort((a, b) => b.Appels - a.Appels)

  return (
    <div className="bg-black/20 border border-white/20 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white mb-4">
        Résultats d&apos;appels
      </h3>
      <ResponsiveContainer width="100%" height={320}>
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
          <Bar dataKey="Appels" fill="#06b6d4" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
