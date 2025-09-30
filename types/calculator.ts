export interface CalculatorState {
  mode: 'inbound' | 'outbound'
  volume: {
    perDay: number
    perWeek: number
    perMonth: number
  }
  averageCallDuration: number
  pricing: {
    perProcessing: number
    perMinute: number
  }
  additionalCosts: {
    integration: number
    monthlyFee: number
  }
  plannedMode?: {
    enabled: boolean
    frequency: number
    dailySchedule: {
      startTime: string
      endTime: string
    }
    activeDays: boolean[]
  }
  roi?: {
    averageConversionValue: number
    conversionRate: number
  }
}

export interface CalculatorResults {
  costPerCall: number
  monthlyOperational: number
  monthlyTotal: number
  firstYearTotal: number
  recurringAnnual: number
  roi?: {
    monthlyConversions: number
    monthlyRevenue: number
    monthlyProfit: number
  }
}

export interface CalculatorLimits {
  volume: {
    max: number
    min: number
  }
  duration: {
    max: number
    min: number
    step: number
  }
  pricing: {
    maxPerCall: number
    maxPerMinute: number
    step: number
  }
  costs: {
    maxIntegration: number
    maxMonthly: number
  }
}

export interface CalculatorDefaults {
  volume: {
    perDay: number
    perWeek: number
    perMonth: number
  }
  averageCallDuration: number
  pricing: {
    perProcessing: number
    perMinute: number
  }
  additionalCosts: {
    integration: number
    monthlyFee: number
  }
}