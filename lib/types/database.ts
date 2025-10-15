export type CallOutcome =
  | 'appointment_scheduled'
  | 'appointment_refused'
  | 'not_interested'
  | 'callback_requested'
  | 'voicemail'
  | 'too_short'
  | 'no_answer'
  | 'busy'
  | 'invalid_number'
  | 'call_failed'
  | 'do_not_call'

export type Emotion = 'positive' | 'neutral' | 'negative'

export type AgentType = 'inbound' | 'outbound'

export type AgentStatus = 'active' | 'inactive' | 'archived'

export type PermissionLevel = 'read' | 'write' | 'admin'

export interface Client {
  id: string
  name: string
  industry: string | null
  webhook_url: string | null
  created_at: string
  updated_at: string
}

export interface Agent {
  id: string
  client_id: string
  name: string
  type: AgentType | null
  status: AgentStatus
  metadata: Record<string, any>
  created_at: string
  updated_at: string
}

export interface Call {
  id: string
  client_id: string
  agent_id: string | null
  first_name: string | null
  last_name: string | null
  email: string | null
  phone: string | null
  started_at: string
  duration_seconds: number | null
  cost: number | null
  emotion: Emotion | null
  appointment_scheduled_at: string | null
  transcript: string | null
  transcript_summary: string | null
  call_outcome: CallOutcome | null
  metadata: Record<string, any> | null
  created_at: string
  updated_at: string
}

export interface UserClientPermission {
  user_id: string
  client_id: string
  permission_level: PermissionLevel
  created_at: string
}

export interface KPIMetrics {
  current_period: {
    appointments_scheduled: number
    answer_rate: number
    avg_duration: number
    avg_cost: number
    conversion_rate: number
    total_cost: number
    total_calls: number
    cpa: number
  }
  previous_period: {
    appointments_scheduled: number
    answer_rate: number
    avg_duration: number
    avg_cost: number
    conversion_rate: number
    total_calls: number
  }
}

export interface ChartData {
  call_volume_by_day: Array<{
    date: string
    total_calls: number
    answered_calls: number
    appointments: number
  }>
  emotion_distribution: Array<{
    emotion: string
    count: number
  }>
  outcome_distribution: Array<{
    outcome: string
    count: number
  }>
  voicemail_by_agent: Array<{
    agent: string
    rate: number
  }>
}

export interface DashboardFilters {
  startDate: Date
  endDate: Date
  clientIds: string[]
  agentIds: string[]
}
