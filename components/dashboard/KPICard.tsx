'use client'

import { motion } from 'framer-motion'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

interface KPICardProps {
  label: string
  value: string | number
  previousValue?: number
  format?: 'number' | 'currency' | 'percentage' | 'duration'
  decorationColor?: 'blue' | 'emerald' | 'amber' | 'red' | 'violet'
  delay?: number
}

const colorClasses = {
  blue: 'from-blue-500/20 to-blue-500/5 border-blue-500/30',
  emerald: 'from-emerald-500/20 to-emerald-500/5 border-emerald-500/30',
  amber: 'from-amber-500/20 to-amber-500/5 border-amber-500/30',
  red: 'from-red-500/20 to-red-500/5 border-red-500/30',
  violet: 'from-violet-500/20 to-violet-500/5 border-violet-500/30',
}

const decorationColors = {
  blue: 'bg-blue-500',
  emerald: 'bg-emerald-500',
  amber: 'bg-amber-500',
  red: 'bg-red-500',
  violet: 'bg-violet-500',
}

export function KPICard({
  label,
  value,
  previousValue,
  format = 'number',
  decorationColor = 'blue',
  delay = 0,
}: KPICardProps) {
  const formatValue = (val: number | string): string => {
    if (typeof val === 'string') return val

    switch (format) {
      case 'currency':
        return `${val.toFixed(2)}€`
      case 'percentage':
        return `${val.toFixed(1)}%`
      case 'duration':
        const minutes = Math.floor(val / 60)
        const seconds = val % 60
        return `${minutes}:${seconds.toString().padStart(2, '0')}`
      default:
        return val.toLocaleString('fr-FR')
    }
  }

  const calculateDelta = (): { value: number; trend: 'up' | 'down' | 'neutral' } | null => {
    if (previousValue === undefined || typeof value === 'string') return null

    const numValue = typeof value === 'number' ? value : parseFloat(value)
    const change = ((numValue - previousValue) / previousValue) * 100

    if (Math.abs(change) < 0.1) return { value: 0, trend: 'neutral' }

    return {
      value: Math.abs(change),
      trend: change > 0 ? 'up' : 'down',
    }
  }

  const delta = calculateDelta()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay }}
      className={`relative overflow-hidden rounded-xl border bg-gradient-to-br backdrop-blur-sm ${colorClasses[decorationColor]}`}
    >
      {/* Decoration bar */}
      <div className={`absolute top-0 left-0 right-0 h-1 ${decorationColors[decorationColor]}`} />

      <div className="p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <p className="text-sm font-medium text-white/60 mb-1">{label}</p>
            <p className="text-3xl font-bold text-white mb-2">
              {formatValue(value)}
            </p>
          </div>

          {delta && (
            <div
              className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${
                delta.trend === 'up'
                  ? 'bg-emerald-500/20 text-emerald-400'
                  : delta.trend === 'down'
                  ? 'bg-red-500/20 text-red-400'
                  : 'bg-gray-500/20 text-gray-400'
              }`}
            >
              {delta.trend === 'up' ? (
                <TrendingUp className="w-3 h-3" />
              ) : delta.trend === 'down' ? (
                <TrendingDown className="w-3 h-3" />
              ) : (
                <Minus className="w-3 h-3" />
              )}
              {delta.value > 0 && (
                <span>
                  {delta.trend === 'up' ? '+' : '-'}
                  {delta.value.toFixed(1)}%
                </span>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Subtle gradient overlay */}
      <div className="absolute bottom-0 left-0 right-0 h-1/2 bg-gradient-to-t from-black/10 to-transparent pointer-events-none" />
    </motion.div>
  )
}
