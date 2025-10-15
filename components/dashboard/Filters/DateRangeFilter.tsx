'use client'

import { useState } from 'react'
import DatePicker, { registerLocale } from 'react-datepicker'
import { fr } from 'date-fns/locale'
import { subDays, startOfMonth, endOfMonth, startOfYear, endOfYear } from 'date-fns'
import 'react-datepicker/dist/react-datepicker.css'
import './datepicker.css'

registerLocale('fr', fr)

interface DateRangeFilterProps {
  startDate: Date
  endDate: Date
  onChange: (startDate: Date, endDate: Date) => void
}

const PRESETS = {
  today: () => ({ start: new Date(), end: new Date() }),
  last7Days: () => ({ start: subDays(new Date(), 7), end: new Date() }),
  last30Days: () => ({ start: subDays(new Date(), 30), end: new Date() }),
  thisMonth: () => ({
    start: startOfMonth(new Date()),
    end: endOfMonth(new Date()),
  }),
  lastMonth: () => {
    const lastMonth = subDays(startOfMonth(new Date()), 1)
    return { start: startOfMonth(lastMonth), end: endOfMonth(lastMonth) }
  },
  thisYear: () => ({
    start: startOfYear(new Date()),
    end: endOfYear(new Date()),
  }),
}

export function DateRangeFilter({
  startDate,
  endDate,
  onChange,
}: DateRangeFilterProps) {
  const handlePreset = (key: keyof typeof PRESETS) => {
    const { start, end } = PRESETS[key]()
    onChange(start, end)
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-2">
        <DatePicker
          selected={startDate}
          onChange={(date) => date && onChange(date, endDate)}
          selectsStart
          startDate={startDate}
          endDate={endDate}
          dateFormat="dd/MM/yyyy"
          locale="fr"
          className="px-2 py-1.5 text-sm border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
          placeholderText="Date début"
        />
        <span className="text-white/60">→</span>
        <DatePicker
          selected={endDate}
          onChange={(date) => date && onChange(startDate, date)}
          selectsEnd
          startDate={startDate}
          endDate={endDate}
          minDate={startDate}
          dateFormat="dd/MM/yyyy"
          locale="fr"
          className="px-2 py-1.5 text-sm border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
          placeholderText="Date fin"
        />
      </div>

      <div className="flex flex-wrap gap-1.5">
        <button
          onClick={() => handlePreset('today')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          Aujourd&apos;hui
        </button>
        <button
          onClick={() => handlePreset('last7Days')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          7 derniers jours
        </button>
        <button
          onClick={() => handlePreset('last30Days')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          30 derniers jours
        </button>
        <button
          onClick={() => handlePreset('thisMonth')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          Ce mois
        </button>
        <button
          onClick={() => handlePreset('lastMonth')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          Mois dernier
        </button>
        <button
          onClick={() => handlePreset('thisYear')}
          className="px-2 py-1 text-xs border border-white/20 rounded-lg hover:bg-white/10 text-white transition-colors"
        >
          Cette année
        </button>
      </div>
    </div>
  )
}
