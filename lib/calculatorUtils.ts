import { CalculatorState, CalculatorResults } from '@/types/calculator'

export function calculateROI(state: CalculatorState): CalculatorResults {
  const costPerCall = state.pricing.perProcessing +
    (state.pricing.perMinute * state.averageCallDuration)

  const monthlyOperational = (costPerCall * state.volume.perMonth) +
    state.additionalCosts.monthlyFee

  const firstYearTotal = state.additionalCosts.integration +
    (monthlyOperational * 12)

  const recurringAnnual = monthlyOperational * 12

  let roi = undefined
  if (state.roi?.averageConversionValue && state.roi?.conversionRate) {
    const monthlyConversions = state.volume.perMonth *
      (state.roi.conversionRate / 100)
    const monthlyRevenue = monthlyConversions *
      state.roi.averageConversionValue
    const monthlyProfit = monthlyRevenue - monthlyOperational

    roi = { monthlyConversions, monthlyRevenue, monthlyProfit }
  }

  return {
    costPerCall,
    monthlyOperational,
    monthlyTotal: monthlyOperational,
    firstYearTotal,
    recurringAnnual,
    roi
  }
}

export function syncVolumeFromMonth(monthlyVolume: number) {
  return {
    perDay: Math.round(monthlyVolume / 30),
    perWeek: Math.round(monthlyVolume / 4.33),
    perMonth: monthlyVolume
  }
}

export function syncVolumeFromDay(dailyVolume: number) {
  const monthly = Math.round(dailyVolume * 30)
  return syncVolumeFromMonth(monthly)
}

export function syncVolumeFromWeek(weeklyVolume: number) {
  const monthly = Math.round(weeklyVolume * 4.33)
  return syncVolumeFromMonth(monthly)
}

export function calculatePlannedVolume(
  frequency: number,
  startTime: string,
  endTime: string,
  activeDays: boolean[]
) {
  const [startHour, startMin] = startTime.split(':').map(Number)
  const [endHour, endMin] = endTime.split(':').map(Number)

  const startMinutes = startHour * 60 + startMin
  const endMinutes = endHour * 60 + endMin

  const minutesPerDay = endMinutes - startMinutes

  if (minutesPerDay <= 0) {
    return syncVolumeFromMonth(0)
  }

  const callsPerDay = Math.floor(minutesPerDay / frequency)
  const activeDaysCount = activeDays.filter(Boolean).length

  if (activeDaysCount === 0) {
    return syncVolumeFromMonth(0)
  }

  const callsPerWeek = callsPerDay * activeDaysCount
  const callsPerMonth = Math.round(callsPerWeek * 4.33)

  return syncVolumeFromMonth(callsPerMonth)
}

export function formatCurrency(value: number, decimals: number = 2): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  }).format(value)
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat('fr-FR').format(value)
}