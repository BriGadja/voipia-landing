// ============================================================================
// Arthur Dashboard TypeScript Interfaces
// Based on: INITIAL_dashboard_arthur.md
// RPC Functions: get_arthur_kpi_metrics, get_arthur_chart_data
// ============================================================================

// ============================================================================
// KPI Metrics - Returned by get_arthur_kpi_metrics()
// ============================================================================

export interface ArthurKPIPeriod {
  reactivation_rate: number // % - (conversions / prospects) * 100
  cost_per_conversion: number // € - total cost / conversions
  avg_duration_per_attempt: number // seconds - average call duration
  appointments_scheduled: number // count - number of appointments scheduled
  answer_rate_attempt_1: number // % - answer rate for first attempt
}

export interface ArthurKPIMetrics {
  current_period: ArthurKPIPeriod
  previous_period: ArthurKPIPeriod
}

// ============================================================================
// Chart Data Structures - Returned by get_arthur_chart_data()
// ============================================================================

export interface ArthurCallVolumeData {
  day: string // ISO date YYYY-MM-DD - Ex: "2025-01-15"
  attempt_label: string // Ex: "Tentative 1", "Tentative 2", ...
  count: number // Number of calls
}

export interface ArthurConversionFunnelData {
  attempt_label: string // Ex: "Tentative 1"
  current_attempt: number // Ex: 1
  total_calls: number
  answered_calls: number
  conversions: number
  conversion_rate: number // % - (conversions / total_calls) * 100
}

export interface ArthurOutcomeDistributionData {
  outcome: string // French category: "Converti", "Callback", "Pas intéressé", etc.
  count: number
}

export interface ArthurSegmentPerformanceData {
  segment: string // Ex: "Chaud", "Froid", "Non segmenté"
  total_calls: number
  conversions: number
  conversion_rate: number // % - (conversions / total_calls) * 100
}

export interface ArthurChartData {
  call_volume_by_day: ArthurCallVolumeData[]
  conversion_funnel: ArthurConversionFunnelData[]
  outcome_distribution: ArthurOutcomeDistributionData[]
  segment_performance: ArthurSegmentPerformanceData[]
}

// ============================================================================
// Enriched Call - For CSV exports (uses v_arthur_calls_enriched view)
// ============================================================================

export interface ArthurCallEnriched {
  // Call info
  call_id: string
  started_at: string
  ended_at: string
  duration_seconds: number
  cost: number
  answered: boolean // Derived: (outcome != 'voicemail')
  call_outcome: string // agent_calls.outcome
  appointment_scheduled_at: string | null // metadata->>'appointment_scheduled_at'
  call_recording_url: string | null
  transcript: string | null

  // Prospect info
  prospect_id: string
  first_name: string
  last_name: string
  email: string
  phone: string // agent_arthur_prospects.phone_number
  company: string // agent_arthur_prospects.company_name
  external_source: string // Ex: 'pipedrive'
  external_deal_id: string
  prospect_status: string // 'active', 'converted', 'lost', 'blacklisted'
  ai_analysis: Record<string, any> // JSONB - {segment, score, reason}

  // Sequence info
  sequence_id: string
  sequence_number: number
  current_attempt: number
  max_attempts: number
  sequence_status: string // 'active', 'completed', 'failed', etc.
  sequence_outcome: string | null
  next_action_at: string | null

  // Agent & Client info
  agent_deployment_id: string
  agent_type_id: string // ⚠️ agent_types.id (NOT agent_id)
  client_id: string
  agent_name: string // agent_types.display_name
  client_name: string

  // Derived fields
  derived_status: 'converted' | 'callback' | 'lost' | 'blacklisted' | 'in_progress'
  attempt_label: string // Ex: "Tentative 3"
  ai_segment: string | null // ai_analysis->>'segment'
  ai_score: string | null
  ai_reason: string | null
}
